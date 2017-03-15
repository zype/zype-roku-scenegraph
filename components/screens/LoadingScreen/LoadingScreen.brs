' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********
 ' inits LoadingScreen
 ' creates all children
Function Init()
    ? "[LoadingScreen] Init"
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