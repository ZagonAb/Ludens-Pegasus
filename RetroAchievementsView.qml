import QtQuick 2.15
import QtGraphicalEffects 1.12

FocusScope {
    id: raView

    property var currentGame: null
    property int collectionIndex: 0
    property string _apiKey: ""
    property string _apiUser: ""

    function _loadCredentials() {
        _apiKey = api.memory.has("ra_api_key") ? api.memory.get("ra_api_key") : ""
        _apiUser = api.memory.has("ra_api_user") ? api.memory.get("ra_api_user") : ""
    }

    Component.onCompleted: _loadCredentials()

    readonly property string _base: "https://retroachievements.org/API/"
    readonly property string _media: "https://media.retroachievements.org"

    property bool _searching: false
    property bool _loading: false
    property bool _notFound: false
    property bool _noAchievements: false
    property string _errorMsg: ""

    readonly property bool raLoading: _searching || _loading

    property string _raGameId: ""
    property string _raTitle: ""
    property string _raConsole: ""
    property string _raImgIcon: ""
    property int _raNumAch: 0
    property int _numEarned: 0

    property var _achievements: []

    signal backRequested()

    visible: false
    width: parent.width * 0.4 - 20 * vpx
    height: parent.height - 23 * vpx
    property real targetY: parent.height
    y: targetY
    x: (300 - 20) * vpx

    function _apiUrl(endpoint, params) {
        var url = _base + endpoint + "?y=" + _apiKey
        for (var k in params) url += "&" + k + "=" + encodeURIComponent(params[k])
            return url
    }

    function _get(url, cb) {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", url, true)
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
                if (xhr.status === 200) {
                    try { cb(null, JSON.parse(xhr.responseText)) }
                    catch(e) { cb("JSON parse error: " + e, null) }
                } else {
                    cb("HTTP " + xhr.status, null)
                }
        }
        xhr.send()
    }

    function _romanToArabic(str) {
        var map = {
            "xv": "15", "xiv": "14", "xiii": "13", "xii": "12", "xi": "11",
            "x": "10", "ix": "9", "viii": "8", "vii": "7", "vi": "6",
            "v": "5", "iv": "4", "iii": "3", "ii": "2", "i": "1"
        }
        return str.replace(/\b(x(?:iv|v|i{1,3})?|i{1,3}|iv|vi{0,3}|viii|ix)\b/g,
                           function(m){ return map[m] || m })
    }

    function _normalize(str) {
        if (!str) return ""
            return _romanToArabic(str.toLowerCase())
            .replace(/\b(the|a|an)\b\s*/g, "")
            .replace(/[:\-\u2013_',\.\!?®™©\(\)\[\]\/\\]/g, " ")
            .replace(/\s+/g, " ")
            .trim()
    }

    function _words(norm) {
        return norm.split(" ").filter(function(w){ return w.length >= 1 })
    }

    function _matchScore(pegTitle, raTitle) {
        var pNorm = _normalize(pegTitle)
        var rNorm = _normalize(raTitle)
        if (pNorm === rNorm) return 2.0

            var pWords = _words(pNorm)
            var rWords = _words(rNorm)
            if (pWords.length === 0) return 0.0

                var hitsP = 0
                for (var i = 0; i < pWords.length; i++)
                    if (rNorm.indexOf(pWords[i]) !== -1) hitsP++
                        var precision = hitsP / pWords.length

                        var hitsR = 0
                        for (var j = 0; j < rWords.length; j++)
                            if (pNorm.indexOf(rWords[j]) !== -1) hitsR++
                                var recall = rWords.length > 0 ? hitsR / rWords.length : 0

                                if (precision + recall === 0) return 0.0
                                    var f1 = 2.0 * precision * recall / (precision + recall)

                                    var extraInRA = rWords.length - hitsR
                                    var extraInPeg = pWords.length - hitsP
                                    if (extraInRA > 0) f1 = Math.max(0.0, f1 - (extraInRA / rWords.length) * 0.5)
                                        if (extraInPeg > 0) f1 = Math.max(0.0, f1 - (extraInPeg / pWords.length) * 0.5)
                                            return f1
    }

    readonly property var _consoleMappings: ({
        "snes": ["SNES/Super Famicom"], "superfamicom": ["SNES/Super Famicom"],
        "nes": ["NES/Famicom"], "famicom": ["NES/Famicom"],
        "fds": ["Famicom Disk System"], "famicomdisksystem": ["Famicom Disk System"],
        "n64": ["Nintendo 64"], "nintendo64": ["Nintendo 64"],
        "gb": ["Game Boy"], "gameboy": ["Game Boy"],
        "gbc": ["Game Boy Color"], "gameboycolor": ["Game Boy Color"],
        "gba": ["Game Boy Advance"], "gameboyadvance": ["Game Boy Advance"],
        "nds": ["Nintendo DS"], "nintendods": ["Nintendo DS"],
        "3ds": ["Nintendo 3DS"], "nintendo3ds": ["Nintendo 3DS"],
        "gamecube": ["GameCube"], "gc": ["GameCube"],
        "wii": ["Wii"], "wiiu": ["Wii U"],
        "virtualboy": ["Virtual Boy"], "pokemini": ["Pokemon Mini"],
        "genesis": ["Genesis/Mega Drive"], "megadrive": ["Genesis/Mega Drive"],
        "mastersystem": ["Master System"], "sms": ["Master System"],
        "gamegear": ["Game Gear"], "gg": ["Game Gear"],
        "saturn": ["Saturn"], "dreamcast": ["Dreamcast"],
        "segacd": ["Sega CD"], "megacd": ["Sega CD"],
        "32x": ["32X"], "sega32x": ["32X"],
        "psx": ["PlayStation"], "ps1": ["PlayStation"], "playstation": ["PlayStation"],
        "ps2": ["PlayStation 2"], "playstation2": ["PlayStation 2"],
        "psp": ["PlayStation Portable"],
        "atari2600": ["Atari 2600"], "atari5200": ["Atari 5200"],
        "atari7800": ["Atari 7800"],
        "lynx": ["Atari Lynx"], "atarilynx": ["Atari Lynx"],
        "jaguar": ["Atari Jaguar"], "atarijaguar": ["Atari Jaguar"],
        "pcengine": ["PC Engine/TurboGrafx-16"], "turbografx": ["PC Engine/TurboGrafx-16"], "tg16": ["PC Engine/TurboGrafx-16"],
        "arcade": ["Arcade"], "mame": ["Arcade"],
        "wonderswan": ["WonderSwan"], "msx": ["MSX"],
        "colecovision": ["ColecoVision"], "intellivision": ["Intellivision"],
        "3do": ["3DO Interactive Multiplayer"],
        "amiga": ["Amiga"], "dos": ["DOS"],
        "c64": ["Commodore 64"], "commodore64": ["Commodore 64"],
        "appleii": ["Apple II"], "zxspectrum": ["ZX Spectrum"],
        "xbox": ["Xbox"]
    })

    readonly property var _consoleIds: ({
        "snes": 3, "superfamicom": 3,
        "nes": 7, "famicom": 7, "fds": 81,
        "n64": 2, "nintendo64": 2,
        "gb": 4, "gameboy": 4, "gbc": 6, "gameboycolor": 6,
        "gba": 5, "gameboyadvance": 5,
        "nds": 18, "nintendods": 18, "3ds": 62, "nintendo3ds": 62,
        "gamecube": 16, "gc": 16, "wii": 19, "wiiu": 20,
        "genesis": 1, "megadrive": 1,
        "mastersystem": 11, "sms": 11,
        "gamegear": 15, "gg": 15,
        "saturn": 39, "dreamcast": 40,
        "segacd": 9, "megacd": 9, "32x": 10, "sega32x": 10,
        "psx": 12, "ps1": 12, "playstation": 12,
        "ps2": 21, "playstation2": 21, "psp": 41,
        "atari2600": 25, "atari5200": 50, "atari7800": 51,
        "lynx": 13, "atarilynx": 13,
        "jaguar": 17, "atarijaguar": 17,
        "pcengine": 8, "turbografx": 8, "tg16": 8,
        "arcade": 27, "mame": 27,
        "wonderswan": 53, "msx": 29,
        "colecovision": 44, "intellivision": 45,
        "3do": 43, "amiga": 35, "dos": 26,
        "c64": 30, "commodore64": 30, "appleii": 38,
        "zxspectrum": 59, "xbox": 22
    })

    function _getCollectionShortName() {
        if (!currentGame) return ""
            try {
                if (currentGame.collections && currentGame.collections.count > 0) {
                    var col = currentGame.collections.get(0)
                    var sn = (col.shortName !== "" ? col.shortName : col.name)
                    return sn.toLowerCase().replace(/[\s\-_]/g, "")
                }
            } catch(e) {}
            return ""
    }

    function load() {
        _raGameId = ""
        _raTitle = ""
        _raConsole = ""
        _raImgIcon = ""
        _raNumAch = 0
        _numEarned = 0
        _achievements = []
        _searching = false
        _loading = false
        _notFound = false
        _noAchievements = false
        _errorMsg = ""

        if (!currentGame) {
            _errorMsg = "No game selected."
            return
        }

        _loadCredentials()

        if (_apiKey === "" || _apiUser === "") {
            _errorMsg = "Add your RetroAchievements credentials\nusing the Achievements button in the Settings panel"
            return
        }

        var colShort = _getCollectionShortName()
        _searchForGame(colShort)
    }

    function _searchForGame(colShort) {
        _searching = true
        var url = _apiUrl("API_GetUserCompletionProgress.php",
                          { u: _apiUser, c: 500, o: 0 })
        _get(url, function(err, data) {
            _searching = false
            if (err || !data) {
                _errorMsg = "Failed to connect to RetroAchievements.\n(" + (err || "empty response") + ")"
                return
            }

            var list = data.Results || (Array.isArray(data) ? data : [])
            var pegTitle = currentGame ? (currentGame.title || "") : ""
            var raConsoles = _consoleMappings[colShort] || []

            var scored = []
            for (var i = 0; i < list.length; i++) {
                var g = list[i]
                var sc = _matchScore(pegTitle, g.Title || "")
                if (raConsoles.length > 0 && (g.ConsoleName || "") !== "") {
                    var cOk = false
                    for (var ci = 0; ci < raConsoles.length; ci++) {
                        if ((g.ConsoleName || "").indexOf(raConsoles[ci]) !== -1) { cOk = true; break }
                    }
                    sc = cOk ? sc + 0.5 : sc - 0.2
                }
                scored.push({ g: g, score: sc })
            }
            scored.sort(function(a, b){ return b.score - a.score })

            var best = scored.length > 0 ? scored[0] : null
            var bestF1 = best ? _matchScore(pegTitle, best.g.Title || "") : 0
            var THRESHOLD = 0.60
            var F1_MIN = 0.70

            var cOkBest = true
            if (best && raConsoles.length > 0) {
                cOkBest = false
                for (var cj = 0; cj < raConsoles.length; cj++) {
                    if ((best.g.ConsoleName || "").indexOf(raConsoles[cj]) !== -1) { cOkBest = true; break }
                }
            }

            var accepted = best && bestF1 >= F1_MIN && best.score >= THRESHOLD && cOkBest

            if (accepted) {
                _raGameId = String(best.g.GameID || "")
                _fetchProgress(_raGameId)
            } else {
                _searchByGameList(pegTitle, colShort)
            }
        })
    }

    function _searchByGameList(pegTitle, colShort) {
        var cid = _consoleIds[colShort] || 0
        if (cid === 0) { _notFound = true; return }

        var url = _apiUrl("API_GetGameList.php", { i: cid })
        _get(url, function(err, data) {
            if (err || !Array.isArray(data)) { _notFound = true; return }

            var scored = []
            for (var i = 0; i < data.length; i++) {
                var g = data[i]
                var sc = _matchScore(pegTitle, g.Title || "")
                scored.push({ g: g, score: sc })
            }
            scored.sort(function(a,b){ return b.score - a.score })

            var best = scored.length > 0 ? scored[0] : null
            if (best && best.score >= 0.55) {
                _raGameId = String(best.g.ID || best.g.GameID || "")
                _fetchProgress(_raGameId)
            } else {
                _notFound = true
            }
        })
    }

    function _fetchProgress(gid) {
        _loading = true
        var url = _apiUrl("API_GetGameInfoAndUserProgress.php",
                          { u: _apiUser, g: gid })
        _get(url, function(err, data) {
            _loading = false
            if (err || !data) {
                _errorMsg = "Failed to load game data.\n(" + (err || "empty") + ")"
                return
            }

            _raTitle = data.Title || ""
            _raConsole = data.ConsoleName || ""
            _raImgIcon = data.ImageIcon ? (_media + data.ImageIcon) : ""
            _raNumAch = parseInt(data.NumAchievements) || 0
            _numEarned = parseInt(data.NumAwardedToUser) || 0

            if (_raNumAch === 0) { _noAchievements = true; return }

            var ach = []
            var achMap = data.Achievements || {}
            for (var id in achMap) {
                var a = achMap[id]
                var earned = !!(a.DateEarned && a.DateEarned !== "")
                ach.push({
                    id: id,
                    title: a.Title || "",
                    description: a.Description || "",
                    points: parseInt(a.Points) || 0,
                         badgeUrl: a.BadgeName ? (_media + "/Badge/" + a.BadgeName + ".png") : "",
                         badgeLocked: a.BadgeName ? (_media + "/Badge/" + a.BadgeName + "_lock.png") : "",
                         earned: earned,
                         dateEarned: earned ? (a.DateEarned || "") : "",
                         displayOrder: parseInt(a.DisplayOrder) || parseInt(id) || 0
                })
            }
            ach.sort(function(a, b) {
                if (a.earned !== b.earned) return a.earned ? -1 : 1
                    return a.displayOrder - b.displayOrder
            })
            _achievements = ach
        })
    }

    onCurrentGameChanged: {
        if (visible) load()
    }

    Rectangle {
        id: raPanel
        anchors.fill: parent
        color: bgSecondary
        radius: 12 * vpx
        border.color: root.getHueColor(collectionIndex)
        border.width: 2 * vpx

        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 0
            verticalOffset: -4
            radius: 12
            samples: 17
            color: "#80000000"
        }

        Rectangle {
            id: raHeader
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 80 * vpx
            color: root.getHueColor(collectionIndex)
            radius: 12 * vpx

            Row {
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    margins: 15 * vpx
                }
                spacing: 12 * vpx

                HexagonIcon {
                    width: 60 * vpx
                    height: 60 * vpx
                    color: "#ffffff"
                    iconSource: ""
                    anchors.verticalCenter: parent.verticalCenter
                    radiusHex: 0.05

                    Item {
                        id: spinnerContainer
                        anchors.centerIn: parent
                        width: parent.width * 0.6
                        height: parent.height * 0.6
                        visible: raView._searching || raView._loading

                        Image {
                            id: spinnerIcon
                            anchors.fill: parent
                            source: "assets/images/icons/spinner.png"
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                        }
                        ColorOverlay {
                            anchors.fill: spinnerIcon
                            source: spinnerIcon
                            color: root.getHueColor(collectionIndex)
                        }
                        RotationAnimator {
                            target: spinnerContainer
                            from: 0
                            to: 360
                            duration: 1000
                            loops: Animation.Infinite
                            running: raView._searching || raView._loading
                        }
                    }

                    Item {
                        anchors.centerIn: parent
                        width: parent.width * 0.6
                        height: parent.height * 0.6
                        visible: !raView._searching && !raView._loading

                        Image {
                            id: achievementIcon
                            anchors.fill: parent
                            source: "assets/images/icons/achievement.svg"
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                        }
                        ColorOverlay {
                            anchors.fill: achievementIcon
                            source: achievementIcon
                            color: root.getHueColor(collectionIndex)
                        }
                    }
                }

                Column {
                    spacing: 3 * vpx
                    anchors.verticalCenter: parent.verticalCenter
                    width: raPanel.width - 200 * vpx

                    Text {
                        text: "RETROACHIEVEMENTS"
                        font {
                            family: global.fonts.sans
                            pixelSize: 16 * vpx
                            bold: true
                            capitalization: Font.AllUppercase
                        }
                        color: "#ffffff"
                    }

                    Text {
                        width: parent.width
                        text: {
                            if (raView._raTitle !== "") return raView._raTitle
                                return currentGame ? currentGame.title : ""
                        }
                        font { family: global.fonts.sans; pixelSize: 14 * vpx }
                        color: "#ffffff"
                        elide: Text.ElideRight
                    }

                    Item {
                        width: parent.width
                        height: 16 * vpx

                        Rectangle {
                            id: progressBarBg
                            anchors {
                                left: parent.left
                                right: percentageText.left
                                rightMargin: 8 * vpx
                                verticalCenter: parent.verticalCenter
                            }
                            height: 8 * vpx
                            color: "#40000000"
                            radius: 3 * vpx
                        }

                        Rectangle {
                            id: progressBar
                            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                            height: 8 * vpx
                            radius: 3 * vpx
                            color: "#ffffff"
                            width: progressBarBg.width * (_raNumAch > 0 ? _numEarned / _raNumAch : 0)
                            Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutQuad } }
                        }

                        Text {
                            id: percentageText
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                            text: _raNumAch > 0
                            ? Math.round(_numEarned / _raNumAch * 100) + "%"
                            : "0%"
                            font { family: global.fonts.sans; pixelSize: 16 * vpx; bold: true }
                            color: "#ffffff"
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
                    }
                }
            }

            Rectangle {
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    rightMargin: 15 * vpx
                }
                width: 80 * vpx
                height: 35 * vpx
                color: "#ffffff"
                radius: 17 * vpx

                Text {
                    anchors.centerIn: parent
                    text: _numEarned + "/" + _raNumAch
                    font { family: global.fonts.sans; pixelSize: 14 * vpx; bold: true }
                    color: root.getHueColor(collectionIndex)
                }
            }
        }

        Item {
            anchors {
                top: raHeader.bottom
                left: parent.left
                right: parent.right
                bottom: raFooter.top
                margins: 10 * vpx
            }
            visible: raView._searching || raView._loading

            Column {
                anchors.centerIn: parent
                spacing: 14 * vpx

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: raView._searching ? "Searching for game..." : "Loading achievements..."
                    font { family: global.fonts.sans; pixelSize: 16 * vpx }
                    color: textSecondary
                }
            }
        }

        Item {
            anchors {
                top: raHeader.bottom
                left: parent.left
                right: parent.right
                bottom: raFooter.top
                margins: 10 * vpx
            }
            visible: !raView._searching && !raView._loading && raView._errorMsg !== ""

            Column {
                anchors.centerIn: parent
                spacing: 10 * vpx
                width: parent.width - 20 * vpx

                Text {
                    width: parent.width
                    text: raView._errorMsg
                    font { family: global.fonts.sans; pixelSize: 18 * vpx }
                    color: textSecondary
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        Item {
            anchors {
                top: raHeader.bottom
                left: parent.left
                right: parent.right
                bottom: raFooter.top
                margins: 10 * vpx
            }
            visible: !raView._searching && !raView._loading && raView._errorMsg === ""
            && (raView._notFound || raView._noAchievements)

            Column {
                anchors.centerIn: parent
                spacing: 10 * vpx

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: raView._notFound
                    ? "Game not found on RetroAchievements"
                    : "No achievements are available for this game yet"
                    font { family: global.fonts.sans; pixelSize: 16 * vpx }
                    color: textSecondary
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    width: raPanel.width - 40 * vpx
                }
            }
        }

        ListView {
            id: raListView
            anchors {
                top: raHeader.bottom
                left: parent.left
                right: parent.right
                bottom: raFooter.top
                margins: 10 * vpx
            }
            clip: true
            spacing: 6 * vpx

            visible: !raView._searching && !raView._loading
            && raView._errorMsg === ""
            && !raView._notFound && !raView._noAchievements
            && raView._achievements.length > 0

            model: raView._achievements

            delegate: Rectangle {
                width: raListView.width
                height: 90 * vpx
                color: raListView.currentIndex === index
                ? Qt.lighter(root.getHueColor(collectionIndex), 1.1)
                : (index % 2 === 0 ? "#2a2a2a" : "#333333")
                radius: 6 * vpx

                property bool isEarned: modelData.earned

                Row {
                    anchors { fill: parent; margins: 8 * vpx }
                    spacing: 10 * vpx

                    Item {
                        width: 74 * vpx
                        height: 74 * vpx
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            anchors.fill: parent
                            color: isEarned ? root.getHueColor(collectionIndex) : "#555555"
                            radius: 6 * vpx

                            Image {
                                id: achievementBadge
                                anchors { fill: parent; margins: 4 * vpx }
                                source: {
                                    if (isEarned && modelData.badgeUrl !== "") return modelData.badgeUrl
                                        if (!isEarned && modelData.badgeLocked !== "") return modelData.badgeLocked
                                            return "assets/images/icons/achievement.png"
                                }
                                fillMode: Image.PreserveAspectFit
                                mipmap: true
                                asynchronous: true
                                onStatusChanged: {
                                    if (status === Image.Error)
                                        source = "assets/images/icons/achievement.png"
                                }
                                layer.enabled: !isEarned
                                layer.effect: Desaturate { desaturation: 0.8 }
                            }
                        }

                        Rectangle {
                            anchors {
                                top: parent.top
                                right: parent.right
                                topMargin: -2 * vpx
                                rightMargin: -2 * vpx
                            }
                            width: 16 * vpx
                            height: 16 * vpx
                            radius: 8 * vpx
                            color: "#4CAF50"
                            visible: isEarned

                            Text {
                                anchors.centerIn: parent
                                text: "✓"
                                font { family: global.fonts.sans; pixelSize: 9 * vpx; bold: true }
                                color: "#000000"
                            }
                        }
                    }

                    Column {
                        width: parent.width - 84 * vpx - parent.spacing - 60 * vpx
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3 * vpx

                        Text {
                            width: parent.width
                            text: modelData.title
                            font { family: global.fonts.sans; pixelSize: 18 * vpx; bold: true }
                            color: isEarned ? "#ffffff" : "#bcbcbc"
                            wrapMode: Text.WordWrap
                            maximumLineCount: 1
                            elide: Text.ElideRight
                            layer.enabled: true
                            layer.effect: DropShadow {
                                transparentBorder: true
                                horizontalOffset: 1
                                verticalOffset: 1
                                radius: 2
                                samples: 0
                                color: "#80000000"
                            }
                        }

                        Item {
                            id: descMarqueeContainer
                            width: parent.width
                            height: descText1.height
                            clip: true

                            property bool isCurrent: raListView.currentIndex === index
                            property bool needsScroll: descText1.implicitWidth > descMarqueeContainer.width
                            property real scrollOffset: 0
                            property real cycleWidth: descText1.implicitWidth + descSep.implicitWidth

                            Text {
                                id: descText1
                                text: modelData.description
                                font { family: global.fonts.sans; pixelSize: 16 * vpx }
                                color: isEarned ? "#ffffff" : "#bcbcbc"
                                wrapMode: Text.NoWrap
                                elide: descMarqueeContainer.isCurrent ? Text.ElideNone : Text.ElideRight
                                width: descMarqueeContainer.isCurrent ? implicitWidth : descMarqueeContainer.width
                                x: -descMarqueeContainer.scrollOffset
                                y: 0
                                layer.enabled: true
                                layer.effect: DropShadow {
                                    transparentBorder: true
                                    horizontalOffset: 1
                                    verticalOffset: 1
                                    radius: 2
                                    samples: 0
                                    color: "#80000000"
                                }
                            }

                            Text {
                                id: descSep
                                text: "  •  "
                                font: descText1.font
                                color: isEarned ? "#ffffff" : "#bcbcbc"
                                wrapMode: Text.NoWrap
                                elide: Text.ElideNone
                                x: descText1.implicitWidth - descMarqueeContainer.scrollOffset
                                y: 0
                                visible: descMarqueeContainer.needsScroll
                                layer.enabled: true
                                layer.effect: DropShadow {
                                    transparentBorder: true
                                    horizontalOffset: 1
                                    verticalOffset: 1
                                    radius: 2
                                    samples: 0
                                    color: "#80000000"
                                }
                            }

                            Text {
                                id: descText2
                                text: modelData.description
                                font: descText1.font
                                color: isEarned ? "#ffffff" : "#bcbcbc"
                                wrapMode: Text.NoWrap
                                elide: Text.ElideNone
                                x: descText1.implicitWidth + descSep.implicitWidth - descMarqueeContainer.scrollOffset
                                y: 0
                                visible: descMarqueeContainer.needsScroll
                                layer.enabled: true
                                layer.effect: DropShadow {
                                    transparentBorder: true
                                    horizontalOffset: 1
                                    verticalOffset: 1
                                    radius: 2
                                    samples: 0
                                    color: "#80000000"
                                }
                            }

                            NumberAnimation {
                                id: descMarqueeAnim
                                target: descMarqueeContainer
                                property: "scrollOffset"
                                from: 0
                                to: descMarqueeContainer.cycleWidth
                                duration: descMarqueeContainer.cycleWidth * 22
                                easing.type: Easing.Linear
                                loops: Animation.Infinite
                                running: false
                            }

                            onIsCurrentChanged: {
                                descMarqueeContainer.scrollOffset = 0;
                                descMarqueeAnim.stop();
                                if (isCurrent && needsScroll) {
                                    descMarqueeAnim.start();
                                }
                            }

                            onNeedsScrollChanged: {
                                if (isCurrent && needsScroll) {
                                    descMarqueeContainer.scrollOffset = 0;
                                    descMarqueeAnim.start();
                                } else {
                                    descMarqueeAnim.stop();
                                    descMarqueeContainer.scrollOffset = 0;
                                }
                            }

                            Component.onCompleted: {
                                if (isCurrent && needsScroll) {
                                    descMarqueeAnim.start();
                                }
                            }
                        }

                        Text {
                            text: isEarned ? ("✓ " + modelData.dateEarned) : ""
                            font { family: global.fonts.sans; pixelSize: 14 * vpx }
                            color: "white"
                            visible: isEarned && modelData.dateEarned !== ""
                            layer.enabled: true
                            layer.effect: DropShadow {
                                transparentBorder: true
                                horizontalOffset: 1
                                verticalOffset: 1
                                radius: 2
                                samples: 0
                                color: "#80000000"
                            }
                        }
                    }

                    Rectangle {
                        width: 55 * vpx
                        height: 26 * vpx
                        anchors.verticalCenter: parent.verticalCenter
                        color: isEarned ? "#4CAF50" : "#555555"
                        radius: 13 * vpx

                        Text {
                            anchors.centerIn: parent
                            text: modelData.points + " pts"
                            font { family: global.fonts.sans; pixelSize: 14 * vpx; bold: true }
                            color: "#ffffff"
                        }
                    }
                }
            }

            highlight: Rectangle {
                color: Qt.lighter(root.getHueColor(collectionIndex), 1.5)
                radius: 6 * vpx
            }
            highlightMoveDuration: 200
        }

        Rectangle {
            id: raFooter
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 40 * vpx
            color: "transparent"

            Component {
                id: footerItemComponent
                Row {
                    spacing: 5 * vpx
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: modelData.enabled !== undefined ? (modelData.enabled ? 1.0 : 0.5) : 1.0

                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 24 * vpx
                        height: 24 * vpx
                        source: modelData.icon
                        fillMode: Image.PreserveAspectFit
                        mipmap: true
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: raView._searching || raView._loading
                        ? (modelData.text === "Reload" ? "Loading…" : modelData.text)
                        : modelData.text
                        font { family: global.fonts.sans; pixelSize: 16 * vpx }
                        color: textSecondary
                    }
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: 20 * vpx

                property var footerItems: [
                    {
                        icon: "assets/images/icons/navigate2.png",
                        text: "Navigate",
                        enabled: !raView._searching && !raView._loading
                    },
                    {
                        icon: "assets/images/icons/ok.png",
                        text: "Reload",
                        enabled: !raView._searching && !raView._loading
                    },
                    {
                        icon: "assets/images/icons/back.png",
                        text: "Back",
                        enabled: true
                    }
                ]

                Repeater {
                    model: parent.footerItems
                    delegate: footerItemComponent
                }
            }
        }
    }

    PropertyAnimation {
        id: showAnimation
        target: raView
        property: "targetY"
        duration: 400
        easing.type: Easing.OutCubic
    }

    PropertyAnimation {
        id: hideAnimation
        target: raView
        property: "targetY"
        duration: 350
        easing.type: Easing.InCubic
        onFinished: raView.visible = false
    }

    Keys.onPressed: {
        if (api.keys.isCancel(event)) {
            event.accepted = true
            soundManager.playCancel()
            hide()
        } else if (api.keys.isAccept(event)) {
            event.accepted = true
            soundManager.playOk()
            load()
        } else if (api.keys.isUp(event)) {
            event.accepted = true
            soundManager.playUp()
            if (raListView.currentIndex > 0)
                raListView.currentIndex--
        } else if (api.keys.isDown(event)) {
            event.accepted = true
            soundManager.playDown()
            if (raListView.currentIndex < raListView.count - 1)
                raListView.currentIndex++
        }
    }

    function show() {
        visible = true
        focus = true
        load()

        var startY = raView.parent.height
        var endY = 20 * vpx
        targetY = startY
        showAnimation.from = startY
        showAnimation.to = endY
        showAnimation.start()

        raListView.currentIndex = 0
    }

    function hide() {
        var startY = 20 * vpx
        var endY = raView.parent.height
        hideAnimation.from = startY
        hideAnimation.to = endY
        hideAnimation.start()
        focus = false
        backRequested()
    }

    function updateGame(game) {
        currentGame = game
    }
}
