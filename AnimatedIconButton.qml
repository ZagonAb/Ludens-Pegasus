import QtQuick 2.15
import QtGraphicalEffects 1.12

Item {
    id: iconButton

    property alias source: iconImage.source
    property alias text: labelText.text
    property bool isSelected: false
    property bool isPressed: false
    property real rotationAngle: 0
    property var iconStates: []
    property int currentStateIndex: 0

    signal clicked()
    signal stateChanged(int newStateIndex)

    width: 80 * vpx
    height: 140 * vpx

    function rotateIcon() {
        rotationAnimation.start()
    }

    function nextState() {
        if (iconStates.length > 0) {
            currentStateIndex = (currentStateIndex + 1) % iconStates.length
            var newState = iconStates[currentStateIndex]
            source = newState.source
            rotationAngle = newState.rotation
            stateChanged(currentStateIndex)
        }
    }

    function animateClick() {
        isPressed = true
        pressTimer.start()
    }

    Item {
        id: hexagonContainer
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
        }
        width: 75 * vpx
        height: 75 * vpx

        HexagonIcon {
            id: hexagon
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            color: root.getHueColor(collectionIndex)
            radiusHex: 0.05
            scale: iconButton.isPressed ? 0.9 : 1.0

            Behavior on scale {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }
        }
    }

    Item {
        id: selectionContainer
        anchors.centerIn: hexagonContainer
        width: 83 * vpx
        height: 83 * vpx

        Canvas {
            id: selectionCanvas
            anchors.fill: parent
            visible: iconButton.isSelected

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                var w = width
                var h = height
                var cx = w / 2
                var cy = h / 2
                var radius = Math.min(w, h) / 2 - 2 * vpx
                var cornerRadius = radius * 0.05
                ctx.beginPath()
                ctx.lineWidth = 2 * vpx
                ctx.strokeStyle = root.isLightTheme ? "#000000" : "#ffffff"
                ctx.lineCap = "round"
                ctx.lineJoin = "round"
                var vertices = []
                for (var i = 0; i < 6; i++) {
                    var angle = (Math.PI / 3) * i - Math.PI / 6 + Math.PI / 2
                    vertices.push({
                        x: cx + radius * Math.cos(angle),
                                  y: cy + radius * Math.sin(angle)
                    })
                }

                for (var j = 0; j < 6; j++) {
                    var current = vertices[j]
                    var next = vertices[(j + 1) % 6]
                    var prev = vertices[(j + 5) % 6]
                    var dx1 = current.x - prev.x
                    var dy1 = current.y - prev.y
                    var len1 = Math.sqrt(dx1 * dx1 + dy1 * dy1)
                    var dx2 = next.x - current.x
                    var dy2 = next.y - current.y
                    var len2 = Math.sqrt(dx2 * dx2 + dy2 * dy2)
                    var startX = current.x - (dx1 / len1) * cornerRadius
                    var startY = current.y - (dy1 / len1) * cornerRadius
                    var endX = current.x + (dx2 / len2) * cornerRadius
                    var endY = current.y + (dy2 / len2) * cornerRadius

                    if (j === 0) {
                        ctx.moveTo(startX, startY)
                    }

                    ctx.quadraticCurveTo(current.x, current.y, endX, endY)

                    if (j < 5) {
                        var nextVertex = vertices[j + 1]
                        var dxNext = nextVertex.x - current.x
                        var dyNext = nextVertex.y - current.y
                        var lenNext = Math.sqrt(dxNext * dxNext + dyNext * dyNext)
                        var nextStartX = nextVertex.x - (dxNext / lenNext) * cornerRadius
                        var nextStartY = nextVertex.y - (dyNext / lenNext) * cornerRadius
                        ctx.lineTo(nextStartX, nextStartY)
                    }
                }

                ctx.closePath()
                ctx.stroke()
            }
        }
    }

    Item {
        id: iconContainer
        anchors.centerIn: hexagonContainer
        width: 50 * vpx
        height: 50 * vpx
        scale: iconButton.isPressed ? 0.9 : 1.0

        Behavior on scale {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        Image {
            id: iconImage
            anchors.fill: parent
            source: iconButton.source
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true

            transform: Rotation {
                id: rotationTransform
                origin.x: iconContainer.width / 2
                origin.y: iconContainer.height / 2
                angle: iconButton.rotationAngle
            }
        }
    }

    Text {
        id: labelText
        anchors {
            top: hexagonContainer.bottom
            topMargin: iconButton.isSelected ? 15 * vpx : -20 * vpx
            horizontalCenter: parent.horizontalCenter
        }
        font {
            family: global.fonts.sans
            pixelSize: 16 * vpx
        }
        color: iconButton.isSelected ? (root.isLightTheme ? "#000000" : "#ffffff") : textSecondary
        opacity: iconButton.isSelected ? 1.0 : 0.0

        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 1
            verticalOffset: 1
            radius: 2
            samples: 5
            color: "#80000000"
        }

        Behavior on anchors.topMargin {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }
    }

    MouseArea {
        anchors.fill: hexagonContainer
        onClicked: {
            iconButton.animateClick()
            iconButton.rotateIcon()
            iconButton.clicked()
        }
    }

    Timer {
        id: pressTimer
        interval: 150
        onTriggered: {
            iconButton.isPressed = false
        }
    }

    SequentialAnimation {
        id: rotationAnimation
        PropertyAnimation {
            target: iconButton
            property: "rotationAngle"
            from: iconButton.rotationAngle
            to: iconButton.rotationAngle + 360
            duration: 400
            easing.type: Easing.OutCubic
        }

        ScriptAction {
            script: {
                iconButton.rotationAngle = iconButton.rotationAngle % 360
            }
        }
    }

    onIsSelectedChanged: {
        if (iconButton.isSelected) {
            selectionCanvas.requestPaint()
        }
    }

    Connections {
        target: root
        function onIsLightThemeChanged() {
            if (iconButton.isSelected) {
                selectionCanvas.requestPaint()
            }
        }
    }
}
