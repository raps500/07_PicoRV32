@echo off
set PATH=c:\tools\iverilog\bin;%PATH%
iverilog -o tb_vga.out -D SIMULATOR=1 tb_vga.v vgatext.v 
if errorlevel = 1 goto error
vvp tb_vga.out
:error