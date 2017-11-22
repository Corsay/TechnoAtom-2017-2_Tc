Домашнее задание №7: wget и telnet
============================

wget
-------
* Написать утилиту wget используя AnyEvent или Coro
скачивание должно вестись параллельно в N запросов одновременно
	`Параметр -N - количество параллельных запросов`
	`Параметр -r - рекурсивный обход`
	`Параметр -l - ограничение глубины`
	`Параметр -L - только относительные ссылки`
	`Параметр -S - вывести ответ сервера`

если параметр - строковый URL - то сначала распознавание
если параметр - ip - то сразу подключение, через порт 80, 
отправка HTTP запроса

perl@perlworkstation:~/temp/d.tcibisov/Async/wget$ wget Ya.rururur
--2017-11-16 15:16:18--  http://ya.rururur/
Распознаётся ya.rururur (ya.rururur)... ошибка: Имя или служба не известны.
wget: не удаётся разрешить адрес «ya.rururur»

perl@perlworkstation:~/temp/d.tcibisov/Async/wget$ wget 213.203.203.2
--2017-11-16 15:16:35--  http://213.203.203.2/
Подключение к 213.203.203.2:80... соединение установлено.
HTTP-запрос отправлен. Ожидание ответа... 404 Not Found
2017-11-16 15:16:35 ОШИБКА 404: Not Found.

perl@perlworkstation:~/temp/d.tcibisov/Async/wget$ wget 256.203.203.2
--2017-11-16 15:21:34--  http://256.203.203.2/
Распознаётся 256.203.203.2 (256.203.203.2)... ошибка: Имя или служба не известны.
wget: не удаётся разрешить адрес «256.203.203.2»
perl@perlworkstation:~/temp/d.tcibisov/Async/wget$ wget 255.203.203.2
--2017-11-16 15:21:43--  http://255.203.203.2/
Подключение к 255.203.203.2:80...

* wget loclahost	- ошибка
* wget localhost	- 
* wget ya.ru		- Переадресация
* wget 256.203.203.2	- ошибка
* wget 213.203.203.2	- соединение установлено, - ошибка 404 NOT FOUND
* wget 255.203.203.2	- непонятки

perl@perlworkstation:~/temp/d.tcibisov/Async/wget$ wget loclahost
--2017-11-16 15:35:42--  http://loclahost/
Распознаётся loclahost (loclahost)... ошибка: Имя или служба не известны.
wget: не удаётся разрешить адрес «loclahost»
perl@perlworkstation:~/temp/d.tcibisov/Async/wget$ wget localhost
--2017-11-16 15:35:49--  http://localhost/
Распознаётся localhost (localhost)... ::1, 127.0.0.1
Подключение к localhost (localhost)|::1|:80... соединение установлено.
HTTP-запрос отправлен. Ожидание ответа... 200 OK
Длина: 11321 (11K) [text/html]
Сохранение в каталог: ««index.html.1»».

index.html.1        100%[===================>]  11,06K  --.-KB/s    in 0s      

2017-11-16 15:35:50 (276 MB/s) - «index.html.1» сохранён [11321/11321]

perl@perlworkstation:~/temp/d.tcibisov/Async/wget$ wget ya.ru
--2017-11-16 15:36:11--  http://ya.ru/
Распознаётся ya.ru (ya.ru)... 87.250.250.242
Подключение к ya.ru (ya.ru)|87.250.250.242|:80... соединение установлено.
HTTP-запрос отправлен. Ожидание ответа... 302 Found
Адрес: https://ya.ru/ [переход]
--2017-11-16 15:36:16--  https://ya.ru/
Подключение к ya.ru (ya.ru)|87.250.250.242|:443... соединение установлено.
HTTP-запрос отправлен. Ожидание ответа... 200 Ok
Длина: 10474 (10K) [text/html]
Сохранение в каталог: ««index.html.2»».

index.html.2        100%[===================>]  10,23K  --.-KB/s    in 0,01s   

2017-11-16 15:36:16 (971 KB/s) - «index.html.2» сохранён [10474/10474]



wget Yayayayyaasdasd.ru
--2017-11-13 13:31:39--  http://yayayayyaasdasd.ru/
Распознаётся yayayayyaasdasd.ru (yayayayyaasdasd.ru)... ошибка: Имя или служба не известны.
wget: не удаётся разрешить адрес «yayayayyaasdasd.ru»


wget Yayayayyaasdasd.ru Ya.ru--2017-11-13 13:31:52--  http://yayayayyaasdasd.ru/
Распознаётся yayayayyaasdasd.ru (yayayayyaasdasd.ru)... ошибка: Имя или служба не известны.
wget: не удаётся разрешить адрес «yayayayyaasdasd.ru»
--2017-11-13 13:31:57--  http://ya.ru/
Распознаётся ya.ru (ya.ru)... 87.250.250.242, 2a02:6b8::2:242
Подключение к ya.ru (ya.ru)|87.250.250.242|:80... соединение установлено.
HTTP-запрос отправлен. Ожидание ответа... 302 Found

-- Тестирование синхронности
perl wget.pm http://255.203.203.21:80/ http://255.203.203.21:80/ http://255.203.203.21:80/ http://255.203.203.21:80/ http://255.203.203.21:80/ -N5


perl wget.pm http://localhost/ http://search.cpan.org https://ya.ru http://ya.ru http://127.0.0.1 http://87.250.250.242 http://255.203.203.21 localhost:443 http://localhost:443/ ya.ru:443 yayayayaya.ru:443 //localhost //localhost: //localhost:90 45678:localhost localhost localhost:abc 127.0.0.1 ya.ru/mail http://perl.find-info.ru/perl/015/process/2.htm#163 -S -r -l0 -L -N1


perl wget.pm http://localhost/ http://search.cpan.org https://ya.ru http://ya.ru http://127.0.0.1 http://87.250.250.242 http://255.203.203.21 localhost:443 http://localhost:443/ ya.ru:443 yayayayaya.ru:443 //localhost //localhost: //localhost:90 45678:localhost localhost localhost:abc 127.0.0.1 ya.ru/mail http://perl.find-info.ru/perl/015/process/2.htm#163

perl wget.pm http://localhost/ http://search.cpan.org https://ya.ru http://ya.ru http://127.0.0.1 http://87.250.250.242 http://255.203.203.21 localhost:443 http://localhost:443/ ya.ru:443 yayayayaya.ru:443 //localhost //localhost: //localhost:90 45678:localhost localhost localhost:abc 127.0.0.1 ya.ru/mail http://perl.find-info.ru/perl/015/process/2.htm#163 http://search.cpan.org


perl wget.pm http://localhost/ http://search.cpan.org https://ya.ru http://127.0.0.1 http://87.250.250.242 http://255.203.203.2
Success: 0
Success: 0
Success: 0
Success: 0
Fail: 406 Not acceptable
Fail: 595 Connection timed out


wget.pl
--2017-11-16 15:16:18-- https://ya.ru:80/
Распознаётся ya.ru (ya.ru)... 87.250.250.242
Подключение к ya.ru (ya.ru)|87.250.250.242|:80... соединение установлено
Fail: 596 ssl23_get_server_hello: unknown protocol

wget
--2017-11-18 21:43:24--  https://ya.ru/
Распознаётся ya.ru (ya.ru)... 87.250.250.242
Подключение к ya.ru (ya.ru)|87.250.250.242|:443... соединение установлено.
HTTP-запрос отправлен. Ожидание ответа... 200 Ok

-- В данной ситуации удалять домен из хеша Recognized - распознанные url и добавлять в очередь на разбор по новой(аналогия со wget)
-- при учете периода валидности данных(т.е. если два подобных запроса подряд в валидности старой инфы можно не сомневаться)
wget
--2017-11-18 21:43:24--  http://localhost:443/
Подключение к localhost (localhost)|::1|:443... ошибка: В соединении отказано.
Подключение к localhost (localhost)|127.0.0.1|:443... ошибка: В соединении отказано.
Распознаётся localhost (localhost)... ::1, 127.0.0.1
Подключение к localhost (localhost)|::1|:443... ошибка: В соединении отказано.
Подключение к localhost (localhost)|127.0.0.1|:443... ошибка: В соединении отказано.
Включен режим робота. Проверка существования удалённого файла.
--2017-11-18 21:43:24--  http://localhost:443/
Подключение к localhost (localhost)|::1|:443... ошибка: В соединении отказано.
Подключение к localhost (localhost)|127.0.0.1|:443... ошибка: В соединении отказано.
Включен режим робота. Проверка существования удалённого файла.

 Date Server Content-Length Content-Type Cache-Control Expires Last-Modified Content-Security-Policy P3P Set-Cookie X-Frame-Options X-XSS-Protection X-Content-Type-Options Keep-Alive Connection


-- NNый каталог с конкретным файлом
[19] "http://search.cpan.org/rss/search.rss",
[21] "http://search.cpan.org/api/module/Dancer",
[22] "http://search.cpan.org/api/dist/Dancer",
[23] "http://search.cpan.org/api/author/SUKRIA",

-- NNый каталог
[265] "/~jeffober/AnyEvent-ProcessPool-0.02/",
[266] "/~capoeirab/Alien-libuv-0.013/",
[267] "/~book/Acme-MetaSyntactic-Themes-1.051/"

-- каталог есть, но index.html для него не нужен
пример каталога - ip, rss


telnet
-------
* Написать утилиту telnet (клиент)

perl@perlworkstation:~/temp/d.tcibisov/Async/wget$ telnet
telnet> open smtp.yandex.ru 25
Trying 93.158.134.38...
Connected to smtp.yandex.ru.
Escape character is '^]'.
220 smtp4o.mail.yandex.net ESMTP (Want to use Yandex.Mail for your domain? Visit http://pdd.yandex.ru)
ls
502 5.5.2 Syntax error, command unrecognized.
ls
502 5.5.2 Syntax error, command unrecognized.
say
502 5.5.2 Syntax error, command unrecognized.
echo
502 5.5.2 Syntax error, command unrecognized.
whoami
502 5.5.2 Syntax error, command unrecognized.
pwd
502 5.5.2 Syntax error, command unrecognized.
cd
502 5.5.2 Syntax error, command unrecognized.
quit
221 2.0.0 Closing connection.
Connection closed by foreign host.
perl@perlworkstation:~/temp/d.tcibisov/Async/wget$ 



