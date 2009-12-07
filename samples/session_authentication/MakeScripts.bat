@echo off
cd pages

for %%i in ( *.html ) do ..\..\..\Compiler\wxc.exe %%i 
cd ..
