import QtQuick 2.15
import QtGraphicalEffects 1.12

Item {
    id: sliderRoot

    property real value: 0.5
    property real minValue: 0.0
    property real maxValue: 1.0
    property string label: "Slider"
    property color trackColor: "#404040"
    property color progressColor: "#ffffff"
    property color textColor: "#ffffff"
    property bool isSelected: false
    property color baseColor: "#c2366d"

    width: 80 * vpx
    height: 140 * vpx

    function updateValue(angle) {
        var normalized = (angle + Math.PI) / (2 * Math.PI)
        var newValue = minValue + (normalized * (maxValue - minValue))
        value = Math.max(minValue, Math.min(maxValue, newValue))
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
            id: mainHexagon
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            color: root.getHueColor(collectionIndex)
            radiusHex: 0.05
        }

        Canvas {
            id: progressCanvas
            anchors.fill: parent

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                var w = width
                var h = height
                var cx = w / 2
                var cy = h / 2
                var radius = Math.min(w, h) / 2 - 8 * vpx
                var cornerRadius = radius * 0.15
                var progress = (value - minValue) / (maxValue - minValue)
                ctx.beginPath()
                ctx.lineWidth = 3 * vpx
                ctx.strokeStyle = progressColor
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

                var totalSegments = 6
                var segmentsToDraw = Math.floor(progress * totalSegments)
                var partialProgress = (progress * totalSegments) - segmentsToDraw

                for (var seg = 0; seg < segmentsToDraw; seg++) {
                    if (seg < totalSegments) {
                        var current = vertices[seg]
                        var next = vertices[(seg + 1) % totalSegments]

                        if (seg === 0) {
                            ctx.moveTo(current.x, current.y)
                        }
                        ctx.lineTo(next.x, next.y)
                    }
                }

                if (segmentsToDraw < totalSegments && partialProgress > 0) {
                    var currentIdx = segmentsToDraw % totalSegments
                    var nextIdx = (currentIdx + 1) % totalSegments
                    var currentVert = vertices[currentIdx]
                    var nextVert = vertices[nextIdx]

                    var midX = currentVert.x + (nextVert.x - currentVert.x) * partialProgress
                    var midY = currentVert.y + (nextVert.y - currentVert.y) * partialProgress

                    if (segmentsToDraw === 0) {
                        ctx.moveTo(currentVert.x, currentVert.y)
                    }
                    ctx.lineTo(midX, midY)
                }

                if (progress >= 1.0) {
                    ctx.closePath()
                }

                ctx.stroke()
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
            visible: isSelected

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

    Text {
        id: valueText
        anchors.centerIn: hexagonContainer
        text: Math.round(value * 100) + "%"
        font {
            family: global.fonts.sans
            pixelSize: 16 * vpx
            bold: true
        }
        color: isSelected ? "#ffffff" : textColor

        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 1
            verticalOffset: 1
            radius: 2
            samples: 5
            color: "#80000000"
        }
    }

    Text {
        id: labelText
        anchors {
            top: hexagonContainer.bottom
            topMargin: isSelected ? 15 * vpx : -20 * vpx
            horizontalCenter: parent.horizontalCenter
        }
        text: label
        font {
            family: global.fonts.sans
            pixelSize: 16 * vpx
        }
        color: isSelected ? (root.isLightTheme ? "#000000" : "#ffffff") : textSecondary
        opacity: isSelected ? 1.0 : 0.0

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
        preventStealing: true

        onPressed: {
            var centerX = hexagonContainer.width / 2
            var centerY = hexagonContainer.height / 2
            var angle = Math.atan2(mouseY - centerY, mouseX - centerX)
            updateValue(angle)
        }

        onPositionChanged: {
            if (pressed) {
                var centerX = hexagonContainer.width / 2
                var centerY = hexagonContainer.height / 2
                var angle = Math.atan2(mouseY - centerY, mouseX - centerX)
                updateValue(angle)
            }
        }
    }

    onValueChanged: {
        progressCanvas.requestPaint()
    }

    onIsSelectedChanged: {
        if (isSelected) {
            selectionCanvas.requestPaint()
        }
    }

    Connections {
        target: root
        function onIsLightThemeChanged() {
            if (isSelected) {
                selectionCanvas.requestPaint()
            }
        }
    }

    Component.onCompleted: {
        progressCanvas.requestPaint()
    }
}
