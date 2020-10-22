
function SmartStream() as Object
  wrapper={}
  wrapper.init = function()
    m.mmsdk=MMSmartStream()
    m.mmsdk.init()
  end function

  wrapper.blacklistRepresentation = function(representationIdx as integer,blacklistRepresentation as boolean)
    m.mmsdk.blacklistRepresentation(representationIdx,blacklistRepresentationn)
  end function

  wrapper.disableManifestFetch = function(disable as boolean)
    m.mmsdk.disableManifestFetch(disable)
  end function

  wrapper.enableLogTrace = function(isEnable as boolean)
    m.mmsdk.enableLogTrace(isEnable)
    return false
  end function

  wrapper.getInstance = function(context as object)
    m.mmsdk.getInstance(context)
  end function

  wrapper.getQBRBandwidth=function(representationTrackIdx as integer, defaultBitrate as integer, bufferLength as integer, playbackPos as integer)
    m.mmsdk.getQBRBandwidth(representationTrackIdx,defaultBitrate, bufferLength, playbackPos)
  end function

  wrapper.getQBRChunk = function(cbrChunk as object)
    m.mmsdk.getQBRChunk(cbrChunk)
  end function

  wrapper.getSmartRouteUrl = function(downloadUrl as String)
    m.mmsdk.getSmartRouteUrl(downloadUrl)
  end function

  wrapper.getRegistrationStatus = function()
    m.mmsdk.getRegistrationStatus()
  end function

  wrapper.getVersion = function()
    m.mmsdk.getVersion()
  end function

  wrapper.initializeSession = function(mode as string, manifestURL as String, metaURL as String, assetID as String, assetName as String,videoId) as object
    response = false
    if manifestURL<>invalid
        response=m.mmsdk.initializeSession(mode, manifestURL, metaURL, assetID, assetName,videoId)
    end if
    return response
  end function

  wrapper.registerMMSmartStreaming = function(name as String, customerID as longInteger, component as String, subscriberID as String, domainName as String, subscriberType as String, subcriberTag as String)
    'Registration call wrapper
    response=false
    if customerID<>invalid
        m.mmsdk.registerMMSmartStreaming(name, customerID, component, subscriberID, domainName, subscriberType, subcriberTag)
        response=true
    end if
    return response
  end function

  wrapper.reportABRSwitch = function(prevBitrate as integer, newBitrate as integer)
    m.mmsdk.reportABRSwitch(prevBitrate,newBitrate)
  end function

  wrapper.reportAdError = function(error as integer, pos1 as longinteger)
    m.mmsdk.reportAdError(error,pos1)
  end function

  wrapper.reportAdInfo = function(adClient as String, adUrl as String, adDuration as longinteger, adPosition as String, adType as object, adCreativeType as String, adServer as String, adResolution as String)
    m.mmsdk.reportAdInfo(adClient,adUrl,adDuration,adPosition,adType,adCreativeType, adServer, adResolution)
  end function

  wrapper.reportAdPlaybackTime = function(playbackPos as longinteger)

    m.mmsdk.reportAdPlaybackTime(playbackPos)
  end function

  wrapper.reportAdState = function(adState as object)

    m.mmsdk.reportAdState(adState)
  end function

  wrapper.reportBufferingCompleted = function()

    m.mmsdk.reportBufferingCompleted()
  end function

  wrapper.reportBufferingStarted = function()

    m.mmsdk.reportBufferingStarted()
  end function

  wrapper.reportChunkRequest = function(chunkInfo as object)
    m.mmsdk.reportChunkRequest(chunkInfo)
  end function

  wrapper.reportCustomMetadata = function(key as String, value as String)
    m.mmsdk.reportCustomMetadata(key,value)
  end function

  wrapper.reportDeviceInfo = function(brand as String,deviceModel as String, deviceOS as String, deviceOsVersion as String, telecomOperator as String, screenWidth as integer, screenHeight as integer)
    m.mmsdk.reportDeviceInfo(brand,deviceModel,deviceOS,deviceOsVersion,telecomOperator,screenWidth, screenHeight)
  end function

  wrapper.reportDownloadRate = function(downloadRate as longinteger)
    m.mmsdk.reportDownloadRate(downloadRate)
  end function

  wrapper.reportError = function(Error as String,pos1 as double)
    m.mmsdk.reportError(Error,pos1)
  end function

  wrapper.reportFrameLoss = function(lossCnt as integer)
    m.mmsdk.reportFrameLoss(lossCnt)
  end function

  wrapper.reportMetricValue = function(chunkInfo as object)

    m.mmsdk.reportMetricValue(chunkInfo)
  end function

  wrapper.reportLocation = function(latitude as double, longitude as double)
    m.mmsdk.reportLocation(latitude,longitude)
  end function

  wrapper.reportNetworkType = function(networkType as object)
    m.mmsdk.reportNetworkType(networkType)
  end function

  wrapper.reportPlaybackPosition = function(playbackPos as double)
    m.mmsdk.reportPlaybackPosition(playbackPos)
  end function

  wrapper.reportPlayerInfo = function(brand as string, model as string, version as string)
    m.mmsdk.reportPlayerInfo(brand,model,version)
  end function

  wrapper.reportPlayerSeekCompleted = function(seekEndPos as double)
    m.mmsdk.reportPlayerSeekCompleted(seekEndPos)
  end function

  wrapper.reportPlayerState = function(playerState as string)
    m.mmsdk.reportPlayerState(playerState)
  end function

  wrapper.reportPresentationSize = function(width as integer, height as integer)
    m.mmsdk.reportPresentationSize(width,heigh)
  end function

  wrapper.reportUserInitiatedPlayback = function(time)
    m.mmsdk.reportUserInitiatedPlayback(time)
  end function

  wrapper.reportWifiDataRate = function(dataRate as longinteger)
    m.mmsdk.reportWifiDataRate(dataRate)
  end function

  wrapper.reportWifiSSID = function(ssid as string)
    m.mmsdk.reportWifiSSID(ssid)
  end function

  wrapper.reportWifiSignalStrengthPercentage = function(strength as double)
    m.mmsdk.reportWifiSignalStrengthPercentage(strength)
  end function

  wrapper.setPresentationInformation = function(presentationInfo as object)
    m.mmsdk.setPresentationInformation(presentationInfo)
  end function

  wrapper.updateSubscriber= function(subscriberID as String, subcriberType as String)
    m.mmsdk.updateSubscriber(subscriberID,subscriberType)
  end function

  wrapper.updateSubscriberID= function(subscriberID as String)
    m.mmsdk.updateSubscriberID(subscriberID)
  end function

  wrapper.fireBeacon=function()
    m.mmsdk.fireBeacon()
  end function
  return wrapper
end function
