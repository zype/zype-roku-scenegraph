Function Init()
  ? "[EPGScreen] Init"
  m.fullGuideGrid = m.top.findNode("fullGuideGrid")
  m.timeline = m.top.findNode("timeline")
  m.isEpgRequested = false
  m.requestedTimelines = []
'  m.requestedDates = []
  m.optionsIcon = m.top.findNode("OptionsIcon")
  m.optionsIcon.blendColor = m.global.brand_color

  ' Set theme
  m.AppBackground = m.top.findNode("AppBackground")
  m.AppBackground.color = m.global.theme.background_color
  m.top.observeField("focusedChild", "onFocusChanged")
  m.fullGuideGrid.observeField("itemSelected", "onProgramSelected")
  m.top.observeField("visible", "onTopVisibilityChange")

  initializeVideoPlayer()
  m.top.videoPlayer.visible = false
End Function


Function initializeVideoPlayer()
  m.top.videoPlayer = m.top.createChild("Video")
  m.top.videoPlayer.translation = [0,0]
  m.top.videoPlayer.width = 0
  m.top.videoPlayer.height = 0
  
  ' Event listener for video player state. Needed to handle video player errors and completion
  m.top.videoPlayer.observeField("state", "OnVideoPlayerStateChange")
End Function


Function ReinitializeVideoPlayer()
  if m.top.RemakeVideoPlayer = true
    m.top.videoPlayer.unobserveField("state")
    m.top.removeChild(m.top.videoPlayer)
    initializeVideoPlayer()
  end if
End Function

' event handler of Video player msg
Sub OnVideoPlayerStateChange()
  if m.top.videoPlayer.state = "error"
    ' error handling
    m.top.videoPlayer.visible = false
    m.fullGuideGrid.setFocus(true)
  else if m.top.videoPlayer.state = "finished" or m.top.videoPlayer.state = "stopped"
    m.top.videoPlayer.visible = false
    m.fullGuideGrid.setFocus(true)
  end if
End Sub


Sub onTopVisibilityChange()
  if m.top.visible
'    m.top.setFocus(true)
  else
    m.fullGuideGrid.channels = invalid
    m.requestedTimelines = []
    m.fullGuideGrid.reset = true
  end if
End Sub


sub onFocusChanged()
  Dbg("EPGScreen hasFocus", m.top.hasFocus())
  if m.top.hasFocus()
    if isEmpty(m.fullGuideGrid.channels)
     updateTimelineWithCurrentTime()
     m.top.getScene().loadingIndicator.control = "start"
    else
      if m.top.visible then m.fullGuideGrid.setFocus(true)
'      m.fullGuideGrid.reset = true
    end if
  else if not m.top.isInFocusChain()
    Dbg("EPGScreen turns off", m.top.isInFocusChain())
    m.top.videoPlayer.visible = false
    m.top.videoPlayer.control = "stop"
  end if
end sub


sub updateTimelineWithCurrentTime()
  date = CreateObject("roDatetime")
  date.toLocalTime()
  m.top.timelineStartTime = date.asSeconds()
end sub


sub onEpgRequest(event)
  responseAA = event.getData()
  m.isEpgRequested = false
  if responseAA <> invalid
'    m.fullGuideGrid.setFields(responseAA)
'    m.requestedDates.push(responseAA.guideDate)
    m.requestedTimelines.push(responseAA.timelineStartTime)
    if isEmpty(m.fullGuideGrid.channels)
      if m.fullGuideGrid.numRows >= responseAA.channels.count() then m.fullGuideGrid.numRows = responseAA.channels.count() - 1
      responseAA.delete("timelineStartTime")
      m.fullGuideGrid.setFields(responseAA)
    else
      m.tempPrograms = m.fullGuideGrid.programs
      for i = 0 to m.fullGuideGrid.channels.count() - 1
        id = m.fullGuideGrid.channels[i].id
        if isNonEmptyArray(m.fullGuideGrid.programs[id]) and responseAA.programs[id] <> invalid then appendProgramsToFullGuide(id, responseAA.programs[id])
      end for
      m.fullGuideGrid.programs = m.tempPrograms
      m.tempPrograms = invalid
    end if
  end if
  if m.top.visible then m.fullGuideGrid.setFocus(true)
  m.top.getScene().loadingIndicator.control = "stop"
end sub


sub appendProgramsToFullGuide(cid, programsUpdate)
  programs = m.fullGuideGrid.programs[cid]
  if programsUpdate[0].utcStart < programs[0].utcStart
    for i = programsUpdate.count() - 1 to 0 step -1
      if isProgramNotInGuide(programs, programsUpdate[i].id) then programs.unshift(programsUpdate[i])
    end for
  else if programsUpdate[programsUpdate.count() - 1].utcStart > programs[programs.count() - 1].utcStart
    for i = 0 to programsUpdate.count() - 1
      if isProgramNotInGuide(programs, programsUpdate[i].id) then programs.push(programsUpdate[i])
    end for
  end if
  programs.sortBy("utcStart")
  m.tempPrograms[cid] = programs
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


sub onProgramSelected()
  if m.fullGuideGrid.itemSelected and m.fullGuideGrid.program <> invalid
    params = {}
    params.append(m.fullGuideGrid.program)
    now = CreateObject("roDatetime").asSeconds()
    if params.utcStart <= now
      if params.utcStart + params.duration > now then params.start_time = ""
      m.top.getScene().loadingIndicator.control = "start"
      m.epgRequest = runTask("epgProgramInfo", params, {responseAA: "onEpgProgramInfoRequest"})
    end if
  end if
end sub


sub onEpgProgramInfoRequest(event)
  responseAA = event.getData()
  if responseAA <> invalid then m.top.startStream = responseAA
end sub


function isEpgRequestRequired()
  if not m.top.visible then return false
  if isEmpty(m.fullGuideGrid.channels) then return true
'  guideDate = convertTimestampToYyyyMmDd(m.top.timelineStartTime)
'  for each timeStamp in m.requestedDates
'    if timeStamp = guideDate return false
'  end for
  for each timeStamp in m.requestedTimelines
    if timeStamp = m.top.timelineStartTime then return false
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


sub stopVideoPlayer()
  m.top.videoPlayer.control = "stop"
  m.top.videoPlayer.visible = false
  m.fullGuideGrid.setFocus(true)
end sub


function onKeyEvent(key as String, press as Boolean) as Boolean
  result = false
  if press
    ? ">>> EPGScreen >> onKeyEvent >> key " key
    if key="down"
      result = true
    else if key="up"
      result = true
    else if key = "options"
      m.fullGuideGrid.reset = true
      result = true
    else if key = "back"
      if m.top.videoPlayer.visible
        stopVideoPlayer()
        result = true
      end if
    end if
  end if
  return result
end function
