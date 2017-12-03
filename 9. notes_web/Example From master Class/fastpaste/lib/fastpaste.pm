package fastpaste;
use utf8;
use Dancer2;
use Dancer2::Plugin::Database;
use Digest::CRC qw(crc64);
use HTML::Entities;

our $VERSION = '0.1';

my $upload_dir = 'paste';

sub get_upload_dir {	# получаем каталог с файлами
	return config->{appdir} . '/' . $upload_dir . '/';
}

sub delete_entry {	# получает на вход $id, удаляем запись из бд
	my $id = shift;
	database->do('DELETE FROM paste WHERE id = cast(? as signed)', {}, $id);
	unlink get_upload_dir . $id;
}

get qr{^/([a-f0-9]{16})$} => sub {
	my ($id) = splat;
	$id = unpack 'Q', pack 'H*', $id;	# распаковываем id из 16-ного числа

	# ToDo validate params	

	my $sth = database->prepare('SELECT cast(id as unsigned), create_time, unix_timestamp(expire_time), title FROM paste where id = cast(? as signed);');
	unless ($sth->execute($id)) {	# если select ничего не вернул
		responce->status(404);	# возвращаем ответ 404 - не найдено
		return template 'index' => {err => ['Fast paste not found']};	# рендерим основную страницу(не страницу 404), передавая параметром ошибки (для их вывода пользователю)
	}
	# если же запрос выполнился, пробуем получить эту запись
	my $db_res = $sth->fetchrow_hashref();
	# проверяем expire_time (на случай если на момент выборки expire_time истек (и cron не успел подчистить))
	if ($db_res->{expire_time} and $db_res->{expire_time} < time()) {	# если просрочено, то
		delete_entry($id);	# удаляем запись
		responce->status(404);	# возвращаем ответ 404 - не найдено
		return template 'index' => {err => ['Fast paste expired']};
	}
	# читаем контент
	my $fh;
	unless (open($fh, '<:utf8', get_upload_dir . $id)) {	# если не удалось открыть, но в базе есть запись, то
		die 'Internal error '.$!;
		responce->status(404);	# возвращаем ответ 404 - не найдено
		return template 'index' => {err => ['Fast paste not found']};
	}
	my @text = <$fh>;
	close($fh);

	for(@text) {
		$_ = encode_entities($_, '<>&"');	# борьба с xss
		# "так как браузер табуляцию и начальные пробелы съест и ничего красивого не выйдет"
		s/\t/&nbsp;&nbsp;&nbsp;&nbsp;/g;	# замена табуляции на 4 пробела
		s/^ /&nbsp;/g;	# замена пробелов в начале строки 
	}
	return template 'paste_show.tt' => {
		id => $id, text => \@text, raw => join('', @text), create_time => $db_res->{create_time}, 
		expire_time => $db_res->{expire_time}, title => $db_res->{title}
	};
};

get '/' => sub {
    template 'index';
};

post '/' => sub {
	my $text = params->{textpaste};		# текст 
	my $title = params->{title}||'';	# заголовок(название)
	my $expire = params->{expire};		# время жизни (0 = бесконечно)

	# ToDo validate params

	my $create_time = time();		# время создания (время прихода запроса на сервер)
	my $expire_time = $expire ? $create_time + $expire : undef;

	my $sth = database->prepare('INSERT INTO paste (id, create_time, expire_time, title) VALUES (cast(? as signed), from_unixtime(?), from_unixtime(?), ?);');

	my $id = '';
	my $try_count = 10;
	while (!$id or -f get_upload_dir.$id) {	# если id (undef,'') или существует файл то входим
		database->do('DELETE FROM paste WHERE id = cast(? as signed);', {}, [$id]) if $id;	# если id не (undef,'')(т.е. добавили в бд успешно, но файл уже существовал),то удаляем сделанную запись
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

true;
