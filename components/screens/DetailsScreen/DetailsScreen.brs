' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********
 ' inits details Screen
 ' sets all observers
 ' configures buttons for Details screen
Function Init()
    ? "[DetailsScreen] init"

    m.scene = m.top.getScene()
    m.content_helpers = ContentHelpers()

    m.top.observeField("visible", "onVisibleChange")
    m.top.observeField("focusedChild", "OnFocusedChildChange")
    m.top.DontShowSubscriptionPackages = true
    m.top.ShowSubscriptionPackagesCallback = false

    m.buttons           =   m.top.findNode("Buttons")

    initializeVideoPlayer()
    m.top.videoPlayer.visible = false

    m.description       =   m.top.findNode("Description")
    m.background        =   m.top.findNode("Background")

    m.top.canWatchVideo = false
    m.buttons.setFocus(true)

    ' Set theme
    m.AppBackground = m.top.findNode("AppBackground")
    m.AppBackground.color = m.global.theme.background_color

    m.overlay = m.top.findNode("thumbOverlay-details")
    m.overlay.uri = m.global.theme.overlay_uri

    m.buttons.color = m.global.theme.primary_text_color
    m.buttons.focusedColor = m.global.theme.secondary_text_color
    m.buttons.focusBitmapUri = m.global.theme.button_focus_uri

    m.subscribeButtons = m.top.findNode("SubscriptionButtons")
    m.subscribeButtons.color = m.global.theme.primary_text_color
    m.subscribeButtons.focusedColor = m.global.theme.secondary_text_color
    m.subscribeButtons.focusBitmapUri = m.global.theme.button_focus_uri

    m.optionsText = m.top.findNode("OptionsText")
    m.optionsText.text = m.global.labels.menu_label
    m.optionsText.color = m.global.theme.primary_text_color

    m.optionsIcon = m.top.findNode("OptionsIcon")
    m.optionsIcon.blendColor = m.global.brand_color

    m.tVideoHeartBeatTimer = m.top.FindNode("tVideoHeartBeatTimer")
    m.tVideoHeartBeatTimer.observeField("fire", "OnVideoHeartBeatEventFired")
    m.tVideoHeartBeatTimer.duration = 5
End Function

sub OnVideoHeartBeatEventFired()
    isSendEvent = false
    ' For Segment Analytics'
    if m.top.videoPlayer.state = "playing"
        if (m.global.enable_segment_analytics = true)
            if (m.global.segment_source_write_key <> invalid AND m.global.segment_source_write_key <> "")
                if (m.top.videoPlayer.state = "playing" AND m.firstTimeVideo = false)
                    isSendEvent = true
                end if
            else
                print "[HomeScene] ERROR : SEGMENT ANALYTICS > Missing Account ID. Please set 'segment_source_write_key' in config.json"
            end if
        else
           print "[HomeScene] INFO : SEGMENT ANALYTICS IS NOT ENABLED..."
        end if
    end if

    if (isSendEvent = true)
        scene = m.top.getScene()
        scene.segmentEvent = GetSegmentVideoEventInfo("playingHeartBeat")
    end if
end sub

sub StartScaleUpAnimation()
    print "StartScaleUpAnimation----------"
    m.AudioThumbnailPoster.scale = [1, 1]
end sub

sub StartScaleDownAnimation()
    print "StartScaleDownAnimation----------"
    if (m.top.squareImageUrl <> "")
        ' Dont downscale if image is already small'
        if (m.top.squareImageWH > 350)
          m.AudioThumbnailPoster.scale = [0.6, 0.6]
        end if
    else
        m.AudioThumbnailPoster.scale = [0.5, 0.5]
    end if
end sub

Function initializeVideoPlayer()
  m.top.videoPlayer = m.top.createChild("Video")
  m.top.videoPlayer.translation = [0,0]
  m.top.videoPlayer.width = 0
  m.top.videoPlayer.height = 0

  old = m.top.findNode("AudioThumbnailPoster")
  if (old <> invalid)
    m.top.removeChild(m.top.findNode("AudioThumbnailPoster"))
  end if
  m.AudioThumbnailPoster = m.top.createChild("Poster")
  m.AudioThumbnailPoster.id="AudioThumbnailPoster"
  m.AudioThumbnailPoster.height=720
  m.AudioThumbnailPoster.width=1280
  m.AudioThumbnailPoster.loadheight=720
  m.AudioThumbnailPoster.loadwidth=1280
  m.AudioThumbnailPoster.scaleRotateCenter = [ 1280/2, 720/2 ]
  m.AudioThumbnailPoster.translation=[0,0]
  m.AudioThumbnailPoster.loadDisplayMode="scaleToFit"
  m.AudioThumbnailPoster.visible = false

  m.firstTimeVideo = true
  ' Event listener for video player state. Needed to handle video player errors and completion
  m.top.videoPlayer.observeField("state", "OnVideoPlayerStateChange")
  m.top.videoPlayer.observeField("position", "OnVideoPlayerPositionChange")

  m.lastVideoPlayerState = "None"
  m.lastVideoPositionWhenPaused = -1
End Function

Function OnSquareImageChanged()
    if (m.top.squareImageUrl <> invalid and m.top.squareImageUrl <> "")
      uriToSet = m.top.squareImageUrl
      if (uriToSet <> invalid AND uriToSet <> "")
          sha1OfImageUrl = GetEncryptedUrlString(uriToSet)
          pathObj = CheckAndGetImagePathIfAvailable(sha1OfImageUrl)
          if (pathObj.foundPath = invalid OR pathObj.foundPath = "")
              DownloadAudioPosterImage(uriToSet, pathObj.newCachePath, pathObj.newTempPath)
          else
              print "squareImageUrl---> found in local"
              m.top.squareImageUrl = pathObj.foundPath
          end if
      end if
    end if
End Function

Function DownloadAudioPosterImage(imageUrl as String, newCachePath as String, newTempPath as String)

  print "DownloadAudioPosterImage::::::::::::" imageUrl
  downloadImageTask = createObject("roSGNode", "DownloadImageTask")
  downloadImageTask.bAPIStatus = "None"
  downloadImageTask.imageUrl = imageUrl
  downloadImageTask.newCachePath = newCachePath
  downloadImageTask.newTempPath = newTempPath
  downloadImageTask.observeField("bAPIStatus", "DownloadAudioImageTaskCompleted")
  downloadImageTask.control = "RUN"
end Function

Function DownloadAudioImageTaskCompleted(event as Object)
  task = event.GetRoSGNode()
  print "FadingBackground : DownloadImageTaskCompleted....................................." task.bAPIStatus
  task = invalid
end Function


Function ReinitializeVideoPlayer()
  if m.top.RemakeVideoPlayer = true
      m.top.removeChild(m.top.videoPlayer)
      m.top.removeChild(m.top.findNode("AudioThumbnailPoster"))
      initializeVideoPlayer()
  end if
End Function

' set proper focus to buttons if Details opened and stops Video if Details closed
Sub onVisibleChange()
    ? "[DetailsScreen] onVisibleChange"
    if m.top.visible = true then
        m.buttons.jumpToItem = 0

        if m.top.content <> invalid
          id = m.top.content.id
          m.top.content.inFavorites = m.global.favorite_ids.DoesExist(id)
        end if

        m.buttons.setFocus(true)
    else
        m.top.videoPlayer.visible = false
        m.top.videoPlayer.control = "stop"
        m.tVideoHeartBeatTimer.control = "stop"
    end if
End Sub

' gets buttons based on video monetization and consumer state
sub refreshButtons() as void
  isSubscribed = (m.global.auth.nativeSubCount > 0 or m.global.auth.universalSubCount > 0)
  svodEnabled = ((m.global.in_app_purchase or m.global.device_linking) and m.top.content.subscriptionRequired)

  userIsLoggedIn = (m.global.auth.isLoggedIn <> invalid and m.global.auth.isLoggedIn <> false)

  videoRequiresEntitlement = (m.top.content.subscriptionRequired or m.top.content.purchaseRequired or m.top.content.rentalRequired or (m.top.rowTVODInitiateContent <> invalid AND m.top.rowTVODInitiateContent.description<>""))
  videoRequiresEntitlement = (videoRequiresEntitlement or m.top.content.passRequired or m.top.content.registrationRequired)
  if videoRequiresEntitlement
    userIsEntitled = false
    if m.global.auth.entitlements <> invalid
      if m.global.auth.entitlements.DoesExist(m.top.content.id) then userIsEntitled = true
    end if

    if svodEnabled ' SVOD
      if userIsEntitled or isSubscribed
        m.top.canWatchVideo = true
        AddButtons()
      else
        m.top.canWatchVideo = false
        AddActionButtons()
      end if
    else if m.top.content.purchaseRequired and m.global.native_tvod ' TVOD
      if userIsEntitled
        m.top.canWatchVideo = true
        AddButtons()
      else
        m.top.canWatchVideo = false
        AddActionButtons()
      end if
    else if m.global.native_tvod and (m.top.rowTVODInitiateContent <> invalid AND m.top.rowTVODInitiateContent.description<>"")
      if userIsEntitled
        m.top.canWatchVideo = true
        AddButtons()
      else
        m.top.canWatchVideo = false
        AddActionButtons()
      end if

    else if m.top.content.registrationRequired
      if userIsLoggedIn
        m.top.canWatchVideo = true
        AddButtons()
      else
        m.top.canWatchVideo = false
        AddSignupButton()
      end if
    else
      if userIsLoggedIn
        m.top.canWatchVideo = true
        AddButtons()
      else
        m.top.canWatchVideo = false
        AddSigninButton()
      end if
    end if
  else
    m.top.canWatchVideo = true
    AddButtons()
  end if

end sub

' set proper focus to Buttons in case if return from Video PLayer
Sub OnFocusedChildChange()
    if m.top.isInFocusChain() and not m.buttons.hasFocus() and not m.top.videoPlayer.hasFocus() then
      ' Just in case overlay loses visibility when returning from video player. Cause of bug unknown
      m.overlay.uri = m.global.theme.overlay_uri
      m.overlay.visible = true

      refreshButtons()

      m.buttons.setFocus(true)
    end if
End Sub

' set proper focus on buttons and stops video if return from Playback to details
Sub onVideoVisibleChange()
    if m.top.videoPlayer.visible = false and m.top.visible = true
      if m.top.canWatchVideo <> invalid AND m.top.canWatchVideo = true
        AddButtons()
        m.buttons.setFocus(true)
        m.top.videoPlayer.control = "stop"
        m.tVideoHeartBeatTimer.control = "stop"
      else
        AddActionButtons()
        m.buttons.setFocus(true)
        m.top.videoPlayer.control = "stop"
        m.tVideoHeartBeatTimer.control = "stop"
      end if
    end if
End Sub

Sub SetSquareImageForAudioOnly()
  print "===============================================m.top.videoPlayer.squareImageUrl : " m.top.squareImageUrl
  print "m.top.videoPlayer.squareImageWH : " m.top.squareImageWH

  m.top.squareImageWH = 350
  AudioThumbnailPoster = m.top.findNode("AudioThumbnailPoster")
  if (AudioThumbnailPoster <> invalid AND m.top.squareImageUrl <> "")
      YSpacing = 72 * 2
      FinalMaxH = 720 - YSpacing
      XOffset = 0
      YOffset = 0
      FinalWH = m.top.squareImageWH
      if (m.top.squareImageWH > FinalMaxH)
        FinalWH = FinalMaxH
        XOffset = (1280 - FinalMaxH) /2
        YOffset = YSpacing / 2
      else
        XOffset = (1280 - FinalWH) /2
        YOffset =  (720 - FinalWH) / 2
      end if

      AudioThumbnailPoster.height=FinalWH
      AudioThumbnailPoster.width=FinalWH
      AudioThumbnailPoster.loadheight=FinalWH
      AudioThumbnailPoster.loadwidth=FinalWH
      AudioThumbnailPoster.translation=[XOffset,YOffset]
      AudioThumbnailPoster.scaleRotateCenter = [ FinalWH/2, FinalWH/2 ]
      AudioThumbnailPoster.loadDisplayMode="scaleToFit"
      AudioThumbnailPoster.uri = m.top.squareImageUrl
  end if
end Sub

sub OnVideoPlayerPositionChange()

    twentyFivePercentOffset = (m.top.videoPlayer.content.LENGTH * 25) \ 100
    fiftyPercentOffset = (m.top.videoPlayer.content.LENGTH * 50) \ 100
    seventyFivePercentOffset = (m.top.videoPlayer.content.LENGTH * 75) \ 100

    if int(m.top.videoPlayer.position) = twentyFivePercentOffset then
        scene = m.top.getScene()
        scene.segmentEvent = GetSegmentVideoEventInfo("25PercentPlaybackCompleted")
    else if int(m.top.videoPlayer.position) = fiftyPercentOffset then
        scene = m.top.getScene()
        scene.segmentEvent = GetSegmentVideoEventInfo("50PercentPlaybackCompleted")
    else if int(m.top.videoPlayer.position) = seventyFivePercentOffset then
        scene = m.top.getScene()
        scene.segmentEvent = GetSegmentVideoEventInfo("75PercentPlaybackCompleted")
    end if


end sub

' event handler of Video player msg
Sub OnVideoPlayerStateChange()
    live = (m.top.videoPlayer.content <> invalid and m.top.videoPlayer.content.live <> invalid and m.top.videoPlayer.content.live = true)

    print "m.top.videoPlayer.streamInfo : " m.top.videoPlayer.streamInfo
    print "m.top.videoPlayer.videoFormat : " m.top.videoPlayer.videoFormat
    print "m.top.videoPlayer.audioFormat : " m.top.videoPlayer.audioFormat
    print "m.top.videoPlayer.state : " m.top.videoPlayer.state

    if (m.top.videoPlayer.videoFormat = "none")
        SetSquareImageForAudioOnly()
        m.AudioThumbnailPoster.visible = true
        if (m.top.videoPlayer.state = "playing")
            StartScaleUpAnimation()
        else if (m.top.videoPlayer.state = "paused")
            StartScaleDownAnimation()
        end if
    else
        m.AudioThumbnailPoster.visible = false
    end if

    isSendEvent = false
    ' For Segment Analytics'
    if m.top.videoPlayer.state = "playing" or m.top.videoPlayer.state = "stopped" or m.top.videoPlayer.state = "finished" or m.top.videoPlayer.state = "paused" or m.top.videoPlayer.state = "error"
        if (m.global.enable_segment_analytics = true)
          	if (m.global.segment_source_write_key <> invalid AND m.global.segment_source_write_key <> "")
                if (m.top.videoPlayer.state = "playing" AND m.firstTimeVideo = true)
                    isSendEvent = true
                    m.firstTimeVideo = false
                    ' Start Timer for sending event periodically'
                    m.tVideoHeartBeatTimer.control = "start"
                else if (m.top.videoPlayer.state = "finished")
                    isSendEvent = true
                else if (m.top.videoPlayer.state = "paused")
                    m.lastVideoPlayerState = "paused"
                    m.lastVideoPositionWhenPaused = m.top.videoPlayer.position
                    isSendEvent = true
                else if m.top.videoPlayer.state = "playing" and m.lastVideoPlayerState = "paused"
                    isSendEvent = true
                else if m.top.videoPlayer.state = "error" OR m.top.videoPlayer.state = "stopped"
                    isSendEvent = true
                end if
          	else
          		  print "[HomeScene] ERROR : SEGMENT ANALYTICS > Missing Account ID. Please set 'segment_source_write_key' in config.json"
          	end if
        else
        	 print "[HomeScene] INFO : SEGMENT ANALYTICS IS NOT ENABLED..."
        end if
    end if

    if (isSendEvent = true)
        scene = m.top.getScene()
        scene.segmentEvent = GetSegmentVideoEventInfo(m.top.videoPlayer.state)
    end if

    ' Only close video player if error and VOD (not live stream)
    if m.top.videoPlayer.state = "error" and live = false
        ' error handling
        m.top.videoPlayer.visible = false
    else if m.top.videoPlayer.state = "playing"
        ' playback handling
        if(m.top.autoplay = true)
            m.top.triggerPlay = false
        end if
    else if m.top.videoPlayer.state = "finished" and live = false
        print "Video finished playing"
        print "Current: "; m.top.content
        print "Current Type: "; type(m.top.content)
        print "m.top.CurrentVideoIndex: "; m.top.CurrentVideoIndex

        ' Fix for autoplay, we need to update content before any further processing as internally at some place it uses that and crashes'
        if m.top.autoplay = true and m.top.itemSelectedRole <> "trailer"
           UpdateContent()
        end if

        m.top.ResumeVideo = m.top.createChild("ResumeVideo")
        m.top.ResumeVideo.id = "ResumeVideo"
        m.top.ResumeVideo.DeleteVideoIdTimer =  m.top.content.id  ' Delete video id and time from reg.

        if m.top.autoplay = true AND isLastVideoInPlaylist() = false and m.top.itemSelectedRole <> "trailer"
            m.top.videoPlayer.visible = true

            m.top.CurrentVideoIndex = m.top.CurrentVideoIndex + 1
            PrepareVideoPlayer()
        else if m.top.autoplay = true AND isLastVideoInPlaylist() = true and m.top.itemSelectedRole <> "trailer"
            m.top.videoPlayer.visible = true

            m.top.CurrentVideoIndex = 0
            PrepareVideoPlayer()
        else
            m.top.videoPlayer.control = "stop"
            m.tVideoHeartBeatTimer.control = "stop"
            m.top.videoPlayer.visible = false
            m.top.videoPlayer.setFocus(false)
            m.top.videoPlayerVisible = false
            refreshButtons()
            m.top.setFocus(true)
        end if

    ' Try playing live stream again instead of closing by default.
    ' Video player tries to close at first sign of missing manifest chunks
    else if m.top.videoPlayer.state = "finished" and live = true
        m.top.videoPlayer.control = "play"
    end if
End Sub

function GetSegmentVideoEventInfo(state as dynamic)
  if (m.top.content = invalid)
    return invalid
  end if
  if state = "playing" and m.lastVideoPlayerState = "paused" then
      currentPosition = m.top.videoPlayer.position
      if m.lastVideoPositionWhenPaused <> -1 and Abs(currentPosition - m.lastVideoPositionWhenPaused) > 5 then
          state = "SeekCompleted"
      else
          state = "resumed"
      end if
      m.lastVideoPlayerState = "None"
  end if

    eventStr = GetSegmentVideoStateEventString(state)
    app_info = CreateObject("roAppInfo")
    percent = 0
    if (m.top.videoPlayer.position <> 0 and m.top.videoPlayer.content.LENGTH <> 0) then
        percent = m.top.videoPlayer.position/m.top.videoPlayer.content.LENGTH
    end if

    episodeNumber = ""
    if (type(m.top.content.episodeNumber) = "roString" AND (m.top.content.episodeNumber = "" OR m.top.content.episodeNumber = "0"))
        episodeNumber = ""
    else if (type(m.top.content.episodeNumber) <> "roString")
        if (m.top.content.episodeNumber <> 0)
          episodeNumber = m.top.content.episodeNumber.tostr()
        end if
    else
        episodeNumber = m.top.content.episodeNumber
    end if

    seasonNumber = ""
    if (type(m.top.content.seasonNumber) = "roString" AND (m.top.content.seasonNumber = "" OR m.top.content.seasonNumber = "0"))
        seasonNumber = ""
    else if (type(m.top.content.seasonNumber) <> "roString")
        if (m.top.content.seasonNumber <> 0)
          seasonNumber = m.top.content.seasonNumber.tostr()
        end if
    else
        seasonNumber = m.top.content.seasonNumber
    end if

    created_at = "null"
    if (m.top.content.created_at <> invalid)
        if (type(m.top.content.created_at) = "roString")
            created_at = m.top.content.created_at
        end if
    end if

    published_at = "null"
    if (m.top.content.published_at <> invalid)
        if (type(m.top.content.published_at) = "roString")
            published_at = m.top.content.published_at
        end if
    end if

    updated_at = "null"
    if (m.top.content.updated_at <> invalid)
        if (type(m.top.content.updated_at) = "roString")
            updated_at = m.top.content.updated_at
        end if
    end if

    series_id = "null"
    if (m.top.content.series_id <> invalid)
        if (type(m.top.content.series_id) = "roString")
            series_id = m.top.content.series_id
        end if
    end if

    currentPosition = m.top.videoPlayer.position
    if (m.top.videoPlayer.content.on_Air = true)
        ' TODO : Check here DVR case'
        currentPosition = 0
    end if

    videoContentDuration = m.top.videoPlayer.content.LENGTH
    if (m.top.videoPlayer.content.on_Air = true)
        videoContentDuration = "null"
    end if

    videoThumbnail = "null"
    if (m.top.videoPlayer.content.HDBACKGROUNDIMAGEURL <> invalid and m.top.videoPlayer.content.HDBACKGROUNDIMAGEURL <> "") then
        videoThumbnail = m.top.videoPlayer.content.HDBACKGROUNDIMAGEURL
    else if (m.top.videoPlayer.content.HDPOSTERURL <> invalid and m.top.videoPlayer.content.HDPOSTERURL <> "") then
        videoThumbnail = m.top.videoPlayer.content.HDPOSTERURL
    end if

    videoAdDuration = "null" ' TODO
    videoAdVolume = "null" ' TODO

    properties = {
            "session_id":   m.scene.uniqueSessionID 'String (autogenerated for the user's session)
            "asset_id":     m.top.videoPlayer.content.id,
            "title":        m.top.videoPlayer.content.TITLE,
            "description":  m.top.content.DESCRIPTION, 'String (Zype video_description, if available)
            "season":       seasonNumber,
            "episode":      episodeNumber,
            "publisher":    app_info.GetTitle(), ' "String (App name)"
            "position":     currentPosition 'Integer (current playhead position)
            "total_length": m.top.videoPlayer.content.LENGTH, 'Integer (total duration of video in seconds)
            "channel":      app_info.GetTitle() ,' "String (App name)"
            "livestream":   m.top.videoPlayer.content.on_Air, 'Boolean (true if on_air = true)
            "airdate":      m.top.videoPlayer.content.RELEASEDATE,  'ISO 8601 Date String (Zype published_at date)
            ' "bitrate":      Integer (The current kbps, if available)
            ' "framerate":    Float (The average fps, if available)

            "contentCmsCategory": "null",
            "contentShownOnPlatform": "ott",
            "streaming_device": "Roku" + " " + createObject("roDeviceInfo").getModel(),
            "videoAccountId": "416418724",
            "videoAccountName": "People",

            "videoAdDuration": videoAdDuration,
            "videoAdVolume": videoAdVolume,

            "videoContentPercentComplete": percent,

            "videoCreatedAt": created_at,
            "videoPublishedAt": published_at,
            "videoUpdatedAt": updated_at,
            "videoFranchise": series_id,
            "videoId": m.top.videoPlayer.content.id,
            "videoName": m.top.videoPlayer.content.TITLE,
            "videoSyndicate": "null",
            "videoThumbnail": videoThumbnail,
            "videoContentPosition": currentPosition,
            "videoContentDuration": videoContentDuration
        }

    adType = "null" ' TODO "pre-roll" “mid-roll” or “post-roll” if known
    properties["Ad Type"] = adType

    videoTagsString = "null"
    if (m.top.content.keywords <> invalid)
        if (type(m.top.content.keywords) = "roArray" and m.top.content.keywords.Count() > 0)
            videoTagsString = ""
            videoTags = m.top.content.keywords
            videoTags.sort()
            videoTagsCount = videoTags.Count() - 1

            for i=0 to videoTagsCount
                videoTagsString += LCase(videoTags[i])
                if (i < videoTagsCount)
                    videoTagsString += " | "
                end if
            end for
        end if
    end if
    properties["videoTags"] = videoTagsString

    trackObj = {
        "action": "track",
        "event": eventStr,
        "userId": "",
    }

    trackObj.properties = properties
    print "DetailsScreen trackObj : " trackObj
    print "DetailsScreen trackObj.properties : " trackObj.properties
    print "DetailsScreen trackObj.properties.videoTags : " trackObj.properties.videoTags
    return trackObj
end function

function GetSegmentVideoStateEventString(state as dynamic) as string
    eventStr = ""
    if (state = "playing")
        eventStr = "Video Content Started"
    else if (state = "playingHeartBeat")
        eventStr = "Video Content Playing"
    else if (state = "finished")
        eventStr = "Video Content Completed"
    end if

    return eventStr
end function

Sub UpdateContent()
  if (m.top.content <> invalid)
    currentTitle = m.top.content.Title
    m.top.content.Title = ""
    m.top.content.Title = currentTitle
  end if
End Sub

Function PrepareVideoPlayer()
    print "PrepareVideoPlayer"
    nextVideoObject = m.top.videosTree[m.top.PlaylistRowIndex][m.top.CurrentVideoIndex]
    if(nextVideoObject <> invalid)
        m.top.content.subscriptionRequired = nextVideoObject.subscriptionrequired
        m.top.content.purchaseRequired = nextVideoObject.purchaseRequired
        m.top.content.rentalRequired = nextVideoObject.rentalRequired
        m.top.content.passRequired = nextVideoObject.passRequired
        m.top.content.id = nextVideoObject.id
        m.top.content.CONTENTTYPE = nextVideoObject.contenttype
        m.top.content.DESCRIPTION = nextVideoObject.description
        m.top.content.HDBACKGROUNDIMAGEURL = nextVideoObject.hdbackgroundimageurl
        m.top.content.HDPOSTERURL = nextVideoObject.hdposterurl
        m.top.content.inFavorites = nextVideoObject.infavorites
        m.top.content.LENGTH = nextVideoObject.length
        m.top.content.on_Air = nextVideoObject.on_Air
        m.top.content.RELEASEDATE = nextVideoObject.releasedate
        m.top.content.STREAMFORMAT = nextVideoObject.streamformat
        m.top.content.TITLE = nextVideoObject.title
        m.top.content.URL = nextVideoObject.url
        m.top.content.POSTERTHUMBNAIL = nextVideoObject.posterThumbnail
        m.top.content.storeProduct = nextVideoObject.storeProduct
        m.top.content.episodeNumber = nextVideoObject.episodeNumber
        m.top.content.seasonNumber = nextVideoObject.seasonNumber
        m.top.content.series_id = nextVideoObject.series_id

        m.top.content.created_at = nextVideoObject.created_at
        m.top.content.published_at = nextVideoObject.published_at
        m.top.content.updated_at = nextVideoObject.updated_at
        m.top.content.keywords = nextVideoObject.keywords
        print "nextVideoObject: "; nextVideoObject
        print "New: "; m.top.content

        if(m.top.canWatchVideo)
            m.top.videoPlayer.visible = true
        else
            m.top.videoPlayer.visible = false
            m.top.videoPlayer.setFocus(false)

            m.buttons.setFocus(true)
        end if
    end if
End Function

Function isLastVideoInPlaylist()
    if(m.top.CurrentVideoIndex = (m.top.totalVideosCount - 1))
        return true
    end if
    return false
End Function

' on Button press handler
Sub onItemSelected()
    index = m.top.itemSelected
    m.top.itemSelectedRole = currentButtonRole(index)
    m.top.itemSelectedTarget = currentButtonTarget(index)
End Sub

' Content change handler
Sub OnContentChange()
  if m.top.content <> invalid
    refreshButtons()
    m.description.content   = m.top.content
    m.description.Description.height = "250"

    print "detailScreen OnContentChange ====> m.top.content : " m.top.content
    m.top.videoPlayer.content   = m.top.content
    m.background.uri        = m.top.content.hdBackgroundImageUrl
    m.top.squareImageUrl = ""
    m.AudioThumbnailPoster.uri = m.top.content.hdBackgroundImageUrl
  end if
End Sub

function currentButtonSelected(index as integer) as string
    return m.buttons.content.getChild(index).title
end function

function currentButtonRole(index as integer) as string
    return m.buttons.content.getChild(index).role
end function

function currentButtonTarget(index as integer) as string
    return m.buttons.content.getChild(index).target
end function

Sub AddButtons() ' user has access
  m.top.ResumeVideo = m.top.createChild("ResumeVideo")
  m.top.ResumeVideo.id = "ResumeVideo"

  statusOfVideo = getStatusOfVideo()
  ' If video id entry is there in Register.
  if(statusOfVideo = true)
    if not (m.top.ResumeVideo.GetVideoIdTimerValue = "notimer")
      startDate = CreateObject("roDateTime")
      timeDiff = startDate.asSeconds() - m.top.ResumeVideo.GetVideoIdTimerValue.toInt()
    end if
  end if

  if m.top.content <> invalid
    ' create buttons
    result = []

    if(statusOfVideo = false)
      btns = [
        {title: m.global.labels.play_button, role: "play"}
      ]
    else
      btns = [
        {title: m.global.labels.watch_from_beginning_button, role: "play"},
        {title: m.global.labels.resume_button, role: "resume"}
      ]
    end if

    if m.top.content.inFavorites = true
      btns.push({title: m.global.labels.unfavorite_button, role: "favorite"})
    else
      btns.push({title: m.global.labels.favorite_button, role: "favorite"})
    end if

    if m.global.in_app_purchase or m.global.device_linking then svod_enabled = true else svod_enabled = false
    if m.global.auth.nativeSubCount > 0 or m.global.auth.universalSubCount > 0 then is_subscribed = true else is_subscribed = false

    if m.global.swaf and svod_enabled and is_subscribed = false
      btns.push({title: m.global.labels.swaf_button, role: "swaf"})
    end if
    addWatchTrailerButton(btns)
    m.btns = btns
    m.buttons.content = m.content_helpers.oneDimList2ContentNode(btns, "ButtonNode")
  end if
End Sub

Sub addWatchTrailerButton(btns)
  if m.top.content.trailers <> invalid and m.top.content.trailers.count() > 0
    for each trailer in m.top.content.trailers
      btns.push({title: m.global.labels.watch_trailer_button, role: "trailer", target: trailer})
    end for
  end if
End Sub

Sub AddActionButtons() ' trigger monetization
    if m.top.content <> invalid then
      btns = []

      if m.top.content.subscriptionrequired

        ' HB : MarketPlaceConnect With RegistrationScreen / SignUpScreen'
        if (not m.global.auth.isLoggedIn AND m.global.marketplace_connect_svod = true) then
            btns.push({ title: m.global.labels.subscribe_button, role: "transition", target: "RegistrationScreen" })
            'btns.push({ title: m.global.labels.subscribe_button, role: "transition", target: "SignUpScreen" })
        else
        	btns.push({ title: m.global.labels.subscribe_button, role: "transition", target: "AuthSelection" })
      	end if
      end if

      '?"m.top.rowTVODInitiateContent==>"m.top.rowTVODInitiateContent
      if m.top.content.purchaseRequired and m.global.native_tvod and (m.top.rowTVODInitiateContent <> invalid AND m.top.rowTVODInitiateContent.description="")
        if m.top.content.storeProduct <> invalid and m.top.content.storeProduct.cost <> invalid
          purchaseButtonText = "Purchase video - " + m.top.content.storeProduct.cost
        else
          purchaseButtonText = "Purchase video"
        end if

        btns.push({ title: purchaseButtonText, role: "transition", target: "PurchaseScreen" })
      else if m.global.native_tvod and (m.top.rowTVODInitiateContent <> invalid AND m.top.rowTVODInitiateContent.description<>"")
        purchaseButtonText = "Buy All "+m.top.rowTVODInitiateContent.NUMEPISODES.toStr()+" Videos - $"+m.top.rowTVODInitiateContent.description
        btns.push({ title: purchaseButtonText, role: "transition", target: "PurchaseScreen" })
      end if

      addWatchTrailerButton(btns)

      if m.top.content.inFavorites = true
        btns.push({title: m.global.labels.unfavorite_button, role: "favorite"})
      else
        btns.push({title: m.global.labels.favorite_button, role: "favorite"})
      end if

      m.buttons.content = m.content_helpers.oneDimList2ContentNode(btns, "ButtonNode")
    end if
End Sub

Sub AddTVODActionButtons()
  if m.top.content <> invalid then
      btns = []
      desc = ""
      if (m.top.rowTVODInitiateContent <> invalid AND m.top.rowTVODInitiateContent.description<>"")
          desc = m.top.rowTVODInitiateContent.description
      end if
      purchaseButtonText = "Buy All "+m.top.rowTVODInitiateContent.NUMEPISODES.toStr()+" Videos - $" + desc

      if m.top.content.inFavorites = true
        btns.push({title: m.global.labels.unfavorite_button, role: "favorite"})
      else
        btns.push({title: m.global.labels.favorite_button, role: "favorite"})
      end if

      btns.push({ title: purchaseButtonText, role: "transition", target: "PurchaseScreen" })
      addWatchTrailerButton(btns)
      m.buttons.content = m.content_helpers.oneDimList2ContentNode(btns, "ButtonNode")
  end if

ENd SUb

sub AddSigninButton() ' sign in only
    if m.top.content <> invalid
      btns = [ { title: m.global.labels.sign_in_button, role: "transition", target: "UniversalAuthSelection" } ]
      addWatchTrailerButton(btns)
      m.buttons.content = m.content_helpers.oneDimList2ContentNode(btns, "ButtonNode")
    end if
end sub


sub AddSignupButton() ' sign in only
  if m.top.content <> invalid
    btns = [ { title: m.global.labels.sign_up_to_watch_submit_button, role: "transition", target: "RegistrationScreen" } ]
    addWatchTrailerButton(btns)
    m.buttons.content = m.content_helpers.oneDimList2ContentNode(btns, "ButtonNode")
  end if
end sub


Function getStatusOfVideo() as boolean
    m.top.ResumeVideo = m.top.createChild("ResumeVideo")
    m.top.ResumeVideo.id = "ResumeVideo"
    m.top.ResumeVideo.HasVideoId = m.top.content.id         ' If video id entry is there in reg
    m.top.ResumeVideo.GetVideoIdTimer = m.top.content.id    ' Get when video was saved in reg.

    if(m.top.ResumeVideo.HasVideoIdValue)
        return true
    else
        m.top.videoPlayer.seek = 0.00                           ' Start video from 0 if entry not saved.
        return false
    end if

    return false
End Function
