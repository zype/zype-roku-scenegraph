' **************************************************
' Akamai Service
'   - Service for Akamai custom integration with scene graph
'
' Functions in service
'     
'
' Usage
'     akamai_service = AkamaiService()
' **************************************************

Function AkamaiService() as object
    this = {}
    this.playStartedOnce = invalid

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

    this.setPlayStartedOnce = function(v)
        m.playStartedOnce = v
    end function

    return this
End Function