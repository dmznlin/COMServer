@echo off

cd .\Source
del /s /a *.~*;*.dcu;*.stat;*.ddp

cd ..\Bin
del /s /a *.~*;*.dcu;*.ddp