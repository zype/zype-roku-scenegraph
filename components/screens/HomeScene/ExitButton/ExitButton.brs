
Sub init()
    m.exitLabel = m.top.findNode("exitLabel")
    m.exitButton = m.top.findNode("exitButton")

    m.exitButton.blendcolor = m.global.theme.primary_text_color
    m.exitLabel.color = m.global.theme.background_color

    changeFocus(0)
End Sub

Sub OnContentChange()
  m.exitLabel.text  = m.top.itemContent.SHORTDESCRIPTIONLINE1
  m.exitButton.width = m.exitLabel.BoundingRect().width + 50
End Sub

Sub onFocusPercentChange()
    focusPercent = m.top.focusPercent
    if m.top.gridHasFocus
        changeFocus(focusPercent)
    end if
End Sub


sub changeFocus(focusPercent)
    if focusPercent > 0 then
        m.exitLabel.color = m.global.theme.background_color
        m.exitButton.blendcolor = m.global.theme.primary_text_color
    else
        m.exitLabel.color = m.global.theme.primary_text_color
        m.exitButton.blendcolor = m.global.theme.background_color
    end if
end sub

sub FocusPercent_Changed(event as dynamic)
    value = event.GetData()
    if (m.top.gridHasFocus) then
        changeFocus(value)
    else
        changeFocus(0)
    end if
end sub

sub ItemHasFocus_Changed(event as dynamic)
    value = event.GetData()
    if (value) then
        changeFocus(1)
    end if
end sub
'
sub ParentHasFocus_Changed(event as dynamic)
    if (m.top.GridHasFocus and (m.top.ItemHasFocus or m.top.FocusPercent = 1)) then
        changeFocus(1)
    else
        changeFocus(0)
    end if
end sub
