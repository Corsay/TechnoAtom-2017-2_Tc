# Операции с датами

Требуется реализовать объекты для работы с датами и временными интервалами.<br>
Все даты должны быть в `GMT` (по Гринвичу).

* `Local::Date` - объект даты
* `Local::Date::Interval` - объект временного интревала

Объекты должны менять свое поведение в зависимости от контекста их использования.

## Особенности `Local::Date`

### Конструктор

Требуется поддержать две формы конструктора: по компонентам даты (дни, месяцы, года, часы, минуты, секунды) и по timestamp.

### Аттрибуты

* `day`, `month`, `year`, `hours`, `minutes`, `seconds` - для компонентов даты
* `epoch` - timestamp
* `format` - формат вывода даты в строковом контексте

В любой момент времени должна быть возможность обратиться как к компонентам времени, как к timestamp, для получения их текущего значения.

### Строковый контекст

Дата должна преобразовываться в строку вида `"Fri May 19 02:08:33 2017"`.<br>
Формат преобразовния определяется атрибутом объекта, и должен быть совмести с форматами функции `strftime`.

### Числовой контекст

Дата должна преобразовываться в число секунд прошедших с `01-01-1970 00:00:00` (*unix timestamp*).

### Операция сложения (`+`)

Операция должна прибавлять указанное количество секунд к объекту.<br>
Если вторым операндом является объект типа `Local::Date::Interval`, то операция должна возвращать объект типа `Local::Date`.<br>
Если вторым операндом является число, то операция должна возвращать число (unix timestamp).<br>
В остальных случая должно вызываться исключение.

### Операция вычитания (`-`)

Операция должна вычитать указанное количество секунд из объекта или вычитать объект даты.<br>
Если вторым операндом является объект типа `Local::Date::Interval`, то операция должна возвращать объект типа `Local::Date`.<br>
Если вторым операндом является число, то операция должна возвращать число (*unix timestamp*).<br>
Если вторым операдном является объект типа `Local::Date`, то операция должна возвращать объект типа `Local::Date::Interval`.<br>
Операция вычитания объекта типа `Local::Date` из чего либо отличного от объект типа `Local::Date`, должна приводить к вызову исключения.<br>
В остальных случая должно вызываться исключение.

### Сложение/вычитание с присваиванием (`+= -=`)

Операции должны прибавлять/вычитать указанное количество секунд к/из объекта.<br>
Если аргументом является число или объект типа `Local::Date::Interval`, то должен возращаться исходный объект типа `Local::Date`.<br>
Новых объектов создаваться не должно!<br>
В остальных случая должно вызываться исключение.

### Операции инкремента/декремента (`++ --`)

К исходному объекту должна быть добавлена/вычтена одна секунда. Новых объектов создаваться не должно!

### Операции сравнения (`< <= > >= == != <=>`)

Должна быть возможность сравнивать объекты между собой, а так же с временем заданным как количество секунд (*unix timestamp*).<br>
Так же объекты должны корректно сортироваться функцией *sort*.

## Особенности `Local::Date::Interval`

### Конструктор

Требуется поддержать две формы конструктора: по компонентам длительности (дни, часы, минуты, секунды) и по длительности в секундах..

### Аттрибуты

* `days`, `hours`, `minutes`, `seconds` - для компонентов длительности интервала
* `duration` - длительность интервала в секундах

В любой момент времени должна быть возможность обратиться как к компонентам длительности интеревала, так и к длительности в секундах, для получения их текущего значения.

## Строковый контекст

Интервал должен преобразовываться в строку вида `"1524 days, 20 hours, 0 minutes, 14 seconds"`.

## Числовой контекст

Интервал должен преобразовываться в число равное длительности интервала в секундах.

## Операция сложения (`+`)

Операция должна прибавлять указанное количество секунд к объекту.<br>
Если вторым операндом является объект типа `Local::Date::Interval`, то операция должна возвращать объект типа `Local::Date::Interval`.<br>
Если вторым операндом является число, то операция должна возвращать число (*unix timestamp*).<br>
В остальных случая должно вызываться исключение.

## Операция вычитания (`-`)

Операция должна вычитать указанное количество секунд из объекта.<br>
Если вторым операндом является объект типа `Local::Date::Interval`, то операция должна возвращать объект типа `Local::Date::Interval`.<br>
Если вторым операндом является число, то операция должна возвращать число (*unix timestamp*).<br>
В остальных случая должно вызываться исключение.

## Сложение/вычитание с присваиванием (`+= -=`)

Операции должны прибавлять/вычитать указанное количество секунд к/из объекта.<br>
Если аргументом является число или объект типа `Local::Date::Interval`, то должен возращаться исходный объект типа `Local::Date::Interval`.<br>
Новых объектов создаваться не должно!<br>
В остальных случая должно вызываться исключение.

## Операции инкремента/декремента (`++ --`)

К исходному объекту должна быть добавлена/вычтена одна секунда. Новых объектов создаваться не должно!

## Операции сравнения (`< <= > >= == != <=>`)

Должна быть возможность сравнивать объекты между собой, а так же с интервалом в секундах.<br>
Так же объекты должны корректно сортироваться функцией *sort*.