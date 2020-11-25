
function MMStore() as object

    'Store object. Contains event queues, segment queues and storage variable with the data.
    'm.mainStore is the associative array which acts as the main point of storage
    store={}
    store.init=function()
        m.mainStore=CreateObject("roAssociativeArray")
        m.mainStore.AddReplace("Component","ROKUSDK")
        m.mainStore.AddReplace("Platform","Brightscript")
        m.mainStore.AddReplace("SDKVERSION","ROKUSDKv1.0.0_5ddc5f4")
        m.mainStore.AddReplace("hFileVersion","3.0.0")
        m.mainStore.AddReplace("EP_SCHEMA","3.0.0")
        m.mainStore.AddReplace("API_SERVER","https://register.mediamelon.com/mm-apis/register/")
        m.mainStore.AddReplace("isRegistration",false)
        m.mainStore.AddReplace("lastKnownPos",0)
        m.mainStore.AddReplace("customTags",false)
        m.mainStore.AddReplace("custom",{})
        m.mainStore.AddReplace("playDur",0.0)
        m.mainStore.AddReplace("pauseDur",0.0)
        m.mainStore.AddReplace("lastPauseDur",0.0)
        m.mainStore.AddReplace("latency",0.0)
        m.mainStore.AddReplace("totalProfiles",-1)
        m.mainStore.AddReplace("deltaTime",0)
        m.mainStore.AddReplace("maxFps",0)
        m.mainStore.AddReplace("minFps",0)
        m.mainStore.AddReplace("maxRes","")
        m.mainStore.AddReplace("minRes","")
        m.mainStore.AddReplace("sumBuffWait",0)
        m.mainStore.AddReplace("profileNum",-1)
        m.buffWait=[]
        m.eventQueue=[]
        m.segmentQueue=[]
        m.segmentTimespan = createObject("roTimeSpan")
        m.dataRates=[]
        m.rate=0
        m.lastRate=0
        m.upshift=0
        m.downShift=0
        m.prevTimestamp=0
        m.MMPlayerStates={
           "START":{desc: "Playback Start",event: "START",id: "START"},
           "ONLOAD":{event: "ONLOAD", desc: "Player Initializing", id: "ONLOAD"},
           "PAUSE":{event: "PAUSE", desc: "Playback Paused", id: "PAUSE"},
           "RESUME":{event: "RESUME", desc: "Playback resumed", id: "RESUME"},
           "SEEKED":{event: "SEEKED", desc: "Playback Seeked", id: "SEEKED"},
           "COMPLETE":{event: "COMPLETE", desc: "Playback completion", id: "COMPLETE"},
           "BUFFERING":{event: "BUFFERING", desc: "Playback Buffering", id: "BUFFERING"},
           "ENDED":{event: "ENDED", desc: "Playback completion", id: "ENDED"}
        }

    end function

    'Unique ID generator for creating and returning unique session ID.
    store.generateSessionId=function() as string
        sessionRegex = CreateObject("roRegex", "[xy]", "i")
        pattern = "xxxxxyyxxxyxxx-ymxyx"
        randomiseX = function() as String
            return StrI(Rnd(0) * 16, 16)
        end function
            randomiseY = function() as String
            randomNumber = Rnd(0) * 16
            randomNumber = randomNumber + 3
            if randomNumber >= 16
                randomNumber = 8
            end if
            return StrI(randomNumber, 16)
        end function
        patternArray = pattern.split("")
        viewId = ""
        for each char in patternArray
        if char = "x"
            viewId = viewId + randomiseX()
        else if char = "y"
            viewId = viewId + randomiseY()
        else
            viewId = viewId + char
        end if
        end for
        if m.mainStore.playerName<>invalid
            viewId=viewId+"_"+m.mainStore.playerName
        else if m.mainStore.brand<>invalid
            viewId=viewId+"_"+m.mainStore.brand
        else if m.mainStore.deviceModel<>invalid
            viewId=viewId+"_"+m.mainStore.deviceModel
        end if
        ?viewId
         return viewId
     end function

    ' Next 3 functions- Event Queue Functions for pushing, clearing and returning the queue
    store.ReportLatency=function(time)
        m.mainStore.addReplace("latency",time)
        m.mainStore.sumBuffWait+=time
        ?"Latency Report"
    end function

    store.pushToEventQueue=function(event)
        m.eventQueue.push(event)
    end function

    store.clearEventQueue = function()
        m.eventQueue=[]
    end function

    store.getEventQueue=function() as object
        return m.eventQueue
    end function

    ' Next 3 functions- Segment Queue Functions for pushing, clearing and returning the queue

    store.getSegmentQueue=function() as object
        if m.segmentQueue.Count()>0
            return m.segmentQueue
        else
            return -1
        end if
    end function


    store.clearSegmentQueue=function()
        m.segmentQueue = []
    end function

    store.pushToSegmentQueue=function(data as object)
        m.segmentQueue.push(data)
    end function

    ' Next 2 functions- Stats creation function. Event stats on playback event, segmentStats on beacon timer firing.

    store.createEventStats=function(state as String) as object
        sdkInfo={"hFileVersion":m.mainStore.hFileVersion, "sdkVersion":m.mainStore.SDKVERSION}
        if m.mainStore.statsInterval<>invalid
            interval=m.mainStore.statsInterval
        else
            interval=30
        end if
        scrnRes=m.mainStore.screenheight.toStr()+"x"+m.mainStore.screenwidth.toStr()
        stats={"version":m.mainStore.hFileVersion,"interval":interval,"pbTime":m.mainStore.lastKnownPos,"playDur":m.mainStore.playDur}
        streamID={"assetId":m.mainStore.assetID,"assetName":m.mainStore.assetName,"custId":m.mainStore.customerId,"dataSrc":m.mainStore.dataSrc,"mode":m.mainStore.mode}
        streamID.addReplace("playerName",m.mainStore.playerName)
        streamID.addReplace("sessionId",m.mainStore.sessionId)
        streamID.AddReplace("streamURL",m.mainStore.manifestURL)
        streamID.AddReplace("subscriberId",m.mainStore.subscriberId)
        streamID.AddReplace("subscriberType",m.mainStore.subscriberType)
        streamID.AddReplace("subscriberTag",m.mainStore.subscriberTag)

        if m.mainStore.videoID<>invalid and m.mainStore.videoID<>"" then
            streamID.AddReplace("videoId", m.mainStore.videoID)
        end if
        if m.mainStore.domainName<>invalid or m.mainstore.domainName<>""
            streamID.addreplace("domainName",m.mainStore.domainName)
        end if
        if m.mainStore.isLive<>invalid
            streamID.addReplace("isLive",m.mainStore.isLive)
        end if
        clientInfo={"device":"Roku","scrnRes":scrnRes,"model":m.mainStore.deviceModel,"platform":m.mainStore.deviceOS,"brand":m.mainStore.brand,"version":m.mainStore.deviceOSVersion}
        timestamp=_getDateTime()
        timestamp=0& + timestamp.AsSeconds() * 1000& + timestamp.GetMilliseconds()+m.mainStore.deltaTime
        stats.AddReplace("timestamp",timestamp)
        pbInfo=[]
        pbInfo.Push({"timestamp":timestamp})
        if state<>invalid
            if state="BUFFERING"
                pbEventInfo=m.MMPlayerStates["BUFFERING"]
            else if state="COMPLETE"
                pbEventInfo=m.MMPlayerStates["COMPLETE"]
                pbInfo[pbInfo.count()-1].AddReplace("sumBuffWait",m.mainStore.sumBuffWait)
            else if state="ENDED"
                pbEventInfo=m.MMPlayerStates["ENDED"]
                pbInfo[pbInfo.count()-1].AddReplace("sumBuffWait",m.mainStore.sumBuffWait)
            else if state="ONLOAD"
                pbEventInfo=m.MMPlayerStates["ONLOAD"]
                m.onloadTime=timestamp
                m.segmentTimespan.mark()
            else if state="PAUSE"
                pbEventInfo=m.MMPlayerStates["PAUSE"]
            else if state="RESUME"
                pbEventInfo=m.MMPlayerStates["RESUME"]
                'm.segmentTimespan.mark()
                pbInfo[pbInfo.count()-1].addReplace("pauseDuration",m.mainStore.lastPauseDur)
            else if state="SEEKED"
                pbEventInfo=m.MMPlayerStates["SEEKED"]
            else if state="START"
                pbEventInfo=m.MMPlayerStates["START"]
                timestamp=m.onloadTime
                stats.AddReplace("timestamp",timestamp)
                info={"latency":m.mainStore.latency,"timestamp":timestamp}
                pbinfo.push(info)
            else if state="ERROR"
                pbEventInfo={"event":"ERROR","id":"ERROR","desc":m.mainStore.errorString}
            else
                pbEventInfo={"event":"RETURN"}
            end if
        end if
        pbEventInfo.AddReplace("pbTime",m.mainStore.lastKnownPos)
        streamInfo={}
        if m.mainStore.bwInUse<>invalid and (state<>"START" or state <>"ONLOAD")
            pbInfo[pbInfo.count()-1].addReplace("bwInUse",m.mainStore.bwInUse)
        end if
        if m.mainStore.totalDuration<>0 and m.mainStore.totalDuration<>invalid
            streamInfo.addReplace("totalDuration",m.mainStore.totalDuration)
        end if
        if state<>"ONLOAD"
            streamInfo.addReplace("numOfProfile",m.mainStore.totalProfiles)
            streamInfo.addReplace("maxFps",m.mainStore.maxFps)
            streamInfo.addReplace("minFps",m.mainStore.minFps)
            streamInfo.addReplace("minRes",m.mainStore.minRes)
            streamInfo.addReplace("maxRes",m.mainStore.maxRes)
        end if
        if m.mainStore.streamFormat<>invalid
            streamInfo.addReplace("streamFormat",m.mainStore.streamFormat)
        end if
        if m.buffWait.count() <> 0 and pbEventInfo.event<>"RETURN"
            pbInfo.append(m.buffWait)
            m.buffWait = []
        end if
        qubitData=[{"streamID":streamID,"sdkInfo":sdkInfo,"clientInfo":clientInfo,"pbEventInfo":pbEventInfo,"pbInfo":pbInfo,"streamInfo":streamInfo}]
        if m.mainStore.customTags=True
            custom=m.mainStore.custom
            qubitData[0].addReplace("customTags",custom)
        end if
        pidString=m.mainStore.customerId.tostr()+m.mainStore.sessionId+((timestamp / 1000).toStr()+(timestamp MOD 1000).toStr())
        ?pidString
        pid=_generatePID(pidString)
        qubitData[0].streamID.addReplace("pId",pid)
        stats.AddReplace("qubitData",qubitData)
        return stats
    end function

    store.createSegmentStats=function() as object
        print "-------------------------- createSegmentStats ---------------- "
        sdkInfo={"hFileVersion":m.mainStore.hFileVersion, "sdkVersion":m.mainStore.SDKVERSION}
        interval=m.segmentTimespan.totalSeconds()-(m.mainStore.lastPauseDur/1000)
        if interval<0
            interval=m.segmentTimespan.totalSeconds()
        else if interval<2
            return invalid
        end if
        interval = Int(interval)
        m.mainStore.lastPauseDur=0
        m.segmentTimespan.mark()
        scrnRes=m.mainStore.screenheight.toStr()+"x"+m.mainStore.screenwidth.toStr()
        stats={"version":m.mainStore.hFileVersion,"interval":interval,"pbTime":m.mainStore.lastKnownPos,"playDur":m.mainStore.playDur}
        streamID={"assetId":m.mainStore.assetID,"assetName":m.mainStore.assetName,"custId":m.mainStore.customerId,"dataSrc":m.mainStore.dataSrc,"mode":m.mainStore.mode}
        streamID.addReplace("playerName",m.mainStore.playerName)
        streamID.addReplace("sessionId",m.mainStore.sessionId)
        streamID.AddReplace("streamURL",m.mainStore.manifestURL)
        streamID.AddReplace("subscriberId",m.mainStore.subscriberId)
        streamID.AddReplace("subscriberType",m.mainStore.subscriberType)

        if m.mainStore.isLive<>invalid
            streamID.addReplace("isLive",m.mainStore.isLive)
        end if
        if m.mainStore.videoID <> invalid and m.mainStore.videoId <> ""
            streamID.AddReplace("videoId", m.mainStore.videoID)
        end if
        if m.mainStore.domainName <> invalid or m.mainstore.domainName <> ""
            streamID.addreplace("domainName", m.mainStore.domainName)
        end if
        streamID.AddReplace("subscriberTag",m.mainStore.subscriberTag)
        clientInfo = { "device": "Roku", "scrnRes": scrnRes, "model": m.mainStore.deviceModel, "platform": m.mainStore.deviceOS, "brand": m.mainStore.brand, "version": m.mainStore.deviceOSVersion }
        timestamp=_getDateTime()
        timestamp=0& + timestamp.AsSeconds() * 1000& + timestamp.GetMilliseconds()+m.mainStore.deltaTime
        pbInfo=[]
        if m.upshift<>0
            info={"timestamp":timestamp,"upShiftCount":m.upshift}
            if m.mainStore.bwInUse <> invalid
                info.addReplace("bwInUse", m.mainStore.bwInUse)
            end if
            pbInfo.Push(info)
            m.upshift=0
        end if
        if m.downshift<>0
            info={"timestamp":timestamp,"downShiftCount":m.downshift}
            if m.mainStore.bwInUse <> invalid
                info.addReplace("bwInUse", m.mainStore.bwInUse)
            end if
            pbInfo.Push(info)
            m.downshift=0
        end if
        if m.mainStore.bwInUse<>invalid
            info={"timestamp":timestamp,"pbTime":m.mainStore.lastKnownPos,"bwInUse":m.mainStore.bwInUse}
            pbInfo.Push(info)
        end if
        segInfo=m.segmentQueue
        streamInfo={}
        if m.mainStore.totalDuration<>0 and m.mainStore.totalDuration<>invalid
            streamInfo.addReplace("totalDuration",m.mainStore.totalDuration)
        end if
        if m.mainStore.streamFormat<>invalid
            streamInfo.addReplace("streamFormat",m.mainStore.streamFormat)
        end if
        streamInfo.addReplace("numOfProfile",m.mainStore.totalProfiles)
        streamInfo.addReplace("maxFps",m.mainStore.maxFps)
        streamInfo.addReplace("minFps",m.mainStore.minFps)
        streamInfo.addReplace("minRes",m.mainStore.minRes)
        streamInfo.addReplace("maxRes",m.mainStore.maxRes)
        if m.buffWait.count() <> 0
            pbinfo.append(m.buffWait)
            m.buffWait = []
        end if
        qubitData=[{"streamID":streamID,"sdkInfo":sdkInfo,"clientInfo":clientInfo,"segInfo":segInfo,"pbInfo":pbInfo,"streamInfo":streamInfo}]
        if m.mainStore.customTags = True
            custom = m.mainStore.custom
            qubitData[0].addReplace("customTags", custom)
        end if

        pidString=m.mainStore.customerId.tostr()+m.mainStore.sessionId+((timestamp / 1000).toStr()+(timestamp MOD 1000).toStr())
        print pidString
        pid=_generatePid(pidString)
        qubitData[0].streamID.addReplace("pId",pid)
        stats.AddReplace("qubitData",qubitData)
        stats.AddReplace("timestamp",timestamp)
        return stats
    end function

    ' Next 4 functions- Main storage object getters and setters

    store.getStore=function() as object
        return m.mainStore
    end function

    store.updateStore=function(mainStore as object)
        m.mainStore=mainStore
    end function

    store.addToStore=function(key as string, value)
        m.mainStore.AddReplace(key,value)
    end function

    store.getFromStore=function(key as string)
        if m.mainStore[key]<>Invalid
            response=m.mainStore[key]
        else
            response=invalid
        end if
        return response
    end function

    ' Next 2 functions- Registration Status getters and setters
    store.setRegistrationStatus=function(isEnable as boolean)
       m.mainStore["isRegistered"]=isEnable
    end function

    store.getRegistrationStatus=function() as boolean
        if m.mainStore["isRegistered"]<>INVALID
            register=m.mainStore["isRegistered"]
        else
            register=False
        end if
        return register
    end function

    ' Next 2 functions- Producer URL getter and setter
    store.getProducerURL = function() as string
        if m.mainStore["producerURL"]<>INVALID
            _prod=m.mainStore["producerURL"]
        else
            _prod=INVALID
        end if
        ?_prod
        return _prod
    end function

    store.setProducerURL = function(_prod as string)
        m.mainStore.AddReplace("producerURL",_prod)
    end function

    ' Next 2 functions- Beacon interval getter and setter
    store.getInterval = function() as integer
        if m.mainStore["statsInterval"]<>INVALID
            _stats=m.mainStore["statsInterval"]
        else
            _stats=30
        end if
        return _stats
    end function

    store.setInterval = function(_stats as integer)
        m.mainStore.AddReplace("statsInterval",_stats)
    end function

    store.sendCoordinates = function(latitude as string, longitude as string)
        m.mainStore.AddReplace("latitude",latitude)
        m.mainStore.AddReplace("longitude",longitude)
    end function

    ' Next 2 functions- Player State getter and setter
    store.setplayerState = function(_state as integer)
        if m.mainStore.presentState<>_state and m.mainStore.presentState<>INVALID
            m.mainStore.AddReplace("previousState",m.mainStore.presentState)
            m.mainStore.AddReplace("presentState",_state)
        end if
    end function

    store.getPlayerState = function() as string
       if m.mainStore["presentState"]<>INVALID
            _state=m.mainStore["presentState"]
       else
            _state=invalid
       end if
       return _state
    end function

    store.setSSID=function(ssid as string)
        m.mainStore.AddReplace("ssid",ssid)
    end function

    store.setWifiSignalStrength=function(strength as string)
        m.mainStore.AddReplace("wifiStrength",strength)
    end function

    store.setSubscriberID=function(ID as string)
       m.mainStore["subscriberId"]=ID
    end function

    store.getsubscriberID=function() as boolean
        if m.mainStore["subscriberId"]<>INVALID
            _sub=m.mainStore["subscriberId"]
        else
            _sub=False
        end if
        return _sub
    end function

    store.setSubscriberType=function(subtype as string)
       m.mainStore["subscriberType"]=subtype
    end function

    store.getsubscriberType=function() as boolean
        if m.mainStore["subscriberType"]<>INVALID
            _sub=m.mainStore["subscriberType"]
        else
            _sub=False
        end if
        return _sub
    end function

    store.setPlaybackPos=function(pos1 as longinteger)
       m.mainStore["lastKnownPos"]=pos1
    end function

    store.getPlaybackPos=function() as longInteger
        if m.mainStore["lastKnownPos"]<>INVALID
            _pos=m.mainStore["lastKnownPos"]
        else
            _pos=m.mainStore.playDur
        end if
        return _pos
    end function
    'Functions to calculate Play Duration
    store.updatePlayDuration=function(playDur)
        m.mainstore.playDur=playDur-m.mainStore.pauseDur
        if m.mainStore.playDur < 0
            m.mainStore.playDur = playDur
        end if
    end function

    store.updatePauseDuration=function(pauseDur)
        m.mainstore.pauseDur+=pauseDur
    end function

    store.pushDataRate=function(dataRate)
        if dataRate<>invalid
            m.dataRates.Push(dataRate)
            m.rate+=dataRate
        end if
        bwInUse=m.rate/m.dataRates.count()
        bwInUse=bwInUse/1024
        m.mainStore.AddReplace("bwInUse",bwInUse)
    end function

    store.getMinAndMaxRes=function()
        if m.mainStore.resolutions.count()>0
            max=0
            min=0
            maximum=0
            minimum=0
            for each items in m.mainStore.resolutions
                item=items.split("x")
                if item[0].toInt()>max
                    max=item[0].toInt()
                    maximum=items
                else if item[0].toInt()<min or min=0
                    min=item[0].toInt()
                    minimum=items
                else if item[1].toInt()>max
                    max=item[0].toInt()
                    maximum=items
                else if item[1].toInt()<min
                    min=item[0].ToInt()
                    minimum=items
                end if
            end for
            m.mainStore.addReplace("minRes",minimum)
            m.mainStore.AddReplace("maxRes",maximum)
        end if
    end function

    store.updateCustomTags=function(key as string,value as string )
        m.mainStore.customTags=True
        m.mainStore.custom.addReplace(key,value)
    end function

    store.updateBuffWait=function(buffWait)
        timestamp=_getDateTime()
        timestamp=0& + timestamp.AsSeconds() * 1000& + timestamp.GetMilliseconds()+m.mainStore.deltaTime
        buffWaiting={"timestamp":timestamp,"buffWait":buffWait,"pbTime":m.mainStore.lastKnownPos}
        m.buffWait.push(buffWaiting)
        m.mainStore.sumBuffWait+=buffWait
    end function

    store.updateChunk=function(chunkInfo as object)
        timestamp=_getDateTime()
        timestamp=0& + timestamp.AsSeconds() * 1000& + timestamp.GetMilliseconds()+m.mainStore.deltaTime
        if timestamp<>m.prevTimestamp
            chunkInfo.AddReplace("timestamp",timestamp)
            m.prevTimestamp=timestamp
            if m.mainStore.vCodec<>invalid
                chunkInfo.addReplace("vCodec",m.mainStore.vCodec)
            end if
            if m.mainStore.aCodec <> invalid
                chunkInfo.addReplace("aCodec", m.mainStore.aCodec)
            end if
            if m.mainStore.bitrateProfiles<>invalid and m.mainStore.bitrateProfiles.count()>0
                index=0
                for each item in m.mainStore.bitrateProfiles
                    if chunkInfo.cbrBitrate=item
                        chunkInfo.AddReplace("profileNum",index)
                        if m.mainStore.resolutions<>invalid and index<m.mainStore.resolutions.count()
                            chunkInfo.AddReplace("res",m.mainStore.resolutions[index])
                        end if
                    end if
                    index+=1
                end for
            end if
            if chunkInfo.cbrBitrate>m.lastRate and m.lastRate<>0
                m.upshift+=1
            end if
            if chunkInfo.cbrBitrate<m.lastRate and m.lastRate<>0
                m.downShift+=1
            end if
            m.lastRate=chunkInfo.cbrBitrate
            m.lastSegment = chunkInfo
            m.segmentQueue.Push(chunkInfo)
        end if
    end function

    store.updateDeltaTime=function(time)
        m.mainStore.addReplace("deltaTime",time)
    end function

    return store
end function

function MMSmartStream() as Object
  ? " MMSmartStream constructor"
  'MM API's engine. Has access to storage object. "init()" function enables beacon timer object and utility functions for engine functioning
  'All requests are handled by this component scope functions.
  mmsdk={}
  mmsdk.init=function()
      m.httpPort=_createPort()
      m.mainStore=MMStore()
      m.mainStore.init()
      ? " MMSmartStream constructor init"
      m.isInitialised=false
      m.playingTime=_getDateTime()
      m.pauseTime=_getDateTime()
      m.latencyTimespan=createObject("roTimeSpan")
      m.pauseTimespan=createObject("roTimeSpan")
      m.events=[]
      m.prevState=""


      m.sendOutStats = function(data as object) as void
        'Not implemented
        if m.isInitialised=false
            return
        end if
        p_url=m.mainStore.getProducerUrl()
        connection= _createConnection(m.httpPort)
        connection.SetURL(p_url)
        connection.SetRequest("POST")
        data=formatJson(data)
        ?data
        sent=connection.AsyncPostFromString(data)
        ?connection.getIdentity()
        ? " sent respones " sent
        if sent
            msg=wait(0,m.httpPort)
            if type(msg)="roURLEvent"
                ?"sent"
                ?msg.getSourceIdentity
            end if
        end if
        'Error handling yet to be implemented(retries etc)
      end function

      m.AsyncRegisterSession = function(api_url as String)
        connection = _createConnection(m.httpPort)
        ?api_url
        connection.setURL(api_url)
        connection.setRequest("GET")
        'data=formatJSON(data)
        'ParseJson(m.connection.AsyncGetToString())
        'Set Retries
        retryCountdown=3
        timeout=15000
        while retryCountdown > 0
            response=connection.AsyncGetToString()
            event = wait(timeout, m.httpPort)
            if type(event) = "roUrlEvent"
                ?"Post Registration"
                response=event.getString()
                response=ParseJSON(response)
                if response<>invalid and response.error=invalid
                    timestamp=_getDateTime()
                    timestamp=0& + timestamp.AsSeconds() * 1000& + timestamp.GetMilliseconds()
                    m.mainStore.updateDeltaTime(response.timestamp-timestamp)
                    'm.mainStore.adjustQueueTime()
                    m.mainStore.setProducerURL(response["producerURL"])
                    m.mainStore.setInterval(response["statsInterval"])
                    m.mainStore.setRegistrationStatus(true)
                    m.isInitialised=true
                else if response=invalid or response.error<>invalid
                    m.isInitialised=False
                    exit while
                end if
                exit while
            end if
          retryCountdown = retryCountdown - 1
        end while
      end function

      m.getProfiles=function(manifestURL as string) as void
        format=_getStreamFormat(manifestURL)
        if m.manifestDisable=True
            m.mainStore.addToStore("mode","QBRDisabled-NoPresentationInfo")
            return
        end if
        if format = "HLS"
            connection=_createConnection(m.httpPort)
            connection.setURL(manifestURL)
            connection.setRequest("GET")
            response=connection.getToString()
            bitrates=response.split("BANDWIDTH=")
            bitrates.shift()
            profiles=[]
            for each item in bitrates
                item=item.split("\n")
                item=item[0].split(",")
                profiles.Push(item[0].toInt())
            end for
            m.mainStore.addToStore("bitrateProfiles",profiles)
            res=response.split("RESOLUTION=")
            res.shift()
            bits=profiles.count()
            profiles=[]
            for each item in res
                item=item.split("\n")
                item=item[0].split(",")
                profiles.Push(item[0])
            end for
            if profiles.count()>0
                temp=profiles[profiles.count()-1].split(",")
                profiles[profiles.count()-1]=temp[0]
            end if
            m.mainStore.addToStore("resolutions",profiles)
            if bits>0 and profiles.count()>0
                m.mainStore.addToStore("totalProfiles",profiles.count())
            else if profiles.count()=0 and bits>0
                m.mainStore.addToStore("totalProfiles",bits)
            end if
            m.mainStore.getMinAndMaxRes()
            if profiles.count() = 1 or (bits = 1 and profiles.count() = 0)
                m.mainStore.addToStore("mode", "QBRDisabled-NoABR")
            end if
        else if format = "DASH"
            connection=_createConnection(m.httpPort)
            connection.setURL(manifestURL)
            connection.setRequest("GET")
            profiles=[]
            res=[]
            response=connection.getToString()
            xml=CreateObject("roXMLelement")
            xml.Parse(response)
            temp=xml.getNamedElements("Period")[0].getBody().GetNamedElements("Representation")
            if xml.getNamedElements("Period").count()>1
                m.mainStore.addToStore("mode","QBRDisabled-MultiplePeriodNotSupported")
            end if
            '[0].getBody()[1].getChildNodes()
            if temp<>invalid
                for each item in temp
                    avc=CreateObject("roRegex", "avc3", "")
                    if item.getAttributes().codecs<>invalid and avc.isMatch(item.getAttributes().codecs)
                        m.mainStore.addToStore("vCodec", item.getAttributes().codecs)
                        profiles.push(item.getAttributes().bandwidth)
                    else if item.getAttributes().codecs <> invalid and avc.isMatch(item.getAttributes().codecs) = False
                        m.mainStore.addToStore("aCodec", item.getAttributes().codecs)
                    end if
                    if item.getAttributes().height<>invalid and item.getAttributes().width<>invalid
                        res.push(item.getAttributes().height.toStr() + "x" + item.getAttributes().width.toStr())
                    end if
                end for
            end if
            m.mainStore.addToStore("totalProfiles",profiles.count())
            m.mainStore.addToStore("resolutions", res)
            if profiles.count()=1
                m.mainStore.addToStore("mode","QBRDisabled-NoABR")
            end if
        else if format="mp4"
            m.mainStore.addToStore("mode","QBRDisabled-ContentNotSupportedForQBR")
        end if
      end function

      m.sendOutQueue=function() as void
        events=m.mainStore.getEventQueue()
        if events.count()>0
            for each data in events
                if data.qubitData[0].pbEventInfo<>invalid
                    if data.qubitData[0].pbeventInfo.event="START"
                        store=m.mainStore.getStore()
                        if data.qubitData[0].streamInfo.totalDuration=invalid
                            if store.totalDuration<>invalid and store.totalDuration<>0
                                data.qubitData[0].streamInfo["totalDuration"]=store.totalDuration
                            else
                                return
                            end if
                        end if
                        if data.qubitData[0].streamID.mode=invalid
                            if store.mode<>invalid
                                data.qubitData[0].streamID["mode"]=store.mode
                            else
                                return
                            end if
                        end if
                        if data.qubitData[0].streamID.isLive=invalid
                            if store.mode<>invalid
                                data.qubitData[0].streamID["isLive"]=store.isLive
                                data.qubitData[0].streamID["mode"]=store.mode
                            else
                                return
                            end if
                        end if
                    end if
                end if
                m.sendOutStats(data)
            end for
            m.mainStore.clearEventQueue()
        end if
      end function

  end function

  mmsdk.blacklistRepresentation = function(representationIdx as integer,blacklistRepresentation as boolean)
    'Not Implemented
    'store.AddReplace("representationIndex",representationIdx)
    'store.AddReplace("blacklistRepresentation",blacklistRepresentation)
  end function

  mmsdk.disableManifestFetch = function(disable as boolean)
    if disable=true
        m.manifestDisable=True
    end if
  end function

  mmsdk.enableLogTrace = function(isEnable as boolean)
    'Not Implemented
    m.mainStore.addToStore("enableLogTrace",isEnable)
  end function

  mmsdk.getInstance = function(context as object)
    'Not implemented
    'Not required, redundant to engine object
  end function

  mmsdk.getQBRBandwidth=function(representationTrackIdx as integer, defaultBitrate as integer, bufferLength as integer, playbackPos as integer)
    'Not implemented
  end function

  mmsdk.getQBRChunk = function(cbrChunk as object)
    'Not Implemented
  end function

  mmsdk.getSmartRouteUrl = function(downloadUrl as String)
    'Not Implemented
  end function

  mmsdk.getRegistrationStatus = function()
    'Not Implemented
  end function

  mmsdk.getVersion = function()
    'Not Implemented
    Return m.mainStore.getFromStore["SDK_VERSION"]
  end function

  mmsdk.initializeSession = function(mode as string, manifestURL as String, metaURL as String, assetID as String, assetName as String,videoId) as object
    print " ----------------- MediaMelon SDK initializeSession "
    store=m.mainStore.getStore()
    api_url= store.API_SERVER +store.customerID.tostr()+"?sdkVersion="+store.SDKVERSION+"&hintFileVersion="+store.hFileVersion+"&EP_SCHEMA_VERSION="+store.EP_SCHEMA+"&platform="+store.platform+"&qmetric=true&component="+store.component+"&mode=QBRDisabled"
    store.addReplace("mode",mode)
    store.addReplace("manifestURL",manifestURL)
    store.AddReplace("assetID",assetID)
    store.AddReplace("assetName",assetName)
    store.AddReplace("videoID",videoID)
    sessionId=m.mainstore.generateSessionId()
    store.AddReplace("sessionId",sessionId)
    m.mainStore.updateStore(store)
    m.playingTime.mark()
    m.latencyTimespan.mark()
    data = m.mainStore.createEventStats("ONLOAD")
    m.prevState = "ONLOAD"
    m.asyncRegisterSession(api_url)
    m.getProfiles(manifestURL)
    m.sendOutStats(data)
    response={"status":m.isInitialised,"interval":m.mainStore.getInterval()}
    return response

    'Create a new branched out thread for subsequent function call and exit.
  end function

  mmsdk.registerMMSmartStreaming = function(name as String, customerID as longInteger, component as String, subscriberID as String, domainName as String, subscriberType as String, subscriberTag as String)
    store=m.mainStore.getStore()
    store.AddReplace("customerID",customerID)
    if component <> invalid and component <> ""
        store.AddReplace("component",component)
    end if
    if subscriberID <> invalid and subscriberID <> ""
        store.AddReplace("subscriberID",subscriberID)
    end if
    store.AddReplace("playerName",name)
    if domainName <> invalid and domainName <> ""
        store.AddReplace("domainName",domainName)
    end if
    if subscriberType <> invalid and subscriberType <> ""
        store.AddReplace("subscriberType",subscriberType)
    end if
    if subscriberTag <> invalid and subscriberTag <> ""
        store.AddReplace("subscriberTag",subscriberTag)
    end if
    store.AddReplace("dataSrc","Player")
    store.AddReplace("isRegistered",True)
    m.mainStore.updateStore(store)
  end function

  mmsdk.reportABRSwitch = function(prevBitrate as integer, newBitrate as integer)
    'Not Implemented
    'm.store.AddReplace("prevBitrate",prevBitrate)
    'm.store.AddReplace("newBitrate",newBitrate)
  end function

  mmsdk.reportAdError = function(error as integer, pos1 as longinteger)
    'Not Implemented
    store.AddReplace("error",error)
    store.AddReplace("pos",pos1)
  end function

  mmsdk.reportAdInfo = function(adClient as String, adUrl as String, adDuration as longinteger, adPosition as String, adType as object, adCreativeType as String, adServer as String, adResolution as String)
    'Not Implemented
  end function

  mmsdk.reportAdPlaybackTime = function(playbackPos as longinteger)
    'Not Implemented
    m.store.AddReplace("playbackPos",playbackPos)

  end function

  mmsdk.reportAdState = function(adState as object)
    'Not Implemented
    m.store.AddReplace("adState",adState)
  end function

  mmsdk.reportBufferingCompleted = function() as void
    if m.isInitialised=false
        return
    end if
    if m.prevState="BUFFERING"
        m.mainStore.updateBuffWait(m.latencyTimeSpan.totalmilliseconds())
    end if
  end function

  mmsdk.reportBufferingStarted = function() as void
    if m.isInitialised=false
        return
    end if
    m.latencyTimeSpan.mark()
    date=_getDateTime()
    playDur=date.AsSeconds()-m.playingTime.AsSeconds()
    m.mainStore.updatePlayDuration(playDur)
    data=m.mainStore.createEventStats("BUFFERING")
    m.mainStore.pushToEventQueue(data)
    m.prevState="BUFFERING"
    if m.isInitialised=true
        m.sendOutQueue()
                'if successful.
    end if
  end function

  mmsdk.reportChunkRequest = function(chunkInfo as object)
    m.mainStore.updateChunk(chunkInfo)
  end function

  mmsdk.reportCustomMetadata = function(key as String, value as String)
    m.mainStore.updateCustomTags(key,value)
  end function

  mmsdk.reportDeviceInfo = function(brand as String,deviceModel as String, deviceOS as String, deviceOsVersion as String, telecomOperator as String, screenWidth as integer, screenHeight as integer)
    m.mainStore.addToStore("brand",brand)
    m.mainStore.addToStore("deviceModel",deviceModel)
    m.mainStore.addToStore("deviceOS",deviceOS)
    m.mainStore.addToStore("deviceOSVersion",deviceOSVersion)
    m.mainStore.addToStore("telecomOperator",telecomOperator)
    m.mainStore.addToStore("screenWidth",screenWidth)
    m.mainStore.addToStore("screenHeight",screenHeight)
  end function

  mmsdk.reportDownloadRate = function(downloadRate as integer)
    'Not Implemented
    m.mainStore.pushDataRate(downloadRate)
  end function

  mmsdk.reportError = function(Error as String,pos1 as double) as void

    'Not Implemented
    if m.isInitialised=false
        return
    end if
    date=_getDateTime()
    playDur=date.AsSeconds()-m.playingTime.AsSeconds()
    m.mainStore.updatePlayDuration(playDur)
    m.mainStore.addToStore("errorString",error)
    m.mainStore.addToStore("lastKnownPos",pos1)
    data=m.mainStore.createEventStats("ERROR")
    m.sendOutStats(data)
  end function

  mmsdk.reportFrameLoss = function(lossCnt as integer)
    'Not Implemented
    m.store.AddReplace("lossCount",lossCnt)
  end function

  mmsdk.reportMetricValue = function(chunkInfo as object)
    'Not Implemented
    m.store.MetricValue("chunkInfo",chunkInfo)
  end function

  mmsdk.reportLocation = function(latitude as double, longitude as double)
    'Not Implemented
    m.mainStore.sendCoordinates(latitude,longitude)
  end function

  mmsdk.reportNetworkType = function(networkType as object)
    'Not Implemented
  end function

  mmsdk.reportPlaybackPosition = function(playbackPos as double)
    'print " >>>>>>> reportPlaybackPosition "
    m.mainStore.addToStore("lastKnownPos",playbackPos)
    'playDur=m.calculatePlayDuration()
    'm.mainStore.addToStore("playDur",playDur)
  end function

  mmsdk.reportPlayerInfo = function(brand as string, model as string, version as string)
    'Not Implemented
    m.mainStore.addToStore("brand",brand)
    m.mainStore.addToStore("deviceModel",model)
    m.mainStore.addToStore("deviceOS",version)
  end function

  mmsdk.reportPlayerSeekCompleted = function(seekEndPos as double) as void
    if m.isInitialised=false
        return
    end if
    date=_getDateTime()
    data=m.mainStore.createEventStats("SEEKED")
    m.mainStore.pushToEventQueue(data)
    m.prevState="SEEKED"
    if m.isInitialised=true
        m.sendOutQueue()
        'if successful.
    end if
  end function

  mmsdk.reportPlayerState = function(playerState as string) as void
    if m.isInitialised=false
        return
    end if
    if playerState <> m.prevState
        date=_getDateTime()
        playDur=date.AsSeconds()-m.playingTime.AsSeconds()
        if (m.prevState="PAUSE" or m.prevState="SEEKED") and (playerState="RESUME" or playerState="PLAYING")
            playerState="RESUME"
            pauseDur=date.AsSeconds()- m.pauseTime.AsSeconds()
            m.mainStore.updatePauseDuration(pauseDur)
            m.mainStore.addToStore("lastPauseDur",m.pauseTimespan.totalMilliseconds())
            m.mainStore.updatePlayDuration(playDur)
        end if
        if playerState="PAUSE"
            m.pauseTime.mark()
            m.pauseTimespan.mark()
            m.mainStore.updatePlayDuration(playDur)

            segments=m.mainStore.createSegmentStats()
            if segments<>invalid
                m.mainStore.pushToEventQueue(segments)
                m.mainStore.clearSegmentQueue()
            end if
        end if
        if playerState="ENDED"
            if m.prevState<>"PAUSE"
                m.mainStore.updatePlayDuration(playDur)
                segments=m.mainStore.createSegmentStats()
                if segments<>invalid
                    m.mainStore.pushToEventQueue(segments)
                    m.mainStore.clearSegmentQueue()
                end if
            end if
        end if
        if playerState = "COMPLETE"
            m.mainStore.updatePlayDuration(playDur)
            segments = m.mainStore.createSegmentStats()
            if segments<>invalid
                m.mainStore.pushToEventQueue(segments)
                m.mainStore.clearSegmentQueue()
            end if
        end if
        data=m.mainStore.createEventStats(playerState)
        if data.qubitData[0].pbEventInfo.event<>"RETURN"
            m.mainStore.pushToEventQueue(data)
            m.prevState=playerState
            if m.isInitialised=true
                m.sendOutQueue()
                'if successful.
            end if
        end if
     end if
     m.prevState=playerState
  end function

  mmsdk.reportPresentationSize = function(width as integer, height as integer)
    'Not Implemented
  end function

  mmsdk.reportUserInitiatedPlayback = function(timeToStartStreaming)
    ?"User initiate playback-engine side"
    timeToStartStreaming=int(timetoStartStreaming)
    latency=int(m.latencyTimespan.TotalMilliseconds())
    latency=latency+timeToStartStreaming
    m.mainStore.reportLatency(latency)
    data=m.mainStore.createEventStats("START")
    m.prevState="START"
    m.mainStore.pushToEventQueue(data)
    m.sendOutQueue()

  end function

  mmsdk.reportWifiDataRate = function(dataRate as longinteger)

    'Not Implemented
  end function

  mmsdk.reportWifiSSID = function(ssid as string)
    m.mainStore.setSsid(ssid)
  end function

  mmsdk.reportWifiSignalStrengthPercentage = function(strength as double)
    'Not Implemented
    m.mainStore.setWifiSignalStrength(strength)
  end function

  mmsdk.setPresentationInformation = function(presentationInfo as object)
    'Not Implemented
    if presentationInfo.isLive=true
        presentationInfo.duration=-1
        m.mainStore.addToStore("mode","QBRDisabled-LiveSessionNotSupported")
    else if presentationInfo.duration=-1
        presentationInfo.isLive=True
        m.mainStore.addToStore("mode","QBRDisabled-LiveSessionNotSupported")
    end if
    m.mainStore.addToStore("totalDuration",presentationInfo.duration)
    m.mainStore.addToStore("representation",presentationInfo.representation)
    m.mainStore.addToStore("isLive",presentationInfo.isLive)
    m.mainStore.addToStore("streamFormat",presentationInfo.streamFormat)
    m.sendOutQueue()
  end function

  mmsdk.updateSubscriber= function(subscriberID as String, subcriberType as String)
    'Not Implemented
    m.mainStore.setSubscriberID(subscriberID)
    m.mainStore.setSubscriberType(subscriberType)
  end function

  mmsdk.updateSubscriberID= function(subscriberID as String)
    'Not Implemented
    m.mainStore.setSubscriberID(subscriberID)
  end function

  mmsdk.fireBeacon=function()
    if m.prevState <> invalid
        if m.prevState <> "ONLOAD"
            date=_getDateTime()
            playDur=date.AsSeconds()-m.playingTime.AsSeconds()
            m.mainStore.updatePlayDuration(playDur)
            data=m.mainStore.createSegmentStats()
            if data<>invalid
                m.sendOutStats(data)
                m.mainStore.clearSegmentQueue()
            end if
        end if
    end if
  end function

  return mmsdk
end function
