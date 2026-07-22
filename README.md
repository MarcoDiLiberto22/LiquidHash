# LiquidHash

LiquidHash is a desktop application built with Python, PySide6 and QML to verify file integrity and calculate secure hashes through a modern DarkGlassmorphism-style interface.

## Features

- Verify a downloaded file against a provided **SHA-256** hash.
- Calculate **SHA-256**, **SHA-512** and **SHA-3-256** for any file.
- Drag & drop file support.
- Native file picker integration.
- Frameless desktop UI with animated background.
- System tray minimize support.
- Colored verification states:
  - Blue = file verified successfully.
  - Red = file not intact.
  - Orange = invalid SHA-256 input.

## Verification behavior

LiquidHash distinguishes between three different cases:

- **File integro**: the provided SHA-256 matches the selected file.
- **File non integro**: the hash format is valid, but it does not match the file.
- **L'hash non e valido, SHA-256 puo contenere solo caratteri esadecimali: 0-9, a-f**: the input is not a valid SHA-256 hash.

## Tech stack

- Python 3.14
- PySide6
- QML / Qt Quick Controls
- PyInstaller (optional, for Windows executable builds)

## Project structure

```text
LiquidHash/
├── main.py
├── Main.qml
├── requirements.txt
├── run.bat
├── build.bat
├── LiquidHash.spec
└── liquidhash.ico
```

## Requirements

- Windows
- Python 3.14
- pip

## Quick start

### 1. Clone the repository

```powershell
git clone https://github.com/MarcoDiLiberto22/LiquidHash
cd LiquidHash
```

### 2. Create and activate a virtual environment

```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
```

If PowerShell blocks script execution for the current session:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
.venv\Scripts\Activate.ps1
```

### 3. Install dependencies

```powershell
pip install -r requirements.txt
```

### 4. Run the app

```powershell
python main.py
```

## Windows shortcut scripts

You can also use the included helper scripts:

- `run.bat` → creates/updates the virtual environment and starts the app.
- `build.bat` → builds `dist\LiquidHash.exe` with PyInstaller.

## Build executable

To generate the Windows executable:

```powershell
.\build.bat
```

Or manually:

```powershell
.venv\Scripts\python.exe -m pip install pyinstaller
.venv\Scripts\python.exe -m PyInstaller --noconfirm LiquidHash.spec
```

The executable will be created in:

```text
dist\LiquidHash.exe
```

## How to use

### Verify a file

1. Open the **Verifica** tab.
2. Paste the provided SHA-256 hash.
3. Select or drag the downloaded file.
4. Click **Verifica integrita**.

### Calculate hashes

1. Open the **Calcola Hash** tab.
2. Select or drag a file.
3. Click **Calcola hash**.
4. Copy the generated SHA-256, SHA-512 or SHA-3-256 values.

## Notes

- SHA-256 verification is intended for integrity checking of downloaded files.
- SHA-512 and SHA-3-256 are available in the hash generation section.
- The app stores window size and position locally using QSettings.
- The close button exits the application, while minimize can send it to the system tray if available.

## .gitignore suggestion

```gitignore
.venv/
dist/
build/
__pycache__/
*.pyc
*.log
```
