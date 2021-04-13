'
' roku_malibrary.brs
' Version - 2.5.3
'
' This file is part of the Media Analytics, http://www.akamai.com
' Media Analytics is a proprietary Akamai software that you may use and modify per the license agreement here:
' http://www.akamai.com/product/licenses/mediaanalytics.html
' THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES,
' INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
'
' Created by Umesh Tank and Vishvesh Kumar.
' This file is main plugin file which implements and controls the plugin flow
' Here is a basic description on plugin architecture
' 1) Create plugin instance using createPluginInstance which will return plugin instance
'   plugin = createPluginInstance(pluginParams)
'  pluginParams - pluginParams is a initialization params for the pluign
'  pluginParams = {
'                   configXML : url
'                   customDimensions : {Associative array}
'                   eventHandlers : {handler functions}
'
'                   }
' 2) Parse configuration xml provided as part of pluginParams
' xml = parseConfigXML(url)
'
' 3) Create a data store which will hold the parsed xml + dimensions and metrics
'   dataStore = AkaMA_createDataStore()
'
' 4) Initialization state
'   plugin.State().beginState("initiliaze", params)
'   (Send out I-line ???)
'
' 5) CreateVideoPlayer and MsgLoop
'
'6) Message loop and wait for messages
' 6.1) If play started
'       plugin.state().beginState("playStarted", params)
'        (send out s-line ???)
' 6.2) if plugin timer events (5-sec one time and then 'log-interval')
'       plugin.state().beginState("playing", params)
'       plugin.state().udpateState("playing", params)
'       (send out p-line ???)
' 6.3) if video completed
'       plugin.state().beginState("completed", params)
'       (send out c-line???)
' 6.4) if video playback error / some other error
'       plugin.state().beginState("error", params)
'       (send out e-line ???)
' 6.5) if app closed
'       plugin.state.beginState("visit", params)
'       (send out v-line???)
' 6.6) if player evetns (pause / seek / rebuffer / bitrate switch)
'   6.6.1) Pause event
'           plugin.dataStore().updatePauseMetrics(params)
'   6.6.2) Seek event
'           plugin.dataStore().updateSeekMetrics(params)
'   6.6.1) Rebuffer event
'           plugin.dataStore().updateRebufferMetrics(params)
'   6.6.1) Bitrate switch event
'           plugin.dataStore().updateTrasitionStreamMetrics(params)
'

FUNCTION roku_malibrary(beaconUrl) as object
 return {
    'plugin                  :   1
    'streamStartTimer        :   invalid'CreateObject("roTimespan")
    'sessionTimer            :   CreateObject("roTimespan")
    'lastLogTime             :   invalid
    'ipAddresses             :   CreateObject("roAssociativeArray")
    'secondaryLogTimer       :   invalid
    'isFirstStreamStartEvent :   true
    'lastHeadPosition        :   0
    'currentStreamInfo       :   {}
    'pluginInstance          :   invalid
    'connectionTimer         :   CreateObject("roTimespan")

    streamStartTimer        :   invalid 'CreateObject("roTimespan")
    sessionTimer            :   invalid 'CreateObject("roTimespan")
    lastLogTime             :   invalid
    ipAddresses             :   invalid 'CreateObject("roAssociativeArray")
    secondaryLogTimer       :   invalid
    isFirstStreamStartEvent :   true
    lastHeadPosition        :   0
    currentStreamInfo       :   {}
    logger                  :   invalid
    pluginInstance          :   invalid
    connectionTimer         :   invalid 'CreateObject("roTimespan")
    viewerId                :   invalid
    viewerDiagnosticsId     :   invalid
    serverIpLookUpPerformed :   false
    videoPlayer             :   invalid
    customDimensions        :   {}
    configXml               :   beaconUrl
    currentPlayerState      :   0
    isActive                :   true

    setViewerId:function(vId)
        ue = CreateObject("roURLTransfer")
        'encodedOutString = AkaMA_str8859toutf8(vId)
        encodedOutString = ue.Escape(vId)
        print "encoded viewerId = "; encodedOutString
        'm.viewerId = AkaMA_strReplace(encodedOutString," ","%20")
        m.viewerId = encodedOutString
    end function

    setViewerDiagnosticId:function(vdId)
        ue = CreateObject("roURLTransfer")
        'encodedOutString = AkaMA_str8859toutf8(vdId)
        encodedOutString = ue.Escape(vdId)
        print "encoded viewerDiagnosticsId = "; encodedOutString

        'm.viewerDiagnosticsId = AkaMA_strReplace(encodedOutString," ","%20")
        m.viewerDiagnosticsId = encodedOutString

    end function

    setData:function(key, value)
        m.customDimensions[key] = value
    end function

    setCustomDimensions:function(customDimensions, beacon)
        ' xmlObj = initConfigurationXML(beacon)
        ' m.pluginDataStore = AkaMA_createDataStore()
        ' m.pluginDataStore.initializeConfigMediaMetrics(xmlObj)
        ' m.pluginDataStore.addUdpateCustomMetrics(customDimensions)
        print "Roku_maLivrary customDimensions set - " customDimensions
        print "Roku_maLivrary m.pluginInstance - " m.pluginInstance
        print "Roku_maLivrary m.sessionTimer - " m.sessionTimer
        print "Roku_maLivrary m.logger - " m.logger
        print "Roku_maLivrary m.viewerId - " m.viewerId
        print "Roku_maLivrary m.viewerDiagnosticsId - " m.viewerDiagnosticsId

        m.pluginInstance.initializeMAPluginInstance(customDimensions, m.sessionTimer, beacon, m.logger, m.viewerId, m.viewerDiagnosticsId)
    end function

    initialize:function()
        m.adStates = { adLoaded : 1, adStarted : 2, adFirstQuartile : 3, adMidpoint: 4, adThirdQuartile : 5}
        m.playerStates = { init : 1, playStart : 2, playing : 3, pause: 4, rebuffer : 5, error : 6}
        m.resetPluginState()
        m.logger.enableLogging(false)
        m.sessionTimer.Mark()
        pluginGlobals = AkaMA_getPluginGlobals()
        logger = AkaMA_logger()

        if pluginGlobals.uniqueTitles = invalid
            pluginGlobals.uniqueTitles = []
            pluginGlobals.temp = 10
        endif
        if pluginGlobals.isVisitSent = invalid
            pluginGlobals.isVisitSent = false
        endif

        if pluginGlobals.isFirstTitleSent = invalid
            pluginGlobals.isFirstTitleSent = false
        endif

        print "unique titles array created"
        'm.pluginInstance = AkaMAPlugin().createPluginInstance({plugin:1, msgPort:params.msgPort, eventHandler:params.eventHandler, currentItem:params.item})
        m.pluginInstance = AkaMAPlugin().createPluginInstance()
        print "m.pluginInstance - " m.pluginInstance
        ' m.pluginInstance.initializeMAPluginInstance(params.customDimensions, m.sessionTimer, params.configXML, m.logger, m.viewerId, m.viewerDiagnosticsId)
        'm.connectionTimer = CreateObject("roTimespan")
    end function


'        pluginEventHandler:function(msg as object)
'                if m.streamStartTimer <> invalid
'                    if m.streamStartTimer.TotalSeconds() >= m.pluginInstance.logInterval.toint()
'                        m.pluginInstance.handlePeriodicEvent(m.sessionTimer, m.lastHeadPosition)
'                        m.streamStartTimer = invalid
'                        m.streamStartTimer = CreateObject("roTimespan")
'                        m.serverIpLookUpPerformed = false
'                    else if m.streamStartTimer.TotalSeconds() >= (m.pluginInstance.logInterval.toint() - 10) and m.serverIpLookUpPerformed = false
'                        m.serverIpLookUpPerformed = true
'                        m.pluginInstance.performSeverIpLookUp()
'                    endif
'                endif
'                if m.secondaryLogTimer <> invalid
'                    if m.secondaryLogTimer.TotalSeconds() >= m.pluginInstance.secondaryLogInterval.toint()
'                        m.pluginInstance.handlePeriodicEvent(m.sessionTimer, m.lastHeadPosition)
'                        m.secondaryLogTimer = invalid
'                    endif
'                endif
'
'            if msg = invalid then
'                        ' msg is invalid when a timeout occurs
'                        AkaMA_logger().AkaMA_print("Executing initConfigXML")
'             else if msg.isScreenClosed() then
'                    'print "screen closed"
'                    endReasonCode = "ApplicationClosed"
'                    m.pluginInstance.handlePlaybackCompleteEvent(m.sessionTimer, endReasonCode, m.lastHeadPosition)
'                    m.pluginInstance.handleVisit(m.sessionTimer)
'             else if msg.isPartialResult() then
'                print "recieved msg.isPartialResult. Playback Interrupted"
'                endReasonCode = "PlaybackInterrupted"
'                m.pluginInstance.handlePlaybackCompleteEvent(m.sessionTimer, endReasonCode, m.lastHeadPosition)
'             else if msg.isFullResult() then
'                print "recieved msg.isFullResult. Playback completed"
'                endReasonCode = "PlaybackEnded"
'                m.pluginInstance.handlePlaybackCompleteEvent(m.sessionTimer,endReasonCode, m.lastHeadPosition)
'
'                else if m.pluginInstance.getCurrenPlaybackState() = "ad"
'                    print "currently in ad state..."
'                else if type(msg) = "roVideoScreenEvent" or type(msg) = "roVideoPlayerEvent" then
'                        if msg.isStreamStarted() then
'                                print"recieved isStreamStarted"
'                                currentStreamInfo = msg.GetInfo()
'                                AkaMA_PrintAnyAA(2,currentStreamInfo)
'                                print "Playback position = "; msg.GetIndex()
'                                if currentStreamInfo.IsUnderrun = true
'                                    print "Entering into rebuffer mode"
'                                    m.pluginInstance.handleRebufferEvent(m.sessionTimer, m.lastHeadPosition)
'                                endif
'
'                            if m.currentStreamInfo.DoesExist("Url") = false
'                                m.currentStreamInfo.addReplace("Url",currentStreamInfo.Url)
'                            endif
'                            if currentStreamInfo.StreamBitrate <> 0 or currentStreamInfo.StreamBitrate <> invalid
'                                m.currentStreamInfo.addReplace("StreamBitrate", currentStreamInfo.StreamBitrate)
'                            endif
'
''                            m.currentStreamInfo = msg.GetInfo()
'                            m.pluginInstance.updateBitrateInfo(m.currentStreamInfo, m.lastHeadPosition)
'                         else if msg.isStatusMessage() then
'                            print "********* Status message *********:"
'                            aa = msg.GetInfo()
'                            AkaMA_PrintAnyAA(2,aa)
'                            if m.lastHeadPosition > 0 and m.connectionTimer = invalid
'                                if msg.getMessage() = "startup progress"
'                                    m.pluginInstance.handleRebufferEvent(m.sessionTimer, m.lastHeadPosition)
'                                else if msg.getMessage() = "start of play"
'                                    m.pluginInstance.handleRebufferEndEvent(m.sessionTimer, m.lastHeadPosition)
'                                endif
'                            endif
'                            print "received status message = ";msg.getMessage()
'                            print "*********Executed Status message *********:"
'                         else if msg.isPaused()
'                            print"executing paused..."
'                            aa = msg.GetInfo()
'                            AkaMA_PrintAnyAA(2,aa)
'                            m.pluginInstance.handlePlaybackPauseEvent(m.sessionTimer, m.lastHeadPosition)
'                            print"executed paused..."
'                         else if msg.isResumed()
'                            print"executing resumed..."
'                            aa = msg.GetInfo()
'                            AkaMA_PrintAnyAA(2,aa)
'                            m.pluginInstance.handlePlaybackResumeEvent(m.sessionTimer, m.lastHeadPosition)
'                            print"executed resumed..."
'                         else if msg.isPlaybackPosition()
'                            'print "********* Playback Position event *********:"
'                            'handle seek
'                            if m.pluginInstance.getCurrenPlaybackState() = "pause"
'                                if m.lastHeadPosition + 1 > msg.GetIndex()
'                                    print "End of seek back operation..."
'                                else if  m.lastHeadPosition + 1 < msg.GetIndex()
'                                    print "end of seek forward operation..."
'                                endif
'                                m.lastHeadPosition = msg.GetIndex()
'                                'Check if we are getting isStreamStarted before isPlaybackPosition
'                                m.pluginInstance.handlePlaybackSeekEndEvent(m.sessionTimer, m.lastHeadPosition, m.currentStreamInfo)
'                            endif
'
'                            m.lastHeadPosition = msg.GetIndex()
'                            'handle rebuffer
'                            if m.pluginInstance.getCurrenPlaybackState() = "rebuffer"
'                                print"Entering into rebufferEnd state"
'                                m.pluginInstance.handleRebufferEndEvent(m.sessionTimer, m.lastHeadPosition)
'                            endif
'
'                            'handle play start
'                            'print "Playback current Head position = "; m.lastHeadPosition
'                            'if m.lastHeadPosition = 0 and m.connectionTimer <> invalid
'                            if m.connectionTimer <> invalid
'                                bufferTime = m.connectionTimer.TotalMilliseconds()
'                                m.connectionTimer = invalid
'                                m.pluginInstance.populateStreamInfo(m.currentStreamInfo, bufferTime)
'                                m.pluginInstance.handlePlayStartEvent(m.sessionTimer, m.lastHeadPosition)
'                                m.secondaryLogTimer = CreateObject("roTimespan")
'                                m.streamStartTimer = CreateObject("roTimespan")
'                            endif
'
'                            aa = msg.GetInfo()
'                            AkaMA_PrintAnyAA(2,aa)
'                            'print "********* Executed Palyback Position event *********:"
'                         else if msg.isStreamSegmentInfo() then
'                            print "********* streamSegmentInfo *********:"
'                            streamSegmentInfo = msg.GetInfo()
'                            if m.currentStreamInfo.DoesExist("Url") = false
'                                m.currentStreamInfo.addReplace("Url",streamSegmentInfo.Url)
'                            endif
'                            if streamSegmentInfo.StreamBandwidth <> 0 or streamSegmentInfo.StreamBandwidth <> invalid
'                                m.currentStreamInfo.addReplace("StreamBitrate", streamSegmentInfo.StreamBandwidth)
'                            endif
'
'                            m.pluginInstance.updateBitrateInfo(m.currentStreamInfo, m.lastHeadPosition)
'                            AkaMA_PrintAnyAA(2,streamSegmentInfo)
'                            print "*********Executed streamSegmentInfo *********:"
'                         end if
'                 else if type(msg) = "roSystemLogEvent" then
'                        ' Handle the roSystemLogEvents:
'                        i = msg.GetInfo()
'                        if i.LogType = "http.connect" then
'                                url = i.OrigUrl
'                                if (not m.ipAddresses.DoesExist(url)) then
'                                        m.ipAddresses[url] = CreateObject("roAssociativeArray")
'                                end if
'                                m.ipAddresses[url].AddReplace(i.TargetIp,"")
'                                'print "server id = "; i.TargetIp
'                                'metrics.serverId = i.TargetIp
'                        else if i.LogType = "http.error"
'                                'do not increment error count here, if the error is fatal
'                                'it'll terminate the session and will be counted by a videoScreenevent
'                                'but report errors so that we can keep track of the errors
'                                'ReportHttpError API should take extra status param for error status message
'                                'for now just append it to errorCode param
'                                code = i.HttpCode
'                                if code < 200 OR code >= 400 then
'                                        eCode = AkaMA_AnyToString(code)
'                                        eStatus = AkaMA_AnyToString(i.Status)
'                                        if eCode <> invalid and eStatus <> invalid
'                                            errorStatus = "Error code:" + eCode + " Error Status:  " + eStatus
'                                            print "error status = "; errorStatus
'                                         endif
'                                        'ReportHttpErrorEvent(metrics, CreateObject("roDateTime").asSeconds()*1000, errorStatus, i.Url)
'                                        ' report streaming sessions event so error is counted if the user clicks home.
'                                        'ReportStreamingSessionEvent(metrics)
'                                end if
'                        else if i.LogType = "bandwidth.minute"
'                                print "bandwidth is " ; i.Bandwidth * 1000
'                                m.pluginInstance.updateBandwidthInfo(i.Bandwidth * 1000)
'                        end if
'                 end if
'
'        end function

        handleAdLoaded:function(params)
            m.pluginInstance.handleAdLoaded(params)
        end function

        handleAdStarted:function(params)
            m.pluginInstance.handleAdStarted(params)
        end function

        handleAdFirstQuartile:function(params)
            m.pluginInstance.handleAdFirstQuartile(params)
        end function

        handleAdMidpoint:function(params)
            m.pluginInstance.handleAdMidpoint(params)
        end function

        handleAdThirdQuartile:function(params)
            m.pluginInstance.handleAdThirdQuartile(params)
        end function

        handleAdComplete:function(params)
            m.pluginInstance.handleAdComplete(params, 0)
        end function

        handleAdStopped:function(params, lastHeadPosition)
            m.connectionTimer.Mark()
            m.pluginInstance.handleAdStopped(params, lastHeadPosition)
        end function

        handleAdEnd:function(params, lastHeadPosition)
            m.connectionTimer.Mark()
            m.pluginInstance.handleAdEnd(params, lastHeadPosition)
        end function

        handleAdError:function(params, lastHeadPosition)
            m.connectionTimer.Mark()
            m.pluginInstance.handleAdError(params, lastHeadPosition)
        end function

        PlaybackCompleteEventReceived:function()
            endReasonCode = "PlaybackInterrupted"
            m.pluginInstance.handlePlaybackCompleteEvent(m.sessionTimer, endReasonCode, m.lastHeadPosition)
        end function

        'This is not an ideal way to handle title switch.
        '1. Only issue is with configXML. we need to decouple plugin instance and beaconXML parsing
        'This will make sure that we can reuse parsed data
        '2. Another issues is with AddReplace("isFirstTitle","0"). if there are other params that
        'needs to be set / reset then better to expose an API in pluginInstance (plugin controller).
        handleTitleSwitch:function(titleSwitchParams)
            endReasonCode = "Title.Switched"
            m.pluginInstance.handlePlaybackCompleteEvent(m.sessionTimer, endReasonCode, m.lastHeadPosition)
            m.pluginInstance = invalid
            m.pluginInstance = AkaMAPlugin().createPluginInstance()
            titleSwitchParams.customDimensions.AddReplace("isFirstTitle", "0")
            AkaMA_PrintAA(titleSwitchParams)
            m.pluginInstance.initializeMAPluginInstance(titleSwitchParams.customDimensions, m.sessionTimer, titleSwitchParams.configXML, m.logger, m.viewerId, m.viewerDiagnosticsId)
            print "session timer = "; m.sessionTimer
            m.pluginInstance.populateStreamInfo(m.currentStreamInfo, 0)
            m.pluginInstance.handlePlayStartEvent(m.sessionTimer, m.lastHeadPosition)
            m.secondaryLogTimer = CreateObject("roTimespan")
            m.streamStartTimer = CreateObject("roTimespan")
        end function

        setMediaPlayer:function(videoElement, cd, beacon)
           videoPlayer = videoElement
           m.isActive = true
           m.initialize()
           m.customDimensions = cd
           m.configXML = beacon
           m.port = CreateObject("roMessagePort")
           videoPlayer.observeField("state", m.port)
           videoPlayer.observeField("position", m.port)
           videoPlayer.observeField("duration", m.port)
           videoPlayer.observeField("streamInfo", m.port)
           videoPlayer.observeField("errorMsg", m.port)
           videoPlayer.observeField("errorCode", m.port)
           videoPlayer.observeField("streamingSegment", m.port)
'           videoPlayer.observeField("completedStreamInfo", m.port)

           if videoPlayer.state <> "none"
            'Player is already playing a video. Initialize the player
             m.startStreamingSession()
             m.currentPlayerState = m.playerStates.init
           endif

           print "before while - "
           while(m.isActive)
             msg = wait(500, m.port)
             msgType = type(msg)
             m.manageBeaconDispatching()

             if msgType = "roSGNodeEvent" then
                messageType = msg.getField()

                if messageType = "position"
                    streamHeadPos = msg.GetData()
                    m.lastHeadPosition = streamHeadPos
                else if messageType = "state"
                    m.onVideoStateChanged(msg)
                else if messageType = "streamingSegment"
                    segment = msg.GetData()
                    if segment.segBitrateBps <> 0 and m.currentStreamInfo.streamBitrate <> segment.segBitrateBps
                        m.currentStreamInfo = {streamBitrate:segment.segBitrateBps}
                        m.pluginInstance.updateBitrateInfo(m.currentStreamInfo, m.lastHeadPosition)
                    end if
                else if messageType = "duration"
                    streamDuration = str(msg.GetData() * 1000)
                    formatInfo = UCase(videoPlayer.content.streamformat)
                    if "ISM" = formatInfo
                        formatInfo = "MSS"
                    else if "MKA" = formatInfo or "MKV" = formatInfo or "MKS" = formatInfo
                        formatInfo = "P"
                    endif
                    delivery = "-"
                    if videoPlayer.content.Live = true
                        delivery = "L"
                    else
                        delivery = "O"
                    endif
                    streamLengthParam = {streamLength : streamDuration.trim(),format: formatInfo, deliveryType:delivery}
                    m.pluginInstance.updatePlaybackInformation(streamLengthParam)
                else if messageType = "streamInfo"
                    m.currentStreamInfo = msg.GetData()
                    m.pluginInstance.updateBitrateInfo(m.currentStreamInfo, m.lastHeadPosition)
                else if messageType = "errorMsg"
                    PRINT "Error Message : "; msg.GetData()
                else if messageType = "errorCode"
                    errorInfo = msg.GetData()
                    if AkaMA_isstr(errorInfo) = false
                        errorInfo = errorInfo.ToStr()
                    end if
                    m.pluginInstance.handleErrorEvent(m.sessionTimer, errorInfo, m.lastHeadPosition)
                    m.currentPlayerState = m.playerstates.error
                    m.isActive = false
                    PRINT "Error Code : "; msg.GetData()
'                   else if messageType = "completedStreamInfo"
'                       ' Not supported in older firmware. Not implementing it now.
'                       PRINT "data: "; msg.GetData()
                end if
             end if
           end while
           print "after while - "
           'Message loop is done, playback completed. Send out V Beacon
           m.visitEventReceived()
        end function

     onVideoStateChanged:function(msg)
        newState = msg.GetData()
        if newState = "buffering"
           if m.currentPlayerState < m.playerStates.init
               m.startStreamingSession()
               m.currentPlayerState = m.playerStates.init
            else if m.currentPlayerState = m.playerStates.playing
              m.pluginInstance.handleRebufferEvent(m.sessionTimer, m.lastHeadPosition)
              m.currentPlayerState = m.playerstates.rebuffer
            end if
        else if newState = "playing"
            if m.currentPlayerState = m.playerstates.rebuffer
                m.pluginInstance.handleRebufferEndEvent(m.sessionTimer, m.lastHeadPosition)
            else if m.currentPlayerState = m.playerstates.init
                bufferTime = 0
                if m.connectionTimer <> invalid
                   bufferTime = m.connectionTimer.TotalMilliseconds()
                   m.connectionTimer = invalid
                end if
                m.pluginInstance.populateStreamInfo(m.currentStreamInfo, bufferTime)
                m.pluginInstance.handlePlayStartEvent(m.sessionTimer, m.lastHeadPosition)
                m.secondaryLogTimer = CreateObject("roTimespan")
                m.streamStartTimer = CreateObject("roTimespan")
            else
                m.pluginInstance.handlePlaybackResumeEvent(m.sessionTimer, m.lastHeadPosition)
            end if
            m.currentPlayerState = m.playerstates.playing
        else if newState = "finished"
            m.pluginInstance.handlePlaybackCompleteEvent(m.sessionTimer, "Play.End.Detected", m.lastHeadPosition)
            m.currentPlayerState = 0
            m.isActive = false
        else if newState = "stopped"
            m.pluginInstance.handlePlaybackCompleteEvent(m.sessionTimer, "Application.Close", m.lastHeadPosition)
            m.currentPlayerState = 0
            m.isActive = false
        else if newState = "paused"
            m.pluginInstance.handlePlaybackPauseEvent(m.sessionTimer, m.lastHeadPosition)
            m.currentPlayerState = m.playerstates.pause
         end if
    end function

        visitEventReceived:function()
            endReasonCode = "PlaybackInterrupted"
            m.pluginInstance.handleVisit(m.sessionTimer)
        end function

        startStreamingSession:function()
            if m.currentPlayerState = 0
                m.sessionTimer.Mark()
                m.pluginInstance.initializeMAPluginInstance(m.customDimensions, m.sessionTimer, m.configXML, m.logger, m.viewerId, m.viewerDiagnosticsId)
                m.currentPlayerState = m.playerstates.init
            end if
        end function

        manageBeaconDispatching:function()
            if m.streamStartTimer <> invalid
                    if m.streamStartTimer.TotalSeconds() >= m.pluginInstance.logInterval.toint()
                        m.pluginInstance.handlePeriodicEvent(m.sessionTimer, m.lastHeadPosition)
                        m.streamStartTimer = invalid
                        m.streamStartTimer = CreateObject("roTimespan")
                        m.serverIpLookUpPerformed = false
                    else if m.streamStartTimer.TotalSeconds() >= (m.pluginInstance.logInterval.toint() - 10) and m.serverIpLookUpPerformed = false
                        m.serverIpLookUpPerformed = true
                        m.pluginInstance.performSeverIpLookUp()
                    endif
            endif
            if m.secondaryLogTimer <> invalid
                if m.secondaryLogTimer.TotalSeconds() >= m.pluginInstance.secondaryLogInterval.toint()
                    m.pluginInstance.handlePeriodicEvent(m.sessionTimer, m.lastHeadPosition)
                    m.secondaryLogTimer = invalid
                endif
            endif
        end function

        resetPluginState:function()
            m.streamStartTimer        =   invalid'CreateObject("roTimespan")
            m.sessionTimer            =   CreateObject("roTimespan")
            m.lastLogTime             =   invalid
            m.ipAddresses             =   CreateObject("roAssociativeArray")
            m.secondaryLogTimer       =   invalid
            m.isFirstStreamStartEvent =   true
            m.lastHeadPosition        =   0
            m.currentStreamInfo       =   {}
            m.logger                  =   AkaMA_logger()
            m.pluginInstance          =   invalid
            m.connectionTimer         =   CreateObject("roTimespan")
        end function
 }
END FUNCTION

function AkaMA_getPluginGlobals() as object
	if m.AkaMA_pluginGlobals = invalid then m.AkaMA_pluginGlobals={}
	return m.AkaMA_pluginGlobals
end function
'plugin state will be updated here
'State should be updated whenever plugin receives an event
'

function AkaMA_pluginStateStatus()
return {
    BeaconOrders:{
    invalidState        :   &H0000
    initializeState     :   &H0001
    playingState        :   &H0002
    pauseState          :   &H0004
    seekState           :   &H0008
    rebufferState       :   &H0010
    playbackEndState    :   &H0020
    }
}
end function

'Function       :   AkaMA_pluginState
'Params         :   None
'Return         :   Returns data structures and functions for state maintainance
'Description    :   Plugin state object which holds all possible states
'                   for the plugin. In turn each state is an object which
'                   provides supporting functions. This can be called
'                   whenever plugin enters from one state to antoher.
'                   calling syntax should be pluginStateObj.initialize.beginInitialize(mediaMetrics)
FUNCTION AkaMA_pluginState() as object
return {
        initialize          :   invalid
        playing             :   invalid
        pause               :   invalid
        seek                :   invalid
        rebuffering         :   invalid
        playEnd             :   invalid
        ad                  :   invalid
        'notPlaying          :   invalid
        currentState        :   invalid
        isFirstRebuffer     :   true
        streamBitrateInfo   :   {}
        encodedBitrate      :   invalid
        currentBitrate      :   invalid
        bitrateSwitchHeadPosition   :   invalid
        adEnded             :   invalid
        pluginGlobals		: 	invalid

    initPluginStates:function()
        m.initialize    =   initializeState()
        m.playing       =   playingState()
        m.pause         =   pauseState()
        m.seek          =   seekState()
        m.rebuffering   =   rebufferingState()
        m.playEnd       =   playEndState()
        m.ad            =   adState()
        m.adEnded       =   adEndState()
        'm.notPlaying    =   notPlayingState()
    end function

    moveToState: function(state as object, endStateParams as object, beginStateParam as object)
        if m.currentState <> invalid
            if m.currentState.state = state.state
                return AkaMAErrors().ERROR_CODES.AKAM_Success
            endif
            m.currentState.endState(endStateParams)
        end if
        state.beginState(beginStateParam)
        m.currentState = state
    end function

    updateCurrentState:function(params as object)
        if m.currentState <> invalid
            m.currentState.updateState(params)
        endif
    end function


    updateStreamInfo:function(params as object)
        m.playing.updateBitrateInfo(params.headPosition, params.currentStreamInfo.StreamBitrate)
'        if params.currentStreamInfo <> invalid
'            'print "measured bitrate = "; params.currentStreamInfo.StreamBitrate
'            if m.encodedBitrate <> params.currentStreamInfo.StreamBitrate
'                m.bitrateSwitchHeadPosition = params.headPosition*1000
'                m.encodedBitrate = params.currentStreamInfo.StreamBitrate
'
'            print "Stream bitreate = "; params.currentStreamInfo.StreamBitrate
'            if m.streamBitrateInfo.DoesExist(AkaMA_itostr(params.currentStreamInfo.StreamBitrate))
'                bitrates = m.streamBitrateInfo[AkaMA_itostr(params.currentStreamInfo.StreamBitrate)]
'                bitrates.push({streamHeadPos:m.bitrateSwitchHeadPosition, playTimeSpent:m.playing.getPlayTimeSpent()})
'                m.playing.updateBitrate(params.currentStreamInfo.StreamBitrate)
'                'bitrates.push({streamHeadPos:params.headPosition*1000})
'                m.streamBitrateInfo.AddReplace(AkaMA_itostr(params.currentStreamInfo.StreamBitrate), bitrates)
'            else
'                m.streamBitrateInfo.AddReplace(AkaMA_itostr(params.currentStreamInfo.StreamBitrate),[{streamHeadPos:m.bitrateSwitchHeadPosition, playTimeSpent:m.playing.getPlayTimeSpent()}])
'                'm.streamBitrateInfo.AddReplace(AkaMA_itostr(params.currentStreamInfo.StreamBitrate),[{streamHeadPos:params.headPosition*1000}])
'            endif
'            endif
'            'm.encodedBitrate = params.currentStreamInfo.StreamBitrate
'        endif
    end function

    updatePlayTimeSpent:function()
        if m.currentBitrate <> invalid
            curBitrate = m.streamBitrateInfo[m.currentBitrate]
            'curBitrate m.playing.playStreamTime
        endif
    end function

    getStatusMetrics: function(statusMetrics as object)
        if m.playing <> invalid
            m.playing.getStateMetrics(statusMetrics, m.streamBitrateInfo, m.encodedBitrate)
        endif

        if m.ad <> invalid
            m.ad.getStateMetrics(statusMetrics)
        endif

        if m.rebuffering <> invalid
            m.rebuffering.getStateMetrics(statusMetrics, m.currentState, m.isFirstRebuffer)
        endif
'        transitionStreamTimeSessionStr = box("")
'        transitionStreamTimesStr = box("")
'        averagedBitrateNumerator = 0
'        averagedBitrateDenominator = 0
'        for each key in m.streamBitrateInfo
'            bitrates = m.streamBitrateInfo[key]
'            totalPlayTimeSpent = 0
'            for each bitrateKey in bitrates
'                transitionStreamTimeSessionStr.ifstringops.AppendString(key, key.len())
'                transitionStreamTimeSessionStr = transitionStreamTimeSessionStr + ":"
'                transitionStreamTimeSessionStr.ifstringops.AppendString(AkaMA_itostr(bitrateKey.streamHeadPos), AkaMA_itostr(bitrateKey.streamHeadPos).len())
'                transitionStreamTimeSessionStr = transitionStreamTimeSessionStr + ":"
'                transitionStreamTimeSessionStr.ifstringops.AppendString(AkaMA_itostr(bitrateKey.playTimeSpent), AkaMA_itostr(bitrateKey.playTimeSpent).len())
'                transitionStreamTimeSessionStr = transitionStreamTimeSessionStr + ":"
'                transitionStreamTimeSessionStr = transitionStreamTimeSessionStr + ":"
'                transitionStreamTimeSessionStr = transitionStreamTimeSessionStr + ","
'                totalPlayTimeSpent = totalPlayTimeSpent + bitrateKey.playTimeSpent
'            next
'            averagedBitrateNumerator = averagedBitrateNumerator + (strtoi(key)*totalPlayTimeSpent)
'            averagedBitrateDenominator = averagedBitrateDenominator + totalPlayTimeSpent
'            transitionStreamTimesStr.ifstringops.AppendString(key, key.len())
'            transitionStreamTimesStr = transitionStreamTimesStr + ":"
'            transitionStreamTimesStr.ifstringops.AppendString(AkaMA_itostr(totalPlayTimeSpent), AkaMA_itostr(totalPlayTimeSpent).len())
'            transitionStreamTimesStr = transitionStreamTimesStr + ","
'        next
'        if averagedBitrateDenominator <> 0
'            statusMetrics.addUdpateMediaMetrics({averagedBitRate: AkaMA_itostr(averagedBitrateNumerator/averagedBitrateDenominator)})
'        endif
'        statusMetrics.addUdpateMediaMetrics({encodedBitrate:AkaMA_itostr(m.encodedBitrate), transitionStreamTimeSession:transitionStreamTimeSessionStr, transitionStreamTimes:transitionStreamTimesStr})
        'm.notPlaying.getStateMetrics(statusMetrics,m.currentState)
        'pluginStateObject.playing().getStateMetrics(statusMetrics)
    end function

    getCurrentState:function() as string
        return m.currentState.state
    end function

    resetRelativeMetrics : function(statusMetrics as object)
        m.playing.resetStateMetrics(m.streamBitrateInfo)
        m.ad.resetStateMetrics(statusMetrics)
        m.rebuffering.resetStateMetrics(statusMetrics)
        'm.streamBitrateInfo.clear()
    end function

    deinitPluginStates:function()
        m.initialize      =   invalid
        m.playing         =   invalid
        m.pause           =   invalid
        m.seek            =   invalid
        m.rebuffering     =   invalid
        m.playEnd         =   invalid
        m.currentState    =   invalid
        m.ad              =   invalid
    end function
}
END FUNCTION


'Function       :   initializeState
'Params         :   None
'Return         :   Returns data structures and functions for init state
'Description    :   Initialize state which provides support for
'   initialization related metrics
FUNCTION initializeState() as object
return {
    beginState      :   beginInitialize
    updateState     :   updateInitialize
    endState        :   endInitialize
    state           :   "initilize"
    'resetState      :   resetInitialize
}
END FUNCTION

FUNCTION beginInitialize(params as object) as void
    AkaMA_logger().AkaMA_Trace("Executing beginInitialize")
    'shall we add atempt id, clientId and visit id while
    'in begin initialize state?
END FUNCTION

FUNCTION updateInitialize(params as object) as void
    AkaMA_logger().AkaMA_Trace("Executing updateInitialize")
END FUNCTION

FUNCTION endInitialize(params as object) as void
    AkaMA_logger().AkaMA_Trace("Executing endInitialize")
END FUNCTION


'Function       :   playingState
'Params         :   None
'Return         :   Returns data structures and functions for play state
'Description    :   Playing state which provides support for play related metrics
FUNCTION playingState() as object
return {
    beginState                  :   beginPlaying
    updateState                 :   updatePlaying
    endState                    :   endPlaying
    getStateMetrics             :   getCurrentStateOfMetrics
    resetStateMetrics           :   resetPlayStateMetrics
    getPlayTimeSpent            :   getCurrentPlayTimeSpent
    updateBitrateInfo           :   updatePlayBitrateInfo
    playClockTime               :   0
    playStreamTime              :   0
    playTimer                   :   invalid
    totalPlayClockTime          :   0
    totalPlayStreamTime         :   0
    isViewSent                  :   false
    state                       :   "playing"
    prevHeadPosition            :   0
    currentBitrate              :   0
    bitratePalyTime             :   0
    bitratePalyTimer            :   invalid
    bitrateInfo                 :   {}
    bitrateSwitchHeadPosition   :   0
    pluginGlobals               :   AkaMA_getPluginGlobals()
    'isValid                    :   false
}
END FUNCTION

FUNCTION beginPlaying(params as object) as void
    print "Executing beginPlaying"
    AkaMA_logger().AkaMA_Trace("Executing beginPlaying")
    m.playTimer = CreateObject("roTimespan")
    m.bitratePalyTimer = CreateObject("roTimespan")
    'm.playStreamTime = params.headPosition * 1000
    if m.prevHeadPosition > 0
        m.prevHeadPosition = params.headPosition * 1000
    endif
    m.isValid = true
END FUNCTION

FUNCTION updatePlaying(params as object) as void
    AkaMA_logger().AkaMA_Trace("Executing updatePlaying")
    print"executing updatePlaying and headPosition= ";params.headPosition
    m.playClockTime = m.playClockTime + m.playTimer.TotalMilliseconds()
    m.totalPlayClockTime = m.totalPlayClockTime + m.playTimer.TotalMilliseconds()
    print "current clock time = ";m.playClockTime;" and playStreamTime value before update = "; m.playStreamTime
    m.playStreamTime = m.playStreamTime + params.headPosition * 1000 - m.prevHeadPosition'(params.headPosition * 1000) - m.playStreamTime
    m.prevHeadPosition = params.headPosition * 1000
    print "playStreamTime value after update ="; m.playStreamTime
    m.totalPlayStreamTime = m.totalPlayStreamTime + m.playStreamTime
    m.bitratePalyTime = m.bitratePalyTime + m.bitratePalyTimer.TotalMilliseconds()
END FUNCTION

function updatePlayBitrateInfo(headPosition, currBitrate)
    if m.bitratePalyTimer <> invalid and m.currentBitrate <> currBitrate and currBitrate > 0
        m.bitratePalyTime = m.bitratePalyTime + m.bitratePalyTimer.TotalMilliseconds()

        if m.bitrateInfo.DoesExist(AkaMA_itostr(currBitrate))
            bitrates = m.bitrateInfo[AkaMA_itostr(currBitrate)]
            bitrates.push({streamHeadPos:headPosition, playTimeSpent:m.bitratePalyTime})
            m.bitrateInfo.AddReplace(AkaMA_itostr(currBitrate), bitrates)
        else
            m.bitrateInfo.AddReplace(AkaMA_itostr(m.currentBitrate),[{streamHeadPos:m.bitrateSwitchHeadPosition, playTimeSpent:m.bitratePalyTime}])
            'm.streamBitrateInfo.AddReplace(AkaMA_itostr(params.currentStreamInfo.StreamBitrate),[{streamHeadPos:params.headPosition*1000}])
        endif

        m.currentBitrate = currBitrate
        m.bitrateSwitchHeadPosition = headPosition*1000
        m.bitratePalyTime = 0
        m.bitrateInfo.AddReplace(AkaMA_itostr(m.currentBitrate),[{streamHeadPos:m.bitrateSwitchHeadPosition, playTimeSpent:0}])
        'bitrateInfo.addReplace(AkaMA_itostr(currBitrate), {})
        m.bitratePalyTimer.Mark()
    endif
end function

function getCurrentPlayTimeSpent() as integer
    if m.playTimer <> invalid
        print "get current play timer = "; m.playTimer.TotalMilliseconds()
        curTimeSpent = m.playClockTime + m.playTimer.TotalMilliseconds()
        print "curTimeSpent = "; curTimeSpent
        return curTimeSpent
    else
        return 0
    endif
end function

FUNCTION endPlaying(params as object) as void
    AkaMA_logger().AkaMA_Trace("Executing endPlaying")
    m.playClockTime = m.playClockTime + m.playTimer.TotalMilliseconds()
    m.totalPlayClockTime = m.totalPlayClockTime + m.playTimer.TotalMilliseconds()
    m.playStreamTime =  m.playStreamTime + params.headPosition * 1000 - m.prevHeadPosition
    m.prevHeadPosition = params.headPosition * 1000
    m.totalPlayStreamTime = m.totalPlayStreamTime + m.playStreamTime
    m.bitratePalyTime = m.bitratePalyTime + m.bitratePalyTimer.TotalMilliseconds()
    'print "endPlaying : playStreamTime value before update ="; m.playStreamTime
    'm.playStreamTime =  params.headPosition * 1000 - m.playStreamTime
    'print "endPlaying : playStreamTime value after update ="; m.playStreamTime
    'm.totalPlayStreamTime = m.totalPlayStreamTime + m.playStreamTime

    'm.totalPlayStreamTime = m.totalPlayStreamTime + m.playStreamTime
    m.playerTimer = invalid
END FUNCTION

function getCurrentStateOfMetrics(metrics as object, streamInfo as object, encdBitrate) as integer
    'metrics.addUdpateMediaMetrics("playClockTime",AkaMA_itostr(m.playClockTime))
    'if m.isValid = false
     '   return AkaMAErrors().ERROR_CODES.AKAM_StateIsNotValid
    'endif

    metrics.addUdpateMediaMetrics({playClockTime:AkaMA_itostr(m.playClockTime), totalPlayClockTime: AkaMA_itostr(m.totalPlayClockTime),
                                    playStreamTime:AkaMA_itostr(m.playStreamTime), totalPlayStreamTime:AkaMA_itostr(m.totalPlayStreamTime),
                                    'encodedBitRate:m.streamBitrate})
                                    'encodedBitRate:AkaMA_itostr(encdBitrate)})
                                    encodedBitRate:AkaMA_itostr(m.currentBitrate)})

    if m.isViewSent = false
        if (m.totalPlayClockTime / 1000) >= 5
            print "isView not sent let's send it"
            metrics.addUdpateMediaMetrics({isView:"1"})
            m.isViewSent = true
        endif
    else
        'if metrics.DoesExist("isView")
            print "isView key is exist let's remove it"
            metrics.deleteIfExist("isView")
        'endif
    endif

    if m.pluginGlobals.isFirstTitleSent = false
    	metrics.addUdpateMediaMetrics({isFirstTitle:"1"})
    	m.pluginGlobals.isFirstTitleSent = true
    else
    	print "isFirstTitle key is exist"
    	'metrics.deleteIfExist("isFirstTitle")
    endif
    print "current clock time in getCurrentStateOfMetrics = "; m.playClockTime; "totalPlayClocktime = "; (m.totalPlayClockTime/1000) "s"

    transitionStreamTimeSessionStr = box("")
    transitionStreamTimesStr = box("")
    averagedBitrateNumerator# = 0.0
    averagedBitrateDenominator# = 0.0
    for each key in m.bitrateInfo
        bitrates = m.bitrateInfo[key]
        totalPlayTimeSpent# = 0.0
        if key <> "0"
        for each bitrateKey in bitrates
            transitionStreamTimeSessionStr.ifstringops.AppendString(key, key.len())
            transitionStreamTimeSessionStr = transitionStreamTimeSessionStr + ":"
            transitionStreamTimeSessionStr.ifstringops.AppendString(AkaMA_itostr(bitrateKey.streamHeadPos), AkaMA_itostr(bitrateKey.streamHeadPos).len())
            transitionStreamTimeSessionStr = transitionStreamTimeSessionStr + ":"
            if key = AkaMA_itostr(m.currentBitrate)
                transitionStreamTimeSessionStr.ifstringops.AppendString(AkaMA_itostr(m.bitratePalyTime), AkaMA_itostr(m.bitratePalyTime).len())
            else
                transitionStreamTimeSessionStr.ifstringops.AppendString(AkaMA_itostr(bitrateKey.playTimeSpent), AkaMA_itostr(bitrateKey.playTimeSpent).len())
            endif
            transitionStreamTimeSessionStr = transitionStreamTimeSessionStr + ":"
            transitionStreamTimeSessionStr = transitionStreamTimeSessionStr + ":"
            transitionStreamTimeSessionStr = transitionStreamTimeSessionStr + ","
            if key = AkaMA_itostr(m.currentBitrate)
                totalPlayTimeSpent# = totalPlayTimeSpent# + m.bitratePalyTime
                print "totalPlayTimeSpent in getCurrentStateOfMetrics (currentBitrate) =" ; totalPlayTimeSpent#
            else
                totalPlayTimeSpent# = totalPlayTimeSpent# + bitrateKey.playTimeSpent
                print "totalPlayTimeSpent in getCurrentStateOfMetrics =" ; totalPlayTimeSpent#
            endif
        next
        averagedBitrateNumerator# = averagedBitrateNumerator# + (1.0 * strtoi(key)*totalPlayTimeSpent#)
        averagedBitrateDenominator# = averagedBitrateDenominator# + totalPlayTimeSpent#
        print "averagedBitrateNumerator =" ; averagedBitrateNumerator#; " and averagedBitrateDenominator = "; averagedBitrateDenominator#
        transitionStreamTimesStr.ifstringops.AppendString(key, key.len())
        transitionStreamTimesStr = transitionStreamTimesStr + ":"
        transitionStreamTimesStr.ifstringops.AppendString(Str(totalPlayTimeSpent#).Trim(), Str(totalPlayTimeSpent#).Trim().len())
        transitionStreamTimesStr = transitionStreamTimesStr + ","
        endif
    next
    if averagedBitrateDenominator# <> 0.0
        print "averagedBitrateNumerator =" ; averagedBitrateNumerator#; " and averagedBitrateDenominator = "; averagedBitrateDenominator#; "and averagedBitRate = "; (averagedBitrateNumerator#/averagedBitrateDenominator#)
        averagedBitrate = box("")
        'averagedBitrate.ifstringops.AppendString(Str(averagedBitrateNumerator#).Trim(),Str(averagedBitrateNumerator#).Trim().len())
        'print"averaged bitrate Numerator = "; averagedBitrateNumerator#.tostr().Trim()
        'print "Averaged bitrate numerator using doubletostring ="; AkaMA_doubleToString(averagedBitrateNumerator#)
        avgBitrateNumeratorString = AkaMA_doubleToStr(averagedBitrateNumerator# / 1000)
        avgBitrateNumeratorString = avgBitrateNumeratorString + "000"
        print "Averaged bitrate numerator using doubletostring =";avgBitrateNumeratorString
        averagedBitrate.ifstringops.AppendString(avgBitrateNumeratorString, avgBitrateNumeratorString.len())
        avgBitrateNumeratorString = invalid
        averagedBitrate = averagedBitrate + ":"
        averagedBitrate.ifstringops.AppendString(Str(averagedBitrateDenominator#).Trim(),Str(averagedBitrateDenominator#).Trim().len())
        'metrics.addUdpateMediaMetrics({averagedBitRate: AkaMA_itostr(averagedBitrateNumerator#/averagedBitrateDenominator#)})
        metrics.addUdpateMediaMetrics({averagedBitRate: averagedBitrate})
    endif
    'transitionStreamTimeSessionStr.Left(Len(transitionStreamTimeSessionStr)-1)
    'transitionStreamTimesStr.Left(Len(transitionStreamTimesStr)-1)
    'metrics.addUdpateMediaMetrics({encodedBitrate:AkaMA_itostr(m.encodedBitrate), transitionStreamTimeSession:transitionStreamTimeSessionStr, transitionStreamTimes:transitionStreamTimesStr})
    metrics.addUdpateMediaMetrics({transitionStreamTimeSession:transitionStreamTimeSessionStr.Left(Len(transitionStreamTimeSessionStr)-1),
                                transitionStreamTimes:transitionStreamTimesStr.Left(Len(transitionStreamTimesStr)-1)})

    'metrics.AddReplace("playStreamTime",playStreamTime)
end function

function resetPlayStateMetrics(streamInfo) as integer
    print "resetting play state metrics..."
    m.playClockTime = 0
    m.playStreamTime = 0
    m.bitratePalyTime = 0
    m.playTimer.Mark()
    m.bitratePalyTimer.Mark()
    m.bitrateInfo.clear()
    'streamInfo.clear()
    m.bitrateInfo.AddReplace(AkaMA_itostr(m.currentBitrate),[{streamHeadPos:m.bitrateSwitchHeadPosition, playTimeSpent:m.bitratePalyTime}])
end function

'Function       :   pauseState
'Params         :   None
'Return         :   Returns data structures and functions for Pause state
'Description    :   Pause state which provides support for pause relate metrics
FUNCTION pauseState() as object
return{
    beginState    :   beginPause
    updateState   :   updatePause
    endState      :   endPause
    state         :   "pause"
}
END FUNCTION

FUNCTION beginPause(params as object) as void
    AkaMA_logger().AkaMA_Trace("Executing beginPause")
END FUNCTION

FUNCTION updatePause(params as object) as void
    AkaMA_logger().AkaMA_Trace("Executing updatePause")
END FUNCTION

FUNCTION endPause(params as object ) as void
    AkaMA_logger().AkaMA_Trace("Executing endPause")
END FUNCTION

'Function       :   seekState
'Params         :   None
'Return         :   Returns data structures and functions for seek state
'Description    :   Seek state which provide support for seek related metrics
FUNCTION seekState() as object
return{
    beginState    :   beginSeek
    updateState   :   updateSeek
    endState      :   endSeek
    state         :   "seek"
}
END FUNCTION

FUNCTION beginSeek(params as object) as void
    AkaMA_logger().AkaMA_Trace("Executing beginSeek")
END FUNCTION

FUNCTION updateSeek(params as object ) as void
    AkaMA_logger().AkaMA_Trace("Executing updateSeek")
END FUNCTION

FUNCTION endSeek(params as object ) as void
    AkaMA_logger().AkaMA_Trace("Executing endSeek")
END FUNCTION

'Function       :   rebufferingState
'Params         :   None
'Return         :   Returns data structures and functions for rebuffer state
'Description    :   Rebuffering state which provides rebuffer related metrics
FUNCTION rebufferingState() as object
return{
    beginState              :   beginRebuffering
    updateState             :   updateRebuffering
    endState                :   endRebuffering
    state                   :   "rebuffer"
    getStateMetrics         :   getCurrentStateOfRebufferMetrics
    resetStateMetrics       :   resetRebufferMetrics

    rebufferCount           :   0
    rebufferDuration        :   0
    rebufferSession         :   invalid
    endOfLastRebuffer       :   0
    startOfRebuffer         :   0
    rebufferTimer           :   invalid
    isContinuesRebuffering  :   false
    rebufferDiff            :   0
    totalRebufferTime       :   0
    rebufferStartTime       :   invalid
    isValid                 :   false
    isFirstRebuffer         :   true
    totalRebufferCount      :   0
    rebufferSessions        :   invalid

}
END FUNCTION

FUNCTION beginRebuffering(params as object ) as void
    AkaMA_logger().AkaMA_Trace("Executing beginRebuffering")
    m.startOfRebuffer = params.rebufferStart
    m.rebufferCount = m.rebufferCount + 1
    m.totalRebufferCount = m.totalRebufferCount + 1
    m.rebufferTimer = CreateObject("roTimespan")
    if m.endOfLastRebuffer <> invalid
        print "start of first rebuffer =";m.startOfRebuffer; " end of last rebuffer = ";m.endOfLastRebuffer;" and diff = ";m.rebufferDiff
        m.rebufferDiff = m.startOfRebuffer - m.endOfLastRebuffer
    endif
    m.rebufferStartTime = params.currentLogTime
    m.isValid = true
END FUNCTION

FUNCTION updateRebuffering(params as object ) as void
    AkaMA_logger().AkaMA_Trace("Executing updateRebuffering")
END FUNCTION

FUNCTION endRebuffering(params as object ) as void
    AkaMA_logger().AkaMA_Trace("Executing endRebuffering")
    m.endOfLastRebuffer = params.rebufferEnd
    m.rebufferDuration = m.rebufferDuration + m.rebufferTimer.TotalMilliseconds()
    m.totalRebufferTime = m.totalRebufferTime + m.rebufferDuration
    if m.rebufferSessions = invalid
        m.rebufferSessions = box("")
    endif
    m.rebufferSessions.ifstringops.AppendString(AkaMA_itostr(m.rebufferStartTime), AkaMA_itostr(m.rebufferStartTime).len())
    m.rebufferSessions = m.rebufferSessions + ":"
    m.rebufferSessions.ifstringops.AppendString(AkaMA_itostr(m.rebufferDuration), AkaMA_itostr(m.rebufferDuration).len())
    m.rebufferSessions = m.rebufferSessions + ";"
END FUNCTION

function getCurrentStateOfRebufferMetrics(metrics as object, currentState as object, isFirstRebuffer) as integer
    if m.isValid = false
        return AkaMAErrors().ERROR_CODES.AKAM_StateIsNotValid
    endif
    metrics.deleteIfExist("isSessionWithRebuffer")
    rebufferSessionString = box("")
    if m.isContinuesRebuffering = true
        rebufferSessionString = rebufferSessionString + "1"
    else
        rebufferSessionString = rebufferSessionString + "0"
    endif
    print "set continuesRebuffering..."
    rebufferSessionString = rebufferSessionString + ":"
    if m.isFirstRebuffer = true
        rebufferSessionString = rebufferSessionString + "-1"
        metrics.addUdpateMediaMetrics({isSessionWithRebuffer:"1"})
        m.isFirstRebuffer = false
        print "First rebuffer"
    else
        rebufferSessionString.ifstringops.AppendString(AkaMA_itostr(m.rebufferDiff), AkaMA_itostr(m.rebufferDiff).len())
    endif
    rebufferSessionString = rebufferSessionString + ";"
    'rebufferSessionString.ifstringops.AppendString(AkaMA_itostr(m.rebufferStartTime), AkaMA_itostr(m.rebufferStartTime).len())
    'rebufferSessionString = rebufferSessionString + ":"
    print "rebufferSession string = "; rebufferSessionString

    if currentState.state = "rebuffer"
        m.rebufferDuration = m.rebufferTimer.TotalMilliseconds()
        m.totalRebufferTime = m.totalRebufferTime + m.rebufferDuration
        'rebufferSessionString.ifstringops.AppendString(AkaMA_itostr(m.rebufferDuration), AkaMA_itostr(m.rebufferDuration).len())
        rebufferSessionString.ifstringops.AppendString(AkaMA_itostr(m.rebufferStartTime), AkaMA_itostr(m.rebufferStartTime).len())
        rebufferSessionString = rebufferSessionString + ":"
        rebufferSessionString.ifstringops.AppendString(AkaMA_itostr(m.rebufferDuration), AkaMA_itostr(m.rebufferDuration).len())
        rebufferSessionString = rebufferSessionString + ";"
        'rebufferSessionString.ifstringops.AppendString(rebufferSessions, rebufferSessions.len())
        m.isContinuesRebuffering = true
        m.rebufferTimer.Mark()
        print"current state is rebuffer"
    else
        'rebufferSessionString.ifstringops.AppendString(AkaMA_itostr(m.rebufferDuration), AkaMA_itostr(m.rebufferDuration).len())
        print "rebufferSessions for current line = "; m.rebufferSessions
        rebufferSessionString.ifstringops.AppendString(m.rebufferSessions, m.rebufferSessions.len())
        m.isContinuesRebuffering = false
        print"current state is NOT rebuffer"
    endif
    metrics.addUdpateMediaMetrics({rebufferSession:rebufferSessionString, rebufferCount:AkaMA_itostr(m.rebufferCount),
                                    rebufferTime:AkaMA_itostr(m.rebufferDuration), totalRebufferTime:AkaMA_itostr(m.totalRebufferTime),
                                    totalRebufferCount:AkaMA_itostr(m.totalRebufferCount)})
    print"rebufferSession string = ";rebufferSessionString
end function

function resetRebufferMetrics(statusMetrics as object) as integer
    m.rebufferCount           =   0
    m.rebufferDuration        =   0
    m.rebufferSession         =   invalid
    m.rebufferSessions        =   invalid
    m.rebufferStartTime       =   0
    m.startOfRebuffer         =   0
    if m.rebufferTimer <> invalid
        m.rebufferTimer.Mark()
    endif
    m.rebufferDiff            =   0
    if m.isContinuesRebuffering <> true
        m.isValid                 =   false
     endif
     if statusMetrics <> invalid
        statusMetrics.deleteIfExist("rebufferSession")
        statusMetrics.deleteIfExist("rebufferCount")
        statusMetrics.deleteIfExist("rebufferTime")
    endif
end function


'Function       :   playEndState
'Params         :   None
'Return         :   Returns data structures and functions for playend state
'Description    :   Playend state which provides play end related metrics
FUNCTION playEndState() as object
return{
    beginState    :   beginPlayEnd
    updateState   :   updatePlayEnd
    endState      :   endPlayEnd
    state         :   "playEnd"
}
END FUNCTION

FUNCTION beginPlayEnd(params as object ) as void
    AkaMA_logger().AkaMA_Trace("Executing beginPlayEnd")
END FUNCTION

FUNCTION updatePlayEnd(params as object ) as void
    AkaMA_logger().AkaMA_Trace("Executing updatePlayEnd")
END FUNCTION

FUNCTION endPlayEnd(dataStore as object) as void
    AkaMA_logger().AkaMA_Trace("Executing endPlayEnd")
END FUNCTION

'Function       :   adState
'Params         :   None
'Return         :   Returns data structures and functions for ad state
'Description    :   Playing state which provides support for play related metrics
FUNCTION adState() as object
return {
    beginState              :   beginAd
    updateState             :   updateAd
    endState                :   endAd
    getStateMetrics         :   getCurrentStateOfAdMetrics
    resetStateMetrics       :   resetAdStateMetrics
    adMetrics               :   {}
    adStartUpTime           :   0
    adStartupTimer          :   invalid
    adPlayTimer             :   invalid
    adPlayTime              :   0
    adPlayBucket            :   0
    adEndStatus             :   invalid
    isAdSessionValid        :   false
    state                   :   "ad"
}
'return AdState
END FUNCTION

FUNCTION beginAd(adParams as object) as void
    print "Executing beginAd"
    AkaMA_logger().AkaMA_Trace("Executing beginAd")
    m.adStartupTimer = CreateObject("roTimespan")
    for each key in adParams
        m.adMetrics.AddReplace(key, adParams[key])
    next
    m.adPlayBucket = -1
    m.isAdSessionValid = true
END FUNCTION

FUNCTION updateAd(adParams as object) as void
    AkaMA_logger().AkaMA_Trace("Executing updateAd")
    if adParams.AkaMA_updateEvent = "adStarUp"
        m.adStartUpTime = m.adStartupTimer.TotalMilliseconds()
        m.adStartupTimer = invalid
        m.adPlayTimer = CreateObject("roTimespan")
        m.adPlayBucket = 0
    else if adParams.AkaMA_updateEvent = "adFirstQuartile"
        m.adPlayBucket = 1
    else if adParams.AkaMA_updateEvent = "adMidPoint"
        m.adPlayBucket = 2
    else if adParams.AkaMA_updateEvent = "adThirdQuartile"
        m.adPlayBucket = 3
    else if adParams.AkaMA_updateEvent = "adComplete"
        m.adPlayBucket = 4
        m.adEndStatus = 0
    else if adParams.AkaMA_updateEvent = "adEnded"
        m.adEndStatus = adParams.endReason
    else if adParams.AkaMA_updateEvent = "adStopped"
        m.adEndStatus = 2
    else if adParams.AkaMA_updateEvent = "adError"
        m.adEndStatus = 3
    endif

    if adParams.DoesExist("AkaMA_updateEvent")
        adParams.Delete("AkaMA_updateEvent")
    endif

    for each key in adParams
        m.adMetrics.AddReplace(key, adParams[key])
    next

END FUNCTION

FUNCTION endAd(params as object) as void
    AkaMA_logger().AkaMA_Trace("Executing endAd")
    if m.adPlayTimer <> invalid
        m.adPlayTime = m.adPlayTimer.TotalMilliseconds()
    endif
END FUNCTION

function getCurrentStateOfAdMetrics(metrics as object) as integer
    if m.isAdSessionValid = false or m.adMetrics = invalid
        return AkaMAErrors().ERROR_CODES.AKAM_Success
    endif

    metrics.addUdpateMediaMetrics(m.adMetrics)
    m.adMetrics.AddReplace("adStartUpTime", AkaMA_itostr(m.adStartUpTime))
    m.adMetrics.AddReplace("PlayTime", AkaMA_itostr(m.adPlayTime))
    m.adMetrics.AddReplace("playBucket", AkaMA_itostr(m.adPlayBucket))
    if m.adEndStatus <> invalid
        m.adMetrics.AddReplace("endStatus", m.adEndStatus)
    endif

    adSessionData = box("")
    adSessionData.ifstringops.AppendString(m.adMetrics.adId, m.adMetrics.adId.len())
    adSessionData = adSessionData + ":"

    if m.adMetrics.adType = "pre-roll"
        adSessionData = adSessionData + "0"
    else if "mid-roll"
        adSessionData = adSessionData + "1"
    else if "post-roll"
        adSessionData = adSessionData + "2"
    endif
    'adSessionData.ifstringops.AppendString(m.adMetrics.adType, m.adMetrics.adType.len())
    adSessionData = adSessionData + ":"

    adSessionData.ifstringops.AppendString(AkaMA_AnyToString(m.adMetrics.startPos), AkaMA_AnyToString(m.adMetrics.startPos).len())
    adSessionData = adSessionData + ":"

    adSessionData.ifstringops.AppendString(AkaMA_itostr(m.adStartUpTime), AkaMA_itostr(m.adStartUpTime).len())
    adSessionData = adSessionData + ":"

    adSessionData.ifstringops.AppendString(AkaMA_itostr(m.adPlayTime), AkaMA_itostr(m.adPlayTime).len())
    adSessionData = adSessionData + ":"

    adSessionData.ifstringops.AppendString(AkaMA_itostr(m.adPlayBucket), AkaMA_itostr(m.adPlayBucket).len())
    adSessionData = adSessionData + ":"

    if m.adEndStatus <> invalid
        adSessionData.ifstringops.AppendString(AkaMA_itostr(m.adEndStatus), AkaMA_itostr(m.adEndStatus).len())
    endif
    adSessionData = adSessionData + ":"

    if  m.adMetrics.DoesExist("adDuration")
        adSessionData.ifstringops.AppendString(m.adMetrics.adDuration, m.adMetrics.adDuration.len())
    endif
    adSessionData = adSessionData + ":"

    if  m.adMetrics.DoesExist("adTitle")
        adSessionData.ifstringops.AppendString(m.adMetrics.adTitle, m.adMetrics.adTitle.len())
    Endif
    adSessionData = adSessionData + ":"

    if  m.adMetrics.DoesExist("adCategory")
        adSessionData.ifstringops.AppendString(m.adMetrics.adCategory, m.adMetrics.adCategory.len())
    endif
    adSessionData = adSessionData + ":"

    if  m.adMetrics.DoesExist("adPartnerID")
        adSessionData.ifstringops.AppendString(m.adMetrics.adPartnerID, m.adMetrics.adPartnerID.len())
    endif
    adSessionData = adSessionData + ":"

    if  m.adMetrics.DoesExist("adServer")
        adSessionData.ifstringops.AppendString(m.adMetrics.adServer, m.adMetrics.adServer.len())
    endif
    adSessionData = adSessionData + ":"

    if  m.adMetrics.DoesExist("adDayPart")
        adSessionData.ifstringops.AppendString(m.adMetrics.adDayPart, m.adMetrics.adDayPart.len())
    endif
    adSessionData = adSessionData + ":"

    if  m.adMetrics.DoesExist("adIndustryCategory")
        adSessionData.ifstringops.AppendString(m.adMetrics.adIndustryCategory, m.adMetrics.adIndustryCategory.len())
    endif
    adSessionData = adSessionData + ":"

    if  m.adMetrics.DoesExist("adEvent")
        adSessionData.ifstringops.AppendString(m.adMetrics.adEvent, m.adMetrics.adEvent.len())
    endif
    'adSessionData = adSessionData + ":"


'    for each key in m.adMetrics
'        if m.adMetrics[key] <> invalid
'            adSessionData.ifstringops.AppendString(m.adMetrics[key], m.adMetrics[key].len())
'            adSessionData = adSessionData + ":"
'        endif
'    next

    if metrics.DoesExist("adSession")
        newAdSessionData = box("")
        existingAdSessionData = metrics[adSession]
        newAdSessionData.ifstringops.AppendString(existingAdSessionData, existingAdSessionData.Len())
        newAdSessionData = newAdSessionData + ","
        newAdSessionData.ifstringops.AppendString(adSessionData, adSessionData.Len())
        metrics.addUdpateMediaMetrics({adSession: newAdSessionData})
    else
        metrics.addUdpateMediaMetrics({adSession: adSessionData})
    endif

end function

function resetAdStateMetrics(statusMetrics as object) as integer
    if m.isAdSessionValid = false
        return AkaMAErrors().ERROR_CODES.AKAM_Success
    endif
    m.adStartUpTime           =   invalid
    m.adStartupTimer          =   invalid
    m.adPlayTimer             =   invalid
    m.adPlayTime              =   invalid
    m.adPlayBucket            =   invalid
    m.adEndStatus             =   invalid
    m.isAdSessionValid        =   false
    if statusMetrics <> invalid
        statusMetrics.deleteIfExist("adSession")
    endif
end function

FUNCTION adEndState() as object
return{
    beginState    :   beginAdEndState
    updateState   :   updateAdEndState
    endState      :   endAdEndState
    state         :   "adEndState"
}
'return seekState
END FUNCTION

FUNCTION beginAdEndState(params as object) as void
    AkaMA_logger().AkaMA_Trace("Executing AdEndState")
END FUNCTION

FUNCTION updateAdEndState(params as object ) as void
    AkaMA_logger().AkaMA_Trace("Executing AdEndState")
END FUNCTION

FUNCTION endAdEndState(params as object ) as void
    AkaMA_logger().AkaMA_Trace("Executing AdEndState")
END FUNCTION

'Beacon system will handle operations related to sending a beacons

'Function       :   AkaMA_isBeaconInOrder
'Params         :   None.
'Return         :   Returns BeaconOrders which defines valid order for the beacons
'Description    :   Use this as a reference for beacon order
function AkaMA_isBeaconInOrder()
return {
    BeaconReported:{
    iLineReported   :   &H0001
    sLineReported   :   &H0002
    pLineReported   :   &H0004
    cLineReported   :   &H0008
    eLineReported   :   &H0010
    vLineReported   :   &H0020
    }
}
end function


'Function       :   AkaMA_MABeacons
'Params         :   None.
'Return         :   Returns function sendBeacon to send beacon
'Description    :   Use this while sending beacons
function AkaMA_MABeacons()
return {
    'Function       :   sendBeacon
    'Params         :   iBeacon. string with complete URL which will be sent to
    '                   back end
    'Return         :   Returns an error code if failed else success
    'Description    :   Send's I-Line and sets beacon status to iLineSent
    '                   Which maintains the status of the beacon system
    '                   this can be used to check if it is right time to send
    '                   a particular beacon
    sendBeacon : function(beacon as string) as integer
        beaconRequest = AkaMA_NewHttp(beacon)
        if (beaconRequest.Http.AsyncGetToString())
            event = wait(0, beaconRequest.Http.GetPort())
            if type(event) = "roUrlEvent"
                str = event.GetString()
                'print "Returned string = ";str
                if event.getResponseCode() <> 200
                    print "Http Request failed"
                    return AkaMAErrors().ERROR_CODES.AKAM_beacon_request_failed
                else if event.getResponseCode() = 200
                    print "Beacon sent successfully!!!"
                endif
            else if event = invalid
                beaconRequest.Http.AsyncCancel()
                ' reset the connection on timeouts
            else
                print "roUrlTransfer::AsyncGetToString(): unknown event"
            endif
        endif
        return AkaMAErrors().ERROR_CODES.AKAM_Success
    end function

}
end function' ConfigParser - utility functions to parse plugin configuration
' file

'******************************************************
' Returns plugin configuration object
' This holds parsed configuration xml
'
'******************************************************
FUNCTION getPluginConfig() as object
    configObject = {
        pluginConfig    :   pluginConfigObject
        }
    return configObject
END FUNCTION

'******************************************************
' Holds different components of configuration xml
' as an object
'******************************************************
FUNCTION pluginConfigObject () as object
    configComponents = {
        configCommon    :   configCommonComponent
        configInit      :   configInitComponent
        configPlayStart :   configPlayStartComponent
        configPlaying   :   configPlayingComponent
        configComplete  :   configCompleteComponent
        configVisit     :   configVisitComponent
        configHeartBeat :   configHeartBeatComponent
        configError     :   configErrorComponent
    }
    return configComponents
END FUNCTION

FUNCTION configCommonComponent () as void
    commonComponent = {
        setCommonComponent  :   function(val):m.commonArray=val:end function
        getCommonComponent  :   function():return m.commonArray:end function
        commonArray : CreateObject("roAssociativeArray")
    }
END FUNCTION

FUNCTION configInitComponent () as void
    initComponent = {
        setInitComponent  :   function(val):m.initArray=val:end function
        getInitComponent  :   function():return m.initArray:end function
        initArray : CreateObject("roAssociativeArray")
    }
END FUNCTION

FUNCTION configPlayStartComponent () as void
    playStartComponent = {
        setPlayStartComponent  :   function(val):m.playStartArray=val:end function
        getPlayStartComponent  :   function():return m.playStartArray:end function
        playStartArray : CreateObject("roAssociativeArray")
    }
END FUNCTION


FUNCTION configPlayingComponent () as void
    playingComponent = {
        setplayingComponent  :   function(val):m.playingArray=val:end function
        getplayingComponent  :   function():return m.playingArray:end function
        playingArray : CreateObject("roAssociativeArray")
    }
END FUNCTION


FUNCTION configCompleteComponent () as void
    completeComponent = {
        setCompleteComponent  :   function(val):m.completeArray=val:end function
        getCompleteComponent  :   function():return m.completeArray:end function
        completeArray : CreateObject("roAssociativeArray")
    }
END FUNCTION


FUNCTION configVisitComponent () as void
    visitComponent = {
        setVisitComponent  :   function(val):m.visitArray=val:end function
        getVisitComponent  :   function():return m.visitArray:end function
        visitArray : CreateObject("roAssociativeArray")
    }
END FUNCTION


FUNCTION configHeartBeatComponent () as void
    heartBeatComponent = {
        setHeartBeatComponent  :   function(val):m.heartBeatArray=val:end function
        getHeartBeatComponent  :   function():return m.heartBeatArray:end function
        heartBeatArray : CreateObject("roAssociativeArray")
    }
END FUNCTION


FUNCTION configErrorComponent () as void
    errorComponent = {
        setErrorComponent  :   function(val):m.errorArray=val:end function
        getErrorComponent  :   function():return m.errorArray:end function
        errorArray : CreateObject("roAssociativeArray")
    }
END FUNCTION
'This file will hold media metrics and dimensions
'Provides data to the beacon system so that beaconing system
' can send beacons

'Function       :   AkaMA_createDataStore
'Params         :   dataStoreParams. initialization params which will initialize
'                   mediaMetricConfig with key value pairs
'Return         :   Returns newly created data store
'Description    :   creates and maintains key-value pairs of dimensions + metrics.
'                   Provides set of functions for operations on dataStore
'
function AkaMA_createDataStore()
dataStore = {
    ' mediaMetrics is a key-value map which will be updated dynamically
    mediaMetrics : CreateObject("roAssociativeArray")

    ' mediaMetricsConfig will hold key-value pairs from configuration xml
    mmConfig : CreateObject("roAssociativeArray")

    'custom dimensions
    custDimension : CreateObject("roAssociativeArray")


    'Function       :   initializeConfigMediaMetrics
    'Params         :   XML as object. A parsed xml content (Nothing but roXMLElement)
    'Return         :   none (UGT:todo -  shall we return error codes)
    'Description    :   Initialization of media metrics object with configuration xml
    '                   Setting logType, and other initializtion from configuration xml
    initializeConfigMediaMetrics: function(xml as object)
        m.mmConfig = mediaMetricsConfig()
        if m.mmConfig.initMetricsWithXMLContents(xml) <> 0
            print"error in parsing xml contents"
        endif
        print "logtype from xml = ";m.mmconfig.logTo["logType"]
        if m.mmconfig.logTo["logType"] = "relative"
            logTypeValue = "R"
        else if m.mmconfig.logTo["logType"] = "cumulative"
            logTypeValue = "C"
        end if
        print "logTypeValue is = ";logTypeValue
        updateParams = {
                        logType         :   logTypeValue
                        logVersion      :   m.mmconfig.logTo["logVersion"]
                        formatVersion   :   m.mmconfig.logTo["formatVersion"]
                       }
         m.addUdpateMediaMetrics(updateParams)
    end function

    'Function       :   addUdpateMediaMetrics
    'Params         :   updatedValues. key-value pair(s) which needs to be added or updated to media metrics
    'Return         :   none (UGT:todo -  shall we return error codes)
    'Description    :   adds / updates values in media metrics array. Iterates through supplied
    '                   key-value pairs and adds/updates them in media metrics
    '                   Note if key is already there it will be over-writen with new values
    addUdpateMediaMetrics: function(updatedValues)
        for each key in updatedValues
            m.mediaMetrics.AddReplace(key, updatedValues[key])
        next
    end function

    'Function       :   addUdpateCustomMetrics
    'Params         :   updatedValues. key-value pair(s) which needs to be added or updated
    'Return         :   none (UGT:todo -  shall we return error codes)
    'Description    :   adds / updates values in custom media metrics array. Iterates through supplied
    '                   key-value pairs and adds/updates them in custom metrics
    addUdpateCustomMetrics: function(updatedValues)
        for each key in updatedValues
            m.custDimension.AddReplace(key, updatedValues[key])
        next
    end function

    'Function       :   deleteIfExist
    'Params         :   key which needs to be deleted from media metrics
    'Return         :   none (UGT:todo -  shall we return error codes)
    'Description    :   deletes values in media metrics array if it is exist
    deleteIfExist: function(key)
        if m.mediaMetrics.DoesExist(key)
            m.mediaMetrics.Delete(key)
        endif
    end function

    'Function       :   uniqueDimensionLookUp
    'Params         :   uniqueMetricName The Unique Dimension to be looked up.
    'Return         :   Will return the metric name associated with the unique dimension.
    'Description    :   Given a unique dimension provides it's associated metric name.
    'Warn           :   This method currently support "viewerinterval" and "viewertitleinterval". For any
    '                   other input it will send empty string.
    uniqueDimensionLookUp: function(uniqueMetricName as String) as String
        dimension = ""
        if uniqueMetricName =  "viewerInterval"
            dimension = "viewerId"
        else if uniqueMetricName =  "viewerTitleInterval"
            dimension = "title"
        endif
        return dimension
    end function


    'Function       :   calculateUniqueDimension
    'Params         :   uniqueMetricName The Unique Dimension to be used for calculations.
    'Params         :   expiryDuration  Time from current time to expire the data.
    'Return         :   None
    'Description    :   Calculates the time at which the Unique Dimension was previously used.
    'Warn           :   Will insert the last time the unique metric was used into mediaMetrics. It will insert "0.0"
    '                   into the mediaMetrics if records were not found.
    calculateUniqueDimension: function(uniqueMetricName as String, expiryDuration as String)  as void
        timeDifference = "0.0"
        metricName = m.uniqueDimensionLookUp(uniqueMetricName)

        if m.mediaMetrics.DoesExist(metricName)
            manager = AkaMA_createStorageManager()
            metricValue = m.mediaMetrics[metricName]
            time = CreateObject("roDateTime")
            currentTime% = time.asSeconds()
            if metricValue.Len() > 0
                lastAccessTime = manager.lastAccessTime(metricValue)
                if lastAccessTime > 0
                    timeDiff = currentTime% - lastAccessTime
                    if timeDiff > 0
                        timeDiff = (timeDiff/60)
                        timeDifference = str(timeDiff).Trim()
                    endif
                endif
            endif
            expiry% = expiryDuration.ToInt()
            ' Converting minutes to seconds
            expiry% = expiry% * 60
            manager.addOrUpdate(metricValue, currentTime%, (currentTime% + expiry%))
        endif
        m.mediaMetrics[uniqueMetricName] = timeDifference
    end function

    'Function       :   getILinedataAsString
    'Params         :   None
    'Return         :   Returns I line data as a string. String should have encoded key-value pairs
    '                   separated by a separator
    'Description    :   This function constructs string from dimensions and metrics wchich will be sent
    '                   as part of I line beacon
    getILinedataAsString : function() as string
        m.populateCustomeDimensions()
        ' Calculating unqiue viewers.
        viewerInternalObject = m.mmconfig.mmBeaconMetric.initMetrics["viewerInterval"]
        if viewerInternalObject <> invalid
            m.calculateUniqueDimension("viewerInterval", viewerInternalObject.expiry)
        endif
        iLineData = box("a=I~")'CreateObject("roString")
        iLineData = iLineData + "b=" + m.mmconfig.beaconId + "~" + "az=" + m.mmconfig.beaconVersion + "~"
        iLineData = iLineData + m.fillupCommonMetrics()
        for each key in m.mmconfig.mmBeaconMetric.initMetrics
            if m.mediaMetrics[key] <> invalid
                keyForMetrics = m.getKeyForElement(m.mmconfig.mmBeaconMetric.initMetrics, key)
                iLineData.ifstringops.AppendString(keyForMetrics, keyForMetrics.Len())
                iLineData = iLineData + "="
                iLineData.ifstringops.AppendString(m.getEncodedString(m.mediaMetrics[key]), m.getEncodedString(m.mediaMetrics[key]).len())
                iLineData = iLineData + "~"
            endif
        next

        isPresent = m.isHTTPPresent(m.mmconfig.logTo["host"])
        if isPresent = true
            iBeaconURL = box("")
        else
            iBeaconURL = box("http://")
        endif
        iBeaconURL.ifstringops.AppendString(m.mmconfig.logTo["host"], m.mmconfig.logTo["host"].Len())
        iBeaconURL.ifstringops.AppendString(m.mmconfig.logTo["path"], m.mmconfig.logTo["path"].Len())
        iBeaconURL = iBeaconURL + "?" + iLineData'm.getEncodedString(iLineData)
        return iBeaconURL.Left(Len(iBeaconURL)-1)
    end function

    'Function       :   getSLinedataAsString
    'Params         :   None
    'Return         :   Returns S line data as a string. String should have encoded key-value pairs
    '                   separated by a separator
    'Description    :   This function constructs string from dimensions and metrics wchich will be sent
    '                   as part of S line beacon
    getSLinedataAsString : function() as string
        m.populateCustomeDimensions()
        sLineData = box("a=S~")
        sLineData = sLineData + "b=" + m.mmconfig.beaconId + "~" + "az=" + m.mmconfig.beaconVersion + "~"
        sLineData = sLineData + m.fillupCommonMetrics()
        for each key in m.mmconfig.mmBeaconMetric.playStartMetrics
        if m.mediaMetrics[key] <> invalid
            keyForMetrics = m.getKeyForElement(m.mmconfig.mmBeaconMetric.playStartMetrics, key)
            sLineData.ifstringops.AppendString(keyForMetrics, keyForMetrics.Len())
            sLineData = sLineData + "="
            sLineData.ifstringops.AppendString(m.getEncodedString(m.mediaMetrics[key]), m.getEncodedString(m.mediaMetrics[key]).len())
            sLineData = sLineData + "~"
        Endif
        next
        isPresent = m.isHTTPPresent(m.mmconfig.logTo["host"])
        if isPresent = true
            sBeaconURL = box("")
        else
            sBeaconURL = box("http://")
        endif

        sBeaconURL.ifstringops.AppendString(m.mmconfig.logTo["host"], m.mmconfig.logTo["host"].Len())
        sBeaconURL.ifstringops.AppendString(m.mmconfig.logTo["path"], m.mmconfig.logTo["path"].Len())
        sBeaconURL = sBeaconURL + "?" + sLineData 'm.getEncodedString(sLineData)
        return sBeaconURL.Left(Len(sBeaconURL)-1)
    end function

    'Function       :   getPLinedataAsString
    'Params         :   None
    'Return         :   Returns P line data as a string. String should have encoded key-value pairs
    '                   separated by a separator
    'Description    :   This function constructs string from dimensions and metrics wchich will be sent
    '                   as part of P line beacon
    getPLinedataAsString : function() as string
        m.populateCustomeDimensions()
        pLineData = box("a=P~")
        pLineData = pLineData + "b=" + m.mmconfig.beaconId + "~" + "az=" + m.mmconfig.beaconVersion + "~"
        pLineData = pLineData + m.fillupCommonMetrics()
        for each key in m.mmconfig.mmBeaconMetric.playingMetrics
            if m.mediaMetrics[key] <> invalid
                keyForMetrics = m.getKeyForElement(m.mmconfig.mmBeaconMetric.playingMetrics, key)
                pLineData.ifstringops.AppendString(keyForMetrics, keyForMetrics.Len())
                pLineData = pLineData + "="
                pLineData.ifstringops.AppendString(m.getEncodedString(m.mediaMetrics[key]), m.getEncodedString(m.mediaMetrics[key]).len())
                pLineData = pLineData + "~"
            endif
        next

        isPresent = m.isHTTPPresent(m.mmconfig.logTo["host"])
        if isPresent = true
            pBeaconURL = m.mmconfig.logTo["host"] + m.mmconfig.logTo["path"] + "?" + pLineData'm.getEncodedString(pLineData)
        else
            pBeaconURL = "http://" + m.mmconfig.logTo["host"] + m.mmconfig.logTo["path"] + "?" + pLineData'm.getEncodedString(pLineData)
        endif

        return pBeaconURL.Left(Len(pBeaconURL)-1)
    end function

    'Function       :   getCLinedataAsString
    'Params         :   None
    'Return         :   Returns C line data as a string. String should have encoded key-value pairs
    '                   separated by a separator
    'Description    :   This function constructs string from dimensions and metrics wchich will be sent
    '                   as part of C line beacon
    getCLinedataAsString : function() as string
        m.populateCustomeDimensions()
        cLineData = box("a=C~")
        cLineData = cLineData + "b=" + m.mmconfig.beaconId + "~" + "az=" + m.mmconfig.beaconVersion + "~"
        cLineData = cLineData + m.fillupCommonMetrics()
        for each key in m.mmconfig.mmBeaconMetric.playbackCompletedMetrics
            if m.mediaMetrics[key] <> invalid
                keyForMetrics = m.getKeyForElement(m.mmconfig.mmBeaconMetric.playbackCompletedMetrics, key)
                cLineData.ifstringops.AppendString(keyForMetrics, keyForMetrics.Len())
                cLineData = cLineData + "="
                cLineData.ifstringops.AppendString(m.getEncodedString(m.mediaMetrics[key]), m.getEncodedString(m.mediaMetrics[key]).len())
                cLineData = cLineData + "~"
            endif
        next

        for each key in m.mmconfig.mmBeaconMetric.playingMetrics
            if m.mmconfig.mmBeaconMetric.playbackCompletedMetrics.DoesExist(key) = false
                if m.mediaMetrics[key] <> invalid
                    keyForMetrics = m.getKeyForElement(m.mmconfig.mmBeaconMetric.playingMetrics, key)
                    cLineData.ifstringops.AppendString(keyForMetrics, keyForMetrics.Len())
                    cLineData = cLineData + "="
                    cLineData.ifstringops.AppendString(m.getEncodedString(m.mediaMetrics[key]), m.getEncodedString(m.mediaMetrics[key]).len())
                    cLineData = cLineData + "~"
                endif
            endif
        next

        isPresent = m.isHTTPPresent(m.mmconfig.logTo["host"])
        if isPresent = true
            cBeaconURL = m.mmconfig.logTo["host"] + m.mmconfig.logTo["path"] + "?" + cLineData'm.getEncodedString(cLineData)
        else
            cBeaconURL = "http://" + m.mmconfig.logTo["host"] + m.mmconfig.logTo["path"] + "?" + cLineData 'm.getEncodedString(cLineData)
        endif

        return cBeaconURL.Left(Len(cBeaconURL)-1)
    end function

    'Function       :   getELinedataAsString
    'Params         :   None
    'Return         :   Returns E line data as a string. String should have encoded key-value pairs
    '                   separated by a separator
    'Description    :   This function constructs string from dimensions and metrics wchich will be sent
    '                   as part of E line beacon
    getELinedataAsString : function() as string
        m.populateCustomeDimensions()
        eLineData = box("a=E~")
        eLineData = eLineData + "b=" + m.mmconfig.beaconId + "~" + "az=" + m.mmconfig.beaconVersion + "~"
        eLineData = eLineData + m.fillupCommonMetrics()
        for each key in m.mmconfig.mmBeaconMetric.errorMetrics
            if m.mediaMetrics[key] <> invalid
                keyForMetrics = m.getKeyForElement(m.mmconfig.mmBeaconMetric.errorMetrics, key)
                eLineData.ifstringops.AppendString(keyForMetrics, keyForMetrics.Len())
                eLineData = eLineData + "="
                eLineData.ifstringops.AppendString(m.getEncodedString(m.mediaMetrics[key]), m.getEncodedString(m.mediaMetrics[key]).len())
                eLineData = eLineData + "~"
            endif
        next

        isPresent = m.isHTTPPresent(m.mmconfig.logTo["host"])
        if isPresent = true
            eBeaconURL = m.mmconfig.logTo["host"] + m.mmconfig.logTo["path"] + "?" + eLineData ' m.getEncodedString(eLineData)
        else
            eBeaconURL = "http://" + m.mmconfig.logTo["host"] + m.mmconfig.logTo["path"] + "?" + eLineData 'm.getEncodedString(eLineData)
        endif

        return eBeaconURL.Left(Len(eBeaconURL)-1)
    end function

    'Function       :   getVLinedataAsString
    'Params         :   None
    'Return         :   Returns V line data as a string. String should have encoded key-value pairs
    '                   separated by a separator
    'Description    :   This function constructs string from dimensions and metrics wchich will be sent
    '                   as part of V line beacon
    getVLinedataAsString : function() as string
        m.populateCustomeDimensions()
        vLineData = box("a=V~")
        vLineData = vLineData + "b=" + m.mmconfig.beaconId + "~" + "az=" + m.mmconfig.beaconVersion + "~"
        vLineData = vLineData + m.fillupCommonMetrics()
        for each key in m.mmconfig.mmBeaconMetric.visitMetrics
            if m.mediaMetrics[key] <> invalid
                keyForMetrics = m.getKeyForElement(m.mmconfig.mmBeaconMetric.visitMetrics, key)
                vLineData.ifstringops.AppendString(keyForMetrics, keyForMetrics.Len())
                vLineData = vLineData + "="
                vLineData.ifstringops.AppendString(m.getEncodedString(m.mediaMetrics[key]), m.getEncodedString(m.mediaMetrics[key]).len())
                vLineData = vLineData + "~"
            endif
        next

        isPresent = m.isHTTPPresent(m.mmconfig.logTo["host"])
        if isPresent = true
            vBeaconURL = m.mmconfig.logTo["host"] + m.mmconfig.logTo["path"] + "?" + vLineData 'm.getEncodedString(vLineData)
        else
            vBeaconURL = "http://" + m.mmconfig.logTo["host"] + m.mmconfig.logTo["path"] + "?" + vLineData 'm.getEncodedString(vLineData)
        endif

        return vBeaconURL.Left(Len(vBeaconURL)-1)
    end function

    'Function       :   fillupCommonMetrics
    'Params         :   None
    'Return         :   Retruns box (string) with common section of xml from common metrics
    'Description    :   This function reads key-value from commonMetrics and puts it in the string
    '                   for beacon request
    fillupCommonMetrics : function () as object
        commonData = box("")
        for each key in m.mmconfig.mmBeaconMetric.commonMetrics
            if m.mediaMetrics[key] <> invalid
                keyForMetrics = m.getKeyForElement(m.mmconfig.mmBeaconMetric.commonMetrics, key)
                commonData.ifstringops.AppendString(keyForMetrics, keyForMetrics.Len())
                commonData = commonData + "="
                commonData.ifstringops.AppendString(m.getEncodedString(m.mediaMetrics[key]), m.getEncodedString(m.mediaMetrics[key]).len())
                commonData = commonData + "~"
            endif
        next
        return commonData
    end function

    'Function       :   populateCustomeDimensions
    'Params         :   None
    'Return         :   None
    'Description    :   This function Populates custome dimensions from custDimenstion dictionary to mediaMetrics dictionary
    populateCustomeDimensions : function ()
        for each key in m.custDimension
            m.mediaMetrics.AddReplace(key, m.custDimension[key])
        next

        if m.mediaMetrics.DoesExist("eventName") = false
            if m.custDimension.DoesExist("title")
                m.mediaMetrics.AddReplace("eventName",m.custDimension["title"])
            else if m.mediaMetrics.DoesExist("streamName")
                m.mediaMetrics.AddReplace("eventName",m.mediaMetrics["streamName"])
            endif
        endif
        if m.mediaMetrics.DoesExist("title") = false
            if m.custDimension.DoesExist("eventName")
                m.mediaMetrics.AddReplace("title",m.custDimension["eventName"])
            else if m.mediaMetrics.DoesExist("streamName")
                m.mediaMetrics.AddReplace("title",m.mediaMetrics["streamName"])
            endif
        endif
    end function

    'Function       :   getEncodedString
    'Params         :   inString a string object which needs to be encoded
    'Return         :   returns encoded string
    'Description    :   This function encodes inString and returns encoded string
    getEncodedString:function(value as dynamic) as string
        ' print "not encoded beacon data = "; value

        if type(value) <> "roString" and type(value) <> "String" then
            inString = value.tostr()
        else
            inString = value
        end if

        ue = CreateObject("roURLTransfer")
        'encodedOutString = AkaMA_str8859toutf8(inString)

        'Replace ~ with *@*
        replaceTilda = AkaMA_strReplace(inString, "~", "*@*")
        encodedOutString = ue.Escape(replaceTilda)

        'encodedOutString = ue.UrlEncode(inString)
        'print "encoded beacon request = "; encodedOutString
        'return AkaMA_strReplace(encodedOutString," ","%20")
        return encodedOutString

'        o = CreateObject("roUrlTransfer")
'        'encodedOutString = o.UrlEncode(AkaMA_HttpEncode(inString))
'        'encodedOutString = o.UrlEncode(inString)
'        encodedOutString = AkaMA_HttpEncode(inString)
'        'print "encoded beacon request = "; encodedOutString
        return encodedOutString
    end function

    'Function       :   isHTTPPresent
    'Params         :   baseString in which to find if "http://" tag present or absent
    'Return         :   returns true / false based on the presence of http
    'Description    :   This function checks if "http://"  present in url at the beginning or not
    '                   As beacon xml's host value may have url with http:// or may not have. This
    '                   Needs to be taken care by plugin
    isHTTPPresent:function(baseString as string) as Boolean
    position = instr(1, baseString, "http://")
    if position = 1
        return true
    else
        position = instr(1, baseString, "https://")
        if position = 1
            return true
        else
            return false
        endif
    endif
   end function

    'Function       :   getKeyForElement
    'Params         :   metrics a media metrics object
    '                   Key : a key for which to get element
    'Return         :   returns correct key based on the value of useKey
    'Description    :   This function returns short key or long key based on the
    '                   value of useKey in beacon xml. Beacon xml has a swtich
    '                   to reprot short key or long key in beacons
   getKeyForElement:function(metrics as object, key as string) as string
     if m.mmconfig.useKey = 0
        return key
     else if m.mmconfig.useKey = 1
        return metrics[key].key
     endif
   end function
}

return dataStore
end function


'Function       :   mediaMetricsConfig
'Params         :   configParams. initialization params which will initialize
'                   from configuration xml with key value pairs
'Return         :   Returns newly created configuration media meatrics
'Description    :   creates and maintains key-value pairs of configuration media metrics
'
'UGT:Todo - do we need configParams and error  in this -- function mediaMetricsConfig(configParams, error)
function mediaMetricsConfig()
mmConfig = {
        mmBeaconMetric : {
            commonMetrics               :   {}
            initMetrics                 :   {}
            playStartMetrics            :   {}
            playingMetrics              :   {}
            playbackCompletedMetrics    :   {}
            errorMetrics                :   {}
            visitMetrics                :   {}
        }
        beaconInfo                      :   {}
        logTo                           :   CreateObject("roAssociativeArray")
        beaconId                        :   CreateObject("roString")
        beaconVersion                   :   CreateObject("roString")
        useKey                          :   0
        securityURLAuthInfo             :   invalid
        securityViewerDiagnosticsInfo   :   invalid

        'initialize from configuration xml
        'Function       :   initMetricsWithXMLContents
        'Params         :   xml parsed xml object
        'Return         :   returns success or error code
        'Description    :   This function creates and fills up associative arrays from
        '                   config xml. This provides more structured representation
        '                   of xml contents and organizes for later use by the plugin
        initMetricsWithXMLContents : function(xml as object) as integer
            if xml = invalid
                return AkaMAErrors().ERROR_CODES.AKAM_Invalid_configuration_xml
            end if
            AkaMA_createStorageManager().deleteExpiredData()
            m.beaconId = xml.beaconId.getText()
            m.beaconVersion =   xml.beaconVersion.getText()

            'Populate logTo values
            element = xml.logTo
            m.logTo.addReplace("logInterval", element@logInterval)
            m.logTo.addReplace("secondaryLogTime", element@secondaryLogTime)
            m.logTo.addReplace("logType", element@logType)
            m.logTo.addReplace("maxLogLineLength", element@maxLogLineLength)
            m.logTo.addReplace("urlParamSeparator", element@urlParamSeparator)
            m.logTo.addReplace("encodedParamSeparator", element@encodedParamSeparator)
            m.logTo.addReplace("heartBeatInterval", element@heartBeatInterval)
            m.logTo.addReplace("visitTimeout", element@visitTimeout)

            hostElement = xml.logTo.host
            'print " host = ";hostElement.GetText()
            m.logTo.addReplace("host", hostElement.GetText())
            m.logTo.addReplace("path", xml.logTo.path.GetText())
            m.logTo.addReplace("logVersion", xml.logTo.logVersion.GetText())
            m.logTo.addReplace("formatVersion", xml.logTo.formatVersion.GetText())
            AkaMA_logger().AkaMA_print("========= Printing logTo key / value ===== ")
            'AkaMA_PrintAnyAA(3, m.logTo)
            AkaMA_logger().AkaMA_print("============End==============")

            'Populate key-valud pairs for URL authentication (Security tag)
            securityUrlAuthElement = xml.security.URLAuth1
            if securityUrlAuthElement <> invalid
                m.securityURLAuthInfo = CreateObject("roAssociativeArray")
                m.securityURLAuthInfo.addReplace("salt", securityUrlAuthElement.salt.GetText())
                m.securityURLAuthInfo.addReplace("window", securityUrlAuthElement.window.GetText())
                m.securityURLAuthInfo.addReplace("param", securityUrlAuthElement.param.GetText())
                print "========= Printing URL authentication key / value ===== "
                AkaMA_PrintAnyAA(3, m.securityURLAuthInfo)
                print "============End=============="
             end if

            'Populate key-valud pairs for viewerdiagnostics (Security tag)
            securityViewerDiagInfo = xml.security.ViewerDiagnostics
            if securityViewerDiagInfo <> invalid
                m.securityViewerDiagnosticsInfo = CreateObject("roAssociativeArray")
                m.securityViewerDiagnosticsInfo.addReplace("version", securityViewerDiagInfo.salt@version)
                m.securityViewerDiagnosticsInfo.addReplace("value", securityViewerDiagInfo.salt@value)
                m.securityViewerDiagnosticsInfo.addReplace("iterations", securityViewerDiagInfo.salt@iterations)
                m.securityViewerDiagnosticsInfo.addReplace("bytes", securityViewerDiagInfo.salt@bytes)

                if securityViewerDiagInfo.iterations@value <> invalid
                    m.securityViewerDiagnosticsInfo.addReplace("iterations", securityViewerDiagInfo.iterations@value)
                end if
                if securityViewerDiagInfo.bytes@value <> invalid
                    m.securityViewerDiagnosticsInfo.addReplace("bytes", securityViewerDiagInfo.bytes@value)
                end if
                print "========= Printing ViewerDiangostics key / value ===== "
                AkaMA_PrintAnyAA(3, m.securityViewerDiagnosticsInfo)
                print "============End=============="
            end if
            'Populate key-value pairs for common metrics
            statsElement = xml.statistics
            if statsElement@useKey = "1"
                m.useKey = 1
                print"setting useKey to 1"
            else if statsElement@useKey = "0"
                m.useKey = 0
                print"setting useKey to 0"
            endif
            for each element in xml.statistics.common.dataMetrics.data
                m.mmBeaconMetric.commonMetrics.AddReplace(element@name, {key:element@key, value:AkaMA_validstr(element@value)})
            next
            AkaMA_logger().AkaMA_print("========= Printing Common key / value ===== ")
            'AkaMA_PrintAnyAA(3, m.mmBeaconMetric.commonMetrics)
            AkaMA_logger().AkaMA_print("============End==============")

            'Populate key-value pairs for init metrics
            m.mmBeaconMetric.initMetrics.AddReplace("eventCode", xml.statistics.init@eventCode)
            for each element in xml.statistics.init.dataMetrics.data
                m.mmBeaconMetric.initMetrics.AddReplace(element@name, {key:element@key, value:AkaMA_validstr(element@value), expiry:AkaMA_validstr(element@expiry)})
            next
            AkaMA_logger().AkaMA_print("========= Printing init key / value ===== ")
            'AkaMA_PrintAnyAA(3, m.mmBeaconMetric.initMetrics)
            AkaMA_logger().AkaMA_print("============End==============")

            'Populate key-value pairs for playStart metrics
            for each element in xml.statistics.playStart.dataMetrics.data
                m.mmBeaconMetric.playStartMetrics.AddReplace(element@name, {key:element@key, value:AkaMA_validstr(element@value), expiry:AkaMA_validstr(element@expiry)})
            next
            AkaMA_logger().AkaMA_print("========= Printing Play start key / value ===== ")
            'print "========= Printing Play start key / value ===== "
            'AkaMA_PrintAnyAA(3, m.mmBeaconMetric.playStartMetrics)
           ' print "============End=============="
            AkaMA_logger().AkaMA_print("============End==============")

            'Populate key-value pairs for playing metrics
            for each element in xml.statistics.playing.dataMetrics.data
                m.mmBeaconMetric.playingMetrics.AddReplace(element@name, {key:element@key, value:AkaMA_validstr(element@value)})
            next
            AkaMA_logger().AkaMA_print("========= Printing Playing key / value ===== ")
            'AkaMA_PrintAnyAA(3, m.mmBeaconMetric.playingMetrics)
            AkaMA_logger().AkaMA_print("============End==============")

            'Populate key-value pairs for complete metrics
            for each element in xml.statistics.complete.dataMetrics.data
                m.mmBeaconMetric.playbackCompletedMetrics.AddReplace(element@name, {key:element@key, value:AkaMA_validstr(element@value)})
            next
            AkaMA_logger().AkaMA_print("========= Printing playback complete key / value ===== ")
            'AkaMA_PrintAnyAA(3, m.mmBeaconMetric.playbackCompletedMetrics)
            AkaMA_logger().AkaMA_print("============End==============")

            'Populate key-value pairs for error metrics
            for each element in xml.statistics.error.dataMetrics.data
                m.mmBeaconMetric.errorMetrics.AddReplace(element@name, {key:element@key, value:AkaMA_validstr(element@value)})
            next
            AkaMA_logger().AkaMA_print("========= Printing error key / value ===== ")
            'AkaMA_PrintAnyAA(3, m.mmBeaconMetric.errorMetrics)
            AkaMA_logger().AkaMA_print("============End==============")

            'Populate key-value pairs for visit metrics
            for each element in xml.statistics.visit.dataMetrics.data
                m.mmBeaconMetric.visitMetrics.AddReplace(element@name, {key:element@key, value:AkaMA_validstr(element@value)})
            next
            AkaMA_logger().AkaMA_print("========= Printing visit key / value ===== ")
            'AkaMA_PrintAnyAA(3, m.mmBeaconMetric.visitMetrics)
            AkaMA_logger().AkaMA_print("============End==============")

            return AkaMAErrors().ERROR_CODES.AKAM_Success
        end function
}
return mmConfig
end function


'Function       :   customDimension
'Params         :   custDimenstionParams. initialization params which will initialize
'                   custom dimenstions with key value pairs
'                   This should be key-value pairs
'Return         :   Returns newly created custome dimension
'Description    :   creates and maintains key-value pairs of custome dimensions
'
function customDimension(custDimensionParams)
return {
    customDimensions   :   custDimensionParams
}
end function
'Main controller which takes care of all the incoming events
'and does orchastra between different components
'

'Function       :   AkaMAPlugin
'Params         :   None
'Return         :   Returns plugin instance along with other supporting functions
'                   and data structures
'Description    :   AkaMAPlugin is a main interface for the player. it should
'                   be created using craeteInstance API
FUNCTION AkaMAPlugin()
return{
    'Function       :   createPluginInstance
    'Params         :   None
    'Return         :   Returns new plugin instance
    'Description    :   createPluginInstance will create a plugin instance using
    '                   and provides event handling functions to handle events
    '                   from the player
    createPluginInstance: function ()
    return {
    pluginDataStore         :   CreateObject("roAssociativeArray")
    logInterval             :   invalid
    secondaryLogInterval    :   invalid
    logType                 :   invalid
    sequenceId              :   0
    sessionStart            :   invalid
    lastLogTime             :   invalid
    pluginStatus            :   CreateObject("roAssociativeArray")
    pendingBeaconRequest    :   CreateObject("roAssociativeArray")
    'Maintains status of the beacons sent. This helps to decide if sending
    'of a particular beacon is valid
    reportedBeaconStatus    :   invalid
    lastLogInterval         :   0.0
    'currentItem             :   pluginParams.videoclip
    currentHeadPosition     :   0
    timeSinceLastLine       :   invalid
    logger                  :   invalid
    viewerId                :   invalid
    viewerDiagnosticsId     :   invalid
    measuredBandwidth       :   invalid
    uniqueTitles            :   CreateObject("roArray", 100, true)
    serverUrl               :   CreateObject("roString")
    performServerIpLookUp   :   true

    'todo: validation of params and retrun appropriate error code if required
    'Function       :   initializeMAPluginInstance
    'Params         :   customDimensions - dictionary of custom dimensions
    '                   sessionTimer - a timer for the session
    '                   configXML - configuration xml for the plugin
    '                   loggerObject - logging helper object
    '                   viewerId -  viewerId set by the player (can be invalid)
    '                   viewerDiagnosticsId - viewerDiagnosticsId for viewer diagnostics feature (can be invalid)
    'Return         :   None
    'Description    :   This function initalizes analytics plugin with input params(configXML, viewrId, viewerDiagnosticsId, etc) from the player
    '                   It sends I-beacon as part of the plugin intialization
    initializeMAPluginInstance : function(customDimensions, sessionTimer, configXML, loggerObject, viewerId, viewerDiagnosticsId)
        'AkaMA_logger().enableLogging(true)
        'AkaMA_logger().eanbelTrace(true)
        m.logger = loggerObject
        xmlObj = initConfigurationXML(configXML)
        m.pluginDataStore = AkaMA_createDataStore()
        m.pluginDataStore.initializeConfigMediaMetrics(xmlObj)
        m.pluginDataStore.addUdpateCustomMetrics(customDimensions)
        m.lastLogInterval# = sessionTimer.TotalMilliseconds()/1000
        di = CreateObject("roDeviceInfo")
        version = GetOSVersion()
        major = Mid(version, 3, 1)
        minor = Mid(version, 5, 2)
        build = Mid(version, 8, 5)
        print("Roku device - Major Version: " + major + " Minor Version: " + minor + " Build Number: " + build)
        m.logger.AkaMA_print("From logger : Roku device - Major Version: " + major + " Minor Version: " + minor + " Build Number: " + build)
        displaySizeArray = di.GetDisplaySize()
        print "Array of display size = ";displaySizeArray

        dt = CreateObject("roDateTime")
        print "DataTime object. asSeconds= "; dt.asSeconds();
        'print "asDateString = "; dt.asDateString();
        print" asDateStringNoParam "; dt.asDateStringNoParam()
        print "getWeekday= "; dt.getWeekday();
        print" getDayOfMonth= "; dt.getDayOfMonth();
        print" getLastDayOfMonth= "; dt.getLastDayOfMonth()
        print "getMonth= "; dt.getMonth();
        print" getYear= "; dt.getYear()

        sessionGuid = AkaMA_GUID()
        if viewerDiagnosticsId <> invalid
            m.viewerDiagnosticsId = viewerDiagnosticsId
        endif

        if viewerId <> invalid
            clientHash = viewerId
            m.viewerId = viewerId
        else
            clientHash = AkaMA_ClientID()
        endif
        m.sequenceId = 0
        pluginInitParams = {
                            pluginVersion   :   AkaMA_PluginConsts().pluginVersion   '"1.1",
                            sequenceId      :   "0",
                            os              :   "Roku",
                            fullOs          :   "Roku-"+version,
                            clientId        :   clientHash
                            viewerId        :   clientHash
                            sessionId       :   sessionGuid
                            attemptId       :   sessionGuid
                            playerType      :   "Roku"
                            'streamLength    :   m.currentItem.Length
                            'format          :   m.currentItem.StreamFormat
                            endOfStream     :   "0"
                            }

        m.pluginDataStore.addUdpateMediaMetrics(pluginInitParams)

        m.pluginStatus = AkaMA_pluginState()
        m.pluginStatus.initPluginStates()

        m.pluginStatus.moveToState(m.pluginStatus.initialize, invalid, invalid)
        m.lastLogInterval# = (sessionTimer.TotalMilliseconds()/1000.0) -  m.lastLogInterval#
        m.pluginDataStore.addUdpateMediaMetrics({logInterval : AkaMA_strTrim(AkaMA_AnyToString(m.lastLogInterval#))})
        m.pluginDataStore.addUdpateMediaMetrics({playerState : m.provideStateString()})
        m.lastLogInterval# = sessionTimer.TotalMilliseconds()/1000.0
        m.populateViewerDiagnosticsId()

        iBeacon = CreateObject("roString")
        iBeacon = m.pluginDataStore.getILinedataAsString()
        print iBeacon
        if AkaMA_MABeacons().sendBeacon(iBeacon) <> 0
            print "failed to send I-Line"
        else
            print "I-Line sent successfully"
        endif
        m.reportedBeaconStatus = AkaMA_isBeaconInOrder().BeaconReported.iLineReported
        m.sessionStart = CreateObject("roTimespan")
        m.timeSinceLastLine = CreateObject("roTimespan")
        m.logInterval = m.pluginDataStore.mmconfig.logTo["logInterval"]
        m.logType = m.pluginDataStore.mmconfig.logTo["logType"]
        m.secondaryLogInterval = m.pluginDataStore.mmconfig.logTo["secondaryLogTime"]
    end function

    'send s line
    'Function       :   handlePlayStartEvent
    'Params         :   sessionTimer - a timer for the session
    '                   lastHeadPosition - last stream head postion
    'Return         :   None
    'Description    :   This function handles play start event and sends S-Beacon
    handlePlayStartEvent : function(sessionTimer, lastHeadPosition)
        'print "send S line ..."
        if (m.reportedBeaconStatus and AkaMA_isBeaconInOrder().BeaconReported.sLineReported) = 0
            reportedBeaconStatus = AkaMA_isBeaconInOrder().BeaconReported.iLineReported
            m.sequenceId = m.sequenceId+1
            m.pluginDataStore.addUdpateMediaMetrics({sequenceId : AkaMA_itostr(m.sequenceId)})
            m.pluginStatus.moveToState(m.pluginStatus.playing, invalid, {headPosition:lastHeadPosition})

            m.lastLogInterval# = (sessionTimer.TotalMilliseconds()/1000.0) -  m.lastLogInterval#
            m.pluginDataStore.addUdpateMediaMetrics({logInterval : AkaMA_strTrim(AkaMA_AnyToString(m.lastLogInterval#)), currentClockTime : AkaMA_AnyToString(sessionTimer.TotalMilliseconds()), currentStreamTime:AkaMA_itostr(lastHeadPosition*1000)})

            pluginGlobals = AkaMA_getPluginGlobals()
            if pluginGlobals.isVisitSent = false
                m.pluginDataStore.addUdpateMediaMetrics({isVisitStart:"1"})
                pluginGlobals.isVisitSent =  true
            endif

            m.lastLogInterval# = sessionTimer.TotalMilliseconds()/1000.0
            m.pluginDataStore.addUdpateMediaMetrics({playerState : m.provideStateString()})
            m.pluginStatus.getStatusMetrics(m.pluginDataStore)

            sBeacon = CreateObject("roString")
            sBeacon = m.pluginDataStore.getsLinedataAsString()
            print sBeacon
            if AkaMA_MABeacons().sendBeacon(sBeacon) <> 0
                print "failed to send S-Line"
            else
                print "S-Line sent successfully"
            endif
            m.timeSinceLastLine.Mark()
            m.reportedBeaconStatus = m.reportedBeaconStatus or AkaMA_isBeaconInOrder().BeaconReported.sLineReported
            m.pluginStatus.resetRelativeMetrics(m.pluginDataStore)
            m.pluginDataStore.deleteIfExist("isVisitStart")
        else
            print "invalid sequence for sline"
        endif
        'print "sline sent..."
    end function

    'Send pline
    'Function       :   handlePeriodicEvent
    'Params         :   sessionTimer - a timer for the session
    '                   lastHeadPosition - last stream head postion
    'Return         :   None
    'Description    :   This function handles Periodic play event and sends P-Beacon
    handlePeriodicEvent : function(sessionTimer, lastHeadPosition)
        'print "send P line ..."
        if (m.reportedBeaconStatus and AkaMA_isBeaconInOrder().BeaconReported.sLineReported) <> 0
            m.lastLogInterval# = (sessionTimer.TotalMilliseconds()/1000.0) -  m.lastLogInterval#
            m.pluginDataStore.addUdpateMediaMetrics({logInterval : AkaMA_strTrim(AkaMA_AnyToString(m.lastLogInterval#)), currentClockTime : AkaMA_AnyToString(sessionTimer.TotalMilliseconds())})
            m.lastLogInterval# = sessionTimer.TotalMilliseconds()/1000.0
            m.currentHeadPosition = m.currentHeadPosition + sessionTimer.TotalMilliseconds()

            m.sequenceId = m.sequenceId+1
            m.pluginDataStore.addUdpateMediaMetrics({sequenceId : AkaMA_itostr(m.sequenceId), currentStreamTime:AkaMA_itostr(lastHeadPosition*1000)})
            m.pluginDataStore.addUdpateMediaMetrics({playerState : m.provideStateString()})
            m.pluginStatus.updateCurrentState({headPosition:lastHeadPosition})
            statusMetrics = CreateObject("roAssociativeArray")
            m.pluginStatus.getStatusMetrics(m.pluginDataStore)
            'AkaMA_PrintAnyAA(2,statusMetrics)

            pBeacon = CreateObject("roString")
            pBeacon = m.pluginDataStore.getPLinedataAsString()
            print pBeacon
            if AkaMA_MABeacons().sendBeacon(pBeacon) <> 0
                print "failed to send P-Line"
            else
                print "P-Line sent successfully"
            endif
            m.reportedBeaconStatus = m.reportedBeaconStatus or AkaMA_isBeaconInOrder().BeaconReported.pLineReported
            m.pluginStatus.resetRelativeMetrics(m.pluginDataStore)
            m.timeSinceLastLine.Mark()
        else
            print "Invalid sequence for pline"
        endif
        'print "pline sent..."
    end function

    'send performSeverIpLookUp
    'Function       :   handlePlaybackCompleteEvent
    'Return         :   None
    'Description    :   This function performs server IP look up
    performSeverIpLookUp : function()
        if m.performServerIpLookUp = false
            return -1
        endif

        if m.serverUrl.Len() = 0
           if m.pluginDataStore.mediaMetrics.DoesExist("streamUrl")
               token = AkaMA_strTokenize( m.pluginDataStore.mediaMetrics["streamUrl"], "/")
               m.serverUrl = token[0] + "//" + token[1] + "/serverip"

               regularExpression = CreateObject ("roRegex", "akamai", "i")
               matchingObjects = regularExpression.Match (m.serverUrl)
               if matchingObjects.Count() = 0
                    m.performServerIpLookUp = false
               endif
           endif
        endif

        'Double checking mate!
        if m.performServerIpLookUp = true
            port = CreateObject("roMessagePort")
            serverIpRequest = AkaMA_NewHttp(m.serverUrl)
            serverIpRequest.Http.SetMessagePort(port)
            if (serverIpRequest.Http.AsyncGetToString())
                while (true)
                    msg = wait(0, port)
                    if (type(msg) = "roUrlEvent")
                        if msg.getResponseCode() = 200
                            xmlData = msg.GetString()
                            xmlElement = CreateObject("roXMLElement")
                            if xmlElement.Parse(xmlData)
                                serverip = CreateObject("roString")
                                serverIpValue = xmlElement.serverip.getText()
                                m.pluginDataStore.addUdpateMediaMetrics({serverIp:serverIpValue})
                            endif
                        endif
                    else if (event = invalid)
                        serverIpRequest.Http.AsyncCancel()
                    endif
                    exit while
                end while
            endif
        endif
    end function

    'send cline
    'Function       :   handlePlaybackCompleteEvent
    'Params         :   sessionTimer - a timer for the session
    '                   lastHeadPosition - last stream head postion
    'Return         :   None
    'Description    :   This function handles play completed event and sends C-Beacon
    handlePlaybackCompleteEvent : function(sessionTimer, playbackEndReasonCode, lastHeadPosition)
        'print "send c line ..."
        if (m.reportedBeaconStatus and AkaMA_isBeaconInOrder().BeaconReported.cLineReported) = 0
            print "m.reportedBeaconStatus - " m.reportedBeaconStatus
            print "AkaMA_isBeaconInOrder().BeaconReported.sLineReported - " AkaMA_isBeaconInOrder().BeaconReported.sLineReported
            if (m.reportedBeaconStatus and AkaMA_isBeaconInOrder().BeaconReported.sLineReported) = 0
                return m.handleErrorEvent(sessionTimer, playbackEndReasonCode, lastHeadPosition)
            endif
            m.lastLogInterval# = (sessionTimer.TotalMilliseconds()/1000.0) -  m.lastLogInterval#
            m.pluginDataStore.addUdpateMediaMetrics({logInterval : AkaMA_strTrim(AkaMA_AnyToString(m.lastLogInterval#)), currentClockTime : AkaMA_AnyToString(sessionTimer.TotalMilliseconds()), endReasonCode:playbackEndReasonCode})
            m.lastLogInterval# = sessionTimer.TotalMilliseconds()/1000.0

            m.sequenceId = m.sequenceId+1
            m.pluginDataStore.addUdpateMediaMetrics({sequenceId : AkaMA_itostr(m.sequenceId), endOfStream : "1",
                                                    currentStreamTime:AkaMA_itostr(lastHeadPosition*1000)})
            m.pluginStatus.moveToState(m.pluginStatus.playEnd, {headPosition:lastHeadPosition}, invalid)
            m.pluginStatus.getStatusMetrics(m.pluginDataStore)
            m.pluginDataStore.addUdpateMediaMetrics({playerState : m.provideStateString()})

            cBeacon = CreateObject("roString")
            cBeacon = m.pluginDataStore.getCLinedataAsString()
            print cBeacon
            if AkaMA_MABeacons().sendBeacon(cBeacon) <> 0
                print "failed to send C-Line"
            else
                print "C-Line sent successfully"
            endif
            m.reportedBeaconStatus = m.reportedBeaconStatus or AkaMA_isBeaconInOrder().BeaconReported.cLineReported
            m.timeSinceLastLine.Mark()
        else
            print"Invalid sequence for cline"
        endif
        'print "cline sent..."
    end function

    provideStateString:function() as string
        playerState = m.pluginStatus.getCurrentState()
        stateString = ""
        if playerState = "initilize"
            stateString = "I"
        else if playerState = "playing"
            stateString = "PL"
        else if playerState = "rebuffer"
            stateString = "B"
        else if playerState = "pause"
            stateString = "PS"
        else if playerState = "seek"
            stateString = "SK"
        else if playerState = "playEnd"
            stateString = "E"
        endif
        return stateString
    end function

    getCurrenPlaybackState:function() as string
        return m.pluginStatus.getCurrentState()
    end function

    handleRebufferEvent:function(sessionTimer, lastHeadPosition)
        m.pluginStatus.moveToState(m.pluginStatus.rebuffering, {headPosition:lastHeadPosition}, {rebufferStart:sessionTimer.TotalMilliseconds(), currentLogTime:m.timeSinceLastLine.TotalMilliseconds()})
    end function

    handleRebufferEndEvent:function(sessionTimer, lastHeadPosition)
    m.pluginStatus.moveToState(m.pluginStatus.playing, {rebufferEnd:sessionTimer.TotalMilliseconds()}, {headPosition:lastHeadPosition})
    end function

    'Function       :   handleErrorEvent
    'Params         :   sessionTimer - a timer for the session
    '                   lastHeadPosition - last stream head postion
    'Return         :   None
    'Description    :   This function handles error condition and on failure sends out E-Beacon
    handleErrorEvent:function(sessionTimer, playbackEndReasonCode, lastHeadPosition)
       'print "send e line ..."
       if (m.reportedBeaconStatus and AkaMA_isBeaconInOrder().BeaconReported.eLineReported) = 0
            m.lastLogInterval# = (sessionTimer.TotalMilliseconds()/1000.0) -  m.lastLogInterval#
            m.pluginDataStore.addUdpateMediaMetrics({logInterval : AkaMA_strTrim(AkaMA_AnyToString(m.lastLogInterval#)), currentClockTime : AkaMA_AnyToString(sessionTimer.TotalMilliseconds())})
            m.lastLogInterval# = sessionTimer.TotalMilliseconds()/1000.0
            if m.sequenceId >= 1
                errCode = playbackEndReasonCode
            else if (sessionTimer.TotalMilliseconds() / 1000) > 900
                errCode = "Application.Close.NoStart.Late"
            else
                errCode = "Application.Close.NoStart"
            endif

            m.sequenceId = m.sequenceId+1
            m.pluginDataStore.addUdpateMediaMetrics({sequenceId : AkaMA_itostr(m.sequenceId), endOfStream : "1", errorCode:errCode,
                                                    currentStreamTime:AkaMA_itostr(lastHeadPosition*1000)})
            m.pluginStatus.moveToState(m.pluginStatus.playEnd, {headPosition:lastHeadPosition}, invalid)
            m.pluginDataStore.addUdpateMediaMetrics({playerState : m.provideStateString()})
            m.pluginStatus.getStatusMetrics(m.pluginDataStore)

             eBeacon = CreateObject("roString")
            eBeacon = m.pluginDataStore.getELinedataAsString()
            print eBeacon
            if AkaMA_MABeacons().sendBeacon(eBeacon) <> 0
                print "failed to send E-Line"
            else
                print "E-Line sent successfully"
            endif
            m.reportedBeaconStatus = m.reportedBeaconStatus or AkaMA_isBeaconInOrder().BeaconReported.eLineReported
            m.timeSinceLastLine.Mark()
            'print "eline sent..."
        else
            print"Invalid sequence for E-line"
        endif

    end function

    'send eline
    'Function       :   handlePlaybackError
    'Params         :   sessionTimer - a timer for the session
    'Return         :   None
    'Description    :   This function handles playback error and sends E-Beacon
    handlePlaybackError : function(sessionTimer)
        'print "send e line ..."
        m.lastLogInterval# = (sessionTimer.TotalMilliseconds()/1000.0) -  m.lastLogInterval#
        m.pluginDataStore.addUdpateMediaMetrics({logInterval : AkaMA_strTrim(AkaMA_AnyToString(m.lastLogInterval#)), currentClockTime : AkaMA_AnyToString(sessionTimer.TotalMilliseconds())})
        m.lastLogInterval# = sessionTimer.TotalMilliseconds()/1000.0

        m.sequenceId = m.sequenceId+1
        m.pluginDataStore.addUdpateMediaMetrics({sequenceId : AkaMA_itostr(m.sequenceId), endOfStream : "1"})
        m.pluginStatus.playing().endPlayingState(m.pluginDataStore)
        m.reportedBeaconStatus = m.reportedBeaconStatus or AkaMA_isBeaconInOrder().BeaconReported.eLineReported
        'print "eline sent..."
    end function

    'send vline
    'Function       :   handleVisit
    'Params         :   sessionTimer - a timer for the session
    'Return         :   None
    'Description    :   This function handles visit for the session and sends V-Beacon
    handleVisit : function(sessionTimer)
        'print "send v line ..."
        m.lastLogInterval# = (sessionTimer.TotalMilliseconds()/1000.0) -  m.lastLogInterval#
        m.pluginDataStore.addUdpateMediaMetrics({logInterval : AkaMA_strTrim(AkaMA_AnyToString(m.lastLogInterval#)), currentClockTime : AkaMA_AnyToString(sessionTimer.TotalMilliseconds())})
        m.lastLogInterval# = sessionTimer.TotalMilliseconds()/1000.0

        m.sequenceId = m.sequenceId+1
        print "setting isVisitEnd to 1"

        pluginGlobals = AkaMA_getPluginGlobals()
        m.pluginDataStore.deleteIfExist("playerState")

        m.pluginDataStore.addUdpateMediaMetrics({sequenceId : AkaMA_itostr(m.sequenceId), isVisitEnd:"1", visitUniqueTitles:AkaMA_itostr(pluginGlobals.uniqueTitles.Count())})
        print "setting isVisitEnd to 1- done"

        vBeacon = CreateObject("roString")
        vBeacon = m.pluginDataStore.getVLinedataAsString()
        print vBeacon
        if AkaMA_MABeacons().sendBeacon(VBeacon) <> 0
            print "failed to send V-Line"
        else
            print "V-Line sent successfully"
        endif

        print"resetting unique titles..."
        'pluginGlobals = AkaMA_getPluginGlobals()
        pluginGlobals.uniqueTitles = invalid
        pluginGlobals.uniqueTitles = []
        pluginGlobals.isVisitSent = false
        pluginGlobals.isFirstTitleSent = false
        print"resetting unique titles... - done"
        m.reportedBeaconStatus = m.reportedBeaconStatus or AkaMA_isBeaconInOrder().BeaconReported.vLineReported
        'print "vline sent..."
    end function

    handlePlaybackPauseEvent:function(sessionTimer, lastHeadPosition)
        m.pluginStatus.moveToState(m.pluginStatus.pause, {headPosition:lastHeadPosition}, invalid)
    end function

    handlePlaybackResumeEvent:function(sessionTimer, lastHeadPosition)
        m.pluginStatus.moveToState(m.pluginStatus.playing, invalid, {headPosition:lastHeadPosition})
    end function

    handlePlaybackSeekEvent:function(sessionTimer, lastHeadPosition)
        m.pluginStatus.moveToState(m.pluginStatus.seek, {headPosition:lastHeadPosition}, invalid)
    end function

    handlePlaybackSeekEndEvent:function(sessionTimer, lastHeadPosition, streamInfo)
        m.pluginStatus.moveToState(m.pluginStatus.playing, invalid, {headPosition:lastHeadPosition, currentStreamInfo:streamInfo})
    end function


    handleAdLoaded:function(params)
        print"handle ad load"
        if (m.reportedBeaconStatus and AkaMA_isBeaconInOrder().BeaconReported.sLineReported) = 0
            params.AddReplace("adType","pre-roll")
        else if (m.reportedBeaconStatus and AkaMA_isBeaconInOrder().BeaconReported.cLineReported) = 0
            params.AddReplace("adType","mid-roll")
        else
            params.AddReplace("adType","post-roll")
        endif
        'params.AddReplace("startPos", m.currentHeadPosition)
        m.pluginStatus.moveToState(m.pluginStatus.ad, invalid, params)
    end function

    handleAdStarted:function(params)
        print"handle ad startup"
        params.addReplace("AkaMA_updateEvent", "adStartUp")
        m.pluginStatus.updateCurrentState(params)
    end function

    handleAdFirstQuartile:function(params)
        print"handle ad firstQuartile"
        if params <> invalid
            params.addReplace("AkaMA_updateEvent", "adFirstQuartile")
            m.pluginStatus.updateCurrentState(params)
         else
            m.pluginStatus.updateCurrentState({AkaMA_updateEvent: "adFirstQuartile"})
         endif
    end function

    handleAdMidpoint:function(params)
        print"handle ad midpoint"
        if params <> invalid
            params.addReplace("AkaMA_updateEvent", "adMidPoint")
            m.pluginStatus.updateCurrentState(params)
         else
            m.pluginStatus.updateCurrentState({AkaMA_updateEvent: "adMidPoint"})
         endif
    end function

    handleAdThirdQuartile:function(params)
        print"handle ad thirdQuartile"
        if params <> invalid
            params.addReplace("AkaMA_updateEvent", "adThirdQuartile")
            m.pluginStatus.updateCurrentState(params)
         else
            m.pluginStatus.updateCurrentState({AkaMA_updateEvent: "adThirdQuartile"})
         endif
    end function

    handleAdComplete:function(params, lastHeadPosition)
        print"handle ad completion event"
        if params <> invalid
            params.addReplace("AkaMA_updateEvent", "adComplete")
            m.pluginStatus.updateCurrentState(params)
        else
            m.pluginStatus.updateCurrentState({AkaMA_updateEvent:"adComplete"})
        endif
        m.pluginStatus.moveToState(m.pluginStatus.adEnded, invalid, invalid)
    end function

    handleAdStopped:function(params, lastHeadPosition)
        print"handle ad stopped event"
        if params <> invalid
            params.addReplace("AkaMA_updateEvent","adStopped")
            params.addReplace("endReason","1")
            m.pluginStatus.updateCurrentState(params)
        else
            m.pluginStatus.updateCurrentState({AkaMA_updateEvent:"adStopped", endReason:"2"})
        endif

        m.pluginStatus.moveToState(m.pluginStatus.adEnded, invalid, invalid)
    end function

    handleAdEnd:function(params, lastHeadPosition)
        print"handle ad end event"
        if params <> invalid
            params.addReplace("AkaMA_updateEvent", "adEnded")
            m.pluginStatus.updateCurrentState(params)
        else
            m.pluginStatus.updateCurrentState({AkaMA_updateEvent:"adEnded"})
        endif

        m.pluginStatus.moveToState(m.pluginStatus.adEnded, invalid, invalid)
    end function

    handleAdError:function(params, lastHeadPosition)
         print"handle ad stooped event"
        if params <> invalid
            params.addReplace("AkaMA_updateEvent","adError")
            m.pluginStatus.updateCurrentState(params)
        else
            m.pluginStatus.updateCurrentState({AkaMA_updateEvent:"adError"})
        endif

        m.pluginStatus.moveToState(m.pluginStatus.adEnded, invalid, invalid)
    end function

    populateStreaminfo: function(currentStreamInfo, bufferTime)
        connectionTime = 0
        updateParams = {
                        bufferingTime   :   AkaMA_itostr(bufferTime)
                        startupTime     :   AkaMA_itostr(connectionTime + bufferTime)
                       }
        if currentStreamInfo <> invalid
            'Check if URL exist and it is a string object
            if currentStreamInfo.DoesExist("streamUrl") = true and AkaMA_isstr(currentStreamInfo.streamUrl) = true
                regularExpression = CreateObject ("roRegex", "(\w+:)\/\/([^\/:]+):?([^\/]+)?(\/[^#?]*)#?([^?]+)?\??(.+)?", "i")
                matchingObjects = regularExpression.Match (currentStreamInfo.streamUrl)
                streamUrl = ""
                if AkaMA_isnullorempty(matchingObjects[1]) = false and AkaMA_isnullorempty(matchingObjects[2]) = false
                    streamUrl = matchingObjects[1] + "//" + matchingObjects[2]
                end if
                if AkaMA_isnullorempty(matchingObjects[3]) = false
                    streamUrl =  streamUrl + ":"+ matchingObjects[3]
                end if
                if AkaMA_isnullorempty(matchingObjects[4]) = false
                    streamUrl =  streamUrl + matchingObjects[4]
                end if
                updateParams.addReplace("streamUrl", streamUrl)
                token = AkaMA_strTokenize(streamUrl, "/")
                updateParams.addReplace("streamName", token[token.count()-1])
            else
                print "current URL is not valid url- not a string object"
                token = ["unknown"]
            endif

            'Check if title exist in custom dimensions and it is a string object
            if m.pluginDataStore.custDimension.DoesExist("title") and AkaMA_isstr(currentStreamInfo.streamUrl) = true
                print"setting title=";m.pluginDataStore.custDimension["title"]
                m.updateVisitUniqueTitles(m.pluginDataStore.custDimension["title"])
            else
            	print"setting title from token"
                m.updateVisitUniqueTitles(token[token.count()-1])
            endif
            if m.pluginDataStore.mediaMetrics.DoesExist("format") = false
                if token.count() >= 1
                    if token[token.count()-1].Instr("m3u8") <> -1
                        print"format is HLS value = "
                        updateParams.addReplace("format","HLS")
                    else if token[token.count()-1].Instr(".mpd") <> -1
                        print"format is DASH value = "
                        updateParams.addReplace("format","DASH")
                    else if token[token.count()-1].Instr("mp4") <> -1
                        print"format is l value = "
                        updateParams.addReplace("format","P")
                    endif
                else if token.count() >= 2
                    if token[token.count()-2].Instr("ism") <> -1 or token[token.count()-2].Instr("ismv") <> -1
                        print"format is MSS value = "
                        updateParams.addReplace("format","MSS")
                    endif
                else
                    print"format is could not be verified = ";token[token.count()-1].Instr("m3u8")
                endif
            else
                print"format was already set."
            endif

            updateParams.addReplace("protocol", left(token[0],len(token[0])-1))
            if left(token[0],len(token[0])-1) = "http"
                updateParams.addReplace("port", "80")
            else if left(token[0],len(token[0])-1) = "https"
                updateParams.addReplace("port", "443")
            end if
        end if

         m.pluginDataStore.addUdpateMediaMetrics(updateParams)
    end function

    updateBitrateInfo:function(streamInfo, lastHeadPosition)
        print "measured bitrate = "; streamInfo.MeasuredBitrate
        print "lastHeadPosition = "; lastHeadPosition
        m.pluginStatus.updateStreamInfo({currentStreamInfo:streamInfo, headPosition:lastHeadPosition})
        'Need to get playStreamtime
    end function

    updateBandwidthInfo:function(bw)
        if m.measuredBandwidth = invalid
            m.measuredBandwidth = bw
        else
            if m.measuredBandwidth < bw
                m.measuredBandwidth = bw
            endif
        endif
        m.pluginDataStore.addUdpateMediaMetrics({maxBandwidth : AkaMA_itostr(m.measuredBandwidth)})
    end function

    updatePlaybackInformation:function(playbackInfo)
        m.pluginDataStore.addUdpateMediaMetrics(playbackInfo)
    end function

    populateViewerDiagnosticsId:function()
        if m.pluginDataStore.mmconfig.securityViewerDiagnosticsInfo <> invalid
            'Get iterations
            if m.pluginDataStore.mmconfig.securityViewerDiagnosticsInfo["iterations"] <> invalid
                iter = strtoi(m.pluginDataStore.mmconfig.securityViewerDiagnosticsInfo["iterations"])
            else
                iter = AkaMA_PluginConsts().viewerDiagIterations
            end if

            'Get desired bytes
            if m.pluginDataStore.mmconfig.securityViewerDiagnosticsInfo["bytes"] <> invalid
                bytes = strtoi(m.pluginDataStore.mmconfig.securityViewerDiagnosticsInfo["bytes"])
            else
                bytes = AkaMA_PluginConsts().viewerDiagBytes
            end if

            'Get password either from viewerDiagnostics id or from viewerId. Don't set viewer diagnostics id if none is present
            password = invalid
            if m.viewerDiagnosticsId <> invalid
                password = m.viewerDiagnosticsId
            else if m.viewerId <> invalid
                password = m.viewerId
            endif

            if password <> invalid and m.pluginDataStore.mmconfig.securityViewerDiagnosticsInfo["value"] <> invalid
                'Get hased valud of viewerDiagnostics id
                print " executing PBKDF2 with password = "; password;" salt= ";m.pluginDataStore.mmconfig.securityViewerDiagnosticsInfo["value"];" iter= ";iter;" bytes= ";bytes
                hashedViewerDiag = AkaMA_PBKDF2(password, m.pluginDataStore.mmconfig.securityViewerDiagnosticsInfo["value"], iter, bytes)
                print "Derieved hashed ViewerDiag = ";hashedViewerDiag

                'Populate viewerDiagnostics version and id in media metrics
                m.pluginDataStore.addUdpateMediaMetrics({xViewerIdVersion : m.pluginDataStore.mmconfig.securityViewerDiagnosticsInfo["version"], xViewerId:hashedViewerDiag})
            end if

        endif
    end function

    updateVisitUniqueTitles:function(streamTitle)
        pluginGlobals = AkaMA_getPluginGlobals()
        bFoundTitle = false
        pluginGlobals.uniqueTitles = invalid
        print "Plugin globals = "; pluginGlobals; " and temp = ";pluginGlobals.temp
        if pluginGlobals.uniqueTitles = invalid
        	pluginGlobals.uniqueTitles = []
        endif

        if pluginGlobals.uniqueTitles.Count() = 0
            pluginGlobals.uniqueTitles.Push(streamTitle)
            print"adding first title to list=";streamTitle
        else
            for each name in pluginGlobals.uniqueTitles
                if name = streamTitle
                    print"found the title no need to add"
                    bFoundTitle = true
                endif
            next
            if bFoundTitle <> true
                pluginGlobals.uniqueTitles.Push(streamTitle)
                print"adding title to list=";streamTitle
            endif
        endif
        print "Plugin globals = "; pluginGlobals
    end function

    }
    end function
}
end function


'Function       :   initConfigurationXML
'Params         :   configXMl as string
'Return         :   None
'Description    :   This function parses the configuration xml
FUNCTION initConfigurationXML(configXML as string) as object
    AkaMA_logger().AkaMA_print("Executing initConfigXML")
    configXMLReq = AkaMA_NewHttp(configXML)
    configXMLString = CreateObject("roString")
    configXMLString = ""
    configXMLString = configXMLReq.GetToStringWithRetry()
    xmlObject = AkaMA_ParseXML(configXMLString)
    return xmlObject
END FUNCTION
' Validator /  outlier check
' This file checks for outliers as well as provides
' validation functions for validating inputs, urls,
' params etc

function AkaMA_Validator_OutlierCheck() as integer
return {
    urlValidator : validateURL
 }
end function' this file contians all the functions related to debug messages
' and other supporting functions for debugging

'Function       :   AkaMA_logger
'Params         :   None
'Return         :   set of functions to switch logging / trace on/off
'Description    :   Set enableLogging to true if logging needs to be printed on the console
'                   set enableTracing to true if trace nees to be printed on the console

function AkaMA_logger()
return {
    isLoggingEnabled    :   false           'Represents logging state
    isTraceEnabled      :   false           'Represents trace state


    'turns logging on/off
    enableLogging : function(loggingEnabled)
        m.isLoggingEnabled = loggingEnabled
    end function
    ' prints log if isLoggingEnabled is true
    AkaMA_print : function(debugLog)
        if m.isLoggingEnabled <> false
            print debugLog
        endif
    end function

    'turns tracing on/off
    eanbelTrace : function(traceEnabled)
        m.isTraceEnabled = traceEnabled
    end function
    'prings trace if isTraceEnabled is true
    AkaMA_Trace : function(traceLog)
        if m.isTraceEnabled <> false
            print debugLog
        endif
    end function
}
end function

'******************************************************
'Walk an AA and print it
'******************************************************
Sub AkaMA_PrintAA(aa as Object)
    print "---- AA ----"
    if aa = invalid
        print "invalid"
        return
    else
        cnt = 0
        for each e in aa
            x = aa[e]
            AkaMA_PrintAny(0, e + ": ", aa[e])
            cnt = cnt + 1
        next
        if cnt = 0
            AkaMA_PrintAny(0, "Nothing from for each. Looks like :", aa)
        endif
    endif
    print "------------"
End Sub


''******************************************************
''Walk a list and print it
''******************************************************
'Sub PrintList(list as Object)
'    print "---- list ----"
'    AkaMA_PrintAnyList(0, list)
'    print "--------------"
'End Sub


'******************************************************
'Print an associativearray
'******************************************************
Sub AkaMA_PrintAnyAA(depth As Integer, aa as Object)
 if type(aa) = "roAssociativeArray" then
    for each e in aa
        x = aa[e]
        AkaMA_PrintAny(depth, e + ": ", aa[e])
    next
 endif
End Sub


'******************************************************
'Print a list with indent depth
'******************************************************
Sub AkaMA_PrintAnyList(depth As Integer, list as Object)
    i = 0
    for each e in list
        AkaMA_PrintAny(depth, "List(" + AkaMA_itostr(i) + ")= ", e)
        i = i + 1
    next
End Sub

Sub AkaMA_tooDeep(depth As Integer) As Boolean
    hitLimit = (depth >= 10)
    if hitLimit then  print "**** TOO DEEP "; depth
    return hitLimit
End Sub

'******************************************************
'Print anything
'******************************************************
Sub AkaMA_PrintAny(depth As Integer, prefix As String, any As Dynamic)
    if AkaMA_tooDeep(depth) then return
    prefix = string(depth*2," ") + prefix
    depth = depth + 1
    str = AkaMA_AnyToString(any)
    if str <> invalid
        print prefix + str
        return
    endif
    if type(any) = "roAssociativeArray"
        print prefix + "(assocarr)..."
        AkaMA_PrintAnyAA(depth, any)
        return
    endif
    if AkaMA_islist(any) = true
        print prefix + "(list of " + AkaMA_itostr(any.Count()) + ")..."
        AkaMA_PrintAnyList(depth, any)
        return
    endif

    print prefix + "?" + type(any) + "?"
End Sub

'******************************************************
'Print an object as a string for debugging. If it is
'very long print the first 500 chars.
'******************************************************
Sub AkaMA_Dbg(pre As Dynamic, o=invalid As Dynamic)
    p = AkaMA_AnyToString(pre)
    if p = invalid p = ""
    if o = invalid o = ""
    s = AkaMA_AnyToString(o)
    if s = invalid s = "???: " + type(o)
    if Len(s) > 4000
        s = Left(s, 4000)
    endif
    print p + s
End Sub

'******************************************************
'Walk an XML tree and print it
'******************************************************
Sub AkaMA_PrintXML(element As Object, depth As Integer)
    print tab(depth*3);"Name: [" + element.GetName() + "]"
    if invalid <> element.GetAttributes() then
        print tab(depth*3);"Attributes: ";
        for each a in element.GetAttributes()
            print a;"=";left(element.GetAttributes()[a], 4000);
            if element.GetAttributes().IsNext() then print ", ";
        next
        print
    endif

    if element.GetBody()=invalid then
        ' print tab(depth*3);"No Body"
    else if type(element.GetBody())="roString" then
        print tab(depth*3);"Contains string: [" + left(element.GetBody(), 4000) + "]"
    else
        print tab(depth*3);"Contains list:"
        for each e in element.GetBody()
            AkaMA_PrintXML(e, depth+1)
        next
    endif
    print
end sub


'******************************************************
'islist
'
'Determine if the given object supports the ifList interface
'******************************************************
Function AkaMA_islist(obj as dynamic) As Boolean
    if obj = invalid return false
    if GetInterface(obj, "ifArray") = invalid return false
    return true
End Function


'******************************************************
'AkaMA_isint
'
'Determine if the given object supports the ifInt interface
'******************************************************
Function AkaMA_isint(obj as dynamic) As Boolean
    if obj = invalid return false
    if GetInterface(obj, "ifInt") = invalid return false
    return true
End Function

'******************************************************
' AkaMA_validstr
'
' always return a valid string. if the argument is
' invalid or not a string, return an empty string
'******************************************************
Function AkaMA_validstr(obj As Dynamic) As String
    if AkaMA_isnonemptystr(obj) return obj
    return ""
End Function


'******************************************************
'AkaMA_isstr
'
'Determine if the given object supports the ifString interface
'******************************************************
Function AkaMA_isstr(obj as dynamic) As Boolean
    if obj = invalid return false
    if GetInterface(obj, "ifString") = invalid return false
    return true
End Function


'******************************************************
'AkaMA_isnonemptystr
'
'Determine if the given object supports the ifString interface
'and returns a string of non zero length
'******************************************************
Function AkaMA_isnonemptystr(obj)
    if AkaMA_isnullorempty(obj) return false
    return true
End Function


'******************************************************
'AkaMA_isnullorempty
'
'Determine if the given object is invalid or supports
'the ifString interface and returns a string of non zero length
'******************************************************
Function AkaMA_isnullorempty(obj)
    if obj = invalid return true
    if not AkaMA_isstr(obj) return true
    if Len(obj) = 0 return true
    return false
End Function


'******************************************************
'AkaMA_isbool
'
'Determine if the given object supports the ifBoolean interface
'******************************************************
Function AkaMA_isbool(obj as dynamic) As Boolean
    if obj = invalid return false
    if GetInterface(obj, "ifBoolean") = invalid return false
    return true
End Function


'******************************************************
'AkaMA_isfloat
'
'Determine if the given object supports the ifFloat interface
'******************************************************
Function AkaMA_isfloat(obj as dynamic) As Boolean
    if obj = invalid return false
    if GetInterface(obj, "ifFloat") = invalid return false
    return true
End Function




'******************************************************
'AkaMA_itostr
'
'Convert int to string. This is necessary because
'the builtin Stri(x) prepends whitespace
'******************************************************
Function AkaMA_itostr(i As Integer) As String
    str = Stri(i)
    return AkaMA_strTrim(str)
End Function

'******************************************************
'Trim a string
'******************************************************
Function AkaMA_strTrim(str As String) As String
    st=CreateObject("roString")
    st.SetString(str)
    return st.Trim()
End Function
' this file contians error codes which can be used
' by the plugin in different functions


FUNCTION AkaMAErrors()
return {
    ERROR_CODES : {
      AKAM_Success                      : 0
      AKAM_Configuration_url_failed     : 1
      AKAM_Invalid_configuration_xml    : 2
      AKAM_xml_parsing_failed           : 3
      AKAM_beacon_request_failed        : 4
      AKAM_InvalidBeaconSequence        : 5
      AKAM_StateIsNotValid              : 6
      AKAM_Unknown                      : 7
    }
   }
END FUNCTION ' this file contians all the functions related to generating PBKDF2 hasing
' and other supporting functions for the same


'Function       :   AkaMA_PBKDF2
'Params         :   None
'Return         :   GUID string
'Description    :   Returns PBDFK2 hashing
'Below is PBKDF2 derivation process
'
' The PBKDF2 key derivation function has five input parameters:
' DK = PBKDF2(PRF, Password, Salt, c, dkLen)
' where:
'
' PRF is a pseudorandom function of two parameters with output length hLen (e.g. a keyed HMAC)
' Password is the master password from which a derived key is generated
' Salt is a cryptographic salt
' c is the number of iterations desired
' dkLen is the desired length of the derived key
' DK is the generated derived key
' Each hLen-bit block Ti of derived key DK, is computed as follows:
'
' DK = T1 || T2 || ... || Tdklen/hlen
' Ti = F(Password, Salt, Iterations, i)
' The function F is the xor (^) of c iterations of chained PRFs. The first iteration of PRF uses
' Password as the PRF key and Salt concatenated to i encoded as a big-endian 32-bit integer. (Note that i is a 1-based index.)
' Subsequent iterations of PRF use Password as the PRF key and the output of the previous PRF computation as the salt:
'
' F(Password, Salt, Iterations, i) = U1 ^ U2 ^ ... ^ Uc
' where:
'
' U1 = PRF(Password, Salt || INT_msb(i))
' U2 = PRF(Password, U1)
' ...
' Uc = PRF(Password, Uc-1)
' For example, WPA2 uses:
'
' DK = PBKDF2(HMAC−SHA1, passphrase, ssid, 4096, 256)
'
' 1) Based on the above description firstly we need to create blocks of size hLen
' Define / get hLen (size in bytes) and do
' no of blocks = (desired length in bytes (IN_PARAM) + hLen-1) / hlen
'
' 2) allocate output with
'   outputBytes = no of blocks * hLen
'
' 3) Password(IN_PARAM) key should be of exact lenght of block. add padding to password if less than block length,
' Hash password if it is longer than the block length
'
' 4) iterate through each block (check step 1 - no. of blocks)
'{
'   5) Get the big endian for the calculation of frist U-iteration : U1
'   6) Calculate first iterations U1 =  PRF(Password, Salt || INT_msb(i))
'   7) run hashfunctions for the no. of desired interations (IN_PARAM) : i= 2 to no. of desired interations
'   {
'       8) Calculate Hash function for Ui +  update temp values for next iterations
'       9) Do XOR with output (all should be 1s as XOR will overrite values otherwise) and Ui
'   }
'   10) update the offsets and other variables to point to the next block
'}
'
'11) Copy output to the result and return the result
'

function AkaMA_PBKDF2(password as object, salt as object, iterations as integer, desiredBytes as integer) as string
    hLenInBytes         =   20
    blockSizeInBytes    =   64
    resultStartOffset   =   0

    'Step-1 calculate no of blocks
    noOfBlocks = (desiredBytes + hLenInBytes-1) / hLenInBytes

    'Step-2 create output to hold the result
    resultBlock = CreateObject("roByteArray")

    'Step-3 Password hash or paddding
    ba = CreateObject("roByteArray")
    ba.FromAsciiString(password)
    if ba.count() > blockSizeInBytes
        digest = CreateObject("roEVPDigest")
        digest.Setup("sha1")
        result = digest.Process(ba)
        ba = result
        digest = invalid
    endif

    'key = ba

    'Step-4 run loop for all blocks
    for block=1 to noOfBlocks
        inblock = CreateObject("roByteArray")
        inblock.FromAsciiString(salt)
        saltLen = inblock.count()'len(salt)

        'Step-5 Get the big endian for the calculation of frist U-iteration : U1
        inblock[saltLen + 0] = AkaMA_RightShift(block, 24)
        inblock[saltLen + 1] = AkaMA_RightShift(block, 16)
        inblock[saltLen + 2] = AkaMA_RightShift(block, 8)
        inblock[saltLen + 3] = block

        'step-6 Calculate first iterations U1 =  PRF(Password, Salt || INT_msb(i))
        outBlock = CreateObject("roByteArray")
        outBlock = AkaMA_PBKDF2_F(ba, inblock)
        resultBlock.Append(outBlock)

        'Step-7 run hashfunctions for the no. of desired interations (IN_PARAM) : i= 2 to no. of desired interations
        for iter=2 to iterations
            tempBlock = inblock
            inblock = outBlock
            outBlock = tempBlock
            outBlock = AkaMA_PBKDF2_F(ba, inblock)   'Step-8 Calculate Hash function for Ui +  update temp values for next iterations
            'Step-9 Do XOR with output (all should be 1s as XOR will overrite values otherwise) and Ui
            for b=0 to hLenInBytes-1
                'print "resultBlock[] = ";resultBlock[resultStartOffset+b];" and outblock[] = ";outBlock[b]
                resultBlock[resultStartOffset+b] = AkaMA_XOR(resultBlock[resultStartOffset+b], outBlock[b]) ' working code

            end for
        end for
        'Step-10: update the offsets and other variables to point to the next block
        'print"resultBlock="; resultBlock;"resultStartOffset = ";resultStartOffset
        resultStartOffset = resultStartOffset + hLenInBytes
        inblock = invalid
        outBlock = invalid
    end for

    'Step-11:Copy output to the result and return the result
    finalHash = LCase(resultBlock.ToHexString())
    'print "Final hash string= "finalHash.left(desiredBytes*2)

    ba = invalid
    resultBlock = invalid
    return finalHash.left(desiredBytes*2)
end function


'Function       :   AkaMA_PBKDF2_F
'Params         :   None
'Return         :
'Description    :   A function which calculates hash for individual block. refer to F(Password, Salt, Iterations, i)
' This function uses HMAC for hashing. We need has key(password) and salt (with index for the first iteration)
function AkaMA_PBKDF2_F(inKey as object, iBlock as object) as object
    innerHmac = CreateObject("roHMAC")
    ba = CreateObject("roByteArray")
    ba = inKey
    result = CreateObject("roByteArray")
    if innerHmac.setup("sha1", ba) = 0
        innerHmac.update(iBlock)
        result = innerHmac.final()
    end if
    ba = invalid
    innerHmac = invalid
    return result
end function

'Function       :   AkaMA_XOR
'Params         :
'Return         :   returns xor value for an integer
'Description    :   Do and operation in xorLhs and or operation in xorRhs.
'                   do and operation on xorLhs, xorRhs and return the result
function AkaMA_XOR(lhs as object, rhs as object) as object
'if lhs <> invalid and rhs <> invalid
    xorLhs = (lhs and not rhs)
    xorRhs =  (not lhs and rhs)
    return (xorLhs or xorRhs)
'endif
'return invalid
end function

'Function       :   AkaMA_LeftShift
'Params         :
'Return         :   returns xor value for an integer
'Description    :   Do and operation in xorLhs and or operation in xorRhs.
'                   do and operation on xorLhs, xorRhs and return the result
function AkaMA_LeftShift(num as integer, noOfShifts as integer) as integer
    totalPower = 0
    for index=0 to noOfShifts
        totalPower = totalPower + (2^index)
    end for
    return num*totalPower
end function

'Function       :   AkaMA_RightShift
'Params         :
'Return         :   returns xor value for an integer
'Description    :   Do and operation in xorLhs and or operation in xorRhs.
'                   do and operation on xorLhs, xorRhs and return the result
function AkaMA_RightShift(num as integer, noOfShifts as integer) as integer
    totalPower = 0
    for index=0 to noOfShifts
        totalPower = totalPower + (2^index)
    end for
    return num/totalPower
end function'Holds values for constant varaibles of plugin
'

function AkaMA_PluginConsts()
    return {
        pluginVersion           :   "Roku-2.5.3"
        viewerDiagIterations    :   50
        viewerDiagBytes         :   16
    }
end function
' This file will hold for storing data into "Registry".
' It provides methods for deleting, accessing and updating
' into the "Registry".

'Function       :   AkaMA_createStorageManager
'Params         :   None
'Return         :   Returns newly created Storage Manager
'Description    :   Provides a set of methods to access and modify the "Registry".
'
function AkaMA_createStorageManager()
storageManager = {

    'Function       :   lastAccessTime
    'Params         :   fieldName The field to be queried in the Registry.
    'Return         :   The time at which the field was last updated.
    'Description    :   Checks Registry to find out the last time the field was updated.
    'Warn           :   Will return 0 if data is not found.
    lastAccessTime: function(fieldName as String)  as Integer
        AkaMA_logger().AkaMA_print("========= lastAccessTime ===== ")
        lastUsedTime = 0
        registrySection = CreateObject("roRegistrySection", "UniqueViewers")
        if registrySection.Exists(fieldName)
            keyInformation = registrySection.Read(fieldName)
            regularExpression = CreateObject ("roRegex", "^.*accessTime:(.*?),", "i")
            matchingObjects = regularExpression.Match (keyInformation)
            if matchingObjects.Count() > 0
                accessTime = matchingObjects[1]
                lastUsedTime = accessTime.ToInt()
            endif
        endif
        return lastUsedTime
    end function

    'Function       :   deleteExpiredData
    'Params         :   None
    'Return         :   None
    'Description    :   Deletes any data that has stayed beyond it's expiry date.
    'Warn           :   If your data is missing. Check if this method was called.
    deleteExpiredData: function() as Void
        AkaMA_logger().AkaMA_print("========= deleteExpiredData ===== ")
        time = CreateObject("roDateTime")
        currentTime = time.AsSeconds()
        registrySection = CreateObject("roRegistrySection", "UniqueViewers")
        keyList = registrySection.GetKeyList()
        regularExpression = CreateObject ("roRegex", "^.*expiryTime:(.*?)$", "i")

        for each key in keyList
            keyInformation = registrySection.Read(key)
            matchingObjects = regularExpression.Match (keyInformation)
            if matchingObjects.Count() > 0
                expiryTime = matchingObjects[1]
                expiryTimeInt = expiryTime.ToInt()
                if (expiryTimeInt < currentTime)
                    registrySection.Delete(key)
                endif
            endif
        next
    end function


    'Function       :   addOrUpdate
    'Params         :   fieldName The field to be added to the Registry.
    'Params         :   currentTime Current system time in seconds.
    'Params         :   expiryTime Future time on which the entry has to be deleted. (in seconds)
    'Return         :   None
    'Description    :   Adds/updates a new entry to the localStorage.
    'Warn           :   key has to be unique. If there is a previous entry with the  same name, it will be updated
    '                   with the new "currentTime" and "expiryTime".
    addOrUpdate: function(fieldName as String, currentTime as Integer, expiryTime as Integer)
        AkaMA_logger().AkaMA_print("========= addOrUpdate ===== ")
        tempTime% = currentTime
        registrySection = CreateObject("roRegistrySection", "UniqueViewers")
        if currentTime > 0 and expiryTime > 0
            expiringData = "accessTime:" + StrI(tempTime%).Trim() + ", expiryTime:" + StrI(expiryTime)
            opStatus = registrySection.Write(fieldName, expiringData)
            registrySection.Flush()
        endif
    end function
}

return storageManager
end function'******************************************************
'Try to convert anything to a string. Only works on simple items.
'
'Test with this script...
'
'    s$ = "yo1"
'    ss = "yo2"
'    i% = 111
'    ii = 222
'    f! = 333.333
'    ff = 444.444
'    d# = 555.555
'    dd = 555.555
'    bb = true
'
'    so = CreateObject("roString")
'    so.SetString("strobj")
'    io = CreateObject("roInt")
'    io.SetInt(666)
'    tm = CreateObject("roTimespan")
'
'    Dbg("", s$ ) 'call the Dbg() function which calls AkaMA_AnyToString()
'    Dbg("", ss )
'    Dbg("", "yo3")
'    Dbg("", i% )
'    Dbg("", ii )
'    Dbg("", 2222 )
'    Dbg("", f! )
'    Dbg("", ff )
'    Dbg("", 3333.3333 )
'    Dbg("", d# )
'    Dbg("", dd )
'    Dbg("", so )
'    Dbg("", io )
'    Dbg("", bb )
'    Dbg("", true )
'    Dbg("", tm )
'
'try to convert an object to a string. return invalid if can't
'******************************************************
Function AkaMA_AnyToString(any As Dynamic) As dynamic
    if any = invalid return "invalid"
    if AkaMA_isstr(any) return any
    if AkaMA_isint(any) return AkaMA_itostr(any)
    if AkaMA_isbool(any)
        if any = true return "true"
        return "false"
    endif
    if AkaMA_isfloat(any) return Str(any)
    if type(any) = "roTimespan" return AkaMA_itostr(any.TotalMilliseconds()) + "ms"
    return invalid
End Function

'******************************************************
'Tokenize a string. Return roList of strings
'******************************************************
Function AkaMA_strTokenize(str As String, delim As String) As Object
    if str <> invalid and delim <> invalid
        st=CreateObject("roString")
        st.SetString(str)
        return st.Tokenize(delim)
    endif
End Function

'******************************************************
'Replace substrings in a string. Return new string
'******************************************************
Function AkaMA_strReplace(basestr As String, oldsub As String, newsub As String) As String
    newstr = ""

    i = 1
    while i <= Len(basestr)
        x = Instr(i, basestr, oldsub)
        if x = 0 then
            newstr = newstr + Mid(basestr, i)
            exit while
        endif

        if x > i then
            newstr = newstr + Mid(basestr, i, x-i)
            i = x
        endif

        newstr = newstr + newsub
        i = i + Len(oldsub)
    end while

    return newstr
End Function

Function AkaMA_str8859toutf8(obj as dynamic) As String
    r = ""
    if AkaMA_isnonemptystr(obj)
        l = len(obj)
        for i=1 to l
            c = mid(obj,i,1)
            a = asc(c)
            if a<0 then a = a + 256
            if a<160
                s = c
            else if a<192
                s = chr(194) + chr(a)
            else
                s = chr(195) + chr(a-64)
            end if
            r = r + s
        end for
    end if
    'print "converted string = "; r
    return r
End Function

function AkaMA_doubleToString(originalVal as double) as string
    modVal% = originalVal mod 10
    print "mod value  = "; modVal%; "original value = "; originalVal
    retStr = box("")
    if originalVal <> 0
        originalVal = originalVal - modVal%
        originalVal = originalVal / 10
        result = AkaMA_doubleToString(originalVal)
        modString = modVal%.tostr()
        print "original value  = "; originalVal; " and return result = "; result
        retStr.ifstringops.AppendString(result, result.len())
        retStr.ifstringops.AppendString(modString, modString.len())
    else
        print "return str = "; retStr
       return retStr
    endif
    return retStr
end function

function AkaMA_doubleToStr(originalVal) as string
    modVal = originalVal mod 10
    if originalVal <> 0
        tempVal% = originalVal - modVal
        tempVal% = originalVal / 10
        result = AkaMA_doubleToStr(tempVal%)
        modString = Str(modVal).Trim()
        result = result + modString
        'print "original value  = "; originalVal; " and return result = "; result
        'retStr.ifstringops.AppendString(result, result.len())
        'retStr.ifstringops.AppendString(modString, modString.len())
        'result = invalid
    else
        'print "return str = "; retStr
        retStr = box("")
        return retStr
    endif
    return result
end function


'**********************************************************
'**  Video Player Example Application - URL Utilities
'**  November 2009
'**  Copyright (c) 2009 Roku Inc. All Rights Reserved.
'**********************************************************

' ******************************************************
' Constucts a URL Transfer object
' ******************************************************

Function AkaMA_CreateURLTransferObject(url As String) as Object
    obj = CreateObject("roUrlTransfer")
    obj.SetPort(CreateObject("roMessagePort"))
    'obj.SetUrl(obj.UrlEncode(url))
    'obj.SetUrl(obj.Escape(url))
    obj.SetUrl(url)
    'obj.SetUrl(AkaMA_HttpEncode(url))

    'obj.SetCertificatesFile("pkg:/testCA.CRT")
    obj.SetCertificatesFile("common:/certs/ca-bundle.crt")
    obj.AddHeader("X-Roku-Reserved-Dev-Id", "")
    obj.InitClientCertificates()

    obj.AddHeader("Content-Type", "application/x-www-form-urlencoded")
    obj.EnableEncodings(true)
    return obj
End Function

' ******************************************************
' Url Query builder
' so this is a quick and dirty name/value encoder/accumulator
' ******************************************************

Function AkaMA_NewHttp(url As String) as Object
    obj = CreateObject("roAssociativeArray")
    obj.Http                        = AkaMA_CreateURLTransferObject(url)
    obj.FirstParam                  = true
    obj.AddParam                    = AkaMA_http_add_param
    obj.AddRawQuery                 = AkaMA_http_add_raw_query
    obj.GetToStringWithRetry        = AkaMA_http_get_to_string_with_retry
    obj.PrepareUrlForQuery          = AkaMA_http_prepare_url_for_query
    obj.GetToStringWithTimeout      = AkaMA_http_get_to_string_with_timeout
    obj.PostFromStringWithTimeout   = AkaMA_http_post_from_string_with_timeout

    if Instr(1, url, "?") > 0 then obj.FirstParam = false

    return obj
End Function


' ******************************************************
' Constucts a URL Transfer object 2
' ******************************************************

Function AkaMA_CreateURLTransferObject2(url As String, contentHeader As String) as Object
    obj = CreateObject("roUrlTransfer")
    obj.SetPort(CreateObject("roMessagePort"))
    'requestURL = obj.UrlEncode(obj.Escape(url))
    obj.SetUrl(url)
    obj.AddHeader("Content-Type", contentHeader)
    obj.EnableEncodings(true)
    return obj
End Function

' ******************************************************
' Url Query builder 2
' so this is a quick and dirty name/value encoder/accumulator
' ******************************************************

Function AkaMA_NewHttp2(url As String, contentHeader As String) as Object
    obj = CreateObject("roAssociativeArray")
    obj.Http                        = AkaMA_CreateURLTransferObject2(url, contentHeader)
    obj.FirstParam                  = true
    obj.AddParam                    = AkaMA_http_add_param
    obj.AddRawQuery                 = AkaMA_http_add_raw_query
    obj.GetToStringWithRetry        = AkaMA_http_get_to_string_with_retry
    obj.PrepareUrlForQuery          = AkaMA_http_prepare_url_for_query
    obj.GetToStringWithTimeout      = AkaMA_http_get_to_string_with_timeout
    obj.PostFromStringWithTimeout   = AkaMA_http_post_from_string_with_timeout

    if Instr(1, url, "?") > 0 then obj.FirstParam = false

    return obj
End Function


' ******************************************************
' AkaMA_HttpEncode - just encode a string
' ******************************************************

Function AkaMA_HttpEncode(str As String) As String
    o = CreateObject("roUrlTransfer")
    return o.Escape(str)
End Function

' ******************************************************
' Prepare the current url for adding query parameters
' Automatically add a '?' or '&' as necessary
' ******************************************************

Function AkaMA_http_prepare_url_for_query() As String
    url = m.Http.GetUrl()
    if m.FirstParam then
        url = url + "?"
        m.FirstParam = false
    else
        url = url + "&"
    endif
    m.Http.SetUrl(url)
    return url
End Function

' ******************************************************
' Percent encode a name/value parameter pair and add the
' the query portion of the current url
' Automatically add a '?' or '&' as necessary
' Prevent duplicate parameters
' ******************************************************

Function AkaMA_http_add_param(name As String, val As String) as Void
    q = m.Http.Escape(name)
    q = q + "="
    url = m.Http.GetUrl()
    if Instr(1, url, q) > 0 return    'Parameter already present
    q = q + m.Http.Escape(val)
    m.AddRawQuery(q)
End Function

' ******************************************************
' Tack a raw query string onto the end of the current url
' Automatically add a '?' or '&' as necessary
' ******************************************************

Function AkaMA_http_add_raw_query(query As String) as Void
    url = m.PrepareUrlForQuery()
    url = url + query
    m.Http.SetUrl(url)
End Function

' ******************************************************
' Performs Http.AsyncGetToString() in a retry loop
' with exponential backoff. To the outside
' world this appears as a synchronous API.
' ******************************************************

Function AkaMA_http_get_to_string_with_retry() as String
    timeout%         = 1500
    num_retries%     = 5

    str = ""
    while num_retries% > 0
'        print "httpget try " + AkaMA_itostr(num_retries%)
        if (m.Http.AsyncGetToString())
            event = wait(timeout%, m.Http.GetPort())
            if type(event) = "roUrlEvent"
                str = event.GetString()
                exit while
            else if event = invalid
                m.Http.AsyncCancel()
                ' reset the connection on timeouts
                m.Http = AkaMA_CreateURLTransferObject(m.Http.GetUrl())
                timeout% = 2 * timeout%
            else
                print "roUrlTransfer::AsyncGetToString(): unknown event"
            endif
        endif

        num_retries% = num_retries% - 1
    end while

    return str
End Function

' ******************************************************
' Performs Http.AsyncGetToString() with a single timeout in seconds
' To the outside world this appears as a synchronous API.
' ******************************************************

Function AkaMA_http_get_to_string_with_timeout(seconds as Integer) as String
    timeout% = 1000 * seconds

    str = ""
    m.Http.EnableFreshConnection(true) 'Don't reuse existing connections
    if (m.Http.AsyncGetToString())
        event = wait(timeout%, m.Http.GetPort())
        if type(event) = "roUrlEvent"
            print "received response code = "; event.GetResponseCode()
            print "received failure reason code = ";event.GetFailureReason()
            print "received response header = ";event.GetResponseHeaders()
            str = event.GetString()
        else if event = invalid
            AkaMA_Dbg("AsyncGetToString timeout")
            m.Http.AsyncCancel()
        else
            AkaMA_Dbg("AsyncGetToString unknown event", event)
        endif
    endif

    return str
End Function

' ******************************************************
' Performs Http.AsyncPostFromString() with a single timeout in seconds
' To the outside world this appears as a synchronous API.
' ******************************************************

Function AkaMA_http_post_from_string_with_timeout(val As String, seconds as Integer) as String
    timeout% = 1000 * seconds

    str = ""
'    m.Http.EnableFreshConnection(true) 'Don't reuse existing connections
    if (m.Http.AsyncPostFromString(val))
        event = wait(timeout%, m.Http.GetPort())
        if type(event) = "roUrlEvent"
            print "1"
            str = event.GetString()
        else if event = invalid
            print "2"
            AkaMA_Dbg("AsyncPostFromString timeout")
            m.Http.AsyncCancel()
        else
            print "3"
            AkaMA_Dbg("AsyncPostFromString unknown event", event)
        endif
    endif

    return str
End Function
' this file provides functions for generating guid and client id for
' MA plugin


'Function       :   AkaMA_GUID
'Params         :   None
'Return         :   GUID string
'Description    :   Creates a GUID
'
function AkaMA_GUID() as string
    id1 = CreateObject("roDateTime").asSeconds()
    id2 = Rnd(0)
    di = CreateObject("roDeviceInfo")
    version = GetOSVersion()
    major = Mid(version, 3, 1)
    minor = Mid(version, 5, 2)
    build = Mid(version, 8, 5)
    'id3 =  major + minor + build
    print "Device unique id = ";di.GetChannelClientId()
    print "Device model = "; di.GetModel()
    print "Device version = ";GetOSVersion()
    id3 = box("")
    id3 = id3 + di.GetChannelClientId() + di.GetModel() + GetOSVersion()

    print"id1 = "; id1
    print"id2 = "; id2
    print"id3 = "; id3

    digestSrc = CreateObject("roByteArray")
    digestSrcString = box("")
    digestSrcString = digestSrcString + AkaMA_itostr(id1) + AkaMA_itostr(id2) + id3

    digestSrc.FromAsciiString(digestSrcString)
    print "digestSrcString = "; digestSrcString; " and digestSrc = "; digestSrc
    digest = CreateObject("roEVPDigest")
    digest.Setup("sha1")
    result = digest.Process(digestSrc)
    print "Digested result = "; result

    return result
end function

'Function       :   AkaMA_ClienID
'Params         :   None
'Return         :   GUID string
'Description    :   Creates a GUID
'
function AkaMA_ClientID() as string
    di = CreateObject("roDeviceInfo")
    digestSrc = CreateObject("roByteArray")
    digestSrc.FromAsciiString(di.GetChannelClientId())
    print " digestSrc = "; digestSrc

    digest = CreateObject("roEVPDigest")
    digest.Setup("md5")
    digest.Update(digestSrc)
    result = digest.Final()
    print "Digested result = "; result
    return result
end function
'******************************************************
'Get all XML subelements by name
'
'return list of 0 or more elements
'******************************************************
Function AkaMA_GetXMLElementsByName(xml As Object, name As String) As Object
    list = CreateObject("roArray", 100, true)
    if AkaMA_islist(xml.GetBody()) = false return list

    for each e in xml.GetBody()
        if e.GetName() = name then
            list.Push(e)
        endif
    next

    return list
End Function


'******************************************************
'Get all XML subelement's string bodies by name
'
'return list of 0 or more strings
'******************************************************
Function AkaMA_GetXMLElementBodiesByName(xml As Object, name As String) As Object
    list = CreateObject("roArray", 100, true)
    if AkaMA_islist(xml.GetBody()) = false return list

    for each e in xml.GetBody()
        if e.GetName() = name then
            b = e.GetBody()
            if type(b) = "roString" or type(b) = "String" list.Push(b)
        endif
    next

    return list
End Function


'******************************************************
'Get first XML subelement by name
'
'return invalid if not found, else the element
'******************************************************
Function AkaMA_GetFirstXMLElementByName(xml As Object, name As String) As dynamic
    if AkaMA_islist(xml.GetBody()) = false return invalid

    for each e in xml.GetBody()
        if e.GetName() = name return e
    next

    return invalid
End Function


'******************************************************
'Get first XML subelement's string body by name
'
'return invalid if not found, else the subelement's body string
'******************************************************
Function AkaMA_GetFirstXMLElementBodyStringByName(xml As Object, name As String) As dynamic
    e = AkaMA_GetFirstXMLElementByName(xml, name)
    if e = invalid return invalid
    if type(e.GetBody()) <> "roString" and type(e.GetBody()) <> "String" return invalid
    return e.GetBody()
End Function


'******************************************************
'Get the xml element as an integer
'
'return invalid if body not a string, else the integer as converted by strtoi
'******************************************************
Function AkaMA_GetXMLBodyAsInteger(xml As Object) As dynamic
    if type(xml.GetBody()) <> "roString" and type(xml.GetBody()) <> "String" return invalid
    return strtoi(xml.GetBody())
End Function


'******************************************************
'Parse a string into a roXMLElement
'
'return invalid on error, else the xml object
'******************************************************
Function AkaMA_ParseXML(str As String) As dynamic
    if str = invalid return invalid
    xml=CreateObject("roXMLElement")
    if not xml.Parse(str) return invalid
    return xml
End Function

'******************************************************
'Get XML sub elements whose bodies are strings into an associative array.
'subelements that are themselves parents are skipped
'namespace :'s are replaced with _'s
'
'So an XML element like...
'
'<blah>
'    <This>abcdefg</This>
'    <Sucks>xyz</Sucks>
'    <sub>
'        <sub2>
'        ....
'        </sub2>
'    </sub>
'    <ns:doh>homer</ns:doh>
'</blah>
'
'returns an AA with:
'
'aa.This = "abcdefg"
'aa.Sucks = "xyz"
'aa.ns_doh = "homer"
'
'return an empty AA if nothing found
'******************************************************
Sub AkaMA_GetXMLintoAA(xml As Object, aa As Object)
    for each e in xml.GetBody()
        body = e.GetBody()
        if type(body) = "roString" or type(body) = "String" then
            name = e.GetName()
            name = AkaMA_strReplace(name, ":", "_")
            aa.AddReplace(name, body)
        endif
    next
End Sub
