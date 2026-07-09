import QtQuick 2.15
import QtGraphicalEffects 1.12
import "utils.js" as Utils

ListView {
    id: list

    property var currentGame: currentItem ? currentItem.gameData : null
    property int collectionIndex: 0
    property string currentCollectionShortName: {
        if (collection) {
            return collection.shortName || "";
        }
        return "";
    }
    property bool skipNextUpdate: false

    clip: true
    spacing: 10 * vpx

    highlightMoveDuration: 200
    highlightMoveVelocity: -1
    highlightRangeMode: ListView.StrictlyEnforceRange
    preferredHighlightBegin: height / 2 - 70 * vpx
    preferredHighlightEnd: height / 2 + 70 * vpx
    highlightFollowsCurrentItem: true
    interactive: true
    flickDeceleration: 1500
    maximumFlickVelocity: 2500

    Component.onCompleted: {
        positionViewAtIndex(0, ListView.Center)
    }

    delegate: Item {
        id: gameItem
        width: list.width
        height: isCurrent ? 150 * vpx : 60 * vpx

        property var gameData: modelData
        property bool isCurrent: ListView.isCurrentItem
        property var regionFlags: Utils.getRegionFlag(modelData.title, modelData.files)
        property int currentFlagIndex: 0

        Behavior on height {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        Canvas {
            id: bubbleCanvas
            anchors {
                fill: parent
                leftMargin: 2 * vpx
                rightMargin: 10 * vpx
                topMargin: 2 * vpx
                bottomMargin: 2 * vpx
            }
            visible: isCurrent
            opacity: isCurrent ? 1 : 0

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                if (!isCurrent) return

                    var cornerRadius = 10 * vpx
                    var triangleWidth = 20 * vpx
                    var triangleHeight = 18 * vpx
                    var triangleY = height / 2

                    ctx.beginPath()
                    ctx.moveTo(triangleHeight + cornerRadius, 0)
                    ctx.lineTo(width - cornerRadius, 0)
                    ctx.arcTo(width, 0, width, cornerRadius, cornerRadius)
                    ctx.lineTo(width, height - cornerRadius)
                    ctx.arcTo(width, height, width - cornerRadius, height, cornerRadius)
                    ctx.lineTo(triangleHeight + cornerRadius, height)
                    ctx.arcTo(triangleHeight, height, triangleHeight, height - cornerRadius, cornerRadius)
                    ctx.lineTo(triangleHeight, triangleY + triangleWidth/2)
                    ctx.lineTo(0, triangleY)
                    ctx.lineTo(triangleHeight, triangleY - triangleWidth/2)
                    ctx.lineTo(triangleHeight, cornerRadius)
                    ctx.arcTo(triangleHeight, 0, triangleHeight + cornerRadius, 0, cornerRadius)

                    ctx.closePath()

                    var hueColor = root.getHueColor(collectionIndex)
                    ctx.fillStyle = hueColor
                    ctx.fill()

                    ctx.strokeStyle = Qt.darker(hueColor, 1.2)
                    ctx.lineWidth = 2 * vpx
                    ctx.stroke()
            }

            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }
        }

        Row {
            anchors {
                fill: parent
                leftMargin: isCurrent ? 35 * vpx : 70 * vpx
                rightMargin: 15 * vpx
                topMargin: isCurrent ? 15 * vpx : 3 * vpx
                bottomMargin: isCurrent ? 15 * vpx : 3 * vpx
            }
            spacing: 15 * vpx

            Behavior on anchors.leftMargin {
                NumberAnimation { duration: 150 }
            }
            Behavior on anchors.topMargin {
                NumberAnimation { duration: 150 }
            }
            Behavior on anchors.bottomMargin {
                NumberAnimation { duration: 150 }
            }

            Item {
                width: height + 10 * vpx
                height: isCurrent ? parent.height * 1.1 : parent.height
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    id: gameImage
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    source: {
                        if (modelData.assets.boxFront && modelData.assets.boxFront !== "") {
                            return modelData.assets.boxFront;
                        } else if (modelData.assets.screenshot && modelData.assets.screenshot !== "") {
                            return modelData.assets.screenshot;
                        } else if (modelData.assets.titlescreen && modelData.assets.titlescreen !== "") {
                            return modelData.assets.titlescreen;
                        } else if (modelData.assets.logo && modelData.assets.logo !== "") {
                            return modelData.assets.logo;
                        } else if (modelData.assets.banner && modelData.assets.banner !== "") {
                            return modelData.assets.banner;
                        } else {
                            return "assets/images/Pegasus-Frontend/icon_0.png" /*Utils.getFallbackPixlOSIcon() //random images*/
                        }
                    }
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                    asynchronous: true

                    onStatusChanged: {
                        if (status === Image.Error) {
                            if (source === modelData.assets.boxFront && modelData.assets.screenshot) {
                                source = modelData.assets.screenshot;
                            } else if (source === modelData.assets.screenshot && modelData.assets.titlescreen) {
                                source = modelData.assets.titlescreen;
                            } else if (source === modelData.assets.titlescreen && modelData.assets.logo) {
                                source = modelData.assets.logo;
                            } else if (source === modelData.assets.logo && modelData.assets.banner) {
                                source = modelData.assets.banner;
                            } else {
                                source = "assets/images/Pegasus-Frontend/icon_0.png" /*Utils.getFallbackPixlOSIcon() //random images*/
                            }
                        } else if (status === Image.Ready) {
                        }
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: gameImage.paintedWidth + 6 * vpx
                    height: gameImage.paintedHeight + 6 * vpx
                    color: "transparent"
                    border.color: textPrimary
                    border.width: 3 * vpx
                    radius: 2 * vpx
                }
            }

            Item {
                width: isCurrent ? (parent.width - parent.spacing - height) * 0.60 : parent.width - parent.spacing - height
                height: parent.height

                Text {
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    text: Utils.cleanGameTitle(modelData.title)

                    font {
                        family: global.fonts.sans
                        pixelSize: isCurrent ? 20 * vpx : 14 * vpx
                        bold: isCurrent
                    }
                    color: isCurrent ? "#ffffff" : textPrimary
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                    Behavior on font.pixelSize {
                        NumberAnimation { duration: 150 }
                    }

                    layer.enabled: isCurrent
                    layer.effect: DropShadow {
                        transparentBorder: true
                        horizontalOffset: 1
                        verticalOffset: 1
                        radius: 2
                        samples: 5
                        color: "#80000000"
                    }
                }

                Item {
                    id: favoriteIndicatorContainer
                    anchors {
                        left: parent.left
                        bottom: parent.bottom
                        bottomMargin: 5 * vpx
                    }
                    width: 33 * vpx
                    height: 33 * vpx
                    visible: gameData.favorite && isCurrent

                    Rectangle {
                        id: favoriteBackground
                        anchors.fill: parent
                        color: "#80000000"
                        radius: width / 2
                    }

                    Image {
                        id: favoriteIcon
                        anchors.centerIn: parent
                        width: parent.width * 0.75
                        height: parent.height * 0.75
                        source: "assets/images/icons/favorite.svg"
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                        visible: false
                    }

                    ColorOverlay {
                        anchors.fill: favoriteIcon
                        source: favoriteIcon
                        color: root.getHueColor(collectionIndex)
                    }

                    layer.enabled: true
                    layer.effect: DropShadow {
                        transparentBorder: true
                        horizontalOffset: 1
                        verticalOffset: 1
                        radius: 2
                        samples: 5
                        color: "#40000000"
                    }
                }

                Item {
                    id: systemTextContainer
                    anchors {
                        left: favoriteIndicatorContainer.visible ? favoriteIndicatorContainer.right : favoriteIndicatorContainer.left
                        leftMargin: favoriteIndicatorContainer.visible ? 2 * vpx : 0
                        bottom: parent.bottom
                        bottomMargin: 5 * vpx
                    }
                    width: Math.min(150 * vpx, systemNameText.implicitWidth + 20 * vpx)
                    height: 33 * vpx
                    visible: isCurrent && Utils.shouldShowSystemIcon(list.currentCollectionShortName) &&
                    systemNameText.text !== ""

                    Rectangle {
                        id: systemTextBackground
                        anchors.fill: parent
                        color: "#80000000"
                        radius: height / 2
                    }

                    Text {
                        id: systemNameText
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.left
                            right: parent.right
                            leftMargin: 10 * vpx
                            rightMargin: 10 * vpx
                        }

                        text: {
                            if (!isCurrent || !gameData) {
                                return "";
                            }
                            var shouldShow = Utils.shouldShowSystemIcon(list.currentCollectionShortName);
                            if (!shouldShow) return "";
                            var collectionShortName = Utils.getGameCollectionShortName(gameData);
                            if (!collectionShortName || collectionShortName === "") return "";
                            var displayName = collectionShortName.toUpperCase();
                            return displayName;
                        }

                        font {
                            family: global.fonts.sans
                            pixelSize: 12 * vpx
                            bold: true
                        }
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight

                        layer.enabled: true
                        layer.effect: DropShadow {
                            transparentBorder: true
                            horizontalOffset: 1
                            verticalOffset: 1
                            radius: 2
                            samples: 5
                            color: "#40000000"
                        }
                    }

                    layer.enabled: true
                    layer.effect: DropShadow {
                        transparentBorder: true
                        horizontalOffset: 1
                        verticalOffset: 1
                        radius: 2
                        samples: 5
                        color: "#40000000"
                    }
                }
            }
        }

        Item {
            id: flagsContainer
            anchors {
                right: parent.right
                rightMargin: 25 * vpx
                verticalCenter: parent.verticalCenter
            }
            width: calculateFlagsWidth()
            height: parent.height * 0.75
            visible: isCurrent && regionFlags.length > 0

            function calculateFlagsWidth() {
                var flagsCount = Math.min(regionFlags.length, 8);
                if (flagsCount === 0) return 0;

                if (flagsCount <= 4) {
                    return 50 * vpx;
                } else {
                    return 100 * vpx;
                }
            }

            property int maxFlags: 8
            property int flagsToShow: Math.min(regionFlags.length, maxFlags)
            property int columns: flagsToShow > 4 ? 2 : 1
            property int rows: Math.ceil(flagsToShow / columns)
            property real flagWidth: 45 * vpx
            property real flagHeight: 30 * vpx

            Grid {
                anchors.centerIn: parent
                columns: parent.columns
                rows: parent.rows
                spacing: 3 * vpx
                columnSpacing: 5 * vpx
                rowSpacing: 3 * vpx

                Repeater {
                    model: parent.parent.flagsToShow

                    delegate: Image {
                        width: parent.parent.flagWidth
                        height: parent.parent.flagHeight
                        source: regionFlags[index]
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                        asynchronous: true

                        onStatusChanged: {
                            if (status === Image.Error) {
                                console.log("Flag image failed to load:", source);
                                visible = false;
                            } else if (status === Image.Ready) {
                                visible = true;
                            }
                        }
                    }
                }
            }
        }

        onIsCurrentChanged: {
            bubbleCanvas.requestPaint()
        }

        MouseArea {
            id: itemMouseArea
            anchors.fill: parent
            z: 10

            property real pressX: 0
            property real pressY: 0
            property bool wasDrag: false
            property int tapCount: 0

            Timer {
                id: doubleTapTimer
                interval: 350
                onTriggered: {
                    itemMouseArea.tapCount = 0
                }
            }

            onPressed: {
                pressX = mouse.x
                pressY = mouse.y
                wasDrag = false
            }

            onPositionChanged: {
                var dx = Math.abs(mouse.x - pressX)
                var dy = Math.abs(mouse.y - pressY)
                if (dx > 10 || dy > 10) {
                    wasDrag = true
                }
            }

            onReleased: {
                if (wasDrag) return

                if (index !== list.currentIndex) {
                    list.currentIndex = index
                    soundManager.playDown()
                    tapCount = 0
                    doubleTapTimer.stop()
                    return
                }

                tapCount++
                if (tapCount === 1) {
                    doubleTapTimer.restart()
                    soundManager.playOk()
                } else if (tapCount >= 2) {
                    doubleTapTimer.stop()
                    tapCount = 0
                    soundManager.playOk()
                    list.forceActiveFocus()
                    launchGame()
                }
            }
        }
    }

    onCurrentGameChanged: {
        //console.log("Game changed to:", currentGame ? currentGame.title : "null")
    }

    Rectangle {
        id: progressBarContainer

        anchors {
            right: parent.right
            rightMargin: 2 * vpx
            verticalCenter: parent.verticalCenter
        }

        width: 6 * vpx
        height: parent.height
        color: Qt.rgba(1, 1, 1, 0.2)
        radius: 3 * vpx
        visible: list.count > 0

        Rectangle {
            id: progressIndicator
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }

            height: {
                if (list.count <= 1) return parent.height
                    var progress = (list.currentIndex + 1) / list.count
                    var minHeight = parent.height * 0.1
                    var calculatedHeight = parent.height * progress
                    return Math.max(minHeight, calculatedHeight)
            }

            color: root.getHueColor(collectionIndex)
            radius: 3 * vpx

            Behavior on height {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on color {
                ColorAnimation { duration: 300 }
            }
        }

        Rectangle {
            anchors.fill: progressIndicator
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.3) }
                GradientStop { position: 0.5; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.2) }
            }
            radius: 3 * vpx
        }
    }
}
