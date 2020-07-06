@echo off
asw.exe %1.asm
p2bin.exe %1.p %1.bin -r 1024-3071
pause