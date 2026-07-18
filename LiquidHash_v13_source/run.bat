@echo off
chcp 65001 >nul 2>&1
title LiquidHash v13
if not exist ".venv\Scripts\python.exe" py -m venv .venv
".venv\Scripts\python.exe" -m pip install --upgrade pip
".venv\Scripts\python.exe" -m pip install -r requirements.txt
start "" ".venv\Scripts\pythonw.exe" main.py
