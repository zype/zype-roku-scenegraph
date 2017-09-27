' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********
 ' inits details Screen
 ' sets all observers
 ' configures buttons for Details screen
Function Init()
    ? "[DetailsScreen] init"

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

Function onShowSubscriptionPackagesCallback()
    print "onShowSubscriptionPackagesCallback"
    if(m.top.ShowSubscriptionPackagesCallback = true)
        print "onShowSubscriptionPackagesCallback: true"
        AddPackagesButtons()
    end if
End Function

' set proper focus to buttons if Details opened and stops Video if Details closed
Sub onVisibleChange()
    ? "[DetailsScreen] onVisibleChange"
    if m.top.visible = true then
        m.buttons.jumpToItem = 0
        m.buttons.setFocus(true)
    else
        m.top.videoPlayer.visible = false
        m.top.videoPlayer.control = "stop"
    end if
End Sub

' set proper focus to Buttons in case if return from Video PLayer
Sub OnFocusedChildChange()
    if m.top.isInFocusChain() and not m.buttons.hasFocus() and not m.top.videoPlayer.hasFocus() then
      ' Just in case overlay looses visibility when returning from video player. Cause of bug unknown
      m.overlay.uri = m.global.theme.overlay_uri
      m.overlay.visible = true

      if m.top.canWatchVideo <> invalid and m.top.canWatchVideo = true
        AddButtons()
        m.buttons.setFocus(true)
      else
        AddActionButtons()
        m.buttons.setFocus(true)
      end if
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
    live = (m.top.videoPlayer.content.live <> invalid and m.top.videoPlayer.content.live = true)

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
            m.top.videoPlayer.visible = false
            m.top.videoPlayer.setFocus(false)
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

    if m.top.itemSelectedRole = "subscribe"
      AddPackagesButtons()
    end if
End Sub

' Content change handler
Sub OnContentChange()
    m.top.SubscriptionPackagesShown = false

    if m.top.content<>invalid then
        ' idParts = m.top.content.id.tokenize(":")

        if(m.top.content.subscriptionRequired = false OR m.global.auth.isLoggedIn = true OR m.top.NoAuthenticationEnabled = true)
            m.top.canWatchVideo = true
        else
            m.top.canWatchVideo = false
        end if

        ' If all else is good and device is linked but there's no subscription found on the server then show native subscription buttons.
        if(m.top.isDeviceLinked = true AND m.global.usvod.UniversalSubscriptionsCount = 0 AND m.top.content.subscriptionRequired = true AND m.top.BothActive = true AND m.top.JustBoughtNativeSubscription = false AND m.global.nsvod.isLoggedInViaNativeSVOD = false)
            m.top.canWatchVideo = false
        end if

        if(m.top.canWatchVideo)
            AddButtons()
            m.top.SubscriptionButtonsShown = false
        else
            AddActionButtons()
            m.top.SubscriptionButtonsShown = true
        end if

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
              {title: "Play", role: "play"}
            ]
        else
            btns = [
              {title: "Play from beginning", role: "play"},
              {title: "Resume playing", role: "resume"}
            ]
        end if

        if(m.top.BothActive AND m.top.isDeviceLinked)
            if m.top.content.inFavorites = true
                btns.push({title: "Unfavorite", role: "favorite"})
            else
                btns.push({title: "Favorite", role: "favorite"})
            end if
        end if

        if m.global.swaf and m.global.svod_enabled and m.global.is_subscribed = false
          btns.push({title: "Watch Ad Free", role: "swaf"})
        end if

        m.btns = btns

        m.buttons.content = ContentList2SimpleNode(btns, "ButtonNode")
    end if
End Sub

function ShowSubscribeButtons() as void
  if m.top.ShowSubscribeButtons = true
    AddActionButtons()
    m.buttons.setFocus(true)
  end if
end function

Sub AddActionButtons()
    if m.top.content <> invalid then
        ' create buttons
        result = []
        btns = [
          {title: "Subscribe", role: "subscribe"}
        ]
        if(m.top.BothActive AND m.top.isDeviceLinked = false)
            btns.push({ title: "Link Device", role: "device_linking" })
        end if

        m.buttons.content = ContentList2SimpleNode(btns, "ButtonNode")
    end if
End Sub

Sub AddPackagesButtons()
    if m.top.content <> invalid then
        ' create buttons
        btns = []
        'for each plan in m.top.SubscriptionPlans
        for each plan in m.top.ProductsCatalog
           btns.push({
            title: plan["title"] + " at " + plan["cost"],
            role: "native_sub"
          })
        end for

        m.buttons.content = ContentList2SimpleNode(btns, "ButtonNode")
    end if
End Sub

'///////////////////////////////////////////'
' Helper function convert AA to Node
Function ContentList2SimpleNode(contentList as Object, nodeType = "ContentNode" as String) as Object
    result = createObject("roSGNode","ContentNode")
    if result <> invalid
        for each itemAA in contentList
            item = createObject("roSGNode", nodeType)
            item.setFields(itemAA)
            result.appendChild(item)
        end for
    end if
    return result
End Function

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
