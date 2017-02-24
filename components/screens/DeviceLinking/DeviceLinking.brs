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

    'm.linkText.text = "Please, visit havoc.com to link your device!"

    di = CreateObject("roDeviceInfo")
    m.pin = m.top.findNode("Pin")
End Function

' onChange handler for "show" field
sub On_show()
    print " [DeviceLinking] On_show()"

    m.top.visible = m.top.show
    m.top.setFocus(m.top.show)
    'm.linkText.text = "Please visit " + m.top.DeviceLinkingURL + " to link your device!"

    m.background.color = m.global.theme.background_color

    m.linkText.text = "From your computer or mobile device, visit:"
    m.linkText.color = m.global.theme.secondary_text_color

    m.linkText2.text = m.top.DeviceLinkingURL
    m.linkText2.color = m.global.theme.primary_text_color

    m.linkText3.text = "Enter Pin:"
    m.linkText3.color = m.global.theme.secondary_text_color

    m.pin.color = m.global.theme.primary_text_color

end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
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
end function
