' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********
 ' info
Function Init()
    ? "[InfoScreen] Init"
    m.top.Info = m.top.findNode("Info")
    m.top.Info.text = ""
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
