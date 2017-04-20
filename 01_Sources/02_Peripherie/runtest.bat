@echo off
set PATH=c:\tools\iverilog\bin;%PATH%
iverilog -o tb_uart.out tb.v uart.v 
if errorlevel = 1 goto error
vvp tb_uart.out
:error