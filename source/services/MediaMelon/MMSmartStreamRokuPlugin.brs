sub init()
    m.top.id = "MM"
    m.top.SDK_VERSION = "0.0.1"
    m.mmSmart = SmartStream()
    m.mmSmart.init()
    m.top.functionName = "registerPlugin"
end sub

'Top most function. When the plugin is given control to run, all operations take place in the following function.
'Use "'" to write a comment, Use "?" to print statement to console.
function registerPlugin()
    m.messagePort = _createPort()
    m.inView = false
    m.isInitialised = false
    m.isRegistered = False
    m.PlaybackInitiated = false
    m._Flag_isSeeking = false
    m.isEnded=True
    m.content = {}
    m.lastStream=""
    if m.top.config <> invalid
        m.config = m.top.config
        if m.config.subscriberId <> invalid
            subscriberId = _generateSubId(m.config.subscriberId)
        else subscriberId = ""
        end if
        if m.config.subscriberType <> invalid
            subscriberType = m.config.subscriberType
        else subscriberType = ""
        end if
        if m.config.subscriberTag <> invalid
            subscriberTag = m.config.subscriberTag
        else subscriberTag = ""
        end if
        if m.config.domainName <> invalid
            domainName = m.config.domainName
        else domainName = ""
        end if
        if m.config.playerName <> invalid
            playerName = m.config.playerName
        else playerName = "RokuSDK"
        end if
        if m.config.disableManifestFetch <> invalid and (m.config.disableManifestFetch = True or m.config.disableManifestFetch = False)
            m.mmSmart.disableManifestFetch(m.config.disableManifestFetch)
        else
            m.mmSmart.disableManifestFetch(False)
        end if
        m.mmSmart.registerMMSmartStreaming(playerName, m.config.customerID, "ROKUSDK", subscriberId, domainName, subscriberType, subscriberTag)
        m.isRegistered = True
    end if
    if m.top.customTags <> invalid and m.top.customTags.count() <> 0
        for each tag in m.top.customTags.keys()
            m.mmSmart.reportCustomMetaData(tag, m.top.customTags[tag])
        end for
    end if

    m.isLive = false
    m.prevBitrate = 0
    m.representation = []
    m._lastReportedPosition = 0
    m._seekThreshold = 2

    'Observed Fields
    m.top.ObserveField("video", m.messagePort)
    m.top.ObserveField("view", m.messagePort)
    m.top.ObserveField("config", m.messagePort)
    m.top.ObserveField("customTags", m.messagePort)
    m.top.video.ObserveField("state", m.messagePort)
    m.top.video.ObserveField("content", m.messagePort)
    m.top.video.ObserveField("control", m.messagePort)
    m.top.video.ObserveField("streamInfo", m.messagePort)
    m.top.video.ObserveField("duration", m.messagePort)
    m.top.video.ObserveField("seek", m.messagePort)
    m.top.video.observeField("streamingSegment", m.messagePort)

    'Beacon timer from the plugin. Signals the engine using mmSmart.fireBeacon().
    'Added to both wrapper and smartstream objects
    m.beaconTimer = createObject("roSGNode", "Timer")
    m.beaconTimer.repeat = True
    m.beaconTimer.id="beaconTimer"
    m.beacontimer.ObserveField("fire", m.messagePort)


    m.pollTimer = createObject("roSGNode","Timer")
    m.pollTimer.repeat = True
    m.pollTimer.duration = 1
    m.pollTimer.id="pollTimer"
    m.pollTimer.ObserveField("fire",m.messagePort)

    'Report device information to the SDK
    deviceInfo = setDeviceInfo()
    m.mmSmart.reportDeviceInfo("Roku", deviceInfo["model"], "Roku OS", "9.0.0", "None", deviceInfo["width"], deviceInfo["height"])
    m.mmSmart.reportPlayerInfo("Roku", deviceInfo["Model"], "Roku OS")
    if deviceInfo.nwType = "WifiConnection"
        m.mmSmart.reportWifiSSID(deviceInfo["ssid"])
    end if

    m.running = true
    'Start the infinite loop waiting for changes from the observed fields
    while (m.running)
        msg = wait(0, m.messagePort) ' wait for a message
        if m.top.exit = true
            m.running = false
        end if
        if msg <> invalid
            msgType = type(msg)
            if msgType = "roSGNodeEvent"
                field = msg.getField()
                if field = "video"
                    data = msg.getData()
                    _videoAddedHandler(data)
                    if m.top.video = invalid
                        m.top.UnobserveField("video")
                        data = msg.getData()
                        _videoAddedHandler(data)
                        m.top.video.ObserveField("state", m.messagePort)
                        m.top.video.ObserveField("content", m.messagePort)
                        m.top.video.ObserveField("control", m.messagePort)
                    end if
                else if field = "config"
                    m.config = m.top.config
                    if m.config.subscriberId <> invalid
                        subscriberId = _generateSubId(m.config.subscriberId)
                    else subscriberId = ""
                    end if
                    if m.config.subscriberType <> invalid
                        subscriberType = m.config.subscriberType
                    else subscriberType = ""
                    end if
                    if m.config.domainName <> invalid
                        domainName = m.config.domainName
                    else domainName = ""
                    end if
                    if m.config.subscriberTag <> invalid
                        subscriberTag = m.config.subscriberTag
                    else subscriberTag = ""
                    end if
                    if m.config.playerName <> invalid
                        playerName = m.config.playerName
                    else playerName = "RokuSDK"
                    end if
                    if m.config.disableManifestFetch <> invalid and (m.config.disableManifestFetch = True or m.config.disableManifestFetch = False)
                        m.mmSmart.disableManifestFetch(m.config.disableManifestFetch)
                    else
                        m.mmSmart.disableManifestFetch(False)
                    end if
                    m.mmSmart.registerMMSmartStreaming(playerName, m.config.customerID, "ROKUSDK", subscriberId, domainName, subscriberType, subscriberTag)
                    m.isRegistered = True
                else if field = "control"
                    '?"MM control"
                    '?msg.getData()
                    _videoControlChangeHandler(msg.getData())
                else if field = "customTags"
                    customTags = msg.getData()
                    if customTags.count() <> 0
                        for each tag in customTags.keys()
                            m.mmSmart.reportCustomMetaData(tag, customTags[tag])
                        end for
                    end if
                else if field = "duration"
                    _setPresentation()
                else if field = "seek"
                    '?"Seek"
                    '?msg.getData()
                else if field = "content"
                    _videoContentChangeHandler(msg.getData())
                else if field = "streamingSegment"
                    segment = msg.getData()
                    chunk = { "cbrBitrate": segment.segBitrateBps, "dur": -1, "qbrBitrate": segment.segBitrateBps, "downloadRate": segment.segBitrateBps, "seqNum": segment.segSequence, "startTime": segment.segStartTime }
                    m.mmSmart.reportPlaybackPosition(m.video.position)
                    m.mmSmart.reportChunkRequest(chunk)
                else if field = "view"
                    _videoViewChangeHandler(msg.getData())
                else if field = "fire"
                    node= msg.getNode()
                    if node="beaconTimer"
                    'Segments payload beacons
                        if m.video<>invalid
                            m.mmSmart.reportPlaybackPosition(m.video.position)
                        end if
                        m.mmSmart.fireBeacon()
                    else if node="pollTimer"
                        if m.video<>invalid
                            m.mmSmart.reportPlaybackPosition(m.video.position)
                            m._lastReportedPosition=m.video.position
                        end if
                    end if
                else if field = "error"
                    _videoErrorHandler(msg.getData())
                else if field = "streamInfo"
                    if m.isInitialised <> True and m.video <> invalid
                        'initialising from streamInfo
                        if m.video.streamInfo <> invalid and m.isRegistered
                            if m.video.content.id <> invalid
                                videoId = m.video.content.id
                            else if m.video.content.contentId <> invalid
                                videoId = m.video.content.contentId
                            else
                                videoId = _generateVideoId(m.video.streaminfo.streamurl)
                            end if
                            if m.video.content.title <> invalid
                                assetName = m.video.content.title
                            else
                                assetName = _getDomain(m.video.streaminfo.streamUrl)
                            end if
                            assetId = videoId
                            ' if m.video.content.description <> invalid
                            '     assetId = m.video.content.description
                            ' else assetId = ""
                            ' end if
                            'if m.lastStream<>m.video.streaminfo.streamUrl
                                response = m.mmSmart.initializeSession("QBRDisabled", m.video.streaminfo.streamUrl, "invalid", assetId, assetName, videoId)
                                if response["status"] = True
                                    m.isInitialised = True
                                    _setPresentation()
                                    m.beaconTimer.duration = response.interval
                                    m.mmSmart.reportUserInitiatedPlayback(m.video.timeToStartStreaming)
                                    m.PlaybackInitiated = true
                                    m.beaconTimer.control = "start"
                                    m.pollTimer.control="start"
                                    m.lastStream=m.video.streamInfo.streamUrl
                                else
                                    m.isInitialised=False
                                    m.isRegistered=False
                                end if
                            'end if
                        end if
                    end if
                    if m.isInitialised = True
                        streamInfo = msg.getData()
                        if m.prevMeasuredBitrate <> streamInfo.measuredBitrate and streamInfo.measuredBitrate <> invalid
                            m.mmSmart.reportDownloadRate(streamInfo.measuredBitrate)
                            m.prevMeasuredBitrate = streamInfo.measuredBitrate
                        end if
                    end if
                else if field = "state"
                    msgData = msg.getData()
                    if msgData <> invalid and type(msgData) = "roString"
                        _videoStateChangeHandler(msgData)
                    end if
                end if
            end if
        end if
    end while
end function

function _startView(setByClient as boolean) as void
    if setByClient = false
        return
    end if
    if m.inView = True
        return
    end if
    if m.video <> invalid and m.isInitialised <> True
        m.inView = True
        if m.video.streamInfo <> invalid and m.isRegistered <> True
            if m.video.streamInfo <> invalid and m.isRegistered
                if m.video.content.id <> invalid
                    videoId = m.video.content.id
                else if m.video.content.contentId <> invalid
                    videoId = m.video.content.contentId
                else
                    videoId = _generateVideoId(m.video.streaminfo.streamurl)
                end if
                if m.video.content.title <> invalid
                    assetName = m.video.content.title
                else
                    assetName = _getDomain(m.video.streaminfo.streamUrl)
                end if
                assetId = videoId
                ' if m.video.content.description <> invalid
                '     assetId = m.video.content.description
                ' else assetId = ""
                ' end if
                'if m.lastStream <> m.video.streaminfo.streamUrl
                    response = m.mmSmart.initializeSession("QBRDisabled", m.video.streaminfo.streamUrl, "invalid", assetId, assetName, videoId)
                    if response.status = True
                        m.isInitialised = True
                        '_setPresentation()
                        m.beaconTimer.duration = response.interval
                        m.mmSmart.reportUserInitiatedPlayback(m.video.timeToStartStreaming)
                        m.PlaybackInitiated = true
                        m.pollTimer.control="start"
                        m.beaconTimer.control = "start"
                        m.lastStream=m.video.streamInfo.streamUrl
                    else
                        m.isInitialised=false
                        m.isRegistered=false
                    end if
                'end if
            end if
        end if
    end if

    m._clientOperatedStartAndEnd = true
    if m.top.video <> invalid
        _videoAddedHandler(m.top.video)
    end if
    ''''Asset Id is source domain from content node, Asset Name is host Name

    'm.pollTimer.control = "start"

end function

function _endView(setByClient = false as boolean) as void
    m.beaconTimer.control = "stop"
    m.inView = false
    m.isLive = false
    m.isInitialised = False
    m.isRegistered = False
    m.PlaybackInitiated=false
    m.prevBitrate = 0
    m._lastVideoState = invalid
    m.representation = []
    m.video=invalid
    m.prevMeasuredBitrate = invalid
    m._lastReportedPosition = invalid
    m._lastPause=invalid
    m.mmSmart = SmartStream()
    m.mmSmart.init()
    if m.top.config <> invalid
        m.config = m.top.config
        if m.config.subscriberId <> invalid
            subscriberId = _generateSubId(m.config.subscriberId)
        else subscriberId = ""
        end if
        if m.config.subscriberType <> invalid
            subscriberType = m.config.subscriberType
        else subscriberType = ""
        end if
        if m.config.domainName <> invalid
            domainName = m.config.domainName
        else domainName = ""
        end if
        if m.config.subscriberTag <> invalid
            subscriberTag = m.config.subscriberTag
        else subscriberTag = ""
        end if
        if m.config.playerName <> invalid
            playerName = m.config.playerName
        else playerName = "RokuSDK"
        end if
        if m.config.disableManifestFetch <> invalid and (m.config.disableManifestFetch = True or m.config.disableManifestFetch = False)
            m.mmSmart.disableManifestFetch(m.config.disableManifestFetch)
        else
            m.mmSmart.disableManifestFetch(False)
        end if
        'Domain Name set host
        m.mmSmart.registerMMSmartStreaming(playerName, m.config.customerID, "ROKUSDK", subscriberId, domainName, subscriberType, subscriberTag)
        m.isRegistered = True
        deviceInfo = setDeviceInfo()
        m.mmSmart.reportDeviceInfo("Roku", deviceInfo["model"], "Roku OS", "9.0.0", "None", deviceInfo["width"], deviceInfo["height"])
        m.mmSmart.reportPlayerInfo("Roku", deviceInfo["Model"], "Roku OS")

    end if

end function

function _videoViewChangeHandler(view as string)
    if view = "end"
        _endView(true)
    else if view = "start"
        _startView(true)
    end if
end function

function _videoAddedHandler(video as object)
    m.video = video
end function

function _videoStateChangeHandler(videoState as string)
    'ALL OPERATIONS TO THE SDK FOR EVENT TRIGGERS IS COMPUTED HERE.
    if m.isRegistered and m.video <> invalid
        m._isPaused = (videoState = "paused" or (videoState = "buffering" and m._lastVideoState = "paused"))
        '_checkForSeek is called at states buffering,paused and playing because the state transition during seeking is
        'PAUSE->BUFFERING->PLAYING->BUFFERING
        if videoState = "buffering"
            _checkForSeek("buffering")
            if m._flag_isSeeking = false or m._flag_isSeeking = invalid and m.isInitialised
                _reportEvent("BUFFERING", m.video.position)
            end if
        else if videoState = "paused"
            m._lastPause=m.video.position
            _checkForSeek("paused")
            if m._flag_isSeeking = false or m._flag_isSeeking = invalid
                _reportEvent("PAUSE", m.video.position)
                m.beaconTimer.control = "stop"
            end if
        else if videoState = "playing"
            if m._lastVideoState = "paused"
                m.beaconTimer.control = "start"
            end if
            if m._flag_isSeeking = false or m._flag_isSeeking = invalid
                _reportEvent("PLAYING", m.video.position)
            else
                _checkForSeek("playing")
            end if
        else if videoState = "stopped" and m._lastVideoState <> "finished"
            m.beaconTimer.control = "stop"
            _reportEvent("ENDED", m.video.position)
            m.isEnded = True
            _endView()
        else if videoState = "finished"
            if m.isInitialised
                if m._lastVideoState="error" and m.video.position<>m.video.duration
                    _reportEvent("ENDED", m.video.position)
                    m.isEnded=True
                    _endView(True)
                else
                    _reportEvent("COMPLETE", m.video.position)
                end if
                m.isEnded=true
                m.beaconTimer.control = "stop"
                _endView()
            end if
        else if videoState = "error"
            if m.isInitialised=false
                if m.video.streamInfo <> invalid and m.isRegistered
                    if m.video.content.id <> invalid
                        videoId = m.video.content.id
                    else if m.video.content.contentId <> invalid
                        videoId = m.video.content.contentId
                    else
                        videoId = _generateVideoId(m.video.streaminfo.streamurl)
                    end if
                    if m.video.content.title <> invalid
                        assetName = m.video.content.title
                    else
                        assetName = _getDomain(m.video.streaminfo.streamUrl)
                    end if
                    'if m.video.content.description <> invalid
                    '    assetId = m.video.content.description
                    'else assetId = ""
                    'end if
                    assetId = videoId
                    response = m.mmSmart.initializeSession("QBRDisabled", m.video.streaminfo.streamUrl, "invalid", assetId, assetName, videoId)
                else if m.video.content.url<>invalid
                    if m.video.content.id <> invalid
                        videoId = m.video.content.id
                    else if m.video.content.contentId<>invalid
                        videoId=m.video.content.contentId
                    else
                        videoId = _generateVideoId(m.video.content.url)
                    end if
                    if m.video.content.title <> invalid
                        assetName = m.video.content.title
                    else
                        assetName = _getDomain(m.video.content.url)
                    end if
                    'if m.video.content.description<>invalid
                    '    assetId=m.video.content.description
                    'else   assetId=""
                    'end if
                    assetId = videoId
                    response = m.mmSmart.initializeSession("QBRDisabled", m.video.content.url, "invalid", assetId, assetName, videoId)
                end if
                errorCode = ""
                errorMessage = ""
                if m.video <> invalid
                    if m.video.errorCode <> invalid
                        errorCode = m.video.errorCode
                    end if
                    if m.video.errorMsg <> invalid
                        errorMessage = m.video.errorMsg
                    end if
                end if
                m.mmSmart.reportError(errorMessage, m.video.position)
            else
                errorCode = ""
                errorMessage = ""
                if m.video <> invalid
                    if m.video.errorCode <> invalid
                        errorCode = m.video.errorCode
                    end if
                    if m.video.errorMsg <> invalid
                        errorMessage = m.video.errorMsg
                    end if
                end if
                m.mmSmart.reportError(errorMessage, m.video.position)
            end if
        end if
        if m.video <> invalid
            m._lastReportedPosition = m.video.position
            m._lastVideoState = videoState
        end if

    end if
end function

function _videoControlChangeHandler(control as string)
    if control = "play"
        'Doing Nothing
    else if control = "pause"
        _reportEvent("PAUSE", m.video.position)
    else if control = "resume"
        _reportEvent("RESUME", m.video.position)
    else if control = "stop"
        if m.isInitialised
                if m._lastVideoState="error" and m.video.position<>m.video.duration
                    _reportEvent("ENDED", m.video.position)
                    m.isEnded=True
                else
                    _reportEvent("COMPLETE", m.video.position)
                end if
                m.isEnded=true
                m.beaconTimer.control = "stop"
        end if
        _endView(true)
    end if
end function

function _videoContentChangeHandler(videoContent as object)
    m.content = videoContent
    if m.content.StreamBitrates <> invalid
        m.representation = m.content.StreamBitrates
    else if m.content.Streams <> invalid
        for each item in m.content.streams
            m.representation.push(item.bitrate)
        end for
    else if m.content.Stream <> invalid
        m.representation.Push(m.Content.Stream.bitrate)
    end if
    if m.content.live = True
        m.isLive = True
    else
        m.isLive = False
    end if
    if m.isInitialised = true and (m._lastVideoState = "buffering" or m._lastVideoState = "paused")
        _reportEvent("ENDED", m._lastReportedPosition)
        _endView(true)
        _startView(true)
    end if
end function

function _videoErrorHandler(error as object)
    errorCode = "0"
    errorMessage = "Unknown"
    if error <> invalid
        if error.errorCode <> invalid
            errorCode = error.errorCode
        end if
        if error.errorMsg <> invalid
            errorMessage = error.errorMsg
        end if
        if error.errorMessage <> invalid
            errorMessage = error.errorMessage
        end if
    end if
    m.mmSmart.reportError(errorMessage, m.video.position)
end function

'Function to send presentation information to the SDK
function _setPresentation() as void
    streamFormat = _getStreamFormat(m.video.streaminfo.streamUrl)
    presentation = { "isLive": m.isLive, "duration": m.video.duration, "representation": m.representation, "streamFormat": streamFormat }
    m.mmSmart.setPresentationInformation(presentation)

end function

'Function to report a playback event to the SDK. Sends both playback time and event state to SDK.
function _reportEvent(eventType as string, pbtime as double)
    m.mmSmart.reportPlaybackPosition(pbtime)
    if eventType = "BUFFERING" and m.isInitialised <> True
        m.mmSmart.reportBufferingStarted()
    else if m._lastVideoState = "buffering" and eventType <> "SEEKED"
        m.mmSmart.reportBufferingCompleted()
        m.mmSmart.reportPlayerState(eventType)
    else if eventType = "SEEKED"
        m.mmSmart.reportPlayerSeekCompleted(pbtime)
    else
        m.mmSmart.reportPlayerState(eventType)
    end if
end function

'Function to check if a seek event was triggered. Reports SEEKED to the SDK.
function _checkForSeek(state) as void
    if state = "buffering"
        if m._Flag_isSeeking <> true and m._lastPause<>invalid
            if m.video.position > (m._lastPause + m._seekThreshold) or m.video.position < m._lastPause
                date = _getDateTime()
                m._viewSeekStartTimeStamp = 0# + date.AsSeconds() * 1000.0# + date.GetMilliseconds()
                m._Flag_isSeeking = true
                '?"Flag is true buffering"
            else m._Flag_isSeeking = false
            end if
        end if
    else if state = "playing"
        if m._Flag_isSeeking = true and m.video.position<>0
            date = _getDateTime()
            now = 0# + date.AsSeconds() * 1000.0# + date.GetMilliseconds()
            seekStartTs = 0#
            if m._viewSeekStartTimeStamp <> invalid
                seekStartTs = m._viewSeekStartTimeStamp
            end if
            if m._viewSeekDuration <> invalid
                m._viewSeekDuration = m._viewSeekDuration + (now - seekStartTs)
            end if
            _reportEvent("SEEKED", m.video.position)
            _reportEvent("PLAYING", m.video.position)
            m.beaconTimer.control = "start"
            'm._addEventToQueue(m._createEvent("seekComplete"))
            m._Flag_isSeeking = false

        end if
    else if state = "paused"
        if m._Flag_isSeeking = true
            date = _getDateTime()
            now = 0# + date.AsSeconds() * 1000.0# + date.GetMilliseconds()
            seekStartTs = 0#
            if m._viewSeekStartTimeStamp <> invalid
                seekStartTs = m._viewSeekStartTimeStamp
            end if
            if m._viewSeekDuration <> invalid
                m._viewSeekDuration = m._viewSeekDuration + (now - seekStartTs)
            end if
            _reportEvent("SEEKED", m.video.position)
            _reportEvent("PLAYING", m.video.position)
            m._Flag_isSeeking = false

        end if
    end if
end function
