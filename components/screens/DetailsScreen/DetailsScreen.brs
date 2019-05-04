' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********
 ' inits details Screen
 ' sets all observers
 ' configures buttons for Details screen
Function Init()
    ? "[DetailsScreen] init"

    m.content_helpers = ContentHelpers()

    m.top.observeField("visible", "onVisibleChange")
    m.top.observeField("focusedChild", "OnFocusedChildChange")
    m.top.DontShowSubscriptionPackages = true
    m.top.ShowSubscriptionPackagesCallback = false

    m.buttons           =   m.top.findNode("Buttons")

    m.top.videoPlayer = m.top.createChild("Video")
    m.top.videoPlayer.visible = false
    m.top.videoPlayer.translation = [0,0]
    m.top.videoPlayer.width = 1280
    m.top.videoPlayer.height = 720
    m.top.videoPlayer.observeField("state", "OnVideoPlayerStateChange")

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
End Function

Function ReinitializeVideoPlayer()
  if m.top.RemakeVideoPlayer = true
      m.top.removeChild(m.top.videoPlayer)

      m.top.videoPlayer = m.top.createChild("Video")
      m.top.videoPlayer.translation = [0,0]
      m.top.videoPlayer.width = 1280
      m.top.videoPlayer.height = 720

    ' Event listener for video player state. Needed to handle video player errors and completion
      m.top.videoPlayer.observeField("state", "OnVideoPlayerStateChange")
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
    end if
End Sub

' gets buttons based on video monetization and consumer state
sub refreshButtons() as void
  isSubscribed = (m.global.auth.nativeSubCount > 0 or m.global.auth.universalSubCount > 0)
  svodEnabled = ((m.global.in_app_purchase or m.global.device_linking) and m.top.content.subscriptionRequired)

  userIsLoggedIn = (m.global.auth.isLoggedIn <> invalid and m.global.auth.isLoggedIn <> false)

  videoRequiresEntitlement = (m.top.content.subscriptionRequired or m.top.content.purchaseRequired or m.top.content.rentalRequired)
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
      else
        AddActionButtons()
        m.buttons.setFocus(true)
        m.top.videoPlayer.control = "stop"
      end if
    end if
End Sub

' event handler of Video player msg
Sub OnVideoPlayerStateChange()
    live = (m.top.videoPlayer.content <> invalid and m.top.videoPlayer.content.live <> invalid and m.top.videoPlayer.content.live = true)

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
        m.top.content.onAir = nextVideoObject.onair
        m.top.content.RELEASEDATE = nextVideoObject.releasedate
        m.top.content.STREAMFORMAT = nextVideoObject.streamformat
        m.top.content.TITLE = nextVideoObject.title
        m.top.content.URL = nextVideoObject.url
        m.top.content.POSTERTHUMBNAIL = nextVideoObject.posterThumbnail
        m.top.content.storeProduct = nextVideoObject.storeProduct

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
    m.top.videoPlayer.content   = m.top.content
    m.background.uri        = m.top.content.hdBackgroundImageUrl
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

    if m.global.favorites_via_api = false or (m.global.device_linking and m.global.auth.isLoggedIn)
      if m.top.content.inFavorites = true
        btns.push({title: m.global.labels.unfavorite_button, role: "favorite"})
      else
        btns.push({title: m.global.labels.favorite_button, role: "favorite"})
      end if
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
        userIsLoggedIn = (m.global.auth.isLoggedIn <> invalid and m.global.auth.isLoggedIn <> false)
        if userIsLoggedIn
          btns.push({ title: m.global.labels.subscribe_button, role: "transition", target: "SubscriptionScreen" })
        else
          btns.push({ title: m.global.labels.subscribe_button, role: "transition", target: "RegistrationAndSubscribeScreen" })
        end if
      end if

      if m.top.content.purchaseRequired and m.global.native_tvod
        if m.top.content.storeProduct <> invalid and m.top.content.storeProduct.cost <> invalid
          purchaseButtonText = "Purchase video - " + m.top.content.storeProduct.cost
        else
          purchaseButtonText = "Purchase video"
        end if

        btns.push({ title: purchaseButtonText, role: "transition", target: "PurchaseScreen" })
      end if
      addWatchTrailerButton(btns)
      m.buttons.content = m.content_helpers.oneDimList2ContentNode(btns, "ButtonNode")
    end if
End Sub

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
