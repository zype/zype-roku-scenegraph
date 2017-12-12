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

' set proper focus to Buttons in case if return from Video PLayer
Sub OnFocusedChildChange()
    if m.top.isInFocusChain() and not m.buttons.hasFocus() and not m.top.videoPlayer.hasFocus() then
      ' Just in case overlay loses visibility when returning from video player. Cause of bug unknown
      m.overlay.uri = m.global.theme.overlay_uri
      m.overlay.visible = true

      handleButtonLogic()

      m.buttons.setFocus(true)
    end if
End Sub

' set proper focus on buttons and stops video if return from Playback to details
Sub onVideoVisibleChange()
    if m.top.videoPlayer.visible = false and m.top.visible = true
        handleButtonLogic()
        m.top.videoPlayer.control = "stop"
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

        if m.top.autoplay = true AND isLastVideoInPlaylist() = false
            m.top.videoPlayer.visible = true

            m.top.CurrentVideoIndex = m.top.CurrentVideoIndex + 1
            PrepareVideoPlayer()
        else if m.top.autoplay = true AND isLastVideoInPlaylist() = true
            m.top.videoPlayer.visible = true

            m.top.CurrentVideoIndex = 0
            PrepareVideoPlayer()
        else
            m.top.videoPlayer.control = "stop"
            m.top.videoPlayer.visible = false
            m.top.videoPlayer.setFocus(false)
            m.top.videoPlayerVisible = false
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

        for each key in nextVideoObject.keys()
            m.top.content[key] = nextVideoObject[key]
        end for

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
    if m.top.content<>invalid then
        handleButtonLogic()

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

Sub AddButtons()
    m.top.ResumeVideo = m.top.createChild("ResumeVideo")
    m.top.ResumeVideo.id = "ResumeVideo"

    statusOfVideo = getStatusOfVideo()
    ' If video id entry is there in Register.
    if(statusOfVideo = true)
        if(m.top.ResumeVideo.GetVideoIdTimerValue = "notimer")
        else
            startDate = CreateObject("roDateTime")
            timeDiff = startDate.asSeconds() - m.top.ResumeVideo.GetVideoIdTimerValue.toInt()
        end if
    end if

    if m.top.content <> invalid then
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

        m.btns = btns

        m.buttons.content = m.content_helpers.oneDimList2ContentNode(btns, "ButtonNode")
    end if
End Sub

Sub AddActionButtons()
    if m.top.content <> invalid then
        btns = [ { title: m.global.labels.subscribe_button, role: "transition", target: "AuthSelection" } ]
        m.buttons.content = m.content_helpers.oneDimList2ContentNode(btns, "ButtonNode")
    end if
End Sub

sub AddSigninButton()
    if m.top.content <> invalid
      btns = [ { title: m.global.labels.sign_in_button, role: "transition", target: "UniversalAuthSelection" } ]
      m.buttons.content = m.content_helpers.oneDimList2ContentNode(btns, "ButtonNode")
    end if
end sub

function handleButtonLogic() as void
    sign_in_enabled = m.global.device_linking
    svod_enabled = (m.global.in_app_purchase or m.global.device_linking)

    user_is_subscribed = (m.global.auth.nativeSubCount > 0 or m.global.auth.universalSubCount > 0)
    is_logged_in = (m.global.auth.isLoggedIn <> invalid and m.global.auth.isLoggedIn <> false)

    videoHasMonetization = (m.top.content.subscriptionRequired or m.top.content.purchaseRequired or m.top.content.rentalRequired or m.top.content.passRequired)

    if m.top.content.subscriptionRequired
        if user_is_subscribed
            m.top.canWatchVideo = true
            AddButtons()  ' show Play/Favorite
        else
            m.top.canWatchVideo = false

            ' Show Subscribe
            '   - normal behavior: transition to AuthSelection (has native plans and sign in)
            '   - plans are empty if no native subscriptions exist (if testing sideloaded app, remember to turn on store and/or update items in csfake folder)
            '   - sign in enabled when device linking is turned on in Zype platform
            AddActionButtons()
        end if

    else if sign_in_enabled and videoHasMonetization
        if is_logged_in
            m.top.canWatchVideo = true
            AddButtons()  ' show Play/Favorite.
        else
            m.top.canWatchVideo = false

             ' Show Sign In
             '    - Normal behavior transition to UniversalAuthSelection (choose between device linking and sign in)
             '    - Can skip authentication select and go straight to Sign In by setting "enable_device_linking" in source/configs.json to false
            AddSigninButton()
        end if
    else
        m.top.canWatchVideo = true
        AddButtons()  ' show Play/Favorite.
    end if
end function

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
