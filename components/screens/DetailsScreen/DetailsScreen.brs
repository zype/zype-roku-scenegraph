' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********
 ' inits details Screen
 ' sets all observers
 ' configures buttons for Details screen
Function Init()
    ? "[DetailsScreen] init"
    'TestStoreFunction(2)

    m.top.observeField("visible", "onVisibleChange")
    m.top.observeField("focusedChild", "OnFocusedChildChange")

    m.buttons           =   m.top.findNode("Buttons")
    m.videoPlayer       =   m.top.findNode("VideoPlayer")
    ' m.poster            =   m.top.findNode("Poster")
    m.description       =   m.top.findNode("Description")
    m.background        =   m.top.findNode("Background")

    m.canWatchVideo = false
    m.buttons.setFocus(true)
    'm.plans = GetPlans({})


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
                AddPackagesButtons()
                'm.top.SubscriptionPackagesShown = true
                print "Subscription Plans++: "; m.top.SubscriptionPlans[0]
            end if
        end if

    ' second button pressed
    else if m.top.itemSelected = 1
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

        if(m.top.content.subscriptionRequired = false OR (idParts[1] = "True" AND m.top.isLoggedIn))
            m.canWatchVideo = true
        else
            m.canWatchVideo = false
        end if

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
    if m.top.content <> invalid then
        ' create buttons
        result = []

        btns = []
        if m.top.content.inFavorites = true
            btns = ["Play", "Unfavorite"]
        else
            btns = ["Play", "Favorite"]
        end if


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
        'btns = ["Subscribe", "Sign In"]
        btns = ["Subscribe", "Link Device"]
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
        'btns = ["Subscribe", "Sign In"]
        'btns = ["Subscribe", "Link Device"]

        for each plan in m.top.SubscriptionPlans
           btns.push(plan["name"] + " at " + plan["amount"] + " " + plan["currency"])
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