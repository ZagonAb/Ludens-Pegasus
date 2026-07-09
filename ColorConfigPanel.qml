import QtQuick 2.15
import QtGraphicalEffects 1.12

FocusScope {
    id: configPanel

    property bool panelVisible: true
    property int currentIndex: 0
    property var collectionListView: null

    width: 480 * vpx
    height: 100 * vpx

    visible: panelVisible

    transform: Scale {
        origin.x: configPanel.width / 2
        origin.y: configPanel.height / 2
        xScale: configPanel.focus ? 1.03 : 1.0
        yScale: configPanel.focus ? 1.03 : 1.0

        Behavior on xScale {
            NumberAnimation { duration: 300; easing.type: Easing.OutBack }
        }
        Behavior on yScale {
            NumberAnimation { duration: 300; easing.type: Easing.OutBack }
        }
    }

    Row {
        id: slidersRow
        anchors.centerIn: parent
        spacing: 10 * vpx

        CircularSlider {
            id: saturationSlider
            value: root.hueSaturation
            label: "Saturation"
            progressColor: "#ffffff"
            baseColor: root.getHueColor(0)
            width: 80 * vpx
            height: 140 * vpx
            isSelected: configPanel.focus && configPanel.currentIndex === 0

            onValueChanged: {
                root.hueSaturation = value
            }

            Connections {
                target: root
                function onHueSaturationChanged() {
                    saturationSlider.value = root.hueSaturation
                }
            }
        }

        CircularSlider {
            id: lightnessSlider
            value: root.hueLightness
            label: "Lightness"
            progressColor: "#ffffff"
            baseColor: root.getHueColor(0)
            width: 80 * vpx
            height: 140 * vpx
            isSelected: configPanel.focus && configPanel.currentIndex === 1

            onValueChanged: {
                root.hueLightness = value
            }

            Connections {
                target: root
                function onHueLightnessChanged() {
                    lightnessSlider.value = root.hueLightness
                }
            }
        }

        AnimatedIconButton {
            id: resetButton
            isSelected: configPanel.focus && configPanel.currentIndex === 2
            source: "assets/images/icons/reset.svg"
            text: "Reset"

            onClicked: {
                root.hueSaturation = 0.4
                root.hueLightness = 0.49
            }
        }

        AnimatedIconButton {
            id: themeButton
            isSelected: configPanel.focus && configPanel.currentIndex === 3
            text: themeButton.currentStateIndex === 0 ? "Light" : "Dark"

            iconStates: [
                {source: "assets/images/icons/night.svg", rotation: 0},
                {source: "assets/images/icons/light.svg", rotation: 0}
            ]

            Component.onCompleted: {
                themeButton.currentStateIndex = root.isLightTheme ? 0 : 1
                themeButton.source = themeButton.iconStates[themeButton.currentStateIndex].source
                themeButton.rotationAngle = themeButton.iconStates[themeButton.currentStateIndex].rotation
            }

            onClicked: {
                themeButton.nextState()
                root.toggleThemeMode(themeButton.currentStateIndex === 0)
            }

            onStateChanged: {
                themeButton.text = newStateIndex === 0 ? "Light" : "Dark"
            }

            Connections {
                target: root
                function onIsLightThemeChanged() {
                    var newIndex = root.isLightTheme ? 0 : 1
                    if (themeButton.currentStateIndex !== newIndex) {
                        themeButton.currentStateIndex = newIndex
                        var newState = themeButton.iconStates[newIndex]
                        themeButton.source = newState.source
                        themeButton.rotationAngle = newState.rotation
                    }
                }
            }
        }

        AnimatedIconButton {
            id: raButton
            isSelected: configPanel.focus && configPanel.currentIndex === 4
            source: "assets/images/icons/achievement.svg"
            text: "RA"

            onClicked: {
                raButton.animateClick()
                raButton.rotateIcon()
                raPopup.open()
            }
        }
    }

    RACredentialsPopup {
        id: raPopup
        anchors.fill: configPanel

        property real tailOffsetAdjust: 0
        tailRightMargin: configPanel.width
            - (slidersRow.x + raButton.x + raButton.width / 2)
            - (15 * vpx)
            + tailOffsetAdjust

        tailTopMargin: configPanel.height - (5 * vpx)

        onPopupClosed: {
            configPanel.forceActiveFocus()
        }

        onCredentialsSaved: {
            configPanel.forceActiveFocus()
        }
    }

    Keys.onPressed: {
        if (api.keys.isCancel(event)) {
            event.accepted = true
            soundManager.playCancel()
            focus = false
            if (collectionListView) {
                collectionListView.focus = true
            }
        } else if (api.keys.isLeft(event)) {
            event.accepted = true
            soundManager.playDown()
            if (currentIndex > 0) {
                currentIndex--
            } else {
                currentIndex = 4
            }
        } else if (api.keys.isRight(event)) {
            event.accepted = true
            soundManager.playUp()
            if (currentIndex < 4) {
                currentIndex++
            } else {
                currentIndex = 0
            }
        } else if (api.keys.isUp(event)) {
            event.accepted = true
            soundManager.playUp()
            adjustValue(0.05)
        } else if (api.keys.isDown(event)) {
            event.accepted = true
            soundManager.playDown()
            adjustValue(-0.05)
        } else if (api.keys.isAccept(event)) {
            event.accepted = true
            soundManager.playOk()
            if (currentIndex === 2) {
                resetButton.animateClick()
                resetButton.rotateIcon()
                root.hueSaturation = 0.4
                root.hueLightness = 0.49
            } else if (currentIndex === 3) {
                themeButton.animateClick()
                themeButton.rotateIcon()
                themeButton.nextState()
                root.toggleThemeMode(themeButton.currentStateIndex === 0)
            } else if (currentIndex === 4) {
                raButton.animateClick()
                raButton.rotateIcon()
                raPopup.open()
            }
        }
    }

    function adjustValue(amount) {
        if (currentIndex === 0) {
            var newSaturation = root.hueSaturation + amount
            root.hueSaturation = Math.max(0.0, Math.min(1.0, newSaturation))
        } else if (currentIndex === 1) {
            var newLightness = root.hueLightness + amount
            root.hueLightness = Math.max(0.0, Math.min(1.0, newLightness))
        }
    }

    onFocusChanged: {
        updateSelectionStates()
    }

    onCurrentIndexChanged: {
        updateSelectionStates()
    }

    function updateSelectionStates() {
        saturationSlider.isSelected = focus && currentIndex === 0
        lightnessSlider.isSelected = focus && currentIndex === 1
        resetButton.isSelected = focus && currentIndex === 2
        themeButton.isSelected = focus && currentIndex === 3
        raButton.isSelected = focus && currentIndex === 4
    }

    Connections {
        target: root
        function onIsLightThemeChanged() {
        }
    }
}
