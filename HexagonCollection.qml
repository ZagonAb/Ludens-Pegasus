import QtQuick 2.15
import "utils.js" as Utils

Item {
    id: hexItem

    property var collectionData
    property bool isCurrentItem: false
    property int collectionIndex: 0
    property int totalCollections: 1

    opacity: 1.0

    HexagonIcon {
        id: hexBg
        anchors.centerIn: parent
        size: Math.min(hexItem.width, hexItem.height)
        color: root.getHueColor(collectionIndex)
        iconSource: ""
        radiusHex: 0.05

        Image {
            anchors.centerIn: parent
            width: parent.width * 0.6
            height: parent.height * 0.6

            source: getCollectionImage()
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true

            onStatusChanged: {
                if (status === Image.Error) {
                    source = "assets/images/Pegasus-Frontend/icon_0.png" /*Utils.getFallbackPixlOSIcon() //random images*/
                }
            }
        }
    }

    function getCollectionImage() {
        if (!collectionData) return Utils.getRandomPixlOSIcon();

        var shortName = collectionData.shortName.toLowerCase();

        if (shortName === "favorite") {
            return "assets/images/systems/favorite.png";
        } else if (shortName === "history") {
            return "assets/images/systems/history.png";
        }

        return "assets/images/systems/" + shortName + ".png";
    }
}
