import QtQuick 2.15
import QtGraphicalEffects 1.12
import "utils.js" as Utils

FocusScope {
    id: collectionRoot

    signal collectionSelected(var collection)

    property int actualCurrentIndex: 0
    property int collectionIndex: 0
    property bool modelInitialized: false

    CollectionsModel {
        id: collectionsModelManager

        onModelBuilt: {
            //console.log("Model built, count:", model.count)
            restoreInitialIndex()
        }

        Component.onCompleted: {
            //console.log("CollectionsModel component completed")
        }
    }

    function setInitialIndex(index) {
        //console.log("Setting initial index to:", index)
        if (index >= 0 && index < collectionsModelManager.model.count) {
            actualCurrentIndex = index
            collectionList.currentIndex = index
            collectionList.positionViewAtIndex(index, ListView.Center)
            modelInitialized = true
        } else if (collectionsModelManager.model.count > 0) {
            actualCurrentIndex = 0
            collectionList.currentIndex = 0
            collectionList.positionViewAtIndex(0, ListView.Center)
            modelInitialized = true
        }
    }

    function restoreInitialIndex() {
        //console.log("Restoring initial index...")
        var lastIndex = api.memory.get('collectionIndex')
        //console.log("Last index from memory:", lastIndex)

        if (lastIndex !== undefined && lastIndex !== null) {
            restoreTimer.lastIndex = lastIndex
            restoreTimer.start()
        } else {
            setInitialIndex(0)
        }
    }

    Timer {
        id: restoreTimer
        property int lastIndex: 0
        interval: 100
        onTriggered: {
            //console.log("Timer triggered, setting index to:", lastIndex)
            setInitialIndex(lastIndex)
        }
    }

    Component.onCompleted: {
        //console.log("CollectionView component completed")
        if (collectionsModelManager.modelReady) {
            //console.log("Model already ready on CollectionView completion")
            restoreInitialIndex()
        }
    }

    Connections {
        target: collectionsModelManager
        function onModelBuilt() {
            restoreIndex()
        }
    }

    function restoreIndex() {
        var lastIndex = api.memory.get('collectionIndex')
        if (lastIndex !== undefined && lastIndex >= 0 && lastIndex < collectionsModelManager.model.count) {
            setInitialIndex(lastIndex)
        } else {
            setInitialIndex(0)
        }
    }

    Item {
        anchors {
            top: parent.top
            left: parent.left
            topMargin: 10 * vpx
            leftMargin: 10 * vpx
        }
        width: hexSize * 0.45
        height: hexSize * 0.45

        HexagonIcon {
            anchors.fill: parent
            size: hexSize * 0.3
            radiusHex: 0.05
            color: root.getHueColor(collectionIndex)
            iconSource: "" /*Utils.getFallbackPixlOSIcon() //random images*/
            Image {
                anchors.centerIn: parent
                width: parent.width * 0.64
                height: parent.height * 0.64
                source: "assets/images/Pegasus-Frontend/icon_0.png"
                fillMode: Image.PreserveAspectFit
                mipmap: true
            }
        }
    }

    ColorConfigPanel {
        id: globalColorConfig
        anchors {
            top: parent.top
            topMargin: 33 * vpx
            left: parent.left
            leftMargin: 80 * vpx
        }
        panelVisible: true
        focus: false
        collectionListView: collectionList
        z: 1002
    }

    ListView {
        id: collectionList

        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        height: hexSize * 1.05

        orientation: ListView.Horizontal
        snapMode: ListView.SnapOneItem
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: width / 2 - hexSize * 0.9
        preferredHighlightEnd: width / 2 + hexSize * 0.9
        highlightMoveDuration: 350
        spacing: 0


        opacity: globalColorConfig.focus ? 0.4 : 1.0
        scale: globalColorConfig.focus ? 0.95 : 1.0

        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }

        Behavior on scale {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }

        layer.enabled: globalColorConfig.focus
        layer.effect: FastBlur {
            radius: 32
            transparentBorder: true
        }

        model: collectionsModelManager.model

        delegate: Item {
            id: delegateItem
            width: getItemWidth()
            height: collectionList.height

            property bool isCurrent: ListView.isCurrentItem

            function getItemWidth() {
                if (isCurrent) return hexSize * 1.8
                    return hexSize * 0.47
            }

            HexagonCollection {
                id: hexDelegate
                anchors.centerIn: parent
                width: hexSize
                height: hexSize
                collectionData: model
                isCurrentItem: isCurrent
                collectionIndex: index
                totalCollections: collectionsModelManager.model.count
                opacity: 1.0

                scale: isCurrentItem ? 1.3 : 0.41
                Behavior on scale {
                    NumberAnimation { duration: 300; easing.type: Easing.OutBack }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    collectionList.currentIndex = index
                    actualCurrentIndex = index
                }
            }
        }

        onCurrentIndexChanged: {
            if (modelInitialized) {
                actualCurrentIndex = currentIndex
                api.memory.set('collectionIndex', actualCurrentIndex)
            }
        }

        focus: true
        Keys.onPressed: {
            if (api.keys.isAccept(event)) {
                event.accepted = true

                var currentCollection = collectionsModelManager.model.get(currentIndex)
                if (currentCollection &&
                    (currentCollection.shortName === "favorite" || currentCollection.shortName === "history") &&
                    currentCollection.games &&
                    currentCollection.games.count === 0) {
                    //console.log("Cannot access empty " + currentCollection.name + " collection")
                    soundManager.playNoticeBack()
                    return
                    }

                    soundManager.playOk()
                    selectCurrentCollection()
            } else if (api.keys.isLeft(event)) {
                event.accepted = true
                soundManager.playUp()
                if (currentIndex > 0) {
                    currentIndex--
                } else {
                    currentIndex = collectionsModelManager.model.count - 1
                }
            } else if (api.keys.isRight(event)) {
                event.accepted = true
                soundManager.playDown()
                if (currentIndex < collectionsModelManager.model.count - 1) {
                    currentIndex++
                } else {
                    currentIndex = 0
                }
            } else if (api.keys.isFilters(event)) {
                event.accepted = true
                soundManager.playOk()
                globalColorConfig.focus = true
                globalColorConfig.currentIndex = 0
                focus = false
            } else if (api.keys.isCancel(event)) {
                soundManager.playCancel()
            }
        }
    }

    NoiseEffect {
        id: noiSe
        anchors.fill: parent
        noiseIntensity: 0.03
        noiseOpacity: 0.5
        visible: globalColorConfig.focus
    }

    Column {
        id: collectionTexts
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: collectionList.bottom
            topMargin: 40 * vpx
        }
        spacing: 25 * vpx

        opacity: globalColorConfig.focus ? 0.4 : 1.0
        scale: globalColorConfig.focus ? 0.95 : 1.0

        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }

        Behavior on scale {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }

        layer.enabled: globalColorConfig.focus
        layer.effect: FastBlur {
            radius: 32
            transparentBorder: true
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: collectionsModelManager.model.count > 0 ?
            collectionsModelManager.model.get(actualCurrentIndex).name : ""

            font {
                family: global.fonts.sans
                pixelSize: 32 * vpx
                bold: false
            }
            color: root.getHueColor(collectionIndex)
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: {
                if (collectionsModelManager.model.count === 0) return ""
                    var collection = collectionsModelManager.model.get(actualCurrentIndex)
                    return collection.games.count + " Games"
            }

            font {
                family: global.fonts.sans
                pixelSize: 20 * vpx
            }
            color: root.getHueColor(collectionIndex)
        }
    }

    function selectCurrentCollection() {
        if (collectionsModelManager.model.count > 0) {
            api.memory.set('collectionIndex', actualCurrentIndex)
            var selectedCollection = collectionsModelManager.model.get(actualCurrentIndex)

            if ((selectedCollection.shortName === "favorite" || selectedCollection.shortName === "history") &&
                selectedCollection.games &&
                selectedCollection.games.count === 0) {
                //console.log(selectedCollection.name + " collection is empty, cannot access")
                soundManager.playNoticeBack()
                return
                }

                var collectionObject = {
                    name: selectedCollection.name,
                    shortName: selectedCollection.shortName,
                    games: selectedCollection.games,
                    isVirtual: selectedCollection.isVirtual
                }

                if (!selectedCollection.isVirtual && selectedCollection.originalCollection) {
                    collectionObject.originalCollection = selectedCollection.originalCollection
                }

                if (selectedCollection.games && selectedCollection.games.count > 0) {
                    var firstGame = selectedCollection.games.get(0)
                    if (firstGame && typeof firstGame.initRetroAchievements === 'function') {
                        firstGame.initRetroAchievements()
                        //console.log("Pre-initialized RA for first game:", firstGame.title)
                    }
                }

                collectionSelected(collectionObject)
        }
    }
}
