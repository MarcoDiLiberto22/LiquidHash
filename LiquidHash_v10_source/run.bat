@echo off
cd /d "%~dp0"
echo === LiquidHash v10 Setup ===
python -m venv .venv
call .venv\Scripts\activate.bat
pip install -r requirements.txt
echo.
echo Avvio LiquidHash...
python main.py
pause
