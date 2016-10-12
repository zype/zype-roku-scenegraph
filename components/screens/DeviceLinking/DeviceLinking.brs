' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********
 ' inits DeviceLinking
 ' creates all children
 ' sets all observers
Function Init()
    ? "[DeviceLinking] Init"

    m.linkText = m.top.findNode("LinkText")
    m.linkText.text = "Please, visit havoc.com to link your device!"

    di = CreateObject("roDeviceInfo")
    m.pin = m.top.findNode("Pin")
End Function

' onChange handler for "show" field
sub On_show()
    print " [DeviceLinking] On_show()"

    m.top.visible = m.top.show
    m.top.setFocus(m.top.show)
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    ? ">>> Device Linking >> onKeyEvent"
    result = false
    if press then
        ? "key == ";  key
        if key = "options" then
            result = true
        end if
    end if
    return result
end function
