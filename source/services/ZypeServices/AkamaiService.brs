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
    this.AnalyticsTask   = CreateObject("roSGNode", "AkamaiAnalyticsTask")

    ' Should be called when video plays from beginning for proper tracking of play vs resume
    this.setPlayStartedOnce = function(v)
        m.playStartedOnce = v
    end function

    this.InitializeAkamaiLibrary = function (customDimensions, beacon, videoNode)
        m.AnalyticsTask.setField("videoElement", videoNode)
        m.AnalyticsTask.setField("customDimensions", customDimensions)
        m.AnalyticsTask.setField("beacon", beacon)
    end function

    this.StartAkamaiEvents = function ()
        m.AnalyticsTask.control = "RUN"
    end function

    return this
End Function
