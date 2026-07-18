# -*- mode: python ; coding: utf-8 -*-
block_cipher = None

a = Analysis(
    ['main.py'],
    pathex=[],
    binaries=[],
    datas=[('Main.qml', '.'), ('liquidhash.ico', '.')],
    hiddenimports=['PySide6.QtCore','PySide6.QtGui','PySide6.QtQml','PySide6.QtQuick','PySide6.QtQuickControls2','PySide6.QtWidgets'],
    hookspath=[], runtime_hooks=[], excludes=[], cipher=block_cipher, noarchive=False,
)
pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)
exe = EXE(
    pyz, a.scripts, a.binaries, a.zipfiles, a.datas, [],
    name='LiquidHash', debug=False, bootloader_ignore_signals=False,
    strip=False, upx=False, runtime_tmpdir=None, console=False,
    disable_windowed_traceback=False, icon='liquidhash.ico'
)
