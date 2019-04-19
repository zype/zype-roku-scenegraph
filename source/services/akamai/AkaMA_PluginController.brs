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
        version = di.GetVersion()
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
            m.pluginDataStore.addUdpateMediaMetrics({logInterval : AkaMA_strTrim(AkaMA_AnyToString(m.lastLogInterval#)), currentClockTime : AkaMA_AnyToString(sessionTimer.TotalMilliseconds())})
          
            pluginGlobals = AkaMA_getPluginGlobals()
            if pluginGlobals.isVisitSent = false
                m.pluginDataStore.addUdpateMediaMetrics({isVisitStart:"1"})
                pluginGlobals.isVisitSent =  true    
            endif
            
            m.lastLogInterval# = sessionTimer.TotalMilliseconds()/1000.0
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
            if (sessionTimer.TotalMilliseconds() / 1000) > 900
                errCode = "Application.Close.NoStart.Late"
            else
                errCode = "Application.Close.NoStart"
            endif 
            
            m.sequenceId = m.sequenceId+1
            m.pluginDataStore.addUdpateMediaMetrics({sequenceId : AkaMA_itostr(m.sequenceId), endOfStream : "1", errorCode:errCode,
                                                    currentStreamTime:AkaMA_itostr(lastHeadPosition*1000)})
            m.pluginStatus.moveToState(m.pluginStatus.playEnd, {headPosition:lastHeadPosition}, invalid)
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
            if currentStreamInfo.DoesExist("Url") = true and AkaMA_isstr(currentStreamInfo.Url) = true
                updateParams.addReplace("streamUrl", currentStreamInfo.Url)
                token = AkaMA_strTokenize(currentStreamInfo.Url, "/")            
                updateParams.addReplace("streamName", token[token.count()-1])
            else
                print "current URL is not valid url- not a string object"
                token = ["unknown"]
            endif
            
            'Check if title exist in custom dimensions and it is a string object
            if m.pluginDataStore.custDimension.DoesExist("title") and AkaMA_isstr(currentStreamInfo.Url) = true
                print"setting title=";m.pluginDataStore.custDimension["title"]
                m.updateVisitUniqueTitles(m.pluginDataStore.custDimension["title"])
            else
            	print"setting title from token"
                m.updateVisitUniqueTitles(token[token.count()-1])
            endif    
            if token[token.count()-1].Instr("m3u8") <> -1
                print"format is l value = ";token[token.count()-1].Instr("m3u8")
                updateParams.addReplace("format","L")
            else if  token[token.count()-1].Instr("mp4") <> -1
                print"format is l value = ";token[token.count()-1].Instr("mp4")
                updateParams.addReplace("format","P")
            else 
                print"format is not l value = ";token[token.count()-1].Instr("m3u8")
            endif  
              
            'print "tokenized string = ";token
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
