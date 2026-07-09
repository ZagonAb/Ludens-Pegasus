import QtQuick 2.15

FocusScope {
    id: root

    property bool inCollectionView: false
    property var currentCollection: null
    property color bgPrimary: "#1a1a1a"
    property color bgSecondary: "#252525"
    readonly property color accentPink: "#c2366d"
    readonly property color accentPurple: "#7b3f99"
    property color textPrimary: "#ffffff"
    property color textSecondary: "#e5e5e5"
    property bool isLightTheme: false

    readonly property real vpx: Math.min(width, height) / 720
    readonly property real hexSize: 180 * vpx

    property real hueSaturation: 0.4
    property real hueLightness: 0.49

    SoundEffects {
        id: soundManager
    }

    onInCollectionViewChanged: {
        if (!inCollectionView) {
            collectionView.focus = true
            collectionView.forceActiveFocus()
        }
    }

    function toggleThemeMode(lightTheme) {
        if (lightTheme) {
            root.bgPrimary = "#dddddd"
            root.bgSecondary = "#c6c6c6"
            root.textPrimary = "#1a1a1a"
            root.textSecondary = "#333333"
            root.isLightTheme = true
        } else {
            root.bgPrimary = "#1a1a1a"
            root.bgSecondary = "#252525"
            root.textPrimary = "#ffffff"
            root.textSecondary = "#e5e5e5"
            root.isLightTheme = false
        }

        saveThemeSettings()

        root.isLightThemeChanged()
    }

    function getHueColor(index) {
        var totalCollections = 0

        if (collectionView &&
            collectionView.collectionsModelManager &&
            collectionView.collectionsModelManager.model) {
            totalCollections = collectionView.collectionsModelManager.model.count
            }

            if (totalCollections === 0) {
                totalCollections = api.collections.count + 2
            }

            if (totalCollections <= 1)
                return Qt.hsla(0.0666, hueSaturation, hueLightness, 1.0)

                var startHue = 0.0666
                var hueIncrement = 1.0 / totalCollections
                var hue = (startHue - hueIncrement * index + 1.0) % 1.0

                return Qt.hsla(hue, hueSaturation, hueLightness, 1.0)
    }


    function saveColorSettings() {
        api.memory.set('hueSaturation', hueSaturation)
        api.memory.set('hueLightness', hueLightness)
    }

    function saveThemeSettings() {
        api.memory.set('isLightTheme', isLightTheme)
    }

    function loadThemeSettings() {
        var savedTheme = api.memory.get('isLightTheme')
        if (savedTheme !== undefined) {
            toggleThemeMode(savedTheme)
        }
    }

    Rectangle {
        anchors.fill: parent
        color: bgPrimary
    }

    CollectionView {
        id: collectionView
        anchors.fill: parent
        visible: !root.inCollectionView
        focus: !root.inCollectionView
        collectionIndex: collectionView.actualCurrentIndex

        onCollectionSelected: function(collection) {
            root.currentCollection = collection
            root.inCollectionView = true
        }
    }

    GameView {
        id: gameView
        width: parent.width
        height: parent.height * 0.92
        visible: root.inCollectionView
        focus: root.inCollectionView
        collection: root.currentCollection
        collectionIndex: collectionView.actualCurrentIndex

        onBackRequested: {
            root.inCollectionView = false
            collectionView.focus = true
            collectionView.forceActiveFocus()
        }
    }

    BottomBar {
        id: bottomBar
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 60 * root.vpx
        inGameView: root.inCollectionView
        blurred: root.inCollectionView && gameView.panelsBlurred

        onColorSettingsClicked: {
            soundManager.playOk()
            collectionView.globalColorConfig.focus = true
            collectionView.globalColorConfig.currentIndex = 0
            collectionView.collectionList.focus = false
        }

        onOkClicked: {
            soundManager.playOk()
            collectionView.selectCurrentCollection()
        }
    }

    StatusBar {
        id: statusBar
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 10 * vpx
            rightMargin: 20 * vpx
        }
        visible: collectionView.visible
    }

    Component.onCompleted: {
        if (typeof Utils !== 'undefined' && Utils.fallbackIcon !== undefined) {
            Utils.fallbackIcon = null;
        }

        var savedSaturation = api.memory.get('hueSaturation')
        var savedLightness = api.memory.get('hueLightness')
        if (savedSaturation !== undefined) hueSaturation = savedSaturation
            if (savedLightness !== undefined) hueLightness = savedLightness

                loadThemeSettings()

                var wasLaunching = api.memory.get('gameLaunching')
                if (wasLaunching) {
                    root.inCollectionView = false
                    api.memory.set('gameLaunching', false)
                    collectionView.focus = true
                    collectionView.forceActiveFocus()
                }
    }

    onHueSaturationChanged: {
        saveColorSettings()
    }

    onHueLightnessChanged: {
        saveColorSettings()
    }
}
