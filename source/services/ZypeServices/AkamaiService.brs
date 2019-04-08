' **************************************************
' Akamai Service
'   - Service for Akamai custom integration with scene graph
'   - Used in conjunction with Akamai SDK (source/services/Akamai)
'
' Functions in service
'     setPlayStartedOnce
'     handleVideoEvents
'
' Usage
'     akamai_service = AkamaiService()
' **************************************************
Function AkamaiService() as object
    this = {}
    this.playStartedOnce = invalid

    ' Should be called when video plays from beginning for proper tracking of play vs resume
    this.setPlayStartedOnce = function(v)
        m.playStartedOnce = v
    end function

    ' Call on video player state changes to pass info to Akamai
    this.handleVideoEvents = function (state, pluginInstance, sessionTimer, lastHeadPosition)
        if(m.playStartedOnce <> invalid AND state = "playing")
            state = "resumed"
        else if(m.playStartedOnce = invalid AND state = "playing")
            state = "playing"
            m.playStartedOnce = true
        end if

        print "=============="
        print "State: "; state
        print "=============="

        if(state = "paused")    ' Video was paused
            pluginInstance.handlePlaybackPauseEvent(sessionTimer, lastHeadPosition)
            print "Akamai Paused Event was called"
        else if(state = "playing")  ' First time play
            pluginInstance.handlePlayStartEvent(sessionTimer, lastHeadPosition)
            print "Akamai Playing Event was called"
        else if(state = "resumed")  ' Video resumed
            pluginInstance.handlePlaybackResumeEvent(sessionTimer, lastHeadPosition)
            print "Akamai Resumed Event was called"
        else if(state = "stopped" OR state = "finished")  ' Stopped by pressing the back button and go out
            m.playStartedOnce = invalid
            endReasonCode = "PlaybackEnded"
            pluginInstance.handlePlaybackCompleteEvent(sessionTimer, endReasonCode, lastHeadPosition)
            print "Akamai Stopped Event was called"
        else if(state = "error")
            endReasonCode = "PlaybackInterrupted"
            pluginInstance.handlePlaybackCompleteEvent(sessionTimer, endReasonCode, lastHeadPosition)
        end if

    end function

    return this
End Function
