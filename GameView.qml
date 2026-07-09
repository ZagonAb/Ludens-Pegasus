import QtQuick 2.15
import QtGraphicalEffects 1.12
import "utils.js" as Utils

FocusScope {
    id: gameRoot

    property var collection
    property int collectionIndex: 0
    property bool panelsBlurred: false
    property var availableLetters: []
    property string currentLetter: ""
    property bool showLetterIndicator: false
    property bool letterNavigationBlur: false

    function applyBlurEffects(shouldBlur) {
        panelsBlurred = shouldBlur;
        bottomBar.blurred = shouldBlur;
    }

    signal backRequested()

    onVisibleChanged: {
        if (!visible) {
            bottomBar.setRALoading(false)
            applyBlurEffects(false)
        } else if (gameList.currentGame) {
            gameList.buildLetterIndex()
        }
    }

    onCollectionChanged: {
        if (collection) {
            gameList.buildLetterIndex()
        }
    }

    Rectangle {
        id: leftPanel

        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }

        width: 280 * vpx
        color: bgSecondary

        opacity: gameRoot.panelsBlurred ? 0.4 : (gameRoot.letterNavigationBlur ? 0.5 : 1.0)
        scale: gameRoot.panelsBlurred ? 0.95 : (gameRoot.letterNavigationBlur ? 0.98 : 1.0)

        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }

        Behavior on scale {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }

        layer.enabled: gameRoot.panelsBlurred || gameRoot.letterNavigationBlur
        layer.effect: FastBlur {
            radius: 32
            transparentBorder: true
        }

        StatusBar {
            id: gameViewStatusBar
            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
                topMargin: 10 * vpx
            }
            width: parent.width * 0.9
            height: 40 * vpx
            scale: 0.8
        }

        HexagonIcon {
            id: hexIcon
            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
            }
            size: hexSize
            color: root.getHueColor(collectionIndex)
            radiusHex: 0.05

            Image {
                id: systemImage
                anchors.centerIn: parent
                width: parent.width * 0.5
                height: parent.height * 0.5
                source: getSystemImage()
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
                cache: false

                onStatusChanged: {
                    if (status === Image.Error) {
                        source = "assets/images/Pegasus-Frontend/icon_0.png"
                    }
                }

                Connections {
                    target: gameRoot
                    function onCollectionChanged() {
                        systemImage.source = ""
                        systemImage.source = getSystemImage()
                    }
                }
            }
        }

        Column {
            anchors {
                top: hexIcon.bottom
                topMargin: 30 * vpx
                horizontalCenter: parent.horizontalCenter
            }
            spacing: 15 * vpx
            width: leftPanel.width - 40 * vpx

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width

                text: collection ? collection.name : ""
                font {
                    family: global.fonts.sans
                    pixelSize: 25 * vpx
                }
                color: root.getHueColor(collectionIndex)
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: collection ? collection.games.count + " Games" : ""
                font {
                    family: global.fonts.sans
                    pixelSize: 20 * vpx
                }
                color: root.getHueColor(collectionIndex)
                horizontalAlignment: Text.AlignHCenter
            }
        }

        FavoriteNotification {
            id: favoriteNotification
            collectionIndex: gameRoot.collectionIndex
        }
    }

    GameList {
        id: gameList
        anchors {
            left: leftPanel.right
            top: parent.top
            bottom: parent.bottom
            margins: 20 * vpx
        }
        width: parent.width * 0.4 - 40 * vpx

        model: collection ? collection.games : null
        focus: true
        collectionIndex: gameRoot.collectionIndex

        opacity: gameRoot.panelsBlurred ? 0.4 : (gameRoot.letterNavigationBlur ? 0.5 : 1.0)
        scale: gameRoot.panelsBlurred ? 0.95 : (gameRoot.letterNavigationBlur ? 0.98 : 1.0)

        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }

        Behavior on scale {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }

        layer.enabled: gameRoot.panelsBlurred || gameRoot.letterNavigationBlur
        layer.effect: FastBlur {
            radius: 32
            transparentBorder: true
        }

        property string currentCollectionShortName: collection ? collection.shortName : ""
        property var letterIndex: ({})

        function buildLetterIndex() {
            if (!collection || !collection.games) return

                var index = {}
                var letters = []

                for (var i = 0; i < collection.games.count; i++) {
                    var game = collection.games.get(i)
                    if (!game) continue

                        var cleanTitle = Utils.cleanGameTitle(game.title).toUpperCase()
                        var firstChar = cleanTitle.charAt(0)

                        if (firstChar.match(/[^A-Z]/)) {
                            firstChar = "#"
                        }

                        if (!index[firstChar]) {
                            index[firstChar] = []
                            letters.push(firstChar)
                        }
                        index[firstChar].push(i)
                }

                letters.sort(function(a, b) {
                    if (a === "#") return -1
                        if (b === "#") return 1
                            return a.localeCompare(b)
                })

                letterIndex = index
                gameRoot.availableLetters = letters
        }

        function jumpToNextLetter() {
            if (gameRoot.availableLetters.length === 0) return

                var currentGame = gameList.currentGame
                if (!currentGame) return

                    var cleanTitle = Utils.cleanGameTitle(currentGame.title).toUpperCase()
                    var currentFirstChar = cleanTitle.charAt(0)

                    if (currentFirstChar.match(/[^A-Z]/)) {
                        currentFirstChar = "#"
                    }

                    var currentLetterIndex = gameRoot.availableLetters.indexOf(currentFirstChar)
                    var nextLetterIndex = (currentLetterIndex + 1) % gameRoot.availableLetters.length
                    var nextLetter = gameRoot.availableLetters[nextLetterIndex]

                    if (letterIndex[nextLetter] && letterIndex[nextLetter].length > 0) {
                        var targetIndex = letterIndex[nextLetter][0]

                        gameRoot.currentLetter = nextLetter
                        gameRoot.showLetterIndicator = true
                        gameRoot.letterNavigationBlur = true

                        gameList.currentIndex = targetIndex
                        gameList.positionViewAtIndex(targetIndex, ListView.Center)

                        letterIndicatorTimer.restart()

                        soundManager.playToggle()
                    }
        }

        function jumpToPrevLetter() {
            if (gameRoot.availableLetters.length === 0) return

                var currentGame = gameList.currentGame
                if (!currentGame) return

                    var cleanTitle = Utils.cleanGameTitle(currentGame.title).toUpperCase()
                    var currentFirstChar = cleanTitle.charAt(0)

                    if (currentFirstChar.match(/[^A-Z]/)) {
                        currentFirstChar = "#"
                    }

                    var currentLetterIndex = gameRoot.availableLetters.indexOf(currentFirstChar)
                    var prevLetterIndex = currentLetterIndex - 1
                    if (prevLetterIndex < 0) {
                        prevLetterIndex = gameRoot.availableLetters.length - 1
                    }
                    var prevLetter = gameRoot.availableLetters[prevLetterIndex]

                    if (letterIndex[prevLetter] && letterIndex[prevLetter].length > 0) {
                        var targetIndex = letterIndex[prevLetter][0]

                        gameRoot.currentLetter = prevLetter
                        gameRoot.showLetterIndicator = true
                        gameRoot.letterNavigationBlur = true

                        gameList.currentIndex = targetIndex
                        gameList.positionViewAtIndex(targetIndex, ListView.Center)

                        letterIndicatorTimer.restart()

                        soundManager.playToggle()
                    }
        }

        Keys.onPressed: {
            if (api.keys.isCancel(event)) {
                event.accepted = true
                soundManager.playCancel()
                backRequested()
            } else if (!event.isAutoRepeat && api.keys.isAccept(event)) {
                event.accepted = true
                soundManager.playOk()
                launchGame()
            }
            else if (api.keys.isDetails(event)) {
                event.accepted = true
                toggleFavorite()
            }
            else if (api.keys.isFilters(event)) {
                event.accepted = true

                if (currentGame) {
                    soundManager.playOk()
                    retroAchievementsView.updateGame(currentGame)
                    retroAchievementsView.show()
                    gameRoot.applyBlurEffects(true)
                } else {
                    soundManager.playCancel()
                }
            }
            else if (api.keys.isNextPage(event)) {
                event.accepted = true
                soundManager.playOk()
                jumpToNextLetter()
            }
            else if (api.keys.isPrevPage(event)) {
                event.accepted = true
                soundManager.playOk()
                jumpToPrevLetter()
            }
            else {
                event.accepted = false
            }
        }

        Keys.onUpPressed: {
            event.accepted = true
            soundManager.playUp()
            if (currentIndex > 0) {
                currentIndex--
            } else {
                currentIndex = count - 1
            }
        }

        Keys.onDownPressed: {
            event.accepted = true
            soundManager.playDown()
            if (currentIndex < count - 1) {
                currentIndex++
            } else {
                currentIndex = 0
            }
        }

        function toggleFavorite() {
            if (currentGame) {
                var wasFavorite = currentGame.favorite
                currentGame.favorite = !currentGame.favorite
                currentIndexChanged()
                if (currentGame.favorite) {
                    soundManager.playNotice()
                } else {
                    soundManager.playNoticeBack()
                }

                favoriteNotification.show(currentGame.favorite, Utils.cleanGameTitle(currentGame.title))
            }
        }

        Component.onCompleted: {
            buildLetterIndex()
        }
    }

    Rectangle {
        id: rightPanel

        anchors {
            left: gameList.right
            top: parent.top
            right: parent.right
            bottom: parent.bottom
        }

        color: root.getHueColor(collectionIndex)

        opacity: gameRoot.panelsBlurred ? 0.4 : (gameRoot.letterNavigationBlur ? 0.5 : 1.0)
        scale: gameRoot.panelsBlurred ? 0.95 : (gameRoot.letterNavigationBlur ? 0.98 : 1.0)

        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }

        Behavior on scale {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }

        layer.enabled: gameRoot.panelsBlurred || gameRoot.letterNavigationBlur
        layer.effect: FastBlur {
            radius: 32
            transparentBorder: true
        }

        GameDetails {
            anchors.fill: parent
            game: gameList.currentGame
            collectionIndex: gameRoot.collectionIndex
        }
    }

    Item {
        id: letterIndicator
        anchors.centerIn: parent
        width: 250 * vpx
        height: 250 * vpx
        opacity: gameRoot.showLetterIndicator ? 1.0 : 0
        visible: opacity > 0
        z: 200
        scale: gameRoot.showLetterIndicator ? 1.0 : 0.7

        Behavior on opacity {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        Behavior on scale {
            NumberAnimation { duration: 250; easing.type: Easing.OutBack }
        }

        HexagonIcon {
            id: letterHexagon
            anchors.centerIn: parent
            size: 220 * vpx
            color: root.getHueColor(collectionIndex)

            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                horizontalOffset: 0
                verticalOffset: 6
                radius: 20
                samples: 41
                color: "#90000000"
            }

            Text {
                anchors.centerIn: parent
                text: gameRoot.currentLetter
                font {
                    family: global.fonts.sans
                    pixelSize: 110 * vpx
                    bold: true
                }
                color: "#ffffff"

                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    horizontalOffset: 2
                    verticalOffset: 2
                    radius: 4
                    samples: 9
                    color: "#60000000"
                }
            }
        }
    }

    Timer {
        id: letterIndicatorTimer
        interval: 800
        onTriggered: {
            gameRoot.showLetterIndicator = false
            gameRoot.letterNavigationBlur = false
        }
    }

    NoiseEffect {
        id: noiSe
        anchors.fill: parent
        noiseIntensity: 0.03
        noiseOpacity: 0.5
        visible: gameRoot.panelsBlurred || gameRoot.letterNavigationBlur
    }

    RetroAchievementsView {
        id: retroAchievementsView
        z: 100

        parent: gameRoot
        collectionIndex: gameRoot.collectionIndex

        onRaLoadingChanged: bottomBar.setRALoading(raLoading)

        onBackRequested: {
            gameList.focus = true
            gameRoot.applyBlurEffects(false)
        }

        onVisibleChanged: {
            if (!visible) {
                gameRoot.applyBlurEffects(false)
                bottomBar.setRALoading(false)
            } else {
                gameRoot.applyBlurEffects(true)
            }
        }
    }

    function getSystemImage() {
        if (!collection) return ""
            var shortName = collection.shortName.toLowerCase()
            return "assets/images/systems/" + shortName + ".png"
    }

    function launchGame() {
        if (gameList.currentGame) {
            console.log("🎮 Launching game:", gameList.currentGame.title)
            api.memory.set('lastGameIndex', gameList.currentIndex)
            api.memory.set('lastCollectionIndex', collectionIndex)
            api.memory.set('gameLaunching', true)
            gameList.focus = false
            gameList.enabled = false
            console.log("⬅️ Exiting GameView before launch")
            backRequested()
            launchDelayTimer.start()
        }
    }

    Timer {
        id: launchDelayTimer
        interval: 100
        repeat: false
        onTriggered: {
            if (gameList.currentGame) {
                console.log("🚀 Actually launching game now")
                gameList.currentGame.launch()
            }
        }
    }

    Timer {
        id: restoreTimer
        interval: 100
        repeat: false
        onTriggered: {
            console.log("🔄 Restoring focus after game exit")
            gameList.enabled = true
            gameList.focus = true

            var lastIndex = api.memory.get('lastGameIndex')
            if (lastIndex !== undefined && lastIndex >= 0 && lastIndex < gameList.count) {
                gameList.currentIndex = lastIndex
                gameList.positionViewAtIndex(lastIndex, ListView.Center)
            }

            api.memory.set('gameLaunching', false)
        }
    }
}
