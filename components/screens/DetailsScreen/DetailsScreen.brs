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

    ' m.poster            =   m.top.findNode("Poster")
    m.description       =   m.top.findNode("Description")
    m.background        =   m.top.findNode("Background")
    ' m.top.PlaylistRowIndex  = invalid
    ' m.top.CurrentVideoIndex = invalid
    ' m.totalVideosCount  = 0

    m.canWatchVideo = false
    m.buttons.setFocus(true)
    'm.plans = GetPlans({})

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
    'print "[DetailsScreen] m.top.SubscriptionButtonsShown; "; m.top.SubscriptionButtonsShown
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
      if m.canWatchVideo <> invalid and m.canWatchVideo = true
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
      if m.canWatchVideo <> invalid AND m.canWatchVideo = true
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
    if m.top.videoPlayer.state = "error"
        ' error handling
        m.top.videoPlayer.visible = false
    else if m.top.videoPlayer.state = "playing"
        ' playback handling
        if(m.top.autoplay = true)
            m.top.triggerPlay = false
        end if
    else if m.top.videoPlayer.state = "finished"
        print "Video finished playing"
        print "Current: "; m.top.content
        print "Current Type: "; type(m.top.content)
        print "m.top.CurrentVideoIndex: "; m.top.CurrentVideoIndex

        m.top.ResumeVideo = m.top.createChild("ResumeVideo")
        m.top.ResumeVideo.id = "ResumeVideo"
        m.top.ResumeVideo.DeleteVideoIdTimer =  m.top.content.id  ' Delete video id and time from reg.
        m.top.ResumeVideo.DeleteVideoIdTimer =  m.top.content.id.tokenize(":")[0]  ' Delete video id and time from reg.

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

        print "nextVideoObject: "; nextVideoObject
        print "New: "; m.top.content

        if(m.canWatchVideo)
            m.top.videoPlayer.visible = true
            m.top.triggerPlay = true
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
' <<<<<<< HEAD
' =======
'     m.top.videoPlayer.observeField("state", "OnVideoPlayerStateChange")
' >>>>>>> autoplay-refactor-v2
    ' first button pressed
    if m.top.itemSelected = 0
        if(m.top.SubscriptionPackagesShown = true)  ' If packages are shown and one of them was clicked, start wizard.
            ' Subscription Wizard
            print "Subscription Wizard"
        else
            if(m.top.SubscriptionButtonsShown = false)
                print "====== Play Button was clicked"
            else
                print "====== Subscription button clicked"
                if(m.top.DontShowSubscriptionPackages = false)
                    AddPackagesButtons()
                end if
                'm.top.SubscriptionPackagesShown = true
                'print "Subscription Plans++: "; m.top.SubscriptionPlans[0]
            end if
        end if

    ' second button pressed
   else if m.top.itemSelected = 1          'favorite btn

        print "m.btns[1] ->";Resume playing

        if(m.btns <> invalid and m.btns[m.top.itemSelected].role = "resume")
            ? "[DetailsScreen] Resume button selected"
            m.top.itemSelected = 2          ' resume btn
        else
            ? "[DetailsScreen] Favorite button selected"
        end if
    else if m.top.itemSelected = 2          ' favorite btn
            m.top.itemSelected = 1
            ? "[DetailsScreen] Favorite button selected"
    end if
    print "[DetailsScreen] m.top.SubscriptionButtonsShown; "; m.top.SubscriptionButtonsShown
End Sub

' Content change handler
Sub OnContentChange()
    ' print "Content: "; m.top.content
    m.top.SubscriptionPackagesShown = false
    ' print "Videos: "; m.top.videosTree[0][6]
    ' FindPlaylistRowIndex()

    if m.top.content<>invalid then
        idParts = m.top.content.id.tokenize(":")

        print "+++++++++++++++++++++++++++++++++++++++++"
        print "m.top.content.subscriptionRequired: "; m.top.content.subscriptionRequired
        print "m.top.isLoggedIn: "; m.top.isLoggedIn
        print "m.top.isLoggedInViaNativeSVOD: "; m.top.isLoggedInViaNativeSVOD
        print "m.top.NoAuthenticationEnabled: "; m.top.NoAuthenticationEnabled
        print "m.top.JustBoughtNativeSubscription: "; m.top.JustBoughtNativeSubscription
        print "+++++++++++++++++++++++++++++++++++++++++"
        'if(m.top.content.subscriptionRequired = false OR (idParts[1] = "True" AND m.top.isLoggedIn))
        if(m.top.content.subscriptionRequired = false OR m.top.isLoggedIn = true OR m.top.NoAuthenticationEnabled = true)
            m.canWatchVideo = true
        else
            m.canWatchVideo = false
        end if

        ' If all else is good and device is linked but there's no subscription found on the server then show native subscription buttons.
        if(m.top.isDeviceLinked = true AND m.top.UniversalSubscriptionsCount = 0 AND m.top.content.subscriptionRequired = true AND m.top.BothActive = true AND m.top.JustBoughtNativeSubscription = false AND m.top.isLoggedInViaNativeSVOD = false)
            m.canWatchVideo = false
        end if
        print "m.canWatchVideo";m.canWatchVideo
        if(m.canWatchVideo)
            AddButtons()
            m.top.SubscriptionButtonsShown = false
        else
            AddActionButtons()
            m.top.SubscriptionButtonsShown = true
        end if

        m.description.content   = m.top.content
        ' m.description.Description.width = "770"
        m.description.Description.height = "250"
        m.top.videoPlayer.content   = m.top.content
        ' m.poster.uri            = m.top.content.hdBackgroundImageUrl
        m.background.uri        = m.top.content.hdBackgroundImageUrl
    end if
End Sub

function currentButtonSelected(index as integer) as string
    return m.buttons.content.getChild(index - 1).TITLE
end function

Sub AddButtons()
    m.top.ResumeVideo = m.top.createChild("ResumeVideo")
    m.top.ResumeVideo.id = "ResumeVideo"

    statusOfVideo = getStatusOfVideo()
    ' If video id entry is there in Register.
    if(statusOfVideo = true)
        if(m.top.ResumeVideo.GetVideoIdTimerValue = "notimer")
        else
          '  print "m.top.ResumeVideo.GetVideoIdTimerValue ->";m.top.ResumeVideo.GetVideoIdTimerValue.toInt()
            startDate = CreateObject("roDateTime")
            timeDiff = startDate.asSeconds() - m.top.ResumeVideo.GetVideoIdTimerValue.toInt()
          '  print "m.top.ResumeVideo.GetVideoIdTimerValue.ToInt()";m.top.ResumeVideo.GetVideoIdTimerValue.ToInt()
          '  print "startDate.asSeconds()";startDate.asSeconds()
          '  print "timeDiff";timeDiff
          'Check if time has exceeded 1 hour
            ' if(timeDiff 3600)
            '    m.top.ResumeVideo.DeleteVideoIdTimer =  m.top.content.id
            ' end if
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

        if m.global.svod_enabled and m.global.is_subscribed = false
          btns.push({title: "Watch ad free", role: "swaf"})
        end if

        m.btns = btns
        ' for each button in btns
        '     result.push({title : button})
        ' end for
        m.buttons.content = ContentList2SimpleNode(btns)
    end if
End Sub

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


        ' for each button in btns
        '     result.push({title : button})
        ' end for
        m.buttons.content = ContentList2SimpleNode(btns)
    end if
End Sub

Sub AddPackagesButtons()
    if m.top.content <> invalid then
        ' create buttons
        result = []
        btns = []
        'for each plan in m.top.SubscriptionPlans
        for each plan in m.top.ProductsCatalog
           'btns.push(plan["name"] + " at " + plan["amount"] + " " + plan["currency"])
           btns.push(plan["title"] + " at " + plan["cost"])
        end for

        for each button in btns
            result.push({title : button})
        end for
        m.buttons.content = ContentList2SimpleNode(result)
    end if
End Sub

'///////////////////////////////////////////'
' Helper function convert AA to Node
Function ContentList2SimpleNode(contentList as Object, nodeType = "ContentNode" as String) as Object
    result = createObject("roSGNode",nodeType)
    if result <> invalid
        for each itemAA in contentList
            print "itemAA_: "; itemAA
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
    print "m.top.content.id";m.top.content.id
    print "m.top.ResumeVideo.HasVideoIdValue ->";m.top.ResumeVideo.HasVideoIdValue
    if(m.top.ResumeVideo.HasVideoIdValue)
        return true
    else
        m.top.videoPlayer.seek = 0.00                           ' Start video from 0 if entry not saved.
        return false
    end if

    return false
End Function

Function FindPlaylistRowIndex()
    print "FindPlaylistRowIndex"
    contentId = invalid
    if(m.top.content <> invalid)
        contentIdParts = m.top.content.id.tokenize(":")
        contentId = contentIdParts[0]
    end if
    index = 0
    found = false
    totalVideos = 0
    childCount = 0
    For Each vt in m.top.videosTree
        ' print "vt: "; vt
        childCount = 0
        For Each v in vt
            ' print "v: "; v
            if(v.id = contentId)
                m.top.PlaylistRowIndex = index
                m.CurrentVideoIndex = v.videoIndex
                found = true
            end if
            childCount = childCount + 1
        End For

        if(found = true)
            totalVideos = childCount
            exit for
        end if
        index = index + 1
    End For

    m.totalVideosCount = totalVideos

    ' For each p in m.top.dataArray
    '     print "P: "; p.contentlist[0]
    ' End for
End Function
