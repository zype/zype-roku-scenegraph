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
        m.playing.updateBitrateInfo(params.headPosition, params.currentStreamInfo.StreamBitrate * 1000)
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
    state         :   "palyEnd"
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

