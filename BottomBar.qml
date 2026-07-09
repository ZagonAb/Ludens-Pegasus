import QtQuick 2.15
import QtGraphicalEffects 1.12

Rectangle {
    id: bar

    property bool inGameView: false
    property string navigateIcon: inGameView ? "assets/images/icons/navigate2.png" : "assets/images/icons/navigate.png"
    property bool raLoading: false
    property bool blurred: false

    signal colorSettingsClicked()
    signal okClicked()
    signal favoriteClicked()
    signal runClicked()
    signal backClicked()
    signal achievementsClicked()

    color: "#000000"

    Item {
        id: blurContainer
        anchors.fill: parent

        Row {
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                leftMargin: 60 * vpx
            }
            spacing: 40 * vpx

            BarButton {
                iconSource: bar.navigateIcon
                label: "Navigate"
            }

            BarButton {
                iconSource: inGameView ? "assets/images/icons/favorite.png" : ""
                label: inGameView ? "Favorite" : ""
                visible: inGameView
                clickable: inGameView
                onClicked: bar.favoriteClicked()
            }

            BarButton {
                iconSource: inGameView ? "assets/images/icons/ok.png" : ""
                label: inGameView ? "Run" : ""
                visible: inGameView
                clickable: inGameView
                onClicked: bar.runClicked()
            }

            BarButton {
                iconSource: inGameView ? "assets/images/icons/back.png" : ""
                label: inGameView ? "Back" : ""
                visible: inGameView
                clickable: inGameView
                onClicked: bar.backClicked()
            }

            BarButton {
                iconSource: !inGameView ? "assets/images/icons/setting.png" : ""
                label: !inGameView ? "Color Setting" : ""
                visible: !inGameView
                clickable: !inGameView
                onClicked: bar.colorSettingsClicked()
            }
        }

        Row {
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
                rightMargin: 60 * vpx
            }
            spacing: 15 * vpx

            BarButton {
                iconSource: !inGameView ? "assets/images/icons/ok.png" : ""
                label: !inGameView ? "Ok" : ""
                visible: !inGameView
                clickable: !inGameView
                onClicked: bar.okClicked()
            }

            BarButton {
                id: raIndicator
                iconSource: inGameView ? (raLoading ? "assets/images/icons/spinner.png"
                                                    : "assets/images/icons/achievement.svg")
                                       : ""
                label: inGameView ? (raLoading ? "Searching..." : "Achievements") : ""
                rotating: raLoading
                visible: inGameView
                opacity: raLoading ? 0.6 : 1.0
                clickable: inGameView && !raLoading
                onClicked: bar.achievementsClicked()
            }
        }
    }

    layer.enabled: true
    layer.effect: FastBlur {
        id: blurEffect
        radius: blurred ? 35 : 0
        transparentBorder: true
    }

    Behavior on blurred {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    function setRALoading(loading) {
        raLoading = loading
    }

    onInGameViewChanged: {
        if (!inGameView) raLoading = false
    }
}
