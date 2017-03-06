sub init()
    m.sec=CreateObject("roRegistrySection","ResumeVideo")
    m.secForTimer =  CreateObject("roRegistrySection","ResumeVideoTime")
end sub

' has videoID in the registry
function HasVideoIdForResume() 
    videoID = RegReadVideoId(m.top.HasVideoId)
    if videoID <> invalid
        m.top.HasVideoIdValue = true
    else
        m.top.HasVideoIdValue = false
    end if
end function

Function RegReadVideoId(key as String)
    if m.sec.Exists(key) then return m.sec.Read(key)
    return invalid
End Function

'Get video id saved time from registry
function GetVideoIdTimerForResumeFromReg() 
    if m.secForTimer.Exists(m.top.GetVideoIdTimer) then 
        m.top.GetVideoIdTimerValue =  m.secForTimer.Read(m.top.GetVideoIdTimer)
    else
        m.top.GetVideoIdTimerValue = "notimer"
    end if
end function

' delete videoID from the registry
function DeleteVideoIdTimerForResumeFromReg() as Void
'    for i = 0 to sec.GetKeyList().Count() - 1
'        print "sec.GetKeyList()[0]  ";sec.GetKeyList()[i]
'    end for
  '  print "delete m.top.DeleteVideoIdTimer";m.top.DeleteVideoIdTimer
    m.secForTimer.Delete(m.top.DeleteVideoIdTimer)
    m.secForTimer.Flush()
    
    m.sec.Delete(m.top.DeleteVideoIdTimer)
    m.sec.Flush()
end function