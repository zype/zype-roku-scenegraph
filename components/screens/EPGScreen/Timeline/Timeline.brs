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
  m.currenttimemark.translation = [m.top.leftOffset, 0]
  m.tlseparator1.translation = [m.top.leftOffset - 1, 0]
  m.top.findNode("tlseparator2").translation = [m.top.leftOffset + m.top.hourwidth * 1 - 1, 0]
  m.top.findNode("tlseparator3").translation = [m.top.leftOffset + m.top.hourwidth * 2 - 1, 0]
  m.top.findNode("tlseparator4").translation = [m.top.leftOffset + m.top.hourwidth * 3 - 1, 0]
  m.timelabel1.translation = [m.top.leftOffset + int(m.top.hourwidth * 0.05), 0]
  m.timelabel2.translation = [m.top.leftOffset + m.top.hourwidth * 1 + int(m.top.hourwidth * 0.05), 0]
  m.timelabel3.translation = [m.top.leftOffset + m.top.hourwidth * 2 + int(m.top.hourwidth * 0.05), 0]
  m.timelabel4.translation = [m.top.leftOffset + m.top.hourwidth * 3 + int(m.top.hourwidth * 0.05), 0]
'  m.currenttimelabel.width = m.top.leftOffset - 20
end sub


function setupTimeline() as object
  m.timelinegroup.translation = [0, m.top.topOffset]
  m.hourStart = getHourStart(m.top.timelineStartTime)
  initialShift = hoursLeft(getHourStart(utcToLocal(CreateObject("roDatetime").asSeconds())) - m.hourStart)
  m.timelabel1.text = secondsToTime(m.hourStart)
  m.timelabel2.text = secondsToTime(m.hourStart + 3600)
  m.timelabel3.text = secondsToTime(m.hourStart + 3600 * 2)
  m.timelabel4.text = secondsToTime(m.hourStart + 3600 * 3)
  m.currenttimemark.visible = (initialShift >= 0) and (initialShift < 3)
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
