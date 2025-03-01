import QtQuick 2.12
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.14
import QtQuick.Controls.Material 2.0

import org.electrum 1.0

import "controls"

ElDialog {
    id: dialog

    property Invoice invoice
    property string invoice_key

    signal doPay
    signal invoiceAmountChanged

    title: qsTr('Invoice')
    iconSource: Qt.resolvedUrl('../../icons/tab_send.png')

    padding: 0

    property bool _canMax: invoice.invoiceType == Invoice.OnchainInvoice

    property Amount _invoice_amount: invoice.amount

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Flickable {
            Layout.preferredWidth: parent.width
            Layout.fillHeight: true

            leftMargin: constants.paddingLarge
            rightMargin: constants.paddingLarge

            contentHeight: rootLayout.height
            clip:true
            interactive: height < contentHeight

            GridLayout {
                id: rootLayout
                width: parent.width

                columns: 2

                InfoTextArea {
                    id: helpText
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                    Layout.bottomMargin: constants.paddingLarge
                    visible: text
                    text: invoice.userinfo
                    iconStyle: invoice.status == Invoice.Failed || invoice.status == Invoice.Expired
                        ? InfoTextArea.IconStyle.Warn
                        : InfoTextArea.IconStyle.Info
                }

                Label {
                    text: qsTr('Type')
                    color: Material.accentColor
                }

                RowLayout {
                    Layout.fillWidth: true
                    Image {
                        Layout.preferredWidth: constants.iconSizeSmall
                        Layout.preferredHeight: constants.iconSizeSmall
                        source: invoice.invoiceType == Invoice.LightningInvoice
                            ? "../../icons/lightning.png"
                            : "../../icons/bitcoin.png"
                    }

                    Label {
                        text: invoice.invoiceType == Invoice.OnchainInvoice
                                ? qsTr('On chain')
                                : invoice.invoiceType == Invoice.LightningInvoice
                                    ? invoice.address
                                        ? qsTr('Lightning with on-chain fallback address')
                                        : qsTr('Lightning')
                                    : ''
                        Layout.fillWidth: true
                    }
                }

                Label {
                    text: qsTr('Status')
                    color: Material.accentColor
                }

                RowLayout {
                    Image {
                        Layout.preferredWidth: constants.iconSizeSmall
                        Layout.preferredHeight: constants.iconSizeSmall
                        source: invoice.status == Invoice.Expired
                            ? '../../icons/expired.png'
                            : invoice.status == Invoice.Unpaid
                                ? '../../icons/unpaid.png'
                                : invoice.status == Invoice.Failed || invoice.status == Invoice.Unknown
                                    ? '../../icons/warning.png'
                                    : invoice.status == Invoice.Inflight || invoice.status == Invoice.Routing
                                        ? '../../icons/status_waiting.png'
                                        : invoice.status == Invoice.Unconfirmed
                                            ? '../../icons/unconfirmed.png'
                                            : invoice.status == Invoice.Paid
                                                ? '../../icons/confirmed.png'
                                                : ''
                    }
                    Label {
                        text: invoice.status_str
                    }
                }

                Label {
                    Layout.columnSpan: 2
                    Layout.topMargin: constants.paddingSmall
                    visible: invoice.invoiceType == Invoice.OnchainInvoice
                    text: qsTr('Address')
                    color: Material.accentColor
                }

                TextHighlightPane {
                    Layout.columnSpan: 2
                    Layout.fillWidth: true

                    visible: invoice.invoiceType == Invoice.OnchainInvoice
                    leftPadding: constants.paddingMedium

                    Label {
                        width: parent.width
                        text: invoice.address
                        font.family: FixedFont
                        wrapMode: Text.Wrap
                    }
                }

                Label {
                    Layout.columnSpan: 2
                    Layout.topMargin: constants.paddingSmall
                    text: qsTr('Description')
                    visible: invoice.message
                    color: Material.accentColor
                }

                TextHighlightPane {
                    Layout.columnSpan: 2
                    Layout.fillWidth: true

                    visible: invoice.message
                    leftPadding: constants.paddingMedium

                    Label {
                        text: invoice.message
                        width: parent.width
                        font.pixelSize: constants.fontSizeXLarge
                        wrapMode: Text.Wrap
                        elide: Text.ElideRight
                    }
                }

                Label {
                    Layout.columnSpan: 2
                    Layout.topMargin: constants.paddingSmall
                    text: qsTr('Amount to send')
                    color: Material.accentColor
                }

                TextHighlightPane {
                    id: amountContainer

                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter

                    leftPadding: constants.paddingXLarge

                    property bool editmode: false

                    RowLayout {
                        id: amountLayout
                        width: parent.width

                        GridLayout {
                            visible: !amountContainer.editmode
                            columns: 2

                            Label {
                                Layout.columnSpan: 2
                                Layout.fillWidth: true
                                visible: _invoice_amount.isMax
                                font.pixelSize: constants.fontSizeXLarge
                                font.bold: true
                                text: qsTr('All on-chain funds')
                            }

                            Label {
                                Layout.columnSpan: 2
                                Layout.fillWidth: true
                                visible: _invoice_amount.isEmpty
                                font.pixelSize: constants.fontSizeXLarge
                                color: constants.mutedForeground
                                text: qsTr('not specified')
                            }

                            Label {
                                Layout.alignment: Qt.AlignRight
                                visible: !_invoice_amount.isMax && !_invoice_amount.isEmpty
                                font.pixelSize: constants.fontSizeXLarge
                                font.family: FixedFont
                                font.bold: true
                                text: Config.formatSats(invoice.amount, false)
                            }

                            Label {
                                Layout.fillWidth: true
                                visible: !_invoice_amount.isMax && !_invoice_amount.isEmpty
                                text: Config.baseUnit
                                color: Material.accentColor
                                font.pixelSize: constants.fontSizeXLarge
                            }

                            Label {
                                id: fiatValue
                                Layout.alignment: Qt.AlignRight
                                visible: Daemon.fx.enabled && !_invoice_amount.isMax && !_invoice_amount.isEmpty
                                text: Daemon.fx.fiatValue(invoice.amount, false)
                                font.pixelSize: constants.fontSizeMedium
                                color: constants.mutedForeground
                            }

                            Label {
                                Layout.fillWidth: true
                                visible: Daemon.fx.enabled && !_invoice_amount.isMax && !_invoice_amount.isEmpty
                                text: Daemon.fx.fiatCurrency
                                font.pixelSize: constants.fontSizeMedium
                                color: constants.mutedForeground
                            }

                        }

                        GridLayout {
                            Layout.fillWidth: true
                            visible: amountContainer.editmode
                            enabled: !(invoice.status == Invoice.Expired && _invoice_amount.isEmpty)

                            columns: 3

                            BtcField {
                                id: amountBtc
                                fiatfield: amountFiat
                                enabled: !amountMax.checked
                                onTextAsSatsChanged: {
                                    invoice.amountOverride = textAsSats
                                }
                            }

                            Label {
                                Layout.fillWidth: amountMax.visible ? false : true
                                Layout.columnSpan: amountMax.visible ? 1 : 2

                                text: Config.baseUnit
                                color: Material.accentColor
                            }

                            Switch {
                                id: amountMax
                                Layout.fillWidth: true

                                text: qsTr('Max')
                                visible: _canMax
                                checked: false
                                onCheckedChanged: {
                                    if (activeFocus)
                                        invoice.amountOverride.isMax = checked
                                }
                            }

                            FiatField {
                                id: amountFiat
                                btcfield: amountBtc
                                visible: Daemon.fx.enabled && !amountMax.checked
                                enabled: !amountMax.checked
                            }

                            Label {
                                Layout.columnSpan: 2
                                visible: Daemon.fx.enabled && !amountMax.checked
                                text: Daemon.fx.fiatCurrency
                                color: Material.accentColor
                            }
                        }
                    }

                }

                Heading {
                    Layout.columnSpan: 2
                    visible: invoice.invoiceType == Invoice.LightningInvoice
                    text: qsTr('Technical properties')
                }

                Label {
                    Layout.columnSpan: 2
                    Layout.topMargin: constants.paddingSmall
                    visible: invoice.invoiceType == Invoice.LightningInvoice
                    text: qsTr('Remote Pubkey')
                    color: Material.accentColor
                }

                TextHighlightPane {
                    Layout.columnSpan: 2
                    Layout.fillWidth: true

                    visible: invoice.invoiceType == Invoice.LightningInvoice
                    leftPadding: constants.paddingMedium

                    RowLayout {
                        width: parent.width
                        Label {
                            id: pubkeyLabel
                            Layout.fillWidth: true
                            text: 'pubkey' in invoice.lnprops ? invoice.lnprops.pubkey : ''
                            font.family: FixedFont
                            wrapMode: Text.Wrap
                        }
                        ToolButton {
                            icon.source: '../../icons/share.png'
                            icon.color: 'transparent'
                            enabled: pubkeyLabel.text
                            onClicked: {
                                var dialog = app.genericShareDialog.createObject(app,
                                    { title: qsTr('Node public key'), text: invoice.lnprops.pubkey }
                                )
                                dialog.open()
                            }
                        }
                    }
                }

                Label {
                    Layout.columnSpan: 2
                    Layout.topMargin: constants.paddingSmall
                    visible: invoice.invoiceType == Invoice.LightningInvoice
                    text: qsTr('Payment hash')
                    color: Material.accentColor
                }

                TextHighlightPane {
                    Layout.columnSpan: 2
                    Layout.fillWidth: true

                    visible: invoice.invoiceType == Invoice.LightningInvoice
                    leftPadding: constants.paddingMedium

                    RowLayout {
                        width: parent.width
                        Label {
                            id: paymenthashLabel
                            Layout.fillWidth: true
                            text: 'payment_hash' in invoice.lnprops ? invoice.lnprops.payment_hash : ''
                            font.family: FixedFont
                            wrapMode: Text.Wrap
                        }
                        ToolButton {
                            icon.source: '../../icons/share.png'
                            icon.color: 'transparent'
                            enabled: paymenthashLabel.text
                            onClicked: {
                                var dialog = app.genericShareDialog.createObject(app, {
                                    title: qsTr('Payment hash'),
                                    text: invoice.lnprops.payment_hash
                                })
                                dialog.open()
                            }
                        }
                    }
                }

                Label {
                    Layout.columnSpan: 2
                    Layout.topMargin: constants.paddingSmall
                    visible: 'r' in invoice.lnprops && invoice.lnprops.r.length
                    text: qsTr('Routing hints')
                    color: Material.accentColor
                }

                Repeater {
                    visible: 'r' in invoice.lnprops && invoice.lnprops.r.length
                    model: invoice.lnprops.r

                    TextHighlightPane {
                        Layout.columnSpan: 2
                        Layout.fillWidth: true

                        RowLayout {
                            width: parent.width

                            Label {
                                text: modelData.scid
                            }
                            Label {
                                Layout.fillWidth: true
                                text: modelData.node
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                }
            }
        }

        ButtonContainer {
            Layout.fillWidth: true

            FlatButton {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                text: qsTr('Delete')
                icon.source: '../../icons/delete.png'
                visible: invoice_key != ''
                onClicked: {
                    invoice.wallet.delete_invoice(invoice_key)
                    dialog.close()
                }
            }
            FlatButton {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                text: qsTr('Save')
                icon.source: '../../icons/save.png'
                visible: invoice_key == ''
                enabled: invoice.canSave
                onClicked: {
                    app.stack.push(Qt.resolvedUrl('Invoices.qml'))
                    if (invoice.amount.isEmpty) {
                        invoice.amount = amountMax.checked ? MAX : Config.unitsToSats(amountBtc.text)
                    }
                    invoice.save_invoice()
                    dialog.close()
                }
            }
            FlatButton {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                text: qsTr('Pay')
                icon.source: '../../icons/confirmed.png'
                enabled: invoice.invoiceType != Invoice.Invalid && invoice.canPay
                onClicked: {
                    if (invoice.amount.isEmpty) {
                        invoice.amount = amountMax.checked ? MAX : Config.unitsToSats(amountBtc.text)
                        if (invoice_key != '') {
                            // delete the existing invoice because this affects get_id()
                            invoice.wallet.delete_invoice(invoice_key)
                            invoice_key = ''
                        }
                    }
                    if (invoice_key == '') {
                        // save invoice if new or modified
                        invoice.save_invoice()
                    }
                    doPay() // only signal here
                }
            }
        }

    }

    Component.onCompleted: {
        if (invoice_key != '') {
            invoice.initFromKey(invoice_key)
        }
        if (invoice.amount.isEmpty && !invoice.status == Invoice.Expired) {
            amountContainer.editmode = true
        } else if (invoice.amount.isMax) {
            amountMax.checked = true
        }
    }
}
