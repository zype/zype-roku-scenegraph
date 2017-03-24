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

    m.canWatchVideo = false
    m.buttons.setFocus(true)
    'm.plans = GetPlans({})

    ' Set theme
    m.AppBackground = m.top.findNode("AppBackground")
    m.AppBackground.color = m.global.theme.background_color

    m.overlay = m.top.findNode("thumbOverlay-details")
    m.overlay.uri = m.global.theme.overlay_uri

    m.buttons.color = m.global.theme.primary_text_color
    m.buttons.focusedColor = m.global.brand_color
    m.buttons.focusBitmapUri = m.global.theme.button_focus_uri

    m.subscribeButtons = m.top.findNode("SubscriptionButtons")
    m.subscribeButtons.color = m.global.theme.primary_text_color
    m.subscribeButtons.focusedColor = m.global.brand_color
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
    if m.videoPlayer.state = "error"
        ' error handling
        m.videoPlayer.visible = false
    else if m.videoPlayer.state = "playing"
        ' playback handling
    else if m.videoPlayer.state = "finished"
        m.videoPlayer.visible = false
        m.top.ResumeVideo = m.top.createChild("ResumeVideo")
        m.top.ResumeVideo.id = "ResumeVideo"
        m.top.ResumeVideo.DeleteVideoIdTimer =  m.top.content.id  ' Delete video id and time from reg.
        AddButtons()                                              ' Change buttons status
    end if
End Sub

' on Button press handler
Sub onItemSelected()
    ' first button pressed
    if m.top.itemSelected = 0
        m.videoPlayer.observeField("state", "OnVideoPlayerStateChange")

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

        if(m.btns <> invalid and m.btns[m.top.itemSelected] = "Resume playing")
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
    print "Content: "; m.top.content
    m.top.SubscriptionPackagesShown = false
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
        m.videoPlayer.seek = 0.00                           ' Start video from 0 if entry not saved.
        return false
    end if

    return false
End Function
