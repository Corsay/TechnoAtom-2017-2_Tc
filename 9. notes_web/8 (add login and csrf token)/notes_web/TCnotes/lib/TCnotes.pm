package TCnotes;
use utf8;
use Dancer2;
use Dancer2::Plugin::Database;
use Dancer2::Plugin::CSRF;
use Digest::CRC qw(crc64);
use Digest::MD5 qw(md5_hex);
use HTML::Entities;

our $VERSION = '0.2';

my $redirect_dir = undef;	# для перенаправления
my $upload_dir = 'note';

sub get_upload_dir {	# получаем каталог с файлами
	return config->{appdir} . '/' . $upload_dir . '/';
}

sub delete_entry {	# получает на вход $id, удаляем запись из бд
	my $id = shift;
	database->do('DELETE FROM note WHERE id = cast(? as signed)', {}, $id);
	unlink get_upload_dir . $id if (-e get_upload_dir . $id);
}

# страница со ссылками на заметки текущего пользователя
get '/MyNotes' => sub {
	my $owner = session('user_login');	# текущий пользователь

	# забираем из бд только валидные заметки для текущего пользователя ($owner -> строка, поэтому (для избегания SQL injection) делаем prepare)
	my $sth = database->prepare(
		'SELECT cast(id as unsigned) as id, create_time, title FROM note where (owner = ? and (expire_time is null or expire_time > current_timestamp)) order by create_time desc;'
	);
	$sth->execute($owner);
	my $MyNotes = $sth->fetchall_arrayref( {} );

	# форматируем данные из бд (XSS, Pack)
	for (@$MyNotes) {
		$_->{title} = encode_entities($_->{title}, '<>&"');	# борьба с xss
		$_->{id} = unpack 'H*', pack 'Q', $_->{id};
	}

	return template 'my_note_show.tt' => {MyNotes => $MyNotes, csrf_token => get_csrf_token() };
};

# просматриваемая заметка (с проверкой разрешения (авторизацией))
get qr{^/([a-f0-9]{16})$} => sub {
	my ($id) = splat;
	my $owner = session('user_login');
	$id = unpack 'Q', pack 'H*', $id;	# распаковываем id из 16-ного числа

	my $sth = database->prepare('SELECT cast(id as unsigned) as id, create_time, unix_timestamp(expire_time) as expire_time, title FROM note where id = cast(? as signed);');

	unless ($sth->execute($id)+0) {	# если select ничего не вернул (т.е. вернул "0E0")
		unlink get_upload_dir . $id if (-e get_upload_dir . $id);	# удаляем файл (если в бд нет записи, не факт что вычищен и файл из папки)
		response->status(404);	# возвращаем ответ 404 - не найдено
		return template 'index' => {err => ['Note not found'], csrf_token => get_csrf_token()};	# рендерим основную страницу(не страницу 404), передавая параметром ошибки (для их вывода пользователю)
	}

	# если у пользователя нет допуска к данной заметке
	my $sth2 = database->prepare('SELECT login, cast(note_id as unsigned) as note_id FROM user_note where (login = ? and note_id = cast(? as signed));');
	unless ($sth2->execute($owner, $id)+0) {	# если select ничего не вернул (т.е. вернул "0E0") (то считаем пользователя не авторизованным)
		response->status(404);	# возвращаем ответ 404 - не найдено
		return template 'index' => {err => ['Note not found'], csrf_token => get_csrf_token()};	# рендерим основную страницу(не страницу 404), передавая параметром ошибки (для их вывода пользователю)
	}

	# если же запрос выполнился, пробуем получить эту запись
	my $db_res = $sth->fetchrow_hashref();
	# проверяем expire_time (на случай если на момент выборки expire_time истек (и cron не успел подчистить))
	if ($db_res->{expire_time} and $db_res->{expire_time} < time()) {	# если просрочено, то
		delete_entry($id);	# удаляем запись
		response->status(404);	# возвращаем ответ 404 - не найдено
		return template 'index' => {err => ['Note expired'], csrf_token => get_csrf_token()};
	}

	# читаем контент
	my $fh;
	unless (open($fh, '<:utf8', get_upload_dir . $id)) {	# если не удалось открыть, но в базе есть запись, то
		delete_entry($id);
		response->status(404);	# возвращаем ответ 404 - не найдено
		return template 'index' => {err => ['Note not found'], csrf_token => get_csrf_token() };
	}
	my @text = <$fh>;
	close($fh);

	my $title = encode_entities($db_res->{title}, '<>&"');	# борьба с xss
	for(@text) {
		$_ = encode_entities($_, '<>&"');	# борьба с xss
		# "так как браузер табуляцию и начальные пробелы съест и ничего красивого не выйдет"
		s/\t/&nbsp;&nbsp;&nbsp;&nbsp;/g;	# замена табуляции на 4 пробела
		s/^ /&nbsp;/g;	# замена пробелов в начале строки
	}
	return template 'note_show.tt' => {
		id => $id, text => \@text, raw => join('', @text), create_time => $db_res->{create_time},
		expire_time => $db_res->{expire_time}, title => $title,
		csrf_token => get_csrf_token()
	};
};

# главная страница
get '/' => sub {
    template 'index', { csrf_token => get_csrf_token() };
};

# главная страница, создание заметки
post '/' => sub {
	my $owner = session('user_login');	# текущий пользователь
	my $text = params->{textnote};		# текст
	my $title = params->{title}||'';	# заголовок(название)			(опционально)
	my $expire = params->{expire};		# время жизни (0 = бесконечно)	(опционально)

	# ToDo добавить пользователей которые могут читать заметку

	my @err = ();
	if (!$text) {	# пустой текст -> ошибка
		push @err, 'Empty text';
	}
	if(length($text) > 10240) {	# больше 10кб -> ошибка
		push @err, 'Text too large';
	}
	if ($expire =~ /\D/ or $expire < 0 or $expire > 3600*24*365) {	# проверем expire на наличие гадостей
		push @err, 'Expare more then 365 days or bad format';
	}
	if (@err) {	# если хоть одна ошибка
		$text = encode_entities($text, '<>&"');	# борьба с xss
		$title = encode_entities($title, '<>&"');
		return template 'index' => {text => $text, title => $title, expire => $expire, err => \@err};	# заполняем введенными пользователем данными форму
	}

	my $create_time = time();		# время создания (время прихода запроса на сервер)
	my $expire_time = $expire ? $create_time + $expire : undef;

	my $sth = database->prepare('INSERT INTO note (id, owner, create_time, expire_time, title) VALUES (cast(? as signed), ?, from_unixtime(?), from_unixtime(?), ?);');

	my $id = '';
	my $try_count = 10;
	while (!$id or -f get_upload_dir.$id) {	# если id (undef,'') или существует файл то входим
		database->do('DELETE FROM note WHERE id = cast(? as signed);', {}, $id) if $id;	# если id не (undef,'')(т.е. добавили в бд успешно, но файл уже существовал),то удаляем сделанную запись
		unless (--$try_count) {	# если превышен лимит попыток добавления
			$id = undef;
			last;
		}
		$id = crc64($text.$create_time . $id);
		$id = undef unless $sth->execute($id, $owner, $create_time, $expire_time, $title);	# если добавление не удалось (id уже есть в базе)
	}
	unless ($id) {	# если id в итоге стал undef (не удалось за 10 проходов)
		response->status(500);	# возвращаем ответ 500 - ошибка с нашей стороны
		return template 'index' => {err => ['Try later']};
	}

	# Добавим права доступа на чтение заметки
	$sth = database->prepare('INSERT INTO user_note (login, note_id) VALUES (?, cast(? as signed));');
	unless ($sth->execute($owner,$id)) {
		response->status(500);	# возвращаем ответ 500 - ошибка с нашей стороны
		return template 'index' => {err => ['Internal server error']};
	}

	# ToDo добавить права на чтение перечисленным в списке пользователям

	# попробуем открыть файл и записать в него данные(заметку)
	my $fh;
	unless (open($fh, '>', get_upload_dir . $id)) {
		response->status(500);	# возвращаем ответ 500 - ошибка с нашей стороны
		return template 'index' => {err => ['Internal error '.$!]};
	}
	print $fh $text;
	close($fh);
	redirect '/' . unpack 'H*', pack 'Q', $id;	# пакуем и делаем redirect
};

# форма авторизации
get '/login' => sub {
	if (!session('user_login')) {
		template 'login', { csrf_token => get_csrf_token() };
	}
	else {
		redirect '/';	# если пользователь уже авторизован
	}
};

# принимаем данные из login формы
post '/login' => sub {
	my $user_login = params->{user_login};				# логин пользователя
	my $user_password = params->{user_password};		# чистый пароль
	my $user_name = params->{user_name} || 'Unnamed';	# имя пользователя	(опционально)	# используется в шаблоне -> возможен XSS

	# проверим параметры
	my @err = ();
	if (!$user_login) {	# пустой логин -> ошибка
		push @err, 'Empty login';
	}
	if (!$user_password) {	# пустой пароль -> ошибка
		push @err, 'Empty pass';
	}
	if ($user_password =~ /^\d+$/) {	# пароль только из цифр -> ошибка
		push @err, 'To easy password, add some word';
	}
	if (@err) {	# если хоть одна ошибка
		$user_login = encode_entities($user_login, '<>&"');
		$user_name = encode_entities($user_name, '<>&"');
		return template 'login' => {user_login => $user_login, user_name_ins => $user_name, err => \@err, csrf_token => get_csrf_token()};	# заполняем введенными пользователем данными форму
	}

	# кодируем пароль
	my $SALT = 'TCnotes web appl';
	$user_password = md5_hex($user_password . $SALT);

	# Проверяем наличие пользователя с указанным логином
	my $sth = database->prepare('SELECT * FROM user WHERE (login = ?);');
	if ($sth->execute($user_login)+0) {	# если пользователь есть (проверим пароль)
		my $user = $sth->fetchrow_hashref();
		if ($user->{pass} ne $user_password) {	# если пароль не соответствует вернемся
			$user_login = encode_entities($user_login, '<>&"');
			$user_name = encode_entities($user_name, '<>&"');
			return template 'login' => {user_login => $user_login, user_name_ins => $user_name, err => ['Unknown pare: login password'], csrf_token => get_csrf_token()};
		}
		$user_name = $user->{name};
	}
	else {	# если пользовател нет (добавим)
		$sth = database->prepare('INSERT INTO user (login, pass, name) VALUES (?, ?, ?);');
		$sth->execute($user_login, $user_password, $user_name);
	}

	# запоминаем сессию
	session user_login => $user_login;
	session user_name => encode_entities($user_name, '<>&"');	# защищать от XSS (используется в приветствии в main)

	# перенаправляем на запрошенную страницу
	my $redirect = $redirect_dir;
	$redirect_dir = undef;
	redirect $redirect || '/';
};

# выполняем перед всем
hook before => sub {
	set session => 'simple';	# volatile, in memory session

	# Проверяем авторизованность пользователя
	if (!session('user_login') && request->path_info !~ m{^/login}) {
        $redirect_dir = request->path_info;  
		redirect 'login';
    }
    # CSRF
	if ( request->is_post() ) {
		my $csrf_token = params->{'csrf_token'};
		if ( !$csrf_token || !validate_csrf_token($csrf_token) ) {
			redirect 'login';
		}
	}
};

# Выполняем перед загрузкой каждого шаблона
hook before_template_render => sub {
	my $tokens = shift;	# хеш переменных переданных шаблону перед которым вызывается hook before_template_render

	# Добавим PageTitle
	$tokens->{PageTitle} = 'TCnotes';
	# Добавим имя для приветствия
	$tokens->{user_name} = session('user_name');
	# разрешение выводить некоторую информацию (login использует тот же main layout и там блокируем вывод бокового меню)
	if (!session('user_login')) { $tokens->{ACCEPT} = 0; }
	else { $tokens->{ACCEPT} = 1; }

	# Заполняем ExpireMas (для Select) (для шаблона index.tt)
	my $ExpireMas = [
		{ value => 0, text => 'Never' },
		{ value => 600, text => '10 min' },
		{ value => 3600, text => '1 hour' },
		{ value => 86400, text => '1 day' },
		{ value => 604800, text => '1 week' },
		{ value => 31536000, text => '365 day' },
	];
	$tokens->{ExpireMas} = $ExpireMas;

	# Добавим в него последние 10 добавленных записей доступных текущему пользователю
	if (session('user_login')) {
		my $sth = database->prepare(
			'SELECT cast(id as unsigned) as id, create_time, title
			FROM note N JOIN user_note U ON N.owner = U.login
			where (N.owner = ? and (expire_time is null or expire_time > current_timestamp)) order by create_time desc limit 10;',
		);
		$sth->execute(session('user_login'));
		my $last_note = $sth->fetchall_arrayref( {} );

		for (@$last_note) {
			$_->{title} = encode_entities($_->{title}, '<>&"');	# борьба с xss
			$_->{id} = unpack 'H*', pack 'Q', $_->{id};
		}
		$tokens->{last_note} = $last_note;
	}
};

true;
