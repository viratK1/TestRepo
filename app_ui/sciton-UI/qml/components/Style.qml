pragma Singleton
import QtQuick 2.0
import QtMultimedia 5.0

QtObject {
    property color  mainbg: "#808080"
    property int    screen_width: 1024
    property int    screen_height: 768
    property string audio_source: "../sounds/button.wav"
    property int    loudness: 5
    property int    audioPlay: 0
    property bool   ctrlReleased: false
    property string default_font: "HelveticaNeue MediumCond"
    property string joule_platform: "mjoule_948.m86"
    property string g2h_file: "mjoule_948.tgz"
    property string build_ver: "0199C"
    property string controller_build: "6300/6711"
}
