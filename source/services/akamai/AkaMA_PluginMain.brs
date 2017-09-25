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

FUNCTION AkaMA_plugin() as object
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
    'logger                  :   AkaMA_logger()
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
    logger                  :   AkaMA_logger()
    pluginInstance          :   invalid
    connectionTimer         :   invalid 'CreateObject("roTimespan")
    viewerId                :   invalid
    viewerDiagnosticsId     :   invalid
    serverIpLookUpPerformed :   false
    
    setViewerId:function(vId)
        ue = CreateObject("roURLTransfer")
        'encodedOutString = AkaMA_str8859toutf8(vId)
        encodedOutString = ue.UrlEncode(vId)
        print "encoded viewerId = "; encodedOutString
        'm.viewerId = AkaMA_strReplace(encodedOutString," ","%20")
        m.viewerId = encodedOutString
    end function

    setViewerDiagnosticId:function(vdId)
        ue = CreateObject("roURLTransfer")
        'encodedOutString = AkaMA_str8859toutf8(vdId)
        encodedOutString = ue.UrlEncode(vdId)
        print "encoded viewerDiagnosticsId = "; encodedOutString
        
        'm.viewerDiagnosticsId = AkaMA_strReplace(encodedOutString," ","%20")
        m.viewerDiagnosticsId = encodedOutString
        
    end function
    
    pluginMain:function(params)
        m.resetPluginState()
        m.logger.enableLogging(false)
        m.sessionTimer.Mark()
        pluginGlobals = AkaMA_getPluginGlobals()
        
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
        m.pluginInstance.initializeMAPluginInstance(params.customDimensions, m.sessionTimer, params.configXML, m.logger, m.viewerId, m.viewerDiagnosticsId)
        'm.connectionTimer = CreateObject("roTimespan")
    end function
    
    
        pluginEventHandler:function(msg as object)
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
                
            if msg = invalid then
                        ' msg is invalid when a timeout occurs
                        AkaMA_logger().AkaMA_print("Executing initConfigXML")
             else if msg.isScreenClosed() then
                    'print "screen closed"
                    endReasonCode = "ApplicationClosed"
                    m.pluginInstance.handlePlaybackCompleteEvent(m.sessionTimer, endReasonCode, m.lastHeadPosition)
                    m.pluginInstance.handleVisit(m.sessionTimer)
             else if msg.isPartialResult() then
                print "recieved msg.isPartialResult. Playback Interrupted"
                endReasonCode = "PlaybackInterrupted"
                m.pluginInstance.handlePlaybackCompleteEvent(m.sessionTimer, endReasonCode, m.lastHeadPosition)
             else if msg.isFullResult() then
                print "recieved msg.isFullResult. Playback completed"
                endReasonCode = "PlaybackEnded"
                m.pluginInstance.handlePlaybackCompleteEvent(m.sessionTimer,endReasonCode, m.lastHeadPosition)
                
                else if m.pluginInstance.getCurrenPlaybackState() = "ad"
                    print "currently in ad state..."
                else if type(msg) = "roVideoScreenEvent" or type(msg) = "roVideoPlayerEvent" then
                        if msg.isStreamStarted() then
                                print"recieved isStreamStarted"
                                currentStreamInfo = msg.GetInfo()
                                AkaMA_PrintAnyAA(2,currentStreamInfo)
                                print "Playback position = "; msg.GetIndex()
                                if currentStreamInfo.IsUnderrun = true
                                    print "Entering into rebuffer mode"
                                    m.pluginInstance.handleRebufferEvent(m.sessionTimer, m.lastHeadPosition)
                                endif   
                                
                            if m.currentStreamInfo.DoesExist("Url") = false
                                m.currentStreamInfo.addReplace("Url",currentStreamInfo.Url)
                            endif    
                            if currentStreamInfo.StreamBitrate <> 0 or currentStreamInfo.StreamBitrate <> invalid
                                m.currentStreamInfo.addReplace("StreamBitrate", currentStreamInfo.StreamBitrate)
                            endif     
                                                        
'                            m.currentStreamInfo = msg.GetInfo()  
                            m.pluginInstance.updateBitrateInfo(m.currentStreamInfo, m.lastHeadPosition)
                         else if msg.isStatusMessage() then
                            print "********* Status message *********:"
                            aa = msg.GetInfo()
                            AkaMA_PrintAnyAA(2,aa)
                            if m.lastHeadPosition > 0 and m.connectionTimer = invalid
                                if msg.getMessage() = "startup progress" 
                                    m.pluginInstance.handleRebufferEvent(m.sessionTimer, m.lastHeadPosition)
                                else if msg.getMessage() = "start of play"
                                    m.pluginInstance.handleRebufferEndEvent(m.sessionTimer, m.lastHeadPosition) 
                                endif
                            endif
                            print "received status message = ";msg.getMessage()
                            print "*********Executed Status message *********:"
                         else if msg.isPaused()
                            print"executing paused..."
                            aa = msg.GetInfo()
                            AkaMA_PrintAnyAA(2,aa)
                            m.pluginInstance.handlePlaybackPauseEvent(m.sessionTimer, m.lastHeadPosition)
                            print"executed paused..."
                         else if msg.isResumed()
                            print"executing resumed..."
                            aa = msg.GetInfo()
                            AkaMA_PrintAnyAA(2,aa)
                            m.pluginInstance.handlePlaybackResumeEvent(m.sessionTimer, m.lastHeadPosition)
                            print"executed resumed..."
                         else if msg.isPlaybackPosition()
                            'print "********* Palyback Position event *********:"
                            'hanlde seek 
                            if m.pluginInstance.getCurrenPlaybackState() = "pause"
                                if m.lastHeadPosition + 1 > msg.GetIndex()
                                    print "End of seek back operation..."
                                else if  m.lastHeadPosition + 1 < msg.GetIndex()
                                    print "end of seek forward operation..."
                                endif
                                m.lastHeadPosition = msg.GetIndex()
                                'Check if we are getting isStreamStarted before isPlaybackPosition
                                m.pluginInstance.handlePlaybackSeekEndEvent(m.sessionTimer, m.lastHeadPosition, m.currentStreamInfo)
                            endif
                            
                            m.lastHeadPosition = msg.GetIndex()
                            'handle rebuffer
                            if m.pluginInstance.getCurrenPlaybackState() = "rebuffer"
                                print"Entering into rebufferEnd state"
                                m.pluginInstance.handleRebufferEndEvent(m.sessionTimer, m.lastHeadPosition)
                            endif
                            
                            'handle play start
                            'print "Playback current Head position = "; m.lastHeadPosition
                            'if m.lastHeadPosition = 0 and m.connectionTimer <> invalid
                            if m.connectionTimer <> invalid
                                bufferTime = m.connectionTimer.TotalMilliseconds()
                                m.connectionTimer = invalid
                                m.pluginInstance.populateStreamInfo(m.currentStreamInfo, bufferTime)
                                m.pluginInstance.handlePlayStartEvent(m.sessionTimer, m.lastHeadPosition)
                                m.secondaryLogTimer = CreateObject("roTimespan")
                                m.streamStartTimer = CreateObject("roTimespan")
                            endif
                            
                            aa = msg.GetInfo()
                            AkaMA_PrintAnyAA(2,aa)
                            'print "********* Executed Palyback Position event *********:"
                         else if msg.isStreamSegmentInfo() then
                            print "********* streamSegmentInfo *********:"
                            streamSegmentInfo = msg.GetInfo()
                            if m.currentStreamInfo.DoesExist("Url") = false
                                m.currentStreamInfo.addReplace("Url",streamSegmentInfo.Url)
                            endif    
                            if streamSegmentInfo.StreamBandwidth <> 0 or streamSegmentInfo.StreamBandwidth <> invalid
                                m.currentStreamInfo.addReplace("StreamBitrate", streamSegmentInfo.StreamBandwidth)
                            endif
                            
                            m.pluginInstance.updateBitrateInfo(m.currentStreamInfo, m.lastHeadPosition)
                            AkaMA_PrintAnyAA(2,streamSegmentInfo)
                            print "*********Executed streamSegmentInfo *********:"
                         end if
                 else if type(msg) = "roSystemLogEvent" then
                        ' Handle the roSystemLogEvents:
                        i = msg.GetInfo()
                        if i.LogType = "http.connect" then 
                                url = i.OrigUrl
                                if (not m.ipAddresses.DoesExist(url)) then
                                        m.ipAddresses[url] = CreateObject("roAssociativeArray")
                                end if        
                                m.ipAddresses[url].AddReplace(i.TargetIp,"")
                                'print "server id = "; i.TargetIp
                                'metrics.serverId = i.TargetIp
                        else if i.LogType = "http.error"
                                'do not increment error count here, if the error is fatal
                                'it'll terminate the session and will be counted by a videoScreenevent
                                'but report errors so that we can keep track of the errors
                                'ReportHttpError API should take extra status param for error status message
                                'for now just append it to errorCode param
                                code = i.HttpCode
                                if code < 200 OR code >= 400 then
                                        eCode = AkaMA_AnyToString(code)
                                        eStatus = AkaMA_AnyToString(i.Status)
                                        if eCode <> invalid and eStatus <> invalid
                                            errorStatus = "Error code:" + eCode + " Error Status:  " + eStatus
                                            print "error status = "; errorStatus
                                         endif   
                                        'ReportHttpErrorEvent(metrics, CreateObject("roDateTime").asSeconds()*1000, errorStatus, i.Url)
                                        ' report streaming sessions event so error is counted if the user clicks home.
                                        'ReportStreamingSessionEvent(metrics)
                                end if
                        else if i.LogType = "bandwidth.minute"
                                print "bandwidth is " ; i.Bandwidth * 1000
                                m.pluginInstance.updateBandwidthInfo(i.Bandwidth * 1000)
                        end if       
                 end if
                 
        end function
        
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
        
        visitEventReceived:function()
            endReasonCode = "PlaybackInterrupted"
            m.pluginInstance.handleVisit(m.sessionTimer)
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


