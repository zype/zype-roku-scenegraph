Sub init()
    m.title = m.top.findNode("title")
    ' m.selectedBorderRectangle = m.top.findNode("selectedBorderRectangle")
    m.focusBorderRectangle = m.top.findNode("focusBorderRectangle")
    ' m.selectedBorderRectangle.color = "#DDA003"
    ' m.focusBorderRectangle.color = "#FFFFFF"
    m.focusBorderRectangle.blendcolor = m.global.theme.secondary_text_color ''"#1919c1"

    m.title.color = m.global.theme.primary_text_color

    m.top.lastFocusPercent = 0
    changeFocus(0)
End Sub

Sub OnContentChange()
  ' print "m.top.itemContent :: " m.top.itemContent
  m.title.text  = m.top.itemContent.SHORTDESCRIPTIONLINE1

  ' m.selectedBorderRectangle.visible = false
  if (m.top.itemContent.ShortDescriptionLine2 = "initialselected")
    ' m.selectedBorderRectangle.visible = true
  end if
  if (m.top.itemContent.ShortDescriptionLine2 <> "" AND m.top.itemContent.ShortDescriptionLine2 <> "initialselected")
      ' if (m.top.itemContent.ShortDescriptionLine2 = "selected")
      '     m.selectedBorderRectangle.visible = true
      ' else
      '     m.selectedBorderRectangle.visible = false
      ' end if
  end if
  ' m.selectedBorderRectangle.width = m.title.BoundingRect().width + 30
  m.focusBorderRectangle.width = m.title.BoundingRect().width + 50
End Sub

Sub onFocusPercentChange()
    focusPercent = m.top.focusPercent
    if m.top.gridHasFocus
        changeFocus(focusPercent)
    end if
End Sub

Sub onSelectionChange()
    print "m.top.isSelected : " m.top.isSelected " : m.title.text = " m.title.text
    ' if m.top.isSelected
    '     changeFocus(focusPercent)
    ' end if
End Sub

sub changeFocus(focusPercent)
    m.focusBorderRectangle.opacity = focusPercent
    m.top.lastFocusPercent = focusPercent
    if focusPercent > 0 then
      m.title.color = m.global.theme.background_color
    else
      m.title.color = m.global.theme.primary_text_color
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
    print "ItemHasFocus_Changed-----------" event.GetData()
    value = event.GetData()
    if (value) then
        changeFocus(1)
    end if
end sub
'
sub ParentHasFocus_Changed(event as dynamic)
  ''  print "ParentHasFocus_Changed-----------" event
    if (m.top.GridHasFocus and (m.top.ItemHasFocus or m.top.FocusPercent = 1)) then
        changeFocus(1)
    else
        changeFocus(0)
    end if
end sub


function onKeyEvent(key as String, press as Boolean)
    print "HOME=========================> press : " press "  key : " key
end function
