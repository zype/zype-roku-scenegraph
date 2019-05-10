Function Init()
  Dbg("init")
  m.timelinegroup   =   m.top.findNode("timelinegroup")

  m.currenttimemark   =   m.top.findNode("currenttimemark")
  m.tlseparator1      =   m.top.findNode("tlseparator1")
  m.timelabel1        =   m.top.findNode("timelabel1")
  m.timelabel2        =   m.top.findNode("timelabel2")
  m.timelabel3        =   m.top.findNode("timelabel3")
  m.timelabel4        =   m.top.findNode("timelabel4")
  m.timelinebg        =   m.top.findNode("timelinebg")
  m.currenttimelabel  =   m.top.findNode("currenttimelabel")
  m.clocklabel        =   m.top.findNode("clocklabel")

  m.tikTakTimer = m.top.findNode("TikTakTimer")

  initTimeline()

  m.top.observeField("visible", "onVisibleChange")
End Function


sub initTimeline()
  if m.top.halfHour
    segmentWidth = m.top.hourwidth / 2
    m.segmentTime = 1800
    m.segments = m.top.visibleHours * 2
  else
    m.segmentTime = 3600
    segmentWidth = m.top.hourwidth
    m.segments = m.top.visibleHours
  end if
  m.timelinebg.color = m.global.theme.plan_button_color
  m.currenttimemark.color = m.global.brand_color
  m.clocklabel.color = m.global.theme.primary_text_color
  m.currenttimelabel.color = m.global.theme.primary_text_color
  m.currenttimemark.translation = [m.top.leftOffset, 0]
  for i = 0 to m.segments - 1
    timelabel = m["timelabel" + (i + 1).toStr()]
    timelabel.color = m.global.theme.primary_text_color
    timelabel.translation = [m.top.leftOffset + segmentWidth * i + int(segmentWidth * 0.05), 0]
    m.top.findNode("tlseparator" + (i + 1).toStr()).translation = [m.top.leftOffset + segmentWidth * i - 1, 0]
  end for
'  m.currenttimelabel.width = m.top.leftOffset - 20
end sub


function setupTimeline() as object
  m.timelinegroup.translation = [0, m.top.topOffset]
  m.hourStart = getHourStart(m.top.timelineStartTime)
  initialShift = hoursLeft(getHourStart(utcToLocal(CreateObject("roDatetime").asSeconds())) - m.hourStart)
  for i = 0 to m.segments - 1
    m["timelabel" + (i + 1).toStr()].text = secondsToTime(m.hourStart + m.segmentTime * i)
  end for
  m.currenttimemark.visible = (initialShift >= 0) and (initialShift < m.segments - 1)
  tiktak()
end function


Sub onVisibleChange()
  if m.top.visible
    Dbg("onVisibleChange")
    m.tikTakTimer.observeField("fire", "tiktak")
    setupTimeline()
    m.tikTakTimer.control = "start"
  else
    m.tikTakTimer.control = "stop"
    m.tikTakTimer.unobserveField("fire")
  end if
End Sub


Sub moveCurrentTimeMark(shiftValue)
'    m.currenttimemark.translation = [m.tlseparator1.translation[0] + shiftValue, m.currenttimemark.translation[1]]
  m.currenttimemark.width = shiftValue
End Sub


Function tiktak()
  if m.currenttimemark.visible then moveCurrentTimeMark(m.top.hourwidth * hoursLeft(getHourStart(utcToLocal(CreateObject("roDatetime").asSeconds())) - m.hourStart) + getCurrentTimeOffset(m.top.hourwidth, m.global.timeShift))
  date = CreateObject("roDatetime")
  if m.top.timelineStartTime > 0 then date.fromSeconds(m.top.timelineStartTime)
  ct = getCurrentTime(false)
  m.clocklabel.text = ct
  m.currenttimelabel.text = date.AsDateString("short-month-short-weekday").split(",")[0] '+ " | " + ct
End Function
