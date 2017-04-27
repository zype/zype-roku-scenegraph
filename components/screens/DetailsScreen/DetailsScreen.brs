' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********
 ' inits details Screen
 ' sets all observers
 ' configures buttons for Details screen
Function Init()
    ? "[DetailsScreen] init"
    'TestStoreFunction(2)

    m.top.observeField("visible", "onVisibleChange")
    m.top.observeField("focusedChild", "OnFocusedChildChange")
    m.top.DontShowSubscriptionPackages = true
    m.top.ShowSubscriptionPackagesCallback = false

    m.buttons           =   m.top.findNode("Buttons")
    m.videoPlayer       =   m.top.findNode("VideoPlayer")
    ' m.poster            =   m.top.findNode("Poster")
    m.description       =   m.top.findNode("Description")
    m.background        =   m.top.findNode("Background")
    m.PlaylistRowIndex  = invalid
    m.CurrentVideoIndex = invalid
    m.totalVideosCount  = 0

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
        m.videoPlayer.visible = false
        m.videoPlayer.control = "stop"
    end if
End Sub

' set proper focus to Buttons in case if return from Video PLayer
Sub OnFocusedChildChange()
    if m.top.isInFocusChain() and not m.buttons.hasFocus() and not m.videoPlayer.hasFocus() then
        m.buttons.setFocus(true)
    end if
End Sub

' set proper focus on buttons and stops video if return from Playback to details
Sub onVideoVisibleChange()
    if m.videoPlayer.visible = false and m.top.visible = true
        m.buttons.setFocus(true)
        m.videoPlayer.control = "stop"
        AddButtons()
    end if
End Sub

' event handler of Video player msg
Sub OnVideoPlayerStateChange()
    print "OnVideoPlayerStateChange: "; m.videoPlayer.state
    if m.videoPlayer.state = "error"
        ' error handling
        m.videoPlayer.visible = false
    else if m.videoPlayer.state = "playing"
        ' playback handling
        if(m.top.autoplay = true)
            m.top.triggerPlay = false
        end if
    else if m.videoPlayer.state = "finished"
        print "Video finished playing"
        print "Current: "; m.top.content
        print "Current Type: "; type(m.top.content)
        print "m.CurrentVideoIndex: "; m.CurrentVideoIndex

        m.videoPlayer.visible = false
        m.top.ResumeVideo = m.top.createChild("ResumeVideo")
        m.top.ResumeVideo.id = "ResumeVideo"
        m.top.ResumeVideo.DeleteVideoIdTimer =  m.top.content.id  ' Delete video id and time from reg.
        m.top.ResumeVideo.DeleteVideoIdTimer =  m.top.content.id.tokenize(":")[0]  ' Delete video id and time from reg.
        AddButtons()                                              ' Change buttons status

        if m.top.autoplay = true AND isLastVideoInPlaylist() = false
            m.CurrentVideoIndex = m.CurrentVideoIndex + 1
            PrepareVideoPlayer()
        else if isLastVideoInPlaylist() = true
            m.CurrentVideoIndex = 0
            PrepareVideoPlayer()
        end if

    end if
End Sub

Function PrepareVideoPlayer()
    print "PrepareVideoPlayer"
    nextVideoObject = m.top.videosTree[m.PlaylistRowIndex][m.CurrentVideoIndex]
    ' nextVideoNode = ContentList2SimpleNode(nextVideoObject)
    if(nextVideoObject <> invalid)
        ' result = createObject("RoSGNode","ContentNode")
        ' nextVideoNode = result.createChild("ContentNode")

        print "================"
        print "Change Start"
        print "================"

        print "subscriptionRequired Before: ";m.top.content.subscriptionRequired; " == After: ";nextVideoObject.subscriptionrequired  
        m.top.content.subscriptionRequired = nextVideoObject.subscriptionrequired
        print "subscriptionRequired ended"

        print "id Before: ";m.top.content.id; " == After: ";nextVideoObject.id
        m.top.content.id = nextVideoObject.id
        print "id ended"

        print "CONTENTTYPE Before: ";m.top.content.CONTENTTYPE; " == After: ";nextVideoObject.contenttype
        m.top.content.CONTENTTYPE = nextVideoObject.contenttype
        print "CONTENTTYPE ended"

        print "DESCRIPTION Before: ";m.top.content.DESCRIPTION; " == After: ";nextVideoObject.description
        m.top.content.DESCRIPTION = nextVideoObject.description
        print "DESCRIPTION ended"

        print "HDBACKGROUNDIMAGEURL Before: ";m.top.content.HDBACKGROUNDIMAGEURL; " == After: ";nextVideoObject.hdbackgroundimageurl
        m.top.content.HDBACKGROUNDIMAGEURL = nextVideoObject.hdbackgroundimageurl
        print "HDBACKGROUNDIMAGEURL ended"

        print "HDPOSTERURL Before: ";m.top.content.HDPOSTERURL; " == After: ";nextVideoObject.hdposterurl
        m.top.content.HDPOSTERURL = nextVideoObject.hdposterurl
        print "HDPOSTERURL ended"

        print "inFavorites Before: ";m.top.content.inFavorites; " == After: ";nextVideoObject.inFavorites
        m.top.content.inFavorites = nextVideoObject.infavorites
        print "inFavorites ended"

        print "LENGTH Before: ";m.top.content.LENGTH; " == After: ";nextVideoObject.length
        m.top.content.LENGTH = nextVideoObject.length
        print "LENGTH ended"

        print "onAir Before: ";m.top.content.onAir; " == After: ";nextVideoObject.onair
        m.top.content.onAir = nextVideoObject.onair
        print "onAir ended"

        print "RELEASEDATE Before: ";m.top.content.RELEASEDATE; " == After: ";nextVideoObject.releasedate
        m.top.content.RELEASEDATE = nextVideoObject.releasedate
        print "RELEASEDATE ended"

        print "STREAMFORMAT Before: ";m.top.content.STREAMFORMAT; " == After: ";nextVideoObject.streamformat
        m.top.content.STREAMFORMAT = nextVideoObject.streamformat
        print "STREAMFORMAT ended"

        print "TITLE Before: ";m.top.content.TITLE; " == After: ";nextVideoObject.title
        m.top.content.TITLE = nextVideoObject.title
        print "TITLE ended"

        print "URL Before: ";m.top.content.URL; " == After: ";nextVideoObject.url
        m.top.content.URL = nextVideoObject.url
        print "URL ended"

        print "================"
        print "Change End"
        print "================"

        ' m.top.content.TestingVar = "hello"
        ' m.top.content.setFields({TestingVar1: "hello"})
        ' result.appendChild(nextVideoNode)

        ' print "Test Start"
        ' print "nextVideoNode: "; nextVideoNode
        ' print "result: "; result
        ' print "Test: "; {TestingVar: "hello"}
        ' print "Test End"

        ' for each itemAA in nextVideoObject
        '     print "itemAA: "; itemAA
        ' end for

        ' m.top.content = nextVideoNode
        ' m.top.content.onAir = nextVideoObject.onair
        ' m.top.content.STREAMFORMAT = "abc"
        ' m.top.content.subscriptionRequired = nextVideoObject.subscriptionrequired

        ' print "nextVideoObject: "; nextVideoObject
        ' print "nextVideoNode: "; nextVideoNode
        ' print "New: "; m.top.content
        ' print "m.canWatchVideo: "; m.canWatchVideo
        ' print "nextVideoNode Type: "; type(nextVideoNode)
        ' print "nextVideoObject.streamformat: "; nextVideoObject.streamformat

        if(m.canWatchVideo)
            m.top.triggerPlay = true
            m.videoPlayer.state = "play"
        end if

    end if
End Function

Function isLastVideoInPlaylist()
    if(m.CurrentVideoIndex = (m.totalVideosCount - 1))
        return true
    end if
    return false
End Function

' on Button press handler
Sub onItemSelected()
    m.videoPlayer.observeField("state", "OnVideoPlayerStateChange")
    ' first button pressed
    if m.top.itemSelected = 0
        if(m.top.SubscriptionPackagesShown = true)  ' If packages are shown and one of them was clicked, start wizard.
            ' Subscription Wizard
            ' print "Subscription Wizard"
        else
            if(m.top.SubscriptionButtonsShown = false)
                ' print "====== Play Button was clicked"
            else
                ' print "====== Subscription button clicked"
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

        if(m.btns <> invalid and m.btns[m.top.itemSelected] = "Resume playing")
            ' ? "[DetailsScreen] Resume button selected"
            m.top.itemSelected = 2          ' resume btn
        else
            ' ? "[DetailsScreen] Favorite button selected"
        end if
    else if m.top.itemSelected = 2          ' favorite btn
            m.top.itemSelected = 1
            ' ? "[DetailsScreen] Favorite button selected"
    end if
    ' print "[DetailsScreen] m.top.SubscriptionButtonsShown; "; m.top.SubscriptionButtonsShown
End Sub

' Content change handler
Sub OnContentChange()
    print "OnContentChange" 
    ' print "Content: "; m.top.content
    m.top.SubscriptionPackagesShown = false
    ' print "Videos: "; m.top.videosTree[0][6]
    FindPlaylistRowIndex()

    if m.top.content<>invalid then
        idParts = m.top.content.id.tokenize(":")

        ' print "+++++++++++++++++++++++++++++++++++++++++"
        ' print "m.top.content.subscriptionRequired: "; m.top.content.subscriptionRequired
        ' print "m.top.isLoggedIn: "; m.top.isLoggedIn
        ' print "m.top.isLoggedInViaNativeSVOD: "; m.top.isLoggedInViaNativeSVOD
        ' print "m.top.NoAuthenticationEnabled: "; m.top.NoAuthenticationEnabled
        ' print "m.top.JustBoughtNativeSubscription: "; m.top.JustBoughtNativeSubscription
        ' print "+++++++++++++++++++++++++++++++++++++++++"
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
        ' print "m.canWatchVideo";m.canWatchVideo
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
        m.videoPlayer.content   = m.top.content
        ' m.poster.uri            = m.top.content.hdBackgroundImageUrl
        m.background.uri        = m.top.content.hdBackgroundImageUrl
    end if
End Sub

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
            btns = ["Play"]
        else
            btns = ["Play from beginning", "Resume playing"]
        end if

        if(m.top.BothActive AND m.top.isDeviceLinked)
            if m.top.content.inFavorites = true
                btns.push("Unfavorite")
            else
                btns.push("Favorite")
            end if
        end if

        m.btns = btns
        for each button in btns
            result.push({title : button})
        end for
        m.buttons.content = ContentList2SimpleNode(result)
    end if
End Sub

Sub AddActionButtons()
    if m.top.content <> invalid then
        ' create buttons
        result = []
        btns = ["Subscribe"]', "Link Device"]
        if(m.top.BothActive AND m.top.isDeviceLinked = false)
            btns.push("Link Device")
        end if
        for each button in btns
            result.push({title : button})
        end for
        m.buttons.content = ContentList2SimpleNode(result)
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
            ' print "itemAA_: "; itemAA
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
    ' print "m.top.content.id";m.top.content.id
    ' print "m.top.ResumeVideo.HasVideoIdValue ->";m.top.ResumeVideo.HasVideoIdValue
    if(m.top.ResumeVideo.HasVideoIdValue)
        return true
    else
        m.videoPlayer.seek = 0.00                           ' Start video from 0 if entry not saved.
        return false
    end if

    return false
End Function

Function FindPlaylistRowIndex()
    ' print "FindPlaylistRowIndex"
    ' print "m.top.videosTree: "; m.top.videosTree
    contentId = invalid
    if(m.top.content <> invalid)
        ' print "m.top.content.id: "; m.top.content.id
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
                m.PlaylistRowIndex = index
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
