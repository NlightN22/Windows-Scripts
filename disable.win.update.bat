::Меняем службе тип запуска на «Отключена»
sc config “wuauserv” start= disabled
:: Останавливаем службу
net stop wuauserv
exit