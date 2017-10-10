' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********
 ' inits DeviceLinking
 ' creates all children
 ' sets all observers
Function Init()
    ? "[DeviceLinking] Init"

    m.background = m.top.findNode("Shade")
    m.linkText = m.top.findNode("LinkText")
    m.linkText2 = m.top.findNode("LinkText2")
    m.linkText3 = m.top.findNode("LinkText3")

    m.unlinkButton = m.top.findNode("UnlinkButton")

    di = CreateObject("roDeviceInfo")
    m.pin = m.top.findNode("Pin")

    m.background.color = m.global.theme.background_color

    m.linkText.text = m.global.labels.device_linking_label_1
    m.linkText.color = m.global.theme.secondary_text_color

    m.linkText2.text = m.top.DeviceLinkingURL
    m.linkText2.color = m.global.theme.primary_text_color

    m.linkText3.text = m.global.labels.device_linking_label_2
    m.linkText3.color = m.global.theme.secondary_text_color

    m.pin.color = m.global.theme.primary_text_color

    m.unlinkButton.focusedColor = m.global.theme.primary_text_color
    m.unlinkButton.focusBitmapUri = m.global.theme.button_focus_uri
End Function

' onChange handler for "show" field
Sub On_show()
    print " [DeviceLinking] On_show()"

    m.top.visible = m.top.show
    m.top.setFocus(m.top.show)
    m.pin.text = "" ' Setting it empty because after the screen loads, it will load either pin or message

    m.linkText2.text = m.top.DeviceLinkingURL

    if(m.global.auth.isLinked = true)
        CreateUnlinkButton()
        m.unlinkButton.setFocus(true)
    else
        m.unlinkButton.content = invalid
    end if
End Sub

Function onDeviceLinkingStateChanged()
    if m.global.auth.isLinked = false
        m.unlinkButton.content = invalid
        m.pin.text = "Device Unlinked Successfully!"
        m.top.setUnlinkFocus = false
    else
        CreateUnlinkButton()
    end if
End Function

Function setUnlinkFocusCallback()
    print "setUnlinkFocusCallback"
    if m.global.auth.isLinked = true
        m.unlinkButton.setFocus(true)
    end if
End Function

Function CreateUnlinkButton()
    result = []
    result.push({title : m.global.labels.unlink_device_button})
    m.unlinkButton.content = ContentList2SimpleNode(result)
End Function

Function onItemSelected()
    print "Device Unlink Clicked"
End Function

Function onKeyEvent(key as String, press as Boolean) as Boolean
    ? ">>> Device Linking >> onKeyEvent"
    result = false
    if press then
        ? "key == ";  key
        if key = "options" then
            result = true
        else if key = "back" then
            print "Back button from Device Linking Screen"
        end if
    end if
    return result
End Function

'///////////////////////////////////////////'
' Helper function convert AA to Node
Function ContentList2SimpleNode(contentList as Object, nodeType = "ContentNode" as String) as Object
    result = createObject("roSGNode",nodeType)
    if result <> invalid
        for each itemAA in contentList
            item = createObject("roSGNode", nodeType)
            item.setFields(itemAA)
            result.appendChild(item)
        end for
    end if
    return result
End Function
