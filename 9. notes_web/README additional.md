Домашнее задание Notes
=====================

Требуется написать web приложение для создания заметок с возможностью поделиться ими со своими друзьями.

В приложении должна присутствовать возможность авторизоваться и создать заметку. Создавать заметки может только авторизованный пользователь. При создании заметки можно выбрать пользователей, которым будет доступна ссылка на чтение заметки. Читать заметки могут только авторизованные пользователи.

Также каждому автору доступен список ранее опубликованных им заметок.
 

Общие требования
----------------

* ООП-код.
* Mojolicious или Dancer в качестве web фреймворка.
* Заметки должны храниться в базе данных, которую можно выбрать на свой вкус. Главное требование - персистентное хранилище данных (поэтому Memcached не подходит).
* Нужен конфиг отдельный файлом. Он должен хранить по крайней мере данные о том, как соединиться с базой.
* Безопасность. Вспомните про XSS, CSRF и другие виды атак на приложения. Небезопасные решения приниматься не будут.

Фронтенд
-----------------
В данной задаче мы не проверяем качество и красоту фронтенда веб приложения, однако правильно спроектированная структура шаблонов будет плюсом.

В `templates/index.html` содержатся элементы верстки, которые могут понадобиться при решении задачи. 

Дополнительные задания
-----------------
* Предусмотреть возможность загрузить файл к заметке, который в последствие можно будет скачать при просмотре этой заметки.


mysql -u TCnotes -p TCnotes

plackup bin/app.psgi

2 qwe 1 йцу 4
2 3 4  2 5 6 7 8  1



SELECT cast(id as unsigned) as id, create_time, title FROM note N JOIN user_note U ON N.owner = U.login where (N.owner = 1 and (expire_time is null or expire_time > current_timestamp)) order by create_time desc limit 10;


Select note_id as id from user_note where login = 1;

SELECT cast(id as unsigned) as id, create_time, title FROM note
where (expire_time is null or expire_time > current_timestamp) order by create_time desc limit 10;

SELECT cast(id as unsigned) as id, create_time, title FROM note
where id IN (Select note_id as id from user_note where login = 1) and
(expire_time is null or expire_time > current_timestamp) order by create_time desc limit 10;








