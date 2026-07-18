import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

ApplicationWindow {
    id: root
    width: 580
    height: 820
    visible: true
    title: "LiquidHash"
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.Window

    property string resultText: ""
    property bool isVerifying: false
    property string hashSha256: ""
    property string hashSha512: ""
    property string hashSha3: ""
    property string hashSize: ""
    property string hashErrorText: ""
    property bool isHashing: false
    property int currentPage: 0

    Component.onCompleted: {
        var savedX = AppSettings.value("window/x", -1)
        var savedY = AppSettings.value("window/y", -1)
        var savedW = AppSettings.value("window/width", 580)
        var savedH = AppSettings.value("window/height", 820)
        if (savedW > 0) root.width = savedW
        if (savedH > 0) root.height = savedH
        if (savedX >= 0 && savedY >= 0) {
            root.x = savedX
            root.y = savedY
        }
    }

    onWidthChanged: saveTimer.restart()
    onHeightChanged: saveTimer.restart()
    onXChanged: saveTimer.restart()
    onYChanged: saveTimer.restart()

    Timer {
        id: saveTimer
        interval: 500
        repeat: false
        onTriggered: {
            AppSettings.setValue("window/x", root.x)
            AppSettings.setValue("window/y", root.y)
            AppSettings.setValue("window/width", root.width)
            AppSettings.setValue("window/height", root.height)
        }
    }

    function minimizeToTray() {
        if (hasTray) {
            root.hide()
            trayManager.showMessage("LiquidHash ridotto ad icona nel system tray")
        } else {
            root.showMinimized()
        }
    }

    onVisibleChanged: {
        if (visible) {
            root.raise()
            root.requestActivate()
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 28
        clip: true
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: "#1a1a2e" }
            GradientStop { position: 0.5; color: "#16213e" }
            GradientStop { position: 1.0; color: "#0f0f23" }
        }

        Rectangle {
            width: 300; height: 300; radius: 150; color: "#5C6BFF"; opacity: 0.08
            x: -60; y: -40
            NumberAnimation on x { from: -60; to: 400; duration: 8000; loops: Animation.Infinite; easing.type: Easing.InOutSine }
            NumberAnimation on y { from: -40; to: 500; duration: 10000; loops: Animation.Infinite; easing.type: Easing.InOutSine }
        }

        Rectangle {
            width: 260; height: 260; radius: 130; color: "#00C2FF"; opacity: 0.06
            x: 350; y: 400
            NumberAnimation on x { from: 350; to: -80; duration: 9000; loops: Animation.Infinite; easing.type: Easing.InOutSine }
            NumberAnimation on y { from: 400; to: 100; duration: 7000; loops: Animation.Infinite; easing.type: Easing.InOutSine }
        }
    }

    Rectangle {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 52
        color: "#00000000"

        MouseArea {
            anchors.fill: parent
            property point startPoint
            onPressed: startPoint = Qt.point(mouse.x, mouse.y)
            onPositionChanged: {
                root.x = root.x + (mouse.x - startPoint.x)
                root.y = root.y + (mouse.y - startPoint.y)
            }
        }

        Text {
            anchors.centerIn: parent
            text: "LiquidHash"
            font.pixelSize: 18
            font.weight: Font.DemiBold
            color: "#FFFFFF"
        }

        Rectangle {
            width: 28; height: 28; radius: 14
            anchors.right: closeButton.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            color: minArea.containsMouse ? "#2A2A4E" : "#333344"
            opacity: 0.8

            Text { anchors.centerIn: parent; text: "\u2014"; color: "#FFFFFF"; font.pixelSize: 12 }
            MouseArea { id: minArea; anchors.fill: parent; hoverEnabled: true; onClicked: root.minimizeToTray() }
        }

        Rectangle {
            id: closeButton
            width: 28; height: 28; radius: 14
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            color: closeArea.containsMouse ? "#FF453A" : "#333344"
            opacity: 0.8

            Text { anchors.centerIn: parent; text: "\u2715"; color: "#FFFFFF"; font.pixelSize: 12 }
            MouseArea { id: closeArea; anchors.fill: parent; hoverEnabled: true; onClicked: Qt.quit() }
        }
    }

    Rectangle {
        id: tabBar
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 8
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        height: 44
        radius: 22
        color: "#1C1C2E"
        border.color: "#2A2A3E"
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 18
                color: root.currentPage === 0 ? "#5C6BFF" : "#00000000"
                Behavior on color { ColorAnimation { duration: 200 } }

                Text { anchors.centerIn: parent; text: "Verifica"; color: root.currentPage === 0 ? "#FFFFFF" : "#8888AA"; font.pixelSize: 14; font.weight: root.currentPage === 0 ? Font.DemiBold : Font.Normal }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; enabled: !root.isVerifying && !root.isHashing; onClicked: root.currentPage = 0 }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 18
                color: root.currentPage === 1 ? "#5C6BFF" : "#00000000"
                Behavior on color { ColorAnimation { duration: 200 } }

                Text { anchors.centerIn: parent; text: "Calcola Hash"; color: root.currentPage === 1 ? "#FFFFFF" : "#8888AA"; font.pixelSize: 14; font.weight: root.currentPage === 1 ? Font.DemiBold : Font.Normal }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; enabled: !root.isVerifying && !root.isHashing; onClicked: root.currentPage = 1 }
            }
        }
    }

    StackLayout {
        id: pageStack
        anchors.top: tabBar.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 12
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        anchors.bottomMargin: 24
        currentIndex: root.currentPage
        clip: true

        // ═══ PAGE 0: Verifica ═══
        Flickable {
            contentHeight: verifyColumn.implicitHeight + 20
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }

            DropArea {
                anchors.fill: parent
                enabled: !root.isVerifying
                onDropped: {
                    if (drop.hasUrls && drop.urls.length > 0) {
                        var url = drop.urls[0].toString()
                        if (url.startsWith("file:///")) { url = url.replace("file:///", "") }
                        else if (url.startsWith("file://")) { url = url.replace("file://", "") }
                        pathField.text = decodeURIComponent(url)
                    }
                }
            }

            ColumnLayout {
                id: verifyColumn
                anchors.fill: parent
                spacing: 20

                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 90; radius: 20; color: "#1C1C2E"; border.color: "#2A2A3E"; border.width: 1
                    Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 1; color: "#FFFFFF"; opacity: 0.08 }
                    ColumnLayout { anchors.fill: parent; anchors.margins: 20; spacing: 4
                        Text { text: "Verifica Integrita File"; font.pixelSize: 22; font.weight: Font.Bold; color: "#FFFFFF" }
                        Text { text: "Confronta l'hash SHA-256 fornito con quello del file scaricato"; font.pixelSize: 12; color: "#8888AA"; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    }
                }

                ColumnLayout { Layout.fillWidth: true; spacing: 8
                    Text { text: "Hash SHA-256 fornito"; font.pixelSize: 13; color: "#AAAABB" }
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 60; radius: 14; color: "#1A1A2A"
                        border.color: hashField.activeFocus ? "#5C6BFF" : "#2A2A3E"; border.width: 1
                        TextArea {
                            id: hashField; anchors.fill: parent; anchors.margins: 12
                            color: "#FFFFFF"; font.pixelSize: 13; font.family: "Consolas, Monaco, monospace"
                            wrapMode: TextArea.Wrap; selectByMouse: true
                            placeholderText: "Incolla qui l'hash SHA-256 a 64 caratteri (0-9, a-f)..."
                            background: null
                        }
                    }
                }

                ColumnLayout { Layout.fillWidth: true; spacing: 8
                    Text { text: "Percorso file scaricato (o trascina qui il file)"; font.pixelSize: 13; color: "#AAAABB" }
                    RowLayout { Layout.fillWidth: true; spacing: 10
                        Rectangle {
                            id: verifyDropTarget; Layout.fillWidth: true; Layout.preferredHeight: 48; radius: 14
                            color: verifyDropActive ? "#2A2A4E" : "#1A1A2A"
                            border.color: verifyDropActive ? "#5C6BFF" : (pathField.activeFocus ? "#5C6BFF" : "#2A2A3E"); border.width: 1
                            property bool verifyDropActive: false
                            DropArea {
                                anchors.fill: parent; enabled: !root.isVerifying
                                onEntered: verifyDropTarget.verifyDropActive = true
                                onExited: verifyDropTarget.verifyDropActive = false
                                onDropped: {
                                    verifyDropTarget.verifyDropActive = false
                                    if (drop.hasUrls && drop.urls.length > 0) {
                                        var url = drop.urls[0].toString()
                                        if (url.startsWith("file:///")) { url = url.replace("file:///", "") }
                                        else if (url.startsWith("file://")) { url = url.replace("file://", "") }
                                        pathField.text = decodeURIComponent(url)
                                    }
                                }
                            }
                            TextField {
                                id: pathField; anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                                color: "#FFFFFF"; font.pixelSize: 13; selectByMouse: true
                                placeholderText: "C:\\percorso\\file.exe"; background: null; leftPadding: 12; rightPadding: 12
                            }
                        }
                        Rectangle {
                            Layout.preferredWidth: 48; Layout.preferredHeight: 48; radius: 14
                            color: browseArea.containsMouse ? "#2A2A4E" : "#1C1C2E"; border.color: "#2A2A3E"; border.width: 1
                            Text { anchors.centerIn: parent; text: "\uD83D\uDCC1"; font.pixelSize: 20 }
                            MouseArea { id: browseArea; anchors.fill: parent; hoverEnabled: true; enabled: !root.isVerifying
                                onClicked: { var p = verifier.browseFile(); if (p && p.length > 0) { pathField.text = p } } }
                        }
                    }
                }

                Rectangle {
                    id: verifyButton; Layout.fillWidth: true; Layout.preferredHeight: 52; radius: 26
                    opacity: verifyMouseArea.pressed ? 0.70 : (verifyMouseArea.containsMouse ? 0.95 : 0.88)
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    Rectangle {
                        anchors.fill: parent; radius: 26
                        gradient: Gradient { orientation: Gradient.Vertical
                            GradientStop { position: 0.0; color: root.isVerifying ? "#FF453A" : "#5C6BFF" }
                            GradientStop { position: 1.0; color: root.isVerifying ? "#CC3333" : "#8B5CFF" } }
                        opacity: 0.9
                        Text { anchors.centerIn: parent; text: root.isVerifying ? "Annulla" : "Verifica integrita"; color: "#FFFFFF"; font.pixelSize: 16; font.weight: Font.DemiBold }
                    }
                    MouseArea { id: verifyMouseArea; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            if (root.isVerifying) { verifier.cancelVerify() }
                            else { root.isVerifying = true; root.resultText = ""; verifier.verify(hashField.text, pathField.text) }
                        }
                    }
                }

                Item { Layout.fillWidth: true; Layout.preferredHeight: 40; visible: root.isVerifying
                    BusyIndicator { id: verifySpinner; width: 24; height: 24; anchors.centerIn: parent; running: root.isVerifying; palette.dark: "#5C6BFF" }
                    Text { anchors.verticalCenter: parent.verticalCenter; anchors.left: verifySpinner.right; anchors.leftMargin: 12; text: "Calcolo hash in corso..."; color: "#8888AA"; font.pixelSize: 13; visible: root.isVerifying }
                }

                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 200; radius: 18; color: "#16162A"; border.color: "#2A2A3E"; border.width: 1
                    visible: root.resultText.length > 0
                    Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 1; color: "#FFFFFF"; opacity: 0.06 }
                    ScrollView {
                        anchors.fill: parent; anchors.margins: 16
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }
                        TextArea {
                            text: root.resultText; readOnly: true; color: "#E0E0F0"; font.pixelSize: 13; font.family: "Consolas, Monaco, monospace"; wrapMode: TextArea.Wrap; background: null
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }

        // ═══ PAGE 1: Calcola Hash ═══
        Flickable {
            contentHeight: hashColumn.implicitHeight + 20
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }

            ColumnLayout {
                id: hashColumn
                anchors.fill: parent
                spacing: 20

                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 90; radius: 20; color: "#1C1C2E"; border.color: "#2A2A3E"; border.width: 1
                    Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 1; color: "#FFFFFF"; opacity: 0.08 }
                    ColumnLayout { anchors.fill: parent; anchors.margins: 20; spacing: 4
                        Text { text: "Calcola Hash"; font.pixelSize: 22; font.weight: Font.Bold; color: "#FFFFFF" }
                        Text { text: "Genera hash SHA-256, SHA-512 e SHA-3 di qualsiasi file"; font.pixelSize: 12; color: "#8888AA"; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    }
                }

                ColumnLayout { Layout.fillWidth: true; spacing: 8
                    Text { text: "Seleziona file (o trascina qui il file)"; font.pixelSize: 13; color: "#AAAABB" }
                    RowLayout { Layout.fillWidth: true; spacing: 10
                        Rectangle {
                            id: hashDropTarget; Layout.fillWidth: true; Layout.preferredHeight: 48; radius: 14
                            color: hashDropActive ? "#2A2A4E" : "#1A1A2A"
                            border.color: hashDropActive ? "#5C6BFF" : (hashFilePath.activeFocus ? "#5C6BFF" : "#2A2A3E"); border.width: 1
                            property bool hashDropActive: false
                            DropArea {
                                anchors.fill: parent; enabled: !root.isHashing
                                onEntered: hashDropTarget.hashDropActive = true
                                onExited: hashDropTarget.hashDropActive = false
                                onDropped: {
                                    hashDropTarget.hashDropActive = false
                                    if (drop.hasUrls && drop.urls.length > 0) {
                                        var url = drop.urls[0].toString()
                                        if (url.startsWith("file:///")) { url = url.replace("file:///", "") }
                                        else if (url.startsWith("file://")) { url = url.replace("file://", "") }
                                        hashFilePath.text = decodeURIComponent(url)
                                    }
                                }
                            }
                            TextField {
                                id: hashFilePath; anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                                color: "#FFFFFF"; font.pixelSize: 13; selectByMouse: true
                                placeholderText: "C:\\percorso\\file.ext"; background: null; leftPadding: 12; rightPadding: 12
                            }
                        }
                        Rectangle {
                            Layout.preferredWidth: 48; Layout.preferredHeight: 48; radius: 14
                            color: hashBrowseArea.containsMouse ? "#2A2A4E" : "#1C1C2E"; border.color: "#2A2A3E"; border.width: 1
                            Text { anchors.centerIn: parent; text: "\uD83D\uDCC1"; font.pixelSize: 20 }
                            MouseArea { id: hashBrowseArea; anchors.fill: parent; hoverEnabled: true; enabled: !root.isHashing
                                onClicked: { var p = verifier.browseFile(); if (p && p.length > 0) { hashFilePath.text = p } } }
                        }
                    }
                }

                Rectangle {
                    id: hashButton; Layout.fillWidth: true; Layout.preferredHeight: 52; radius: 26
                    opacity: hashMouseArea.pressed ? 0.70 : (hashMouseArea.containsMouse ? 0.95 : 0.88)
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    Rectangle {
                        anchors.fill: parent; radius: 26
                        gradient: Gradient { orientation: Gradient.Vertical
                            GradientStop { position: 0.0; color: root.isHashing ? "#FF453A" : "#5C6BFF" }
                            GradientStop { position: 1.0; color: root.isHashing ? "#CC3333" : "#8B5CFF" } }
                        opacity: 0.9
                        Text { anchors.centerIn: parent; text: root.isHashing ? "Annulla" : "Calcola hash"; color: "#FFFFFF"; font.pixelSize: 16; font.weight: Font.DemiBold }
                    }
                    MouseArea { id: hashMouseArea; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            if (root.isHashing) { verifier.cancelCompute() }
                            else { root.isHashing = true; root.hashSha256 = ""; root.hashSha512 = ""; root.hashSha3 = ""; root.hashSize = ""; root.hashErrorText = ""; verifier.computeHash(hashFilePath.text) }
                        }
                    }
                }

                Item { Layout.fillWidth: true; Layout.preferredHeight: 40; visible: root.isHashing
                    BusyIndicator { id: hashSpinner; width: 24; height: 24; anchors.centerIn: parent; running: root.isHashing; palette.dark: "#5C6BFF" }
                    Text { anchors.verticalCenter: parent.verticalCenter; anchors.left: hashSpinner.right; anchors.leftMargin: 12; text: "Calcolo hash in corso..."; color: "#8888AA"; font.pixelSize: 13; visible: root.isHashing }
                }

                // SHA-256 result
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 80; radius: 14; color: "#16162A"; border.color: "#2A2A3E"; border.width: 1
                    visible: root.hashSha256.length > 0
                    RowLayout { anchors.fill: parent; anchors.margins: 12; spacing: 10
                        ColumnLayout { Layout.fillWidth: true; spacing: 4
                            Text { text: "SHA-256"; font.pixelSize: 11; color: "#5C6BFF"; font.weight: Font.Bold }
                            Text { text: root.hashSha256; font.pixelSize: 12; color: "#E0E0F0"; font.family: "Consolas, Monaco, monospace"; Layout.fillWidth: true; wrapMode: Text.WrapAnywhere }
                        }
                        Rectangle {
                            width: 32; height: 32; radius: 16; color: copy256Area.containsMouse ? "#2A2A4E" : "#1C1C2E"; border.color: "#2A2A3E"; border.width: 1
                            Text { anchors.centerIn: parent; text: "\u2398"; font.pixelSize: 16; color: "#8888AA" }
                            MouseArea { id: copy256Area; anchors.fill: parent; hoverEnabled: true
                                onClicked: { verifier.copyToClipboard(root.hashSha256); trayManager.showMessage("Hash SHA-256 copiato") } }
                        }
                    }
                }

                // SHA-512 result
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 100; radius: 14; color: "#16162A"; border.color: "#2A2A3E"; border.width: 1
                    visible: root.hashSha512.length > 0
                    RowLayout { anchors.fill: parent; anchors.margins: 12; spacing: 10
                        ColumnLayout { Layout.fillWidth: true; spacing: 4
                            Text { text: "SHA-512"; font.pixelSize: 11; color: "#00C2FF"; font.weight: Font.Bold }
                            Text { text: root.hashSha512; font.pixelSize: 12; color: "#E0E0F0"; font.family: "Consolas, Monaco, monospace"; Layout.fillWidth: true; wrapMode: Text.WrapAnywhere }
                        }
                        Rectangle {
                            width: 32; height: 32; radius: 16; color: copy512Area.containsMouse ? "#2A2A4E" : "#1C1C2E"; border.color: "#2A2A3E"; border.width: 1
                            Text { anchors.centerIn: parent; text: "\u2398"; font.pixelSize: 16; color: "#8888AA" }
                            MouseArea { id: copy512Area; anchors.fill: parent; hoverEnabled: true
                                onClicked: { verifier.copyToClipboard(root.hashSha512); trayManager.showMessage("Hash SHA-512 copiato") } }
                        }
                    }
                }

                // SHA-3-256 result
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 80; radius: 14; color: "#16162A"; border.color: "#2A2A3E"; border.width: 1
                    visible: root.hashSha3.length > 0
                    RowLayout { anchors.fill: parent; anchors.margins: 12; spacing: 10
                        ColumnLayout { Layout.fillWidth: true; spacing: 4
                            Text { text: "SHA-3-256"; font.pixelSize: 11; color: "#FF9F43"; font.weight: Font.Bold }
                            Text { text: root.hashSha3; font.pixelSize: 12; color: "#E0E0F0"; font.family: "Consolas, Monaco, monospace"; Layout.fillWidth: true; wrapMode: Text.WrapAnywhere }
                        }
                        Rectangle {
                            width: 32; height: 32; radius: 16; color: copy3Area.containsMouse ? "#2A2A4E" : "#1C1C2E"; border.color: "#2A2A3E"; border.width: 1
                            Text { anchors.centerIn: parent; text: "\u2398"; font.pixelSize: 16; color: "#8888AA" }
                            MouseArea { id: copy3Area; anchors.fill: parent; hoverEnabled: true
                                onClicked: { verifier.copyToClipboard(root.hashSha3); trayManager.showMessage("Hash SHA-3 copiato") } }
                        }
                    }
                }

                // File size
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 44; radius: 14; color: "#16162A"; border.color: "#2A2A3E"; border.width: 1
                    visible: root.hashSize.length > 0
                    RowLayout { anchors.fill: parent; anchors.margins: 12; spacing: 10
                        Text { text: "Dimensione file:"; font.pixelSize: 13; color: "#AAAABB" }
                        Text { text: root.hashSize; font.pixelSize: 13; color: "#FFFFFF"; font.weight: Font.DemiBold }
                        Item { Layout.fillWidth: true }
                    }
                }

                // Error
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 50; radius: 14; color: "#2A1A1A"; border.color: "#3E2A2A"; border.width: 1
                    visible: root.hashErrorText.length > 0
                    Text { anchors.centerIn: parent; text: root.hashErrorText; color: "#FF6B6B"; font.pixelSize: 13 }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }

    Connections {
        target: verifier
        function onVerifyResult(result) { root.isVerifying = false; root.resultText = result }
    }

    Connections {
        target: verifier
        function onHashResult(sha256, sha512, sha3, size) {
            root.isHashing = false
            root.hashSha256 = sha256
            root.hashSha512 = sha512
            root.hashSha3 = sha3
            root.hashSize = size
        }
        function onHashError(msg) { root.isHashing = false; root.hashErrorText = msg }
    }

    Connections {
        target: trayManager
        function onShowWindow() { root.show(); root.raise(); root.requestActivate() }
    }
}
