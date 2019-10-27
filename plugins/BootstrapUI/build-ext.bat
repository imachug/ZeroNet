@echo off
pushd %~dp0webext
rmdir /s /q %~dp0webext\web-ext-artifacts 2>NUL
call web-ext sign
copy /b %~dp0webext\web-ext-artifacts\*.xpi %~dp0media\zeronet.xpi
popd