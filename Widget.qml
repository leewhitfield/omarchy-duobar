import QtQuick
import Quickshell
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import qs.Ui
import qs.Commons

Panel {
    id: root
    moduleName: "lee.duobar"
    ipcTarget: "lee.duobar"
    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight
    readonly property color ink: bar ? bar.foreground : Color.foreground
    readonly property var batteryDevice: UPower.displayDevice
    readonly property bool batteryPresent: !!(batteryDevice && batteryDevice.isPresent)
    readonly property real batteryFraction: batteryPresent ? Math.max(0, Math.min(1, batteryDevice.percentage)) : 0
    readonly property bool charging: batteryPresent && batteryDevice.state === UPowerDeviceState.Charging
    readonly property bool lowBattery: batteryPresent && UPower.onBattery && batteryFraction <= 0.20
    readonly property var devices: Networking.devices ? Networking.devices.values : []
    readonly property var wifiDevice: findDevice(DeviceType.Wifi)
    readonly property var wiredDevice: findDevice(DeviceType.Wired)
    readonly property bool wired: !!(wiredDevice && wiredDevice.connected)
    readonly property var wifiNetworks: wifiDevice && wifiDevice.networks ? wifiDevice.networks.values : []
    readonly property var wifi: {
        for (var i = 0; i < wifiNetworks.length; i++)
            if (wifiNetworks[i] && wifiNetworks[i].connected) return wifiNetworks[i]
        return null
    }
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool bluetoothOn: !!(adapter && adapter.enabled)
    readonly property var bluetoothDevices: Bluetooth.devices ? Bluetooth.devices.values : []
    readonly property int connectedCount: {
        var n = 0
        for (var i = 0; i < bluetoothDevices.length; i++) if (bluetoothDevices[i].connected) n++
        return n
    }
    readonly property string batteryLabel: batteryPresent ? Math.round(batteryFraction * 100) + "%" : "No battery"
    readonly property string batteryDetail: !batteryPresent ? "External power" : charging ? "Charging" : UPower.onBattery ? "On battery power" : batteryDevice.state === UPowerDeviceState.FullyCharged ? "Fully charged" : "Plugged in · not charging"
    readonly property string wifiLabel: wifi ? Math.round(wifi.signalStrength * 100) + "% signal" : !wifiDevice ? "Unavailable" : Networking.wifiEnabled ? "Disconnected" : "Off"
    readonly property string wifiDetail: wifi ? (wifi.name || "Connected network") : wired ? "Ethernet connected" : !wifiDevice ? "No Wi-Fi adapter" : Networking.wifiEnabled ? "No network connected" : "Wi-Fi disabled"
    readonly property string bluetoothLabel: !adapter ? "Unavailable" : bluetoothOn ? "On" : "Off"
    readonly property string bluetoothDetail: !adapter ? "No Bluetooth adapter" : !bluetoothOn ? "Bluetooth disabled" : connectedCount ? connectedCount + (connectedCount === 1 ? " device connected" : " devices connected") : "No devices connected"

    function findDevice(type) {
        var fallback = null
        for (var i = 0; i < devices.length; i++) {
            if (devices[i].type !== type) continue
            if (devices[i].connected) return devices[i]
            fallback = devices[i]
        }
        return fallback
    }

    component LiveGlyph: Glyph {
        battery: root.batteryFraction
        batteryPresent: root.batteryPresent
        charging: root.charging
        lowBattery: root.lowBattery
        wifiConnected: !!root.wifi
        wifiEnabled: Networking.wifiEnabled
        signalStrength: root.wifi ? root.wifi.signalStrength : 0
        wired: root.wired
        bluetoothEnabled: root.bluetoothOn
        foreground: root.ink
        urgent: root.bar ? root.bar.urgent : "#ff6666"
    }

    BarIconButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        opticalSize: Style.bar.iconCanvas
        slotSize: Style.bar.iconSlot
        tooltipText: "Battery " + root.batteryLabel + " · Wi-Fi " + root.wifiLabel + " · Bluetooth " + root.bluetoothLabel
        iconComponent: Component { LiveGlyph { transform: Translate { y: 1 } } }
        onPressed: root.toggle()
    }

    KeyboardPanel {
        id: popup
        anchorItem: button
        owner: root
        bar: root.bar
        open: root.opened
        focusTarget: keys
        contentWidth: popup.fittedContentWidth(Style.space(340))
        contentHeight: popup.fittedContentHeight(content.implicitHeight)

        PanelKeyCatcher {
            id: keys
            anchors.fill: parent
            onCloseRequested: root.close()
            onTabRequested: function(direction) { root.switchPanel(direction) }

            Column {
                id: content
                width: parent.width
                spacing: Style.space(12)
                Item {
                    width: parent.width
                    height: Style.space(40)
                    Column {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        Text { text: "DuoBar"; color: root.ink; font.family: root.bar ? root.bar.fontFamily : "monospace"; font.pixelSize: Style.font.title; font.bold: true }
                        Text { text: "Three states. One glance."; color: root.ink; opacity: 0.55; font.pixelSize: Style.font.caption }
                    }
                    LiveGlyph { width: 38; height: 38; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter }
                }
                Repeater {
                    model: [
                        {label: "Wi-Fi", detail: root.wifiDetail, value: root.wifiLabel, icon: "󰖩"},
                        {label: "Bluetooth", detail: root.bluetoothDetail, value: root.bluetoothLabel, icon: "󰂯"},
                        {label: "Battery", detail: root.batteryDetail, value: root.batteryLabel, icon: "󰁹"}
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        width: content.width
                        height: Style.space(74)
                        radius: Style.space(10)
                        color: Qt.alpha(root.ink, 0.055)
                        Text {
                            id: icon
                            anchors.left: parent.left; anchors.leftMargin: Style.space(13); anchors.verticalCenter: parent.verticalCenter
                            text: modelData.icon; color: root.ink; font.family: root.bar ? root.bar.fontFamily : "monospace"; font.pixelSize: Style.font.title
                        }
                        Column {
                            anchors.left: icon.right; anchors.leftMargin: Style.space(12)
                            anchors.right: parent.right; anchors.rightMargin: Style.space(13)
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Style.space(5)
                            Item {
                                width: parent.width; height: title.implicitHeight
                                Text { id: title; text: modelData.label; color: root.ink; font.pixelSize: Style.font.body; font.bold: true }
                                Text { anchors.right: parent.right; text: modelData.value; color: root.ink; opacity: 0.75; font.pixelSize: Style.font.body }
                            }
                            Text { width: parent.width; textFormat: Text.PlainText; text: modelData.detail; elide: Text.ElideRight; color: root.ink; opacity: 0.55; font.pixelSize: Style.font.caption }
                        }
                    }
                }
                Text { text: "ARC  battery   ·   CENTER  Wi-Fi   ·   DOTS  Bluetooth"; color: root.ink; opacity: 0.4; font.pixelSize: Style.font.caption - 2; width: parent.width; wrapMode: Text.WordWrap }
            }
        }
    }
}
