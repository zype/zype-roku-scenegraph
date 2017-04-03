' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********
 ' inits LoadingScreen
 ' creates all children
Function Init()
    ? "[LoadingScreen] Init"

    ' Set theme
    m.background = m.top.findNode("Background")
    m.background.color = m.global.theme.background_color

    m.loadingIndicator = m.top.findNode("loadingIndicator1")
    m.loadingIndicator.imageUri = m.global.theme.loader_uri
    m.loadingIndicator.textColor = m.global.theme.primary_text_color
    m.loadingIndicator.backgroundColor = m.global.theme.backgrond_color
End Function

' onChange handler for "show" field
sub onShow()
    print " [LoadingScreen] onShow()"

    m.top.visible = m.top.show
    m.top.setFocus(m.top.show)
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    ? ">>> Loading Screen >> onKeyEvent"
    result = false
    if press then
        ? "key == ";  key
        if key = "options" then
            result = true
        else if key = "back" then
            print "Back button from Loading Screen"
        end if
    end if
    return result
end function
