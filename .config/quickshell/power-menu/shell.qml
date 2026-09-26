//@ pragma UseQApplication
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

ShellRoot {
    id: root

    property bool entered: false
    property string pendingLabel: ""
    property string pendingIcon: ""
    property color pendingAccent: "#cba6f7"
    property var pendingCommand: []
    property string iconRoot: Quickshell.shellDir + "/icons/"

    function runAction(command) {
        Quickshell.execDetached(command);
        Qt.quit();
    }

    function requestAction(label, icon, accent, command, needsConfirmation) {
        if (!needsConfirmation) {
            runAction(command);
            return;
        }

        pendingLabel = label;
        pendingIcon = icon;
        pendingAccent = accent;
        pendingCommand = command;
    }

    function clearPendingAction() {
        pendingLabel = "";
        pendingIcon = "";
        pendingCommand = [];
    }

    Component.onCompleted: entered = true

    component ActionButton: Item {
        id: actionButton

        required property string buttonText
        required property string iconSource
        required property color accent
        required property color hoverColor
        signal activated()

        Layout.fillWidth: true
        Layout.preferredHeight: 154

        Rectangle {
            id: hoverRing
            anchors.centerIn: actionDisc
            width: actionDisc.width + 12
            height: width
            radius: width / 2
            color: "transparent"
            border.width: 1
            border.color: actionButton.accent
            opacity: actionArea.containsMouse ? 0.28 : 0
            scale: actionArea.containsMouse ? 1 : 0.88

            Behavior on opacity {
                NumberAnimation { duration: 140 }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 160
                    easing.type: Easing.OutCubic
                }
            }
        }

        Rectangle {
            id: actionDisc
            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
            }
            width: 112
            height: 112
            radius: width / 2
            color: actionArea.pressed ? Qt.darker(actionButton.hoverColor, 1.08)
                                      : actionArea.containsMouse ? actionButton.hoverColor : "#dc1e1e2e"
            border.width: 1
            border.color: Qt.rgba(
                actionButton.accent.r,
                actionButton.accent.g,
                actionButton.accent.b,
                actionArea.containsMouse ? 0.92 : 0.34)
            scale: actionArea.pressed ? 0.96 : actionArea.containsMouse ? 1.04 : 1

            Behavior on color {
                ColorAnimation { duration: 130 }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 140
                    easing.type: Easing.OutCubic
                }
            }

            Image {
                anchors.centerIn: parent
                width: 48
                height: 48
                source: actionButton.iconSource
                sourceSize.width: 96
                sourceSize.height: 96
                fillMode: Image.PreserveAspectFit
                smooth: true
            }
        }

        Text {
            anchors {
                top: actionDisc.bottom
                topMargin: 13
                horizontalCenter: parent.horizontalCenter
            }
            color: actionArea.containsMouse ? actionButton.accent : "#e8e8f2"
            text: actionButton.buttonText
            font.family: "Noto Sans"
            font.pixelSize: 14
            font.weight: Font.DemiBold

            Behavior on color {
                ColorAnimation { duration: 130 }
            }
        }

        MouseArea {
            id: actionArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: actionButton.activated()
        }
    }

    component ConfirmButton: Rectangle {
        id: confirmButton

        required property string buttonText
        required property color accent
        property bool primary: false
        signal activated()

        implicitWidth: 150
        implicitHeight: 46
        radius: 12
        color: confirmArea.pressed
            ? Qt.darker(confirmButton.primary ? confirmButton.accent : "#34354d", 1.08)
            : confirmArea.containsMouse
                ? (confirmButton.primary ? Qt.lighter(confirmButton.accent, 1.05) : "#34354d")
                : (confirmButton.primary ? confirmButton.accent : "#292a3d")
        border.width: confirmButton.primary ? 0 : 1
        border.color: "#45475a"

        Behavior on color {
            ColorAnimation { duration: 120 }
        }

        Text {
            anchors.centerIn: parent
            color: confirmButton.primary ? "#15151f" : "#f0ecf7"
            text: confirmButton.buttonText
            font.family: "Noto Sans"
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: confirmArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: confirmButton.activated()
        }
    }

    PanelWindow {
        id: powerWindow

        screen: Quickshell.screens.find(screen => screen.name === Quickshell.env("POWER_MENU_OUTPUT"))
                ?? Quickshell.screens[0]
        anchors {
            top: true
            right: true
            bottom: true
            left: true
        }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell-power-menu"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: "#8f0a0a10"
            opacity: root.entered ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Qt.quit()
            }
        }

        StackLayout {
            anchors.centerIn: parent
            width: Math.min(powerWindow.width - 64, 1000)
            height: 174
            currentIndex: root.pendingLabel.length > 0 ? 1 : 0
            opacity: root.entered ? 1 : 0
            scale: root.entered ? 1 : 0.96

            Behavior on opacity {
                NumberAnimation { duration: 170 }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 170
                    easing.type: Easing.OutCubic
                }
            }

            RowLayout {
                spacing: 24

                ActionButton {
                    buttonText: "Lock"
                    iconSource: root.iconRoot + "lock.svg"
                    accent: "#89b4fa"
                    hoverColor: "#ef263349"
                    onActivated: root.requestAction(
                        "Lock", iconSource, accent,
                        ["/home/eugene/.config/sway/scripts/lock"], false)
                }

                ActionButton {
                    buttonText: "Suspend"
                    iconSource: root.iconRoot + "suspend.svg"
                    accent: "#cba6f7"
                    hoverColor: "#ef352b48"
                    onActivated: root.requestAction(
                        "Suspend", iconSource, accent,
                        ["/home/eugene/.config/sway/scripts/suspend"], false)
                }

                ActionButton {
                    buttonText: "Log out"
                    iconSource: root.iconRoot + "logout.svg"
                    accent: "#f5c2e7"
                    hoverColor: "#ef432f43"
                    onActivated: root.requestAction(
                        "Log out", iconSource, accent,
                        ["swaymsg", "exit"], true)
                }

                ActionButton {
                    buttonText: "Restart"
                    iconSource: root.iconRoot + "reboot.svg"
                    accent: "#f9e2af"
                    hoverColor: "#ef443d30"
                    onActivated: root.requestAction(
                        "Restart", iconSource, accent,
                        ["loginctl", "reboot"], true)
                }

                ActionButton {
                    buttonText: "Power off"
                    iconSource: root.iconRoot + "shutdown.svg"
                    accent: "#f38ba8"
                    hoverColor: "#ef472c38"
                    onActivated: root.requestAction(
                        "Power off", iconSource, accent,
                        ["loginctl", "poweroff"], true)
                }

                ActionButton {
                    buttonText: "Cancel"
                    iconSource: Qt.resolvedUrl("cancel.svg")
                    accent: "#a6adc8"
                    hoverColor: "#ef34354d"
                    onActivated: Qt.quit()
                }
            }

            ColumnLayout {
                spacing: 14

                Image {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 58
                    Layout.preferredHeight: 58
                    source: root.pendingIcon
                    sourceSize.width: 116
                    sourceSize.height: 116
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    color: "#f0ecf7"
                    text: `${root.pendingLabel}?`
                    font.family: "Noto Sans"
                    font.pixelSize: 20
                    font.weight: Font.Bold
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 12

                    ConfirmButton {
                        buttonText: "Cancel"
                        accent: "#cba6f7"
                        onActivated: root.clearPendingAction()
                    }

                    ConfirmButton {
                        buttonText: root.pendingLabel
                        accent: root.pendingAccent
                        primary: true
                        onActivated: root.runAction(root.pendingCommand)
                    }
                }
            }
        }
    }
}
