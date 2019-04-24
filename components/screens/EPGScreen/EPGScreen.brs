Function Init()
  ? "[EPGScreen] Init"
  m.global.addFields({ timeShift: 0 })

  m.fullGuideGrid = m.top.findNode("fullGuideGrid")

  m.timeline = m.top.findNode("timeline")

  ' Set theme
  m.AppBackground = m.top.findNode("AppBackground")
  m.AppBackground.color = m.global.theme.background_color
  m.top.observeField("focusedChild", "onFocusChanged")
End Function


Sub OnTopVisibilityChange()
  if m.top.visible
    m.top.setFocus(true)
  end if
End Sub


sub onFocusChanged()
  Dbg("EPGScreen hasFocus", m.top.hasFocus())
  if m.top.hasFocus()
    if isEmpty(m.fullGuideGrid.channels)
      date = CreateObject("roDatetime")
      utc = date.asSeconds()
      date.toLocalTime()
      m.global.timeShift = date.asSeconds() - utc
      m.top.timelineStartTime = date.asSeconds()
      m.epgRequest = runTask("epgRequest", invalid, {responseAA: "onEpgRequest"})
      m.top.getScene().loadingIndicator.control = "start"
    else
      m.fullGuideGrid.setFocus(true)
    end if
  end if
end sub


sub onEpgRequest(event)
  responseAA = event.getData()
  if responseAA <> invalid
    m.fullGuideGrid.setFields(responseAA)
  end if
  m.fullGuideGrid.setFocus(true)
  m.top.getScene().loadingIndicator.control = "stop"
end sub


sub setupTimelineStartTime()
  m.timeline.timelineStartTime = m.top.timelineStartTime
end sub


function onKeyEvent(key as String, press as Boolean) as Boolean
  ? ">>> EPGScreen >> onKeyEvent"
  result = false
  if press
    ? "key == ";  key
    if key="down"
      result = true
    else if key="up"
      result = true
    else if key = "options"
      result = true
    else if key = "back"
    end if
  else
    ? "press: "; press
    if key = "back"
    end if
  end if
  return result
end function
