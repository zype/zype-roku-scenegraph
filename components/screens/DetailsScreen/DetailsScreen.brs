' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********
 ' inits details Screen
 ' sets all observers
 ' configures buttons for Details screen
Function Init()
    ? "[DetailsScreen] init"

    m.top.observeField("visible", "onVisibleChange")
    m.top.observeField("focusedChild", "OnFocusedChildChange")

    m.buttons           =   m.top.findNode("Buttons")
    m.videoPlayer       =   m.top.findNode("VideoPlayer")
    ' m.poster            =   m.top.findNode("Poster")
    m.description       =   m.top.findNode("Description")
    m.background        =   m.top.findNode("Background")
    m.PlaylistRowIndex  = invalid
    m.CurrentVideoIndex = invalid
    m.totalVideosCount  = 0

End Function

' set proper focus to buttons if Details opened and stops Video if Details closed
Sub onVisibleChange()
    ? "[DetailsScreen] onVisibleChange"
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
        if(m.top.autoplay = true)
            m.top.triggerPlay = false
        end if
    else if m.videoPlayer.state = "finished"
        print "Video finished playing"
        print "Current: "; m.top.content
        if m.top.autoplay = true AND isLastVideoInPlaylist() = false
            m.CurrentVideoIndex = m.CurrentVideoIndex + 1
            PrepareVideoPlayer()
        else if isLastVideoInPlaylist() = true
            m.CurrentVideoIndex = 0
            PrepareVideoPlayer()
        end if
        
        m.videoPlayer.visible = false
    end if
End Sub

Function PrepareVideoPlayer()
    nextVideoObject = m.top.videosTree[m.PlaylistRowIndex][m.CurrentVideoIndex]
    nextVideoNode = ContentList2SimpleNode(nextVideoObject)

    if(nextVideoObject <> invalid)
        nextVideoNode.id = nextVideoObject.id
        nextVideoNode.CONTENTTYPE = nextVideoObject.contenttype
        nextVideoNode.DESCRIPTION = nextVideoObject.description
        nextVideoNode.HDBACKGROUNDIMAGEURL = nextVideoObject.hdbackgroundimageurl
        nextVideoNode.HDPOSTERURL = nextVideoObject.hdposterurl
        nextVideoNode.inFavorites = nextVideoObject.infavorites
        nextVideoNode.LENGTH = nextVideoObject.length
        nextVideoNode.onAir = nextVideoObject.onair
        nextVideoNode.RELEASEDATE = nextVideoObject.releasedate
        nextVideoNode.STREAMFORMAT = nextVideoObject.streamformat
        nextVideoNode.subscriptionRequired = nextVideoObject.subscriptionrequired
        nextVideoNode.TITLE = nextVideoObject.title
        nextVideoNode.URL = nextVideoObject.url


        m.top.content = nextVideoNode
        print "nextVideoObject: "; nextVideoObject
        print "nextVideoNode: "; nextVideoNode
        print "New: "; m.top.content
        m.top.triggerPlay = true
        m.videoPlayer.state = "play"
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
    ' first button is Play
    if m.top.itemSelected = 0
        ' m.videoPlayer.visible = true
        ' m.videoPlayer.setFocus(true)
        ' m.videoPlayer.control = "play"
        ? "[DetailsScreen] Play button selected"
        m.videoPlayer.observeField("state", "OnVideoPlayerStateChange")
    else if m.top.itemSelected = 1
        ? "[DetailsScreen] Favorite button selected"
    end if
End Sub

' Content change handler
Sub OnContentChange()
    print "Content: "; m.top.content
    print "Videos: "; m.top.videosTree[0][6]
    FindPlaylistRowIndex()

    if m.top.content<>invalid then
    
        AddButtons()

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

Function FindPlaylistRowIndex()
    index = 0
    found = false
    totalVideos = 0
    childCount = 0
    For Each vt in m.top.videosTree
        childCount = 0
        For Each v in vt
            if(v.id = m.top.content.id)
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