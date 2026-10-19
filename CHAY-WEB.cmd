@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0QuanLyKinhMatWeb\scripts\Start-Web.ps1" %*
if errorlevel 1 pause
