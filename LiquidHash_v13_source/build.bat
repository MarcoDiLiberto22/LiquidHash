@echo off
chcp 65001 >nul 2>&1
title Build LiquidHash v13
if exist "dist" rmdir /s /q dist
if exist "build" rmdir /s /q build
if not exist ".venv\Scripts\python.exe" py -m venv .venv
".venv\Scripts\python.exe" -m pip install --upgrade pip
".venv\Scripts\python.exe" -m pip install -r requirements.txt
".venv\Scripts\python.exe" -m pip install pyinstaller
".venv\Scripts\python.exe" -m PyInstaller --noconfirm LiquidHash.spec
pause
