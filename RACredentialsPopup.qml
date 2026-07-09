import QtQuick 2.15
import QtGraphicalEffects 1.12

FocusScope {
    id: raPopup

    property bool isOpen: false
    property real tailRightMargin: (215 * vpx)
    property real tailTopMargin: 0
    readonly property bool buttonFocused: _okBtn.activeFocus || _cancelBtn.activeFocus
    readonly property bool credentialsHasText: _userInput.text.length > 0 || _keyInput.text.length > 0

    signal credentialsSaved()
    signal popupClosed()
    signal userInputActivated()
    signal keyInputActivated()

    readonly property color _popupBg: bgSecondary
    readonly property color _borderColor: isLightTheme ? "#22000000" : "#22ffffff"
    readonly property color _accentColor: root.getHueColor(collectionIndex)
    readonly property color _titleText: textPrimary
    readonly property color _labelText: textSecondary
    readonly property color _inputBg: isLightTheme ? Qt.lighter(bgSecondary, 1.08) : Qt.darker(bgSecondary, 1.3)
    readonly property color _inputBgActive: isLightTheme ? Qt.lighter(bgSecondary, 1.15) : Qt.darker(bgSecondary, 1.1)
    readonly property color _inputBorder: isLightTheme ? "#22000000" : "#22ffffff"
    readonly property color _inputBorderActive: root.getHueColor(collectionIndex)
    readonly property color _inputText: textPrimary
    readonly property color _placeholderText: Qt.rgba(textSecondary.r, textSecondary.g, textSecondary.b, 0.55)
    readonly property color _cursorColor: textPrimary
    readonly property color _separator: isLightTheme ? "#18000000" : "#18ffffff"
    readonly property color _msgBgTesting: bgPrimary
    readonly property color _msgBgSuccess: "#2E7D32"
    readonly property color _msgBgError: "#C62828"
    readonly property color _msgTextTesting: textSecondary
    readonly property color _msgTextSuccess: "#66BB6A"
    readonly property color _msgTextError: "#EF5350"
    readonly property color _okBtnBg: _inputBg
    readonly property color _okBtnBgFocus: root.getHueColor(collectionIndex)
    readonly property color _okBtnText: textPrimary
    readonly property color _okBtnTextFocus: "#ffffff"
    readonly property color _cancelBtnBg: _inputBg
    readonly property color _cancelBtnBgFocus: "#C62828"
    readonly property color _cancelBtnBorder: _inputBorder
    readonly property color _cancelBtnBorderFocus: "#E53935"
    readonly property color _cancelBtnText: textSecondary
    readonly property color _cancelBtnTextFocus: "#EF5350"

    property string _testState: "idle"
    property string _testMsg: ""
    property string _activeField: "none"

    function appendToUser(ch) {
        if (_testState !== "testing") _userInput.text += ch
    }
    function backspaceUser() {
        if (_testState !== "testing" && _userInput.text.length > 0)
            _userInput.text = _userInput.text.slice(0, -1)
    }
    function appendToKey(ch) {
        if (_testState !== "testing") _keyInput.text += ch
    }
    function backspaceKey() {
        if (_testState !== "testing" && _keyInput.text.length > 0)
            _keyInput.text = _keyInput.text.slice(0, -1)
    }

    function focusFieldSafe(field) {
        if (field === "key") _keyFieldScope.forceActiveFocus()
            else _userFieldScope.forceActiveFocus()
    }

    function _activateField(field) {
        raPopup._activeField = field
        if (field === "key") {
            _keyFieldScope.forceActiveFocus()
            _keyInput.forceActiveFocus()
            raPopup.keyInputActivated()
        } else {
            _userFieldScope.forceActiveFocus()
            _userInput.forceActiveFocus()
            raPopup.userInputActivated()
        }
    }

    function open() {
        soundManager.playOk()
        _userInput.text = api.memory.has("ra_api_user") ? api.memory.get("ra_api_user") : ""
        _keyInput.text = api.memory.has("ra_api_key") ? api.memory.get("ra_api_key") : ""
        _testState = "idle"
        _testMsg = ""
        isOpen = true
        _focusTimer.start()
    }

    function close() {
        soundManager.playCancel()
        isOpen = false
        raPopup._activeField = "none"
        raPopup.focus = false
        raPopup.popupClosed()
    }

    function _save() {
        var u = _userInput.text.trim()
        var k = _keyInput.text.trim()
        if (u === "" || k === "") {
            _testState = "error"
            _testMsg = "Both fields are required."
            return
        }
        api.memory.set("ra_api_user", u)
        api.memory.set("ra_api_key", k)
        _testState = "testing"
        _testMsg = ""
        _testConnection(u, k)
    }

    function _testConnection(user, key) {
        var url = "https://retroachievements.org/API/API_GetUserSummary.php"
        + "?y=" + encodeURIComponent(key)
        + "&u=" + encodeURIComponent(user)
        + "&g=1"
        var xhr = new XMLHttpRequest()
        xhr.open("GET", url, true)
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
                if (xhr.status === 200) {
                    try {
                        var data = JSON.parse(xhr.responseText)
                        if (data && (data.User || data.Username || data.MemberSince)) {
                            var displayName = data.User || data.Username || user
                            _testState = "success"
                            _testMsg = "Connected as " + displayName
                            _closeTimer.start()
                        } else {
                            _testState = "error"
                            _testMsg = "Invalid credentials. Check your API User and Key."
                        }
                    } catch(e) {
                        _testState = "error"
                        _testMsg = "Could not parse server response."
                    }
                } else if (xhr.status === 0) {
                    _testState = "success"
                    _testMsg = "Saved. (No network — could not verify)"
                    _closeTimer.start()
                } else {
                    _testState = "error"
                    _testMsg = "Server error: HTTP " + xhr.status
                }
        }
        xhr.send()
    }

    Timer {
        id: _closeTimer
        interval: 1400
        onTriggered: {
            isOpen = false
            raPopup._activeField = "none"
            raPopup.focus = false
            raPopup.credentialsSaved()
        }
    }

    Timer {
        id: _focusTimer
        interval: 30
        onTriggered: {
            raPopup._activeField = "user"
            raPopup.userInputActivated()
            _userFieldScope.forceActiveFocus()
        }
    }

    property real _panelOpacity: isOpen ? 1.0 : 0.0
    Behavior on _panelOpacity { NumberAnimation { duration: 210; easing.type: Easing.InOutQuad } }

    visible: _panelOpacity > 0.001
    opacity: _panelOpacity

    Keys.onPressed: function(event) {
        if (api.keys.isCancel(event) && raPopup._testState !== "testing") {
            event.accepted = true
            raPopup.close()
        }
    }

    Canvas {
        id: _tail
        width: (32 * vpx)
        height: (20 * vpx)
        anchors.right: parent.right
        anchors.rightMargin: raPopup.tailRightMargin
        anchors.top: parent.top
        anchors.topMargin: raPopup.tailTopMargin
        z: 2

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.fillStyle = _popupBg
            ctx.beginPath()
            ctx.moveTo(0, height)
            ctx.lineTo(width / 2, 0)
            ctx.lineTo(width, height)
            ctx.closePath()
            ctx.fill()
        }

        Connections {
            target: root
            function onIsLightThemeChanged() { _tail.requestPaint() }
        }
    }

    Rectangle {
        id: _panel

        property real _slideOffset: raPopup.isOpen ? 0 : (-8 * vpx)
        Behavior on _slideOffset { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        anchors.right: parent.right
        anchors.top: _tail.bottom
        anchors.topMargin: (-1 * vpx)
        width: (460 * vpx)
        y: _slideOffset
        height: _col.height + (36 * vpx)

        color: _popupBg
        radius: (25 * vpx)
        Behavior on color { ColorAnimation { duration: 200 } }

        Column {
            id: _col
            anchors {
                top: parent.top; topMargin: (20 * vpx)
                left: parent.left; leftMargin: (22 * vpx)
                right: parent.right; rightMargin: (22 * vpx)
            }
            spacing: (12 * vpx)

            Row {
                spacing: (8 * vpx)
                anchors.horizontalCenter: parent.horizontalCenter

                Item {
                    width: (32 * vpx); height: (32 * vpx)
                    anchors.verticalCenter: parent.verticalCenter
                    Image {
                        id: _titleIcon
                        anchors.fill: parent
                        source: "assets/images/icons/achievement.svg"
                        fillMode: Image.PreserveAspectFit
                        mipmap: true; visible: false
                    }
                    ColorOverlay {
                        anchors.fill: _titleIcon; source: _titleIcon
                        color: _accentColor; visible: _titleIcon.status === Image.Ready
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: _titleIcon.status !== Image.Ready
                        text: "RA"; font.pixelSize: (13 * vpx); font.bold: true; color: _accentColor
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Enter your RA credentials here."
                    font.pixelSize: (18 * vpx); font.family: global.fonts.sans
                    font.bold: true; color: _titleText
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }

            Rectangle { width: parent.width; height: (1 * vpx); color: _separator; Behavior on color { ColorAnimation { duration: 200 } } }

            FocusScope {
                id: _userFieldScope
                width: parent.width
                height: _userFieldCol.implicitHeight

                readonly property bool _highlighted: activeFocus || raPopup._activeField === "user"

                Keys.onPressed: {
                    if (raPopup._testState === "testing") { event.accepted = true; return }
                    if (!event.isAutoRepeat && api.keys.isAccept(event)) {
                        event.accepted = true
                        raPopup._activateField("user")
                        return
                    }
                    if (api.keys.isCancel(event)) {
                        event.accepted = true
                        raPopup.close()
                        return
                    }
                }
                Keys.onDownPressed: { event.accepted = true; soundManager.playDown(); _keyFieldScope.forceActiveFocus() }

                Column {
                    id: _userFieldCol
                    width: parent.width
                    spacing: (5 * vpx)

                    Text {
                        text: "USER NAME:"
                        font.pixelSize: (14 * vpx); font.family: global.fonts.sans
                        font.letterSpacing: 0.6; color: _labelText
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    Rectangle {
                        id: _userRect
                        width: parent.width; height: (32 * vpx); radius: (25 * vpx)
                        color: _userFieldScope._highlighted ? _inputBgActive : _inputBg
                        border.color: _userFieldScope._highlighted ? _inputBorderActive : _inputBorder
                        border.width: (3 * vpx)
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        TextInput {
                            id: _userInput
                            anchors {
                                left: parent.left; right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: (10 * vpx); rightMargin: (10 * vpx)
                            }
                            color: _inputText; font.pixelSize: (13 * vpx)
                            font.family: global.fonts.sans
                            selectionColor: "#2a6496"; selectedTextColor: "#ffffff"
                            clip: true
                            readOnly: raPopup._activeField !== "user" || raPopup._testState === "testing"
                            activeFocusOnPress: false
                            inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                            | Qt.ImhSensitiveData | Qt.ImhMultiLine

                            cursorDelegate: Rectangle {
                                id: _userCursor
                                width: (2 * vpx)
                                height: (16 * vpx)
                                color: _cursorColor
                                visible: raPopup._activeField === "user" && raPopup._testState !== "testing"
                                SequentialAnimation on opacity {
                                    running: _userCursor.visible
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 1; duration: 0 }
                                    NumberAnimation { to: 1; duration: 480 }
                                    NumberAnimation { to: 0; duration: 0 }
                                    NumberAnimation { to: 0; duration: 480 }
                                }
                                onVisibleChanged: if (!visible) opacity = 1
                            }

                            Text {
                                anchors.fill: parent
                                text: "your username"
                                color: _placeholderText
                                font: _userInput.font
                                visible: _userInput.text.length === 0
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.IBeamCursor
                            onClicked: {
                                if (raPopup._testState !== "testing")
                                    raPopup._activateField("user")
                            }
                        }
                    }
                }
            }

            FocusScope {
                id: _keyFieldScope
                width: parent.width
                height: _keyFieldCol.implicitHeight

                readonly property bool _highlighted: activeFocus || raPopup._activeField === "key"

                Keys.onPressed: {
                    if (raPopup._testState === "testing") { event.accepted = true; return }
                    if (!event.isAutoRepeat && api.keys.isAccept(event)) {
                        event.accepted = true
                        raPopup._activateField("key")
                        return
                    }
                    if (api.keys.isCancel(event)) {
                        event.accepted = true
                        raPopup.close()
                        return
                    }
                }
                Keys.onUpPressed: { event.accepted = true; soundManager.playUp(); _userFieldScope.forceActiveFocus() }
                Keys.onDownPressed: { event.accepted = true; soundManager.playDown(); _okBtn.forceActiveFocus() }

                Column {
                    id: _keyFieldCol
                    width: parent.width
                    spacing: (5 * vpx)

                    Text {
                        text: "API KEY:"
                        font.pixelSize: (14 * vpx); font.family: global.fonts.sans
                        font.letterSpacing: 0.6; color: _labelText
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    Rectangle {
                        id: _keyRect
                        width: parent.width; height: (32 * vpx); radius: (25 * vpx)
                        color: _keyFieldScope._highlighted ? _inputBgActive : _inputBg
                        border.color: _keyFieldScope._highlighted ? _inputBorderActive : _inputBorder
                        border.width: (3 * vpx)
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        TextInput {
                            id: _keyInput
                            anchors {
                                left: parent.left; right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: (10 * vpx); rightMargin: (10 * vpx)
                            }
                            color: _inputText; font.pixelSize: (13 * vpx)
                            font.family: global.fonts.sans
                            selectionColor: "#2a6496"; selectedTextColor: "#ffffff"
                            clip: true
                            readOnly: raPopup._activeField !== "key" || raPopup._testState === "testing"
                            activeFocusOnPress: false
                            inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                            | Qt.ImhSensitiveData | Qt.ImhMultiLine

                            cursorDelegate: Rectangle {
                                id: _keyCursor
                                width: (2 * vpx)
                                height: (16 * vpx)
                                color: _cursorColor
                                visible: raPopup._activeField === "key" && raPopup._testState !== "testing"
                                SequentialAnimation on opacity {
                                    running: _keyCursor.visible
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 1; duration: 0 }
                                    NumberAnimation { to: 1; duration: 480 }
                                    NumberAnimation { to: 0; duration: 0 }
                                    NumberAnimation { to: 0; duration: 480 }
                                }
                                onVisibleChanged: if (!visible) opacity = 1
                            }

                            Text {
                                anchors.fill: parent
                                text: "your API key"
                                color: _placeholderText
                                font: _keyInput.font
                                visible: _keyInput.text.length === 0
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.IBeamCursor
                            onClicked: {
                                if (raPopup._testState !== "testing")
                                    raPopup._activateField("key")
                            }
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: raPopup._testState !== "idle" ? (34 * vpx) : 0
                clip: true
                Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }

                Rectangle {
                    anchors { fill: parent; topMargin: (2 * vpx) }
                    radius: (4 * vpx)
                    color: {
                        if (raPopup._testState === "testing") return _msgBgTesting
                            if (raPopup._testState === "success") return _msgBgSuccess
                                return _msgBgError
                    }
                    Behavior on color { ColorAnimation { duration: 200 } }

                    Row {
                        anchors {
                            left: parent.left; leftMargin: (10 * vpx)
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: (8 * vpx)

                        Item {
                            width: (16 * vpx); height: (16 * vpx)
                            anchors.verticalCenter: parent.verticalCenter
                            visible: raPopup._testState === "testing"
                            Rectangle {
                                anchors.fill: parent; radius: width / 2
                                color: "transparent"
                                border.width: (2 * vpx); border.color: _msgTextTesting
                                Rectangle {
                                    anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
                                    width: (2 * vpx); height: (5 * vpx); color: _msgTextTesting; radius: (1 * vpx)
                                }
                                RotationAnimator on rotation {
                                    running: raPopup._testState === "testing"
                                    loops: Animation.Infinite; from: 0; to: 360; duration: 900
                                }
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: raPopup._testState === "success" || raPopup._testState === "error"
                            text: raPopup._testState === "success" ? "✔" : "✘"
                            color: raPopup._testState === "success" ? _msgTextSuccess : _msgTextError
                            font.pixelSize: (13 * vpx); font.bold: true
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: {
                                if (raPopup._testState === "testing") return "Verifying credentials…"
                                    return raPopup._testMsg
                            }
                            color: {
                                if (raPopup._testState === "testing") return _msgTextTesting
                                    if (raPopup._testState === "success") return _msgTextSuccess
                                        return _msgTextError
                            }
                            font.pixelSize: (11 * vpx); font.family: global.fonts.sans
                            elide: Text.ElideRight; width: (370 * vpx)
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: (12 * vpx)

                Item {
                    id: _okBtn
                    width: (90 * vpx); height: (32 * vpx)
                    readonly property bool _busy: raPopup._testState === "testing"

                    Rectangle {
                        anchors.fill: parent; radius: (15 * vpx)
                        color: {
                            if (_okBtn._busy) return _msgBgTesting
                                if (_okBtn.activeFocus) return _okBtnBgFocus
                                    return _okBtnBg
                        }
                        border.color: (_okBtn.activeFocus && !_okBtn._busy) ? _inputBorderActive : _inputBorder
                        border.width: (1 * vpx)
                        opacity: _okBtn._busy ? 0.5 : 1.0
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "OK"
                        font.pixelSize: (13 * vpx); font.family: global.fonts.sans; font.bold: true
                        color: (_okBtn.activeFocus && !_okBtn._busy) ? _okBtnTextFocus : _okBtnText
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Keys.onUpPressed: { event.accepted = true; soundManager.playUp(); _keyFieldScope.forceActiveFocus() }
                    Keys.onRightPressed: { event.accepted = true; soundManager.playUp(); _cancelBtn.forceActiveFocus() }
                    Keys.onPressed: {
                        if (_okBtn._busy) { event.accepted = true; return }
                        if (api.keys.isCancel(event)) { event.accepted = true; raPopup.close(); return }
                        if (!event.isAutoRepeat && api.keys.isAccept(event)) {
                            event.accepted = true; soundManager.playOk(); raPopup._save(); return
                        }
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            event.accepted = true; soundManager.playOk(); raPopup._save()
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (!_okBtn._busy) { soundManager.playOk(); raPopup._save() } }
                    }
                }

                Item {
                    id: _cancelBtn
                    width: (90 * vpx); height: (32 * vpx)

                    Rectangle {
                        anchors.fill: parent; radius: (15 * vpx)
                        color: _cancelBtn.activeFocus ? _cancelBtnBgFocus : _cancelBtnBg
                        border.color: _cancelBtn.activeFocus ? _cancelBtnBorderFocus : _cancelBtnBorder
                        border.width: (1 * vpx)
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        font.pixelSize: (13 * vpx); font.family: global.fonts.sans; font.bold: true
                        color: _cancelBtn.activeFocus ? _cancelBtnTextFocus : _cancelBtnText
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Keys.onUpPressed: { event.accepted = true; soundManager.playUp(); _keyFieldScope.forceActiveFocus() }
                    Keys.onLeftPressed: { event.accepted = true; soundManager.playDown(); _okBtn.forceActiveFocus() }
                    Keys.onPressed: {
                        if (raPopup._testState === "testing") { event.accepted = true; return }
                        if (api.keys.isCancel(event) || api.keys.isAccept(event)
                            || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            event.accepted = true; raPopup.close()
                            }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (raPopup._testState !== "testing") raPopup.close() }
                    }
                }
            }

            Item { width: 1; height: (4 * vpx) }
        }
    }
}
