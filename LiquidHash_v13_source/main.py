import sys, os, hashlib, logging
from logging.handlers import RotatingFileHandler
from pathlib import Path

from PySide6.QtCore import QObject, Slot, Signal, QThread, QSettings, QUrl
from PySide6.QtGui import QGuiApplication, QIcon, QAction
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtWidgets import QApplication, QFileDialog, QSystemTrayIcon, QMenu


def resource_path(relative_path):
    if hasattr(sys, '_MEIPASS'):
        return os.path.join(sys._MEIPASS, relative_path)
    return os.path.join(os.path.dirname(os.path.abspath(__file__)), relative_path)


def setup_logging():
    log_dir = Path.home() / '.liquidhash'
    log_dir.mkdir(parents=True, exist_ok=True)
    handler = RotatingFileHandler(str(log_dir / 'liquidhash.log'), maxBytes=1_048_576, backupCount=3, encoding='utf-8')
    handler.setFormatter(logging.Formatter('%(asctime)s [%(levelname)s] %(message)s'))
    root = logging.getLogger()
    root.setLevel(logging.INFO)
    root.handlers.clear()
    root.addHandler(handler)


class AppSettingsBridge(QObject):
    def __init__(self):
        super().__init__()
        self._settings = QSettings('LiquidHash', 'LiquidHash')

    @Slot(str, 'QVariant', result='QVariant')
    def value(self, key, default_value=None):
        return self._settings.value(key, default_value)

    @Slot(str, 'QVariant')
    def setValue(self, key, value):
        self._settings.setValue(key, value)
        self._settings.sync()


class VerifyWorker(QObject):
    finished = Signal(str)
    error = Signal(str)

    def __init__(self, expected_hash, file_path):
        super().__init__()
        self.expected_hash = (expected_hash or '').strip().lower()
        self.file_path = os.path.realpath(file_path or '')
        self._cancel = False

    def cancel(self):
        self._cancel = True

    @Slot()
    def run(self):
        try:
            if not self.expected_hash:
                self.error.emit('Inserisci l\'hash SHA-256 fornito.')
                return
            if len(self.expected_hash) != 64 or any(c not in '0123456789abcdef' for c in self.expected_hash):
                self.error.emit('L\'hash SHA-256 deve contenere 64 caratteri esadecimali.')
                return
            if not self.file_path or not os.path.isfile(self.file_path):
                self.error.emit('File non trovato.')
                return
            h = hashlib.sha256()
            size = os.path.getsize(self.file_path)
            with open(self.file_path, 'rb') as f:
                while True:
                    if self._cancel:
                        self.finished.emit('Operazione annullata.')
                        return
                    chunk = f.read(1024 * 1024)
                    if not chunk:
                        break
                    h.update(chunk)
            computed = h.hexdigest()
            if computed == self.expected_hash:
                self.finished.emit(f'File integro\n\nSHA-256 calcolato:\n{computed}\n\nDimensione: {size:,} byte')
            else:
                self.finished.emit(f'File NON integro\n\nSHA-256 atteso:\n{self.expected_hash}\n\nSHA-256 calcolato:\n{computed}\n\nDimensione: {size:,} byte')
        except Exception as e:
            logging.exception('Verify failed')
            self.error.emit(str(e))


class ComputeWorker(QObject):
    finished = Signal(str, str, str, str)
    error = Signal(str)

    def __init__(self, file_path):
        super().__init__()
        self.file_path = os.path.realpath(file_path or '')
        self._cancel = False

    def cancel(self):
        self._cancel = True

    @Slot()
    def run(self):
        try:
            if not self.file_path or not os.path.isfile(self.file_path):
                self.error.emit('File non trovato.')
                return
            sha256 = hashlib.sha256()
            sha512 = hashlib.sha512()
            sha3 = hashlib.sha3_256()
            size = os.path.getsize(self.file_path)
            with open(self.file_path, 'rb') as f:
                while True:
                    if self._cancel:
                        self.error.emit('Operazione annullata.')
                        return
                    chunk = f.read(1024 * 1024)
                    if not chunk:
                        break
                    sha256.update(chunk)
                    sha512.update(chunk)
                    sha3.update(chunk)
            self.finished.emit(sha256.hexdigest(), sha512.hexdigest(), sha3.hexdigest(), f'{size:,} byte')
        except Exception as e:
            logging.exception('Hash compute failed')
            self.error.emit(str(e))


class TrayManager(QObject):
    showWindow = Signal()

    def __init__(self, app_icon):
        super().__init__()
        self.tray = None
        if QSystemTrayIcon.isSystemTrayAvailable():
            self.tray = QSystemTrayIcon(app_icon)
            menu = QMenu()
            action_show = QAction('Apri LiquidHash', menu)
            action_quit = QAction('Esci', menu)
            action_show.triggered.connect(self.showWindow.emit)
            action_quit.triggered.connect(QApplication.quit)
            menu.addAction(action_show)
            menu.addSeparator()
            menu.addAction(action_quit)
            self.tray.setContextMenu(menu)
            self.tray.activated.connect(self._on_activated)
            self.tray.setToolTip('LiquidHash')
            self.tray.show()

    @Slot(str)
    def showMessage(self, message):
        if self.tray:
            self.tray.showMessage('LiquidHash', message, QSystemTrayIcon.Information, 2500)

    def _on_activated(self, reason):
        if reason in (QSystemTrayIcon.Trigger, QSystemTrayIcon.DoubleClick):
            self.showWindow.emit()


class VerifierBridge(QObject):
    verifyResult = Signal(str)
    hashResult = Signal(str, str, str, str)
    hashError = Signal(str)

    def __init__(self):
        super().__init__()
        self.verify_thread = None
        self.verify_worker = None
        self.compute_thread = None
        self.compute_worker = None
        self._last_dir = str(Path.home())

    @Slot(result=str)
    def browseFile(self):
        path, _ = QFileDialog.getOpenFileName(None, 'Seleziona file')
        if path:
            self._last_dir = os.path.dirname(path)
        return path or ''

    @Slot(str)
    def copyToClipboard(self, text):
        QApplication.clipboard().setText(text or '')

    @Slot(str, str)
    def verify(self, expected_hash, file_path):
        if self.verify_thread and self.verify_thread.isRunning():
            return
        self.verify_worker = VerifyWorker(expected_hash, file_path)
        self.verify_thread = QThread()
        self.verify_worker.moveToThread(self.verify_thread)
        self.verify_thread.started.connect(self.verify_worker.run)
        self.verify_worker.finished.connect(self.verifyResult.emit)
        self.verify_worker.error.connect(self.hashError.emit)
        self.verify_worker.finished.connect(self.verify_thread.quit)
        self.verify_worker.error.connect(self.verify_thread.quit)
        self.verify_worker.finished.connect(self.verify_worker.deleteLater)
        self.verify_worker.error.connect(self.verify_worker.deleteLater)
        self.verify_thread.finished.connect(self.verify_thread.deleteLater)
        self.verify_thread.start()

    @Slot()
    def cancelVerify(self):
        if self.verify_worker:
            self.verify_worker.cancel()

    @Slot(str)
    def computeHash(self, file_path):
        if self.compute_thread and self.compute_thread.isRunning():
            return
        self.compute_worker = ComputeWorker(file_path)
        self.compute_thread = QThread()
        self.compute_worker.moveToThread(self.compute_thread)
        self.compute_thread.started.connect(self.compute_worker.run)
        self.compute_worker.finished.connect(self.hashResult.emit)
        self.compute_worker.error.connect(self.hashError.emit)
        self.compute_worker.finished.connect(self.compute_thread.quit)
        self.compute_worker.error.connect(self.compute_thread.quit)
        self.compute_worker.finished.connect(self.compute_worker.deleteLater)
        self.compute_worker.error.connect(self.compute_worker.deleteLater)
        self.compute_thread.finished.connect(self.compute_thread.deleteLater)
        self.compute_thread.start()

    @Slot()
    def cancelCompute(self):
        if self.compute_worker:
            self.compute_worker.cancel()


def main():
    setup_logging()
    app = QApplication(sys.argv)
    app.setApplicationName('LiquidHash')
    app.setOrganizationName('LiquidHash')
    icon_path = resource_path('liquidhash.ico')
    icon = QIcon(icon_path) if os.path.exists(icon_path) else QIcon()
    app.setWindowIcon(icon)

    app_settings = AppSettingsBridge()
    verifier = VerifierBridge()
    tray_manager = TrayManager(icon)

    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty('AppSettings', app_settings)
    engine.rootContext().setContextProperty('verifier', verifier)
    engine.rootContext().setContextProperty('trayManager', tray_manager)
    engine.rootContext().setContextProperty('hasTray', tray_manager.tray is not None)
    qml_path = resource_path('Main.qml')
    engine.load(QUrl.fromLocalFile(qml_path))
    if not engine.rootObjects():
        sys.exit(-1)
    sys.exit(app.exec())


if __name__ == '__main__':
    main()
