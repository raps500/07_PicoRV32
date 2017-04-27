@echo off
set path=c:\iverilog\bin;%PATH%
iverilog -o tb.out tb.v audio.v
if errorlevel == 1 goto error
vvp tb.out
:error