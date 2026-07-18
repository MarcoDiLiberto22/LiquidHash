@echo off
cd /d "%~dp0"
echo === LiquidHash v10 Build ===
echo.
python -m venv .venv
call .venv\Scripts\activate.bat
pip install -r requirements.txt
echo Build in corso...
pyinstaller --noconfirm --onefile --windowed --name "LiquidHash" --icon "liquidhash.ico" main.py
echo.
echo Build completato! Eseguibile in: dist\LiquidHash.exe
pause
