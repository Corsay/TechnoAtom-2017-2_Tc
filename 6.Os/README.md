Домашнее задание №6: Shell и Netcat
============================

Shell
-------
* Необходимо реализовать собственный шелл
	`встроенные команды: cd/pwd/echo/kill/ps`
	`поддержать fork/exec команды`
	`конвеер на пайпах`

Netcat
-------
* Реализовать утилиту netcat (nc) клиент
	`принимать данные из stdin и отправлять в соединение (tcp/udp)`

-- In netcat.pm
- connect by TCP to server
perl netcat.pm localhost 1028
- connect by UDP to server
perl -u netcat.pm localhost 1028

-- UNIX(Ubuntu 16.04) nc
- UDP netcat UNIX server (default -4u UDP, can be -6u UDP6)
nc -u -kl 1028
- TCP netcat UNIX server
nc -kl 1028
- connect by UDP to server (-4u UDP, can use -6u UDP6)
nc -4u localhost 1028
- connect by TCP to server
nc localhost 1028
