package TCnotes;
use utf8;
use Dancer2;
use Dancer2::Plugin::Database;
use Digest::CRC qw(crc64);
use HTML::Entities;

our $VERSION = '0.1';

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

	# ToDo доделать

	# забираем из бд только валидные заметки для текущего пользователя
	my $MyNotes = database->selectall_arrayref(
		'SELECT cast(id as unsigned) as id, create_time, title FROM note where (expire_time is null or expire_time > current_timestamp) order by create_time desc limit 10;',
		{ Slice => {} }
	);
	# форматируем данные из бд (XSS, Pack)
	for (@$MyNotes) {
		$_->{title} = encode_entities($_->{title}, '<>&"');	# борьба с xss
		$_->{id} = unpack 'H*', pack 'Q', $_->{id};
	}

	return template 'my_note_show.tt' => {MyNotes => $MyNotes};
};

# просматриваемая заметка
get qr{^/([a-f0-9]{16})$} => sub {
	my ($id) = splat;
	$id = unpack 'Q', pack 'H*', $id;	# распаковываем id из 16-ного числа

	my $sth = database->prepare('SELECT cast(id as unsigned) as id, create_time, unix_timestamp(expire_time) as expire_time, title FROM note where id = cast(? as signed);');
	unless ($sth->execute($id)) {	# если select ничего не вернул
		response->status(404);	# возвращаем ответ 404 - не найдено
		return template 'index' => {err => ['Note not found']};	# рендерим основную страницу(не страницу 404), передавая параметром ошибки (для их вывода пользователю)
	}
	# если же запрос выполнился, пробуем получить эту запись
	my $db_res = $sth->fetchrow_hashref();
	# проверяем expire_time (на случай если на момент выборки expire_time истек (и cron не успел подчистить))
	if ($db_res->{expire_time} and $db_res->{expire_time} < time()) {	# если просрочено, то
		delete_entry($id);	# удаляем запись
		response->status(404);	# возвращаем ответ 404 - не найдено
		return template 'index' => {err => ['Note expired']};
	}
	# читаем контент
	my $fh;
	unless (open($fh, '<:utf8', get_upload_dir . $id)) {	# если не удалось открыть, но в базе есть запись, то
		delete_entry($id);
		response->status(404);	# возвращаем ответ 404 - не найдено
		return template 'index' => {err => ['Note not found']};
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
		expire_time => $db_res->{expire_time}, title => $title
	};
};

# главная страница
get '/' => sub {
    template 'index';
};

# главная страница, создание заметки
post '/' => sub {
	my $text = params->{textnote};		# текст
	my $title = params->{title}||'';	# заголовок(название)			(опционально)
	my $expire = params->{expire};		# время жизни (0 = бесконечно)	(опционально)

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

	my $sth = database->prepare('INSERT INTO note (id, create_time, expire_time, title) VALUES (cast(? as signed), from_unixtime(?), from_unixtime(?), ?);');

	my $id = '';
	my $try_count = 10;
	while (!$id or -f get_upload_dir.$id) {	# если id (undef,'') или существует файл то входим
		database->do('DELETE FROM note WHERE id = cast(? as signed);', {}, $id) if $id;	# если id не (undef,'')(т.е. добавили в бд успешно, но файл уже существовал),то удаляем сделанную запись
		unless (--$try_count) {	# если превышен лимит попыток добавления
			$id = undef;
			last;
		}
		$id = crc64($text.$create_time . $id);
		$id = undef unless $sth->execute($id, $create_time, $expire_time, $title);	# если добавление не удалось (id уже есть в базе)
	}
	unless ($id) {	# если id в итоге стал undef (не удалось за 10 проходов)
		die 'Try latter';
	}

	my $fh;
	unless (open($fh, '>', get_upload_dir . $id)) {
		die 'Internal error '.$!;
	}
	print $fh $text;
	close($fh);
	redirect '/' . unpack 'H*', pack 'Q', $id;	# пакуем и делаем redirect
};

# Выполняем перед загрузкой каждого шаблона
hook before_template_render => sub {
	my $tokens = shift;	# хеш переменных переданных шаблону перед которым вызывается hook before_template_render

	# Добавим PageTitle
	$tokens->{PageTitle} = 'TCnotes';

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

	# Добавим в него последние 10 добавленных записей
	my $last_note = database->selectall_arrayref(
		'SELECT cast(id as unsigned) as id, create_time, title FROM note where (expire_time is null or expire_time > current_timestamp) order by create_time desc limit 10;',
		{ Slice => {} }
	);
	for (@$last_note) {
		$_->{title} = encode_entities($_->{title}, '<>&"');	# борьба с xss
		$_->{id} = unpack 'H*', pack 'Q', $_->{id};
	}
	$tokens->{last_note} = $last_note;
};

true;
