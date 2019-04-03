'get videoID from the registry
Function GetVideoIdForResumeFromReg(key as String) as String
    videoID = RegRead(key, "ResumeVideo")
    if videoID = invalid
        videoID = "noseektime"
    end if
    return videoID
End Function

'add videoID to the registry
Sub AddVideoIdForResumeToReg(key as String,param_videoID as String)
    RegWrite(key, param_videoID, "ResumeVideo")
End Sub

'add videoIDtime played to the registry
Sub AddVideoIdTimeSaveForResumeToReg(key as String,param_videoID as String)
    if(RegRead(key, "ResumeVideoTime") = invalid)
        startDate = CreateObject("roDateTime")
        time = startDate.asSeconds()
        RegWrite(key, time.ToStr(), "ResumeVideoTime")
    end if
end Sub

' delete videoID from the registry
function RemoveVideoIdForResumeFromReg(key as String) as Void
    RegDelete(key, "ResumeVideo")
    RegDelete(key, "ResumeVideoTime")
end function
