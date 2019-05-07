Function Init()
  ? "[EPGScreen] Init"
  m.fullGuideGrid = m.top.findNode("fullGuideGrid")
  m.timeline = m.top.findNode("timeline")
  m.isEpgRequested = false
  m.requestedTimelines = []
  m.requestedDates = []

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
      date.toLocalTime()
      m.top.timelineStartTime = date.asSeconds()
      m.top.getScene().loadingIndicator.control = "start"
    else
      m.fullGuideGrid.setFocus(true)
    end if
  end if
end sub


sub onEpgRequest(event)
  responseAA = event.getData()
  m.isEpgRequested = false
  if responseAA <> invalid
'    m.fullGuideGrid.setFields(responseAA)
    m.requestedDates.push(responseAA.guideDate)
    m.requestedTimelines.push(responseAA.timelineStartTime)
    if isEmpty(m.fullGuideGrid.channels)
      responseAA.delete("timelineStartTime")
      m.fullGuideGrid.setFields(responseAA)
    else
      m.tempPrograms = m.fullGuideGrid.programs
      for i = 0 to m.fullGuideGrid.channels.count() - 1
        id = m.fullGuideGrid.channels[i].id
        if isNonEmptyArray(m.fullGuideGrid.programs[id]) and responseAA.programs[id] <> invalid then appendProgramsToFullGuide(id, responseAA.programs[id])
      end for
      m.fullGuideGrid.programs = m.tempPrograms
    end if
  end if
  m.fullGuideGrid.setFocus(true)
  m.top.getScene().loadingIndicator.control = "stop"
end sub


sub appendProgramsToFullGuide(ci, programsUpdate)
  programs = m.fullGuideGrid.programs[ci]
  if programsUpdate[0].utcStart < programs[0].utcStart
    for i = programsUpdate.count() - 1 to 0 step -1
      if isProgramNotInGuide(programs, programsUpdate[i].id) then programs.unshift(programsUpdate[i])
    end for
  else if programsUpdate[programsUpdate.count() - 1].utcStart > programs[programs.count() - 1].utcStart
    for i = 0 to programsUpdate.count() - 1
      if isProgramNotInGuide(programs, programsUpdate[i].id) then programs.push(programsUpdate[i])
    end for
  end if
  m.tempPrograms[ci] = programs
end sub


function isProgramNotInGuide(programs, id)
  for i = 0 to programs.count() - 1
    if programs[i].id = id then return false
  end for
  return true
end function


sub setupTimelineStartTime()
  m.timeline.timelineStartTime = m.top.timelineStartTime
  if not m.isEpgRequested and isEpgRequestRequired()
    params =  { visibleHours: m.fullGuideGrid.visibleHours
                timelineStartTime: m.top.timelineStartTime
                channels: m.fullGuideGrid.channels
              }
    m.isEpgRequested = true
    m.epgRequest = runTask("epgRequest", params, {responseAA: "onEpgRequest"})
  end if
end sub


function isEpgRequestRequired()
  if isEmpty(m.fullGuideGrid.channels) then return true
'  guideDate = convertTimestampToYyyyMmDd(m.top.timelineStartTime)
'  for each timeStamp in m.requestedDates
'    if timeStamp = guideDate return false
'  end for
  for each timeStamp in m.requestedTimelines
    if timeStamp = m.top.timelineStartTime return false
  end for
  startTime = m.top.timelineStartTime - m.fullGuideGrid.visibleHours * 2 * 3600
  endTime = m.top.timelineStartTime + m.fullGuideGrid.visibleHours * 2 * 3600
  programs = m.fullGuideGrid.programs[m.fullGuideGrid.channels[m.fullGuideGrid.focusedRow].id]
  return programs[0].utcStart > startTime or programs[programs.count() - 1].utcStart < endTime
end function


function convertTimestampToYyyyMmDd(timestamp)
  date = CreateObject("roDatetime")
  date.fromSeconds(timestamp)
  return date.ToISOString().split("T")[0]
end function


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
