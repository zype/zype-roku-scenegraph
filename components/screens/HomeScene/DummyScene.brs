Function Init()
    ' listen on port 8089
    m.top.setFocus(true)
End Function

function onKeyEvent(key as String, press as Boolean) as Boolean
    result = false
    if press then
        if key="OK"
            m.top.outRequest = {"ExitApp": true}
        end if
    end if
End Function
