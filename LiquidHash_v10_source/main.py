import sys
import hashlib
import hmac
import os
import re
import logging
from logging.handlers import RotatingFileHandler
from pathlib import Path
from PySide6.QtCore import QObject, Slot, Signal, QUrl, QThread, QSettings
from PySide6.QtGui import QIcon
from PySide6.QtWidgets import QApplication, QFileDialog, QSystemTrayIcon, QMenu
from PySide6.QtQml import QQmlApplicationEngine

MAX_FILE_SIZE = 10 * 1024 * 1024 * 1024  # 10 GB
CHUNK_SIZE = 1048576  # 1 MB

_log_dir = Path.home() / ".liquidhash"
_log_dir.mkdir(exist_ok=True)
log_path = str(_log_dir / "liquidhash.log")

_handler = RotatingFileHandler(
    log_path,
    maxBytes=1024 * 1024,
    backupCount=3,
    encoding="utf-8",
)
_handler.setFormatter(logging.Formatter("%(asctime)s [%(levelname)s] %(message)s"))
logging.basicConfig(
    level=logging.ERROR,
    handlers=[_handler],
)


def resource_path(relative_path):
    if hasattr(sys, "_MEIPASS"):
        return os.path.join(sys._MEIPASS, relative_path)
    return os.path.join(os.path.dirname(os.path.abspath(__file__)), relative_path)


class CancelFlag:
    def __init__(self):
        self._flag = False
    def is_set(self):
        return self._flag
    def set(self):
        self._flag = True


def sha256_file(path, cancel_flag=None):
    h = hashlib.sha256()
    try:
        with open(path, "rb") as f:
            while True:
                if cancel_flag is not None and cancel_flag.is_set():
                    return None
                chunk = f.read(CHUNK_SIZE)
                if not chunk:
                    break
                h.update(chunk)
    except FileNotFoundError:
        raise
    return h.hexdigest()


def compute_hashes(path, cancel_flag=None):
    """Compute SHA-256, SHA-512 and SHA-3-256 in a single pass."""
    h256 = hashlib.sha256()
    h512 = hashlib.sha512()
    h3 = hashlib.sha3_256()
    try:
        with open(path, "rb") as f:
            while True:
                if cancel_flag is not None and cancel_flag.is_set():
                    return None
                chunk = f.read(CHUNK_SIZE)
                if not chunk:
                    break
                h256.update(chunk)
                h512.update(chunk)
                h3.update(chunk)
    except FileNotFoundError:
        raise
    return h256.hexdigest(), h512.hexdigest(), h3.hexdigest()


def format_size(size_bytes):
    if size_bytes < 1024:
        return f"{size_bytes} B"
    elif size_bytes < 1024 * 1024:
        return f"{size_bytes / 1024:.1f} KB"
    elif size_bytes < 1024 * 1024 * 1024:
        return f"{size_bytes / (1024 * 1024):.1f} MB"
    else:
        return f"{size_bytes / (1024 * 1024 * 1024):.2f} GB"


class VerifyWorker(QThread):
    finished = Signal(str)

    def __init__(self, provided_hash, file_path):
        super().__init__()
        self.provided_hash = provided_hash
        self.file_path = file_path
        self._cancel_flag = CancelFlag()

    def cancel(self):
        self._cancel_flag.set()

    def run(self):
        try:
            provided_hash = self.provided_hash.strip().lower()

            if len(provided_hash) > 64:
                self.finished.emit("Hash troppo lungo (max 64 caratteri).")
                return

            if not re.match(r"^[0-9a-f]{64}$", provided_hash):
                self.finished.emit("Hash non valido.\nL'hash SHA-256 deve essere di 64 caratteri esadecimali (0-9, a-f).")
                return

            if not self.file_path or not self.file_path.strip():
                self.finished.emit("Seleziona il file da verificare.")
                return

            file_path = os.path.realpath(self.file_path.strip())

            file_size = os.path.getsize(file_path)
            if file_size > MAX_FILE_SIZE:
                self.finished.emit("File troppo grande (max 10 GB).")
                return

            computed = sha256_file(file_path, self._cancel_flag)

            if computed is None:
                self.finished.emit("Verifica annullata.")
                return

            if hmac.compare_digest(computed, provided_hash):
                self.finished.emit(
                    "FILE INTEGRO\n\n"
                    "Hash calcolato:\n" + computed + "\n\n"
                    "Hash fornito:\n" + provided_hash + "\n\n"
                    "Dimensione: " + format_size(file_size)
                )
            else:
                self.finished.emit(
                    "FILE MODIFICATO - non installare!\n\n"
                    "Hash calcolato:\n" + computed + "\n\n"
                    "Hash fornito:\n" + provided_hash
                )

        except FileNotFoundError:
            self.finished.emit("File non trovato o eliminato durante la lettura.")
        except PermissionError:
            logging.error("PermissionError su file: %s", self.file_path)
            self.finished.emit("Permesso negato. Impossibile leggere il file.")
        except OSError as e:
            logging.error("OSError: %s", e)
            self.finished.emit("Errore di sistema durante la lettura del file.")
        except Exception as e:
            logging.error("Errore imprevisto: %s", e, exc_info=True)
            self.finished.emit("Errore imprevisto durante la verifica. Consulta il file liquidhash.log per i dettagli.")


class HashWorker(QThread):
    """Compute SHA-256, SHA-512, SHA-3-256 of a file in a background thread."""
    finished = Signal(str, str, str, str)  # sha256, sha512, sha3, size
    error = Signal(str)

    def __init__(self, file_path):
        super().__init__()
        self.file_path = file_path
        self._cancel_flag = CancelFlag()

    def cancel(self):
        self._cancel_flag.set()

    def run(self):
        try:
            if not self.file_path or not self.file_path.strip():
                self.error.emit("Seleziona un file.")
                return

            file_path = os.path.realpath(self.file_path.strip())

            file_size = os.path.getsize(file_path)
            if file_size > MAX_FILE_SIZE:
                self.error.emit("File troppo grande (max 10 GB).")
                return

            result = compute_hashes(file_path, self._cancel_flag)

            if result is None:
                self.error.emit("Calcolo annullato.")
                return

            sha256, sha512, sha3 = result
            self.finished.emit(sha256, sha512, sha3, format_size(file_size))

        except FileNotFoundError:
            self.error.emit("File non trovato o eliminato durante la lettura.")
        except PermissionError:
            logging.error("PermissionError su file: %s", self.file_path)
            self.error.emit("Permesso negato. Impossibile leggere il file.")
        except OSError as e:
            logging.error("OSError: %s", e)
            self.error.emit("Errore di sistema durante la lettura del file.")
        except Exception as e:
            logging.error("Errore imprevisto: %s", e, exc_info=True)
            self.error.emit("Errore imprevisto. Consulta liquidhash.log per i dettagli.")


class HashVerifier(QObject):
    verifyResult = Signal(str)
    hashResult = Signal(str, str, str, str)
    hashError = Signal(str)

    def __init__(self):
        super().__init__()
        self._worker = None
        self._hashWorker = None

    @Slot(str, str)
    def verify(self, provided_hash, file_path):
        if self._worker is not None and self._worker.isRunning():
            return

        self._worker = VerifyWorker(provided_hash, file_path)
        self._worker.finished.connect(self.verifyResult)
        self._worker.finished.connect(self._cleanupVerifyWorker)
        self._worker.start()

    def _cleanupVerifyWorker(self):
        if self._worker is not None:
            self._worker.deleteLater()
            self._worker = None

    @Slot()
    def cancelVerify(self):
        if self._worker is not None and self._worker.isRunning():
            self._worker.cancel()

    @Slot(result=str)
    def browseFile(self):
        path, _ = QFileDialog.getOpenFileName(
            None,
            "Seleziona il file da verificare",
            "",
            "Tutti i file (*);;Eseguibili (*.exe *.msi);;Archivi (*.zip *.7z *.rar *.iso *.tar *.gz);;Immagini disco (*.img *.dmg)"
        )
        return path

    @Slot(str)
    def computeHash(self, file_path):
        if self._hashWorker is not None and self._hashWorker.isRunning():
            return

        self._hashWorker = HashWorker(file_path)
        self._hashWorker.finished.connect(self.hashResult)
        self._hashWorker.error.connect(self.hashError)
        self._hashWorker.finished.connect(self._cleanupHashWorker)
        self._hashWorker.error.connect(self._cleanupHashWorker)
        self._hashWorker.start()

    def _cleanupHashWorker(self):
        if self._hashWorker is not None:
            self._hashWorker.deleteLater()
            self._hashWorker = None

    @Slot()
    def cancelCompute(self):
        if self._hashWorker is not None and self._hashWorker.isRunning():
            self._hashWorker.cancel()

    @Slot(str)
    def copyToClipboard(self, text):
        QApplication.clipboard().setText(text)


class TrayManager(QObject):
    showWindow = Signal()

    def __init__(self, app, icon_path):
        super().__init__()
        self.app = app
        self.tray = QSystemTrayIcon(QIcon(icon_path))
        self.tray.setToolTip("LiquidHash")

        menu = QMenu()
        show_action = menu.addAction("Mostra")
        show_action.triggered.connect(self.showWindow.emit)
        menu.addSeparator()
        quit_action = menu.addAction("Esci")
        quit_action.triggered.connect(self.app.quit)

        self.tray.setContextMenu(menu)
        self.tray.activated.connect(self._onActivated)
        self.tray.show()

    def _onActivated(self, reason):
        if reason == QSystemTrayIcon.Trigger:
            self.showWindow.emit()

    @Slot(str)
    def showMessage(self, message):
        self.tray.showMessage("LiquidHash", message, QSystemTrayIcon.Information, 3000)


if __name__ == "__main__":
    app = QApplication(sys.argv)
    app.setApplicationName("LiquidHash")
    app.setWindowIcon(QIcon(resource_path("liquidhash.ico")))

    engine = QQmlApplicationEngine()

    verifier = HashVerifier()
    engine.rootContext().setContextProperty("verifier", verifier)

    settings = QSettings("LiquidHash", "LiquidHash")
    engine.rootContext().setContextProperty("AppSettings", settings)

    has_tray = QSystemTrayIcon.isSystemTrayAvailable()
    engine.rootContext().setContextProperty("hasTray", has_tray)

    if has_tray:
        app.setQuitOnLastWindowClosed(False)
        tray_manager = TrayManager(app, resource_path("liquidhash.ico"))
        engine.rootContext().setContextProperty("trayManager", tray_manager)

    engine.load(QUrl.fromLocalFile(resource_path("Main.qml")))

    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())
