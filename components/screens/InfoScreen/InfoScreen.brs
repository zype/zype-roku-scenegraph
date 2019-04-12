' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********
 ' info
Function Init()
    ? "[InfoScreen] Init"
    m.top.Info = m.top.findNode("Info")
    m.top.Info.text = ""

    ' Set theme
    m.AppBackground = m.top.findNode("AppBackground")
    m.AppBackground.color = m.global.theme.background_color

    m.info = m.top.findNode("Info")
    m.info.color = m.global.theme.primary_text_color

    m.version = m.top.findNode("Version")
    m.version.color = m.global.theme.primary_text_color
    m.version.text = "v" + m.global.version
End Function

' Content change handler
' All fields population
Sub OnContentChanged()
    ? "[InfoScreen] Content changed"
End Sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    ? ">>> Info >> onKeyEvent"
    result = false
    if press then
        ? "key == ";  key
        if key="down" then
            result = true
        else if key="up" then
            result = true
        else if key = "options" then
            result = true
        else if key = "back"
            result = false
        end if
    end if
    return result
end function
