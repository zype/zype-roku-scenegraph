Library "Roku_Ads.brs"

' ********** Copyright 2016 Zype Inc.  All Rights Reserved. **********

Sub RunUserInterface()
    screen = CreateObject("roSGScreen")
    m.scene = screen.CreateScene("HomeScene")
    m.port = CreateObject("roMessagePort")
    screen.SetMessagePort(m.port)
    screen.Show()

    m.store = CreateObject("roChannelStore")
    m.store.FakeServer(true)
    m.store.SetMessagePort(m.port)
    m.purchasedItems = []
    m.productsCatalog = []
    
    getUserPurchases()
    getProductsCatalog()

    m.scene.gridContent = ParseContent(GetContent())
    ' m.scene.gridContent = ParseContent(GetPlaylistsAsRows("579116fc6689bc0d1d00f092"))


    m.infoScreen = m.scene.findNode("InfoScreen")
    m.infoScreenText = m.infoScreen.findNode("Info")
    m.infoScreenText.text = GetAppConfigs().info_text

    m.search = m.scene.findNode("Search")
    m.searchDetailsScreen = m.search.findNode("SearchDetailsScreen")
    m.searchDetailsScreen.observeField("itemSelected", m.port)

    m.favorites = m.scene.findNode("Favorites")
    m.favorites.observeField("visible", m.port)
    m.favoritesDetailsScreen = m.favorites.findNode("FavoritesDetailsScreen")
    m.favoritesDetailsScreen.observeField("itemSelected", m.port)

    m.loadingIndicator = m.scene.findNode("loadingIndicator")

    m.detailsScreen = m.scene.findNode("DetailsScreen")
    m.detailsScreen.observeField("itemSelected", m.port)

    m.scene.observeField("SearchString", m.port)

    m.gridScreen = m.scene.findNode("GridScreen")

    m.scene.observeField("playlistItemSelected", m.port)

    m.deviceLinking = m.scene.findNode("DeviceLinking")
    m.deviceLinking.observeField("show", m.port)

    ' pl = CreatePlaylistObject(GetPlaylists({"id": "57928ae4e7b34c2c06000005"})[0])
    ' print pl

    LoadLimitStream() ' Load LimitStream Object
    print GetLimitStreamObject()

    while(true)
        msg = wait(0, m.port)
        msgType = type(msg)
        print "------------------"
        'print "msg = "; msg

        if msgType = "roSGNodeEvent"
            if msg.getField() = "playlistItemSelected" and msg.GetData() = true and m.gridScreen.focusedContent.contentType = 2 then
                m.loadingIndicator.control = "start"
                m.gridScreen.playlistItemSelected = false
                content = m.gridScreen.focusedContent
                m.gridScreen.content = ParseContent(GetPlaylistsAsRows(content.id))

                rowList = m.gridScreen.findNode("RowList")
                print rowList
                m.loadingIndicator.control = "stop"
            else if msg.getNode() = "Favorites" and msg.getField() = "visible" and msg.getData() = true
                m.loadingIndicator.control = "start"
                m.scene.favoritesContent = ParseContent(GetFavoritesContent())
                m.loadingIndicator.control = "stop"
            else if msg.getField() = "SearchString"
                m.loadingIndicator.control = "start"
                SearchQuery(m.scene.SearchString)
                m.loadingIndicator.control = "stop"
            else if (msg.getNode() = "FavoritesDetailsScreen" or msg.getNode() = "SearchDetailsScreen" or msg.getNode() = "DetailsScreen") and msg.getField() = "itemSelected" and msg.getData() = 0 then

                ' access component node content
                if msg.getNode() = "FavoritesDetailsScreen"
                    lclScreen = m.favoritesDetailsScreen
                else if msg.getNode() = "SearchDetailsScreen"
                    lclScreen = m.searchDetailsScreen
                else if msg.getNode() = "DetailsScreen"
                    lclScreen = m.detailsScreen
                end if

                print "THIS IS THE CONTENT"; lclScreen.content

                detailScreenIdFull = lclScreen.content.id
                detailScreenIdObj = detailScreenIdFull.tokenize(":")
                detailScreenId = detailScreenIdObj[0]
                '_isSubscribed = isSubscribed(detailScreenId)
                _isSubscribed = isSubscribed(lclScreen.content.subscription_required)

                ' if(_isSubscribed)
                '     playVideoButton(lclScreen)

                ' ' Monthly subscription button was clicked
                ' else
                '     monthlySubscription(lclScreen)

                ' end if

                handleButtonEvents(1, _isSubscribed, lclScreen)


            else if (msg.getNode() = "FavoritesDetailsScreen" or msg.getNode() = "SearchDetailsScreen" or msg.getNode() = "DetailsScreen") and msg.getField() = "itemSelected" and msg.getData() = 1 then
                print "[Main] Add to favorites"

                'print msg.getNode()

                if msg.getNode() = "FavoritesDetailsScreen"
                    lclScreen = m.favoritesDetailsScreen
                    print "Favorites"
                else if msg.getNode() = "SearchDetailsScreen"
                    lclScreen = m.searchDetailsScreen
                    print "Search Screen"
                else if msg.getNode() = "DetailsScreen"
                    print "Screen"
                    lclScreen = m.detailsScreen
                end if

                print lclScreen
                
                detailScreenIdFull = lclScreen.content.id
                detailScreenIdObj = detailScreenIdFull.tokenize(":")
                detailScreenId = detailScreenIdObj[0]
                '_isSubscribed = isSubscribed(detailScreenId)
                _isSubscribed = isSubscribed(lclScreen.content.subscription_required)

                ' if(_isSubscribed)
                '     markFavoriteButton(lclScreen)

                ' ' Yearly subscription button was pressed
                ' else
                '     yearlySubscription(lclScreen)
                ' end if

                handleButtonEvents(2, _isSubscribed, lclScreen)


            else if msg.getField() = "position"
                ' print m.videoPlayer.position
                ' print GetLimitStreamObject().limit
                'print m.videoPlayer
                GetLimitStreamObject().played = GetLimitStreamObject().played + 1
                print  GetLimitStreamObject().played
                if IsPassedLimit(GetLimitStreamObject().played, GetLimitStreamObject().limit)
                    if IsLinked({"linked_device_id": GetUdidFromReg(), "type": "roku"}).linked = false
                        m.videoPlayer.visible = false
                        m.videoPlayer.control = "stop"
                        dialog = createObject("roSGNode", "Dialog")
                        dialog.title = "Limit Reached"
                        dialog.optionsDialog = true
                        dialog.message = GetLimitStreamObject().message
                        m.scene.dialog = dialog
                    else
                        oauth = GetAccessToken(GetApiConfigs().client_id, GetApiConfigs().client_secret, GetUdidFromReg(), GetPin(GetUdidFromReg()))
                        if oauth <> invalid

                            ' print lclScreen.content.id
                            ' playVideo(lclScreen, oauth.access_token)

                            if IsEntitled(m.videoPlayer.content.id, {"access_token": oauth.access_token}) = false
                                m.videoPlayer.visible = false
                                m.videoPlayer.control = "stop"
                                dialog = createObject("roSGNode", "Dialog")
                                dialog.title = "Limit Reached"
                                dialog.optionsDialog = true
                                dialog.message = GetLimitStreamObject().message
                                m.scene.dialog = dialog
                            end if
                        else
                            print "No OAuth available"
                        end if
                    end if
                end if
            else if msg.getNode() = "DeviceLinking" and msg.getField() = "show" and msg.GetData() = true then
                pin = m.deviceLinking.findNode("Pin")

                if HasUDID() = true then
                    print "Has UDID"
                    if IsLinked({"linked_device_id": GetUdidFromReg(), "type": "roku"}).linked
                        pin.text = "You are already linked!"
                    else
                        while true
                            if m.deviceLinking.show = false
                                exit while
                            else
                                print "refreshing PIN"
                                pin.text = GetPin(GetUdidFromReg())

                                if IsLinked({"linked_device_id": GetUdidFromReg(), "type": "roku"}).linked then
                                    pin.text = "You are linked!"
                                    exit while
                                end if
                            end if

                            sleep(5000)
                        end while
                    end if
                else
                    print "Adding UDID"
                    AddUdidToReg(GenerateUdid())
                    pin.text = GetPin(GetUdidFromReg())
                end if
            end if
        end if
    end while

    if screen <> invalid then
        screen.Close()
        screen = invalid
    end if
End Sub

sub playLiveVideo(screen as Object)
    print "THE KEY: "; GetApiConfigs()
    if HasUDID() = false or IsLinked({"linked_device_id": GetUdidFromReg(), "type": "roku"}).linked = false
        playVideo(screen, {"app_key": GetApiConfigs().app_key})
    else
        oauth = GetAccessToken(GetApiConfigs().client_id, GetApiConfigs().client_secret, GetUdidFromReg(), GetPin(GetUdidFromReg()))
        if oauth <> invalid

            ' print lclScreen.content.id
            ' playVideo(lclScreen, oauth.access_token)

            if IsEntitled(screen.content.id, {"access_token": oauth.access_token}) = true
                playVideo(screen, {"access_token": oauth.access_token})
            else
                playVideo(screen, {"app_key": GetApiConfigs().app_key})
            end if
        else
            print "No OAuth available"
        end if
    end if
end sub

sub playRegularVideo(screen as Object)
    print "PLAY REGULAR VIDEO"
    if screen.content.subscriptionRequired = true
        print "SUBSCRIPTION REQUIRED"
        if HasUDID() = false or IsLinked({"linked_device_id": GetUdidFromReg(), "type": "roku"}).linked = false
            print "You do not have access! Please, link you device!"

            dialog = createObject("roSGNode", "Dialog")
            dialog.title = "Link Device"
            dialog.optionsDialog = true
            dialog.message = "Press * To Dismiss. And link your device using the options."
            m.scene.dialog = dialog
        else
            oauth = GetAccessToken(GetApiConfigs().client_id, GetApiConfigs().client_secret, GetUdidFromReg(), GetPin(GetUdidFromReg()))
            if oauth <> invalid

                ' print lclScreen.content.id
                ' playVideo(lclScreen, oauth.access_token)

                if IsEntitled(screen.content.id, {"access_token": oauth.access_token}) = true
                    playVideo(screen, {"access_token": oauth.access_token})
                else
                    dialog = createObject("roSGNode", "Dialog")
                    dialog.title = "Subscription Required"
                    dialog.optionsDialog = true
                    dialog.message = "You are not subscribed to watch this content. Press * To Dismiss."
                    m.scene.dialog = dialog
                end if
            else
                print "No OAuth available"
            end if
        end if
    else
        print "FREE VIDEO"
        playVideoWithAds(screen, {"app_key": GetApiConfigs().app_key})
    end if
end sub

sub playVideo(screen as Object, auth As Object)

    'print "FUNC: PlayVideo: ", screen.content
    playerInfo = GetPlayerInfo(screen.content.id, auth)

    screen.content.stream = playerInfo.stream
    screen.content.streamFormat = playerInfo.streamFormat
    screen.content.url = playerInfo.url

    ' show loading indicator before requesting ad and playing video
    m.loadingIndicator.control = "start"
    m.VideoPlayer = screen.findNode("VideoPlayer")

    if screen.content.onAir = true
        m.VideoPlayer.observeField("position", m.port)
    end if

    m.loadingIndicator.control = "stop"
    print "[Main] Playing video"
    m.videoPlayer.visible = true
    m.videoPlayer.setFocus(true)
    m.videoPlayer.control = "play"
end sub

sub playVideoWithAds(screen as Object, auth as Object)

    'print "FUNC: PlayVideoWithAds: ", screen.content
    playerInfo = GetPlayerInfo(screen.content.id, auth)

    screen.content.stream = playerInfo.stream
    screen.content.streamFormat = playerInfo.streamFormat
    screen.content.url = playerInfo.url

    ' show loading indicator before requesting ad and playing video
    m.loadingIndicator.control = "start"
    m.VideoPlayer = screen.findNode("VideoPlayer")

    if playerInfo.on_air = true
        m.VideoPlayer.observeField("position", m.port)
    end if

    playContent = true
    if HasUDID() = false or IsLinked({"linked_device_id": GetUdidFromReg(), "type": "roku"}).linked = false
        adIface = Roku_Ads() 'RAF initialize
        print "Roku_Ads library version: " + adIface.getLibVersion()
        adIface.setAdPrefs(true, 2)
        adIface.setDebugOutput(true) 'for debug pupropse

        ' Normally, would set publisher's ad URL here.
        ' Otherwise uses default Roku ad server (with single preroll placeholder ad)
        adIface.setAdUrl("")

        'Returns available ad pod(s) scheduled for rendering or invalid, if none are available.
        adPods = adIface.getAds()

        playContent = true
        'render pre-roll ads
        if adPods <> invalid and adPods.count() > 0 then
            m.loadingIndicator.control = "stop"
            playContent = adIface.showAds(adPods)
        end if
    end if


    if playContent then
        m.loadingIndicator.control = "stop"
        print "[Main] Playing video"
        m.videoPlayer.visible = true
        m.videoPlayer.setFocus(true)
        m.videoPlayer.control = "play"
    end if
end sub

sub SearchQuery(SearchString as String)
    m.scene.searchContent = ParseContent(GetSearchContent(SearchString))
end sub

function GetSearchContent(SearchString as String)
    list = []

    favs = GetFavoritesIDs()

    row = {}
    row.Title = "Search results"
    row.ContentList = []

    params = {}
    params.AddReplace("q", SearchString)
    params.AddReplace("dpt", "true")
    videos = []
    for each video in GetVideos(params)
        video.inFavorites = favs.DoesExist(video._id)
        print video
        videos.push(CreateVideoObject(video))
    end for
    row.ContentList = videos

    if videos.count() = 0
        m.scene.ResultsText = "No results found..."
    else
        m.scene.ResultsText = ""
    end if

    list.Push(row)

    return list
end function

function GetFavoritesIDs()
    videoFavs = {}
    deviceLinking = IsLinked({"linked_device_id": GetUdidFromReg(), "type": "roku"})
    if HasUDID() = true and deviceLinking.linked = true
        oauth = GetAccessToken(GetApiConfigs().client_id, GetApiConfigs().client_secret, GetUdidFromReg(), GetPin(GetUdidFromReg()))
        videoFavorites = GetVideoFavorites(deviceLinking.consumer_id, {"access_token": oauth.access_token, "per_page": "100"})

        ' print videoFavorites
        if videoFavorites <> invalid
            if videoFavorites.count() > 0
                for each fav in videoFavorites
                    videoFavs.AddReplace(fav.video_id, fav._id)
                end for
            end if
        end if
    end if

    return videoFavs
end function

function GetFavoritesContent()
    list = []

    favs = GetFavoritesIDs()

    deviceLinking = IsLinked({"linked_device_id": GetUdidFromReg(), "type": "roku"})
    if HasUDID() = true and deviceLinking.linked = true
        print "Consumer ID: "; deviceLinking.consumer_id
        oauth = GetAccessToken(GetApiConfigs().client_id, GetApiConfigs().client_secret, GetUdidFromReg(), GetPin(GetUdidFromReg()))
        videoFavorites = GetVideoFavorites(deviceLinking.consumer_id, {"access_token": oauth.access_token, "per_page": "100"})

        if videoFavorites <> invalid
            if videoFavorites.count() > 0
                row = {}
                row.title = "Favorites"
                row.ContentList = []
                for each fav in videoFavorites
                    vid = GetVideo(fav.video_id)
                    vid.inFavorites = favs.DoesExist(vid._id)
                    row.ContentList.push(CreateVideoObject(vid))
                end for
                list.push(row)
            end if
        end if
    end if

    return list
end function

Function ParseContent(list As Object)

    RowItems = createObject("RoSGNode","ContentNode")

    ' videoObject = createObject("RoSGNode", "VideoNode")
    for each rowAA in list
        row = createObject("RoSGNode","ContentNode")
        row.Title = rowAA.Title

        for each itemAA in rowAA.ContentList
            item = createObject("RoSGNode","VideoNode")

            ' We don't use item.setFields(itemAA) as doesn't cast streamFormat to proper value
            for each key in itemAA
                item[key] = itemAA[key]
            end for

            print "***********************************************"
            print itemAA
            ' Get the ID element from itemAA and check if the product against that id was subscribed
            if(isSubscribed(itemAA["subscriptionrequired"]))
                isSub = "True"
            else
                isSub = "False"
            end if

            item["id"] = item["id"] + ":" + isSub

            row.appendChild(item)
        end for

        RowItems.appendChild(row)
    end for

    print RowItems.metadata
    return RowItems
End Function

Function GetContent()
    rowTitles = GetCategory(GetAppConfigs().category_id).values
    categoryTitle = GetCategory(GetAppConfigs().category_id).title
    query = "category[" + categoryTitle + "]"


    favs = GetFavoritesIDs()

    list = []
    for each item in rowTitles
        row = {}
        row.title = item
        params = {}
        params.AddReplace(query, item)
        params.AddReplace("dpt", "true")
        videos = []
        for each video in GetVideos(params)
            video.inFavorites = favs.DoesExist(video._id)
            print video
            videos.push(CreateVideoObject(video))
        end for

        row.ContentList = videos
        list.push(row)
    end for

    return list
End Function

function GetPlaylistContent(playlist_id as String)
    pl = GetPlaylists({"id": playlist_id})[0]

    favs = GetFavoritesIDs()

    if pl.playlist_item_count > 0 then
        list = []

        row = {}
        row.title = pl.title
        videos = []
        for each video in GetPlaylistVideos(pl._id)
            video.inFavorites = favs.DoesExist(video._id)
            print video
            videos.push(CreateVideoObject(video))
        end for
        row.ContentList = videos

        list.push(row)
        return list
    else
        return GetContentPlaylists(pl._id)
    end if
end function

function GetContentPlaylists(parent_id as String)
    ' https://admin.zype.com/playlists/579116fc6689bc0d1d00f092
    rawPlaylists = GetPlaylists({"parent_id": parent_id})

    list = []
    row = {}
    row.title = "Playlists"
    row.ContentList = []
    for each item in rawPlaylists
        row.ContentList.push(CreatePlaylistObject(item))
    end for

    list.push(row)

    return list
end function

function GetPlaylistsAsRows(parent_id as String)
    ' https://admin.zype.com/playlists/579116fc6689bc0d1d00f092
    rawPlaylists = GetPlaylists({"parent_id": parent_id, "sort": "priority", "order": "asc"})

    favs = GetFavoritesIDs()

    list = []
    ' row = {}
    ' row.title = "Playlists"
    ' row.ContentList = []
    for each item in rawPlaylists
        row = {}
        row.title = item.title
        row.ContentList = []
        ' row.ContentList.push(CreatePlaylistObject(item))
        if item.playlist_item_count > 0
            row.ContentList = []
            videos = []
            for each video in GetPlaylistVideos(item._id, {"per_page": GetAppConfigs().per_page})
                video.inFavorites = favs.DoesExist(video._id)
                print video
                videos.push(CreateVideoObject(video))
            end for
            row.ContentList = videos
        else
            pls = GetPlaylists({"parent_id": item._id})
            for each pl in pls
                row.ContentList.push(CreatePlaylistObject(pl))
            end for
        endif

        list.push(row)
    end for



    return list
end function


'/////////////////////////////////////////////////
' Get a list of items in the product catalog
Function getProductsCatalog()
    m.store.GetCatalog()
    while (true)
        msg = wait(0, m.port)
        if (type(msg) = "roChannelStoreEvent")
            if (msg.isRequestSucceeded())
                response = msg.GetResponse()
                for each item in response
                    m.productsCatalog.Push({
                        Title: item.name
                        code: item.code
                        cost: item.cost
                        description: item.description
                        productType: item.productType
                    })
                end for
                exit while
            else if (msg.isRequestFailed())
                print "***** Failure: " + msg.GetStatusMessage() + " Status Code: " + stri(msg.GetStatus()) + " *****"
            end if
        end if
    end while
End Function

'/////////////////////////////////////////////////
' Get a list of items that the user has purchased
Function getUserPurchases() as void
    m.store.GetPurchases()
    while (true)
        msg = wait(0, m.port)
        if (type(msg) = "roChannelStoreEvent")
            if (msg.isRequestSucceeded())
                response = msg.GetResponse()
                for each item in response
                    m.purchasedItems.Push({
                        Title: item.name
                        code: item.code
                        cost: item.cost
                    })
                end for
                exit while
            else if (msg.isRequestFailed())
                print "***** Failure: " + msg.GetStatusMessage() + " Status Code: " + stri(msg.GetStatus()) + " *****"
            end if
        end if
    end while

End Function

' ///////////////////////////////////////////////////////////////////////////////////
' Checks from the list of purchased items if the user was subscribed to a product
Function isSubscribed(subscriptionRequired) as boolean
    if(subscriptionRequired = false)
        return true
    end if

    subscribed = false

    for each pi in m.purchasedItems
        if(pi.code = "svod-monthly" OR pi.code = "svod-yearly") ' Means the user has subscribed to atleast one of these
            subscribed = true
            exit for
        end if
    end for
    return subscribed
    ' monthlyCode = id + "_m"
    ' yearlyCode = id + "_y"
    ' owned = false
    ' for each pi in m.purchasedItems
    '     ' Current item on Detail Screen is either subscribed monthly or yearly
	'     if (monthlyCode = pi.code or yearlyCode = pi.code)
	'         owned = true
	' 	    exit for
	'     end if
	' end for
    ' return owned
End Function


'///////////////////////////////////
' LabelList click handlers go here
'///////////////////////////////////

Function handleButtonEvents(index, _isSubscribed, lclScreen)
    print "Handle Event: "; isSubscribed
    if(isLoggedIn() OR lclScreen.content.subscriptionRequired = false)    ' Play / Favorite buttons
        print "LoggedIn"
        ' This is going to be the Play button
        if(index = 1 and (_isSubscribed = true OR lclScreen.content.subscriptionRequired = false))
        'if(index = 1 and _isSubscribed)
            print "LoggedIn If: "
            playVideoButton(lclScreen)
        
        else if(index = 2)  ' This is going to be the favorites button
            print "LoggedIn Else If: "
        end if

    else    ' Subscribe / Sign In buttons
        print "Handle Else: "
        if(index = 1)   ' Subscribe
            print "Handle Else -> If"
            ShowPackagesDialog()

        else            ' Sign In
            print "Handle Else -> else"
            ShowSignInOptionsDialog()
        end if
    end if
End Function

Function isLoggedIn()
    deviceLinking = IsLinked({"linked_device_id": GetUdidFromReg(), "type": "roku"})
    if HasUDID() = true and deviceLinking.linked = true
        return true
    end if
    'return true
    return false
End Function

Function ShowPackagesDialog()
    plans = GetPlans({})

    screen = CreateObject("roMessageDialog")
    screen.SetMessagePort(m.port)
    screen.SetTitle("Subscribe")
    screen.SetText("Please select your preferred subscription plan to continue")

    'screen.AddButton(1, "Link Device to Existing Account")
    'screen.AddButton(2, "Restore Roku Purchase")

    index = 1
    for each plan in plans
        print "Plan: "; plan
        if(plan.active = true)
            screen.AddButton(index, plan.name + " at " + plan.amount + " " + plan.currency)
        end if
        index = index + 1
    end for

    screen.EnableBackButton(true)
    screen.Show()

    while true
        msg = wait(0, m.port)
        if type(msg) = "roMessageDialogEvent"
            if msg.isScreenClosed() then 'ScreenClosed event'
                'print "Closing video screen"
                exit while
            else if msg.isButtonPressed() then
                HandlePackagesEvents(msg.GetIndex(), plans)
            else
                'print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
            end if
        end if
    end while
End Function

Function HandlePackagesEvents(index, plans)
    if(index = 1)
        print "Monthly Plan"
        monthlySubscription(plans, index, m.store, m.port, m.productsCatalog)

    else if(index = 2)
        print "Yearly Plan"
        yearlySubscription(plans, index, m.store, m.port, m.productsCatalog)
    end if
End Function

Function ShowSignInOptionsDialog()
    print "ShowSignInOptionsDialog"
    screen = CreateObject("roMessageDialog")
    screen.SetMessagePort(m.port)
    screen.SetTitle("Sign In")
    screen.SetText("Please select your preferred method to sign in")
    screen.AddButton(1, "Link Device to Existing Account")
    screen.AddButton(2, "Restore Roku Purchase")
    screen.EnableBackButton(true)
    screen.Show()

    while true
        msg = wait(0, m.port)
        if type(msg) = "roMessageDialogEvent"
            if msg.isScreenClosed() then 'ScreenClosed event'
                'print "Closing video screen"
                exit while
            else if msg.isButtonPressed() then
                HandleSignInButtonEvents(msg.GetIndex(), screen)
            else
                'print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
            end if
        end if
    end while
End Function

Function HandleSignInButtonEvents(buttonIndex, screen)
    if(buttonIndex = 1) ' Link Device
        print "Link Device Button Pressed"

        screen.Close()

        ' show and focus Device Linking
        m.deviceLinking.show = true
        m.deviceLinking.setFocus(true)

    else if(buttonIndex = 2)    ' Restore Roku Purchase
        print "Restore Roku Purchase Button Pressed"
    end if
End Function

Function playVideoButton(lclScreen)
    if lclScreen.content.onAir = false
        playRegularVideo(lclScreen)
    else
        playLiveVideo(lclScreen)
    end if
End Function

Function markFavoriteButton(lclScreen)
    deviceLinking = IsLinked({"linked_device_id": GetUdidFromReg(), "type": "roku"})
    if HasUDID() = true and deviceLinking.linked = true
        favs = GetFavoritesIDs()
        print "Consumer ID: "; deviceLinking.consumer_id
        oauth = GetAccessToken(GetApiConfigs().client_id, GetApiConfigs().client_secret, GetUdidFromReg(), GetPin(GetUdidFromReg()))
        if lclScreen.content.inFavorites = false
            CreateVideoFavorite(deviceLinking.consumer_id, {"access_token": oauth.access_token, "video_id": lclScreen.content.id })
            lclScreen.content.inFavorites = true
        else
            DeleteVideoFavorite(deviceLinking.consumer_id, favs[lclScreen.content.id], {"access_token": oauth.access_token, "video_id": lclScreen.content.id, "_method": "delete"})
            lclScreen.content.inFavorites = false
        end if
    end if
End Function

' '///////////////////////////////////////////////
' ' Make Purchase
' Function makePurchase(title, code) as void
'     if(isValidProduct(code) = false)
'         invalidProductDialog(title)
'         return
'     end if
'     result = m.store.GetUserData()
'     if (result = invalid)
'         return
'     end if
'     order = [{
'         code: code
'         qty: 1        
'     }]
    
'     val = m.store.SetOrder(order)
'     res = m.store.DoOrder()

'     purchaseDetails = invalid
'     error = {}
'     while (true)
'         msg = wait(0, m.port)
'         if (type(msg) = "roChannelStoreEvent")
'             if(msg.isRequestSucceeded())
'                 ' purchaseDetails can be used for any further processing of the transactional information returned from roku store.
'                 purchaseDetails = msg.GetResponse()
'             else
'                 error.status = msg.GetStatus()
'                 error.statusMessage = msg.GetStatusMessage()
'             end if
'             exit while
'         end if
'     end while

'     if (res = true)
'         orderStatusDialog(true, title)
'     else
'         orderStatusDialog(false, title)
'     end if
' End Function

' '///////////////////////////////////////////////
' ' Order Status Dialog
' Function orderStatusDialog(success as boolean, item as string) as void
'     dialog = CreateObject("roMessageDialog")
'     port = CreateObject("roMessagePort")
'     dialog.SetMessagePort(port)
'     if (success = true)
'         dialog.SetTitle("Order Completed Successfully")
'         str = "Your Purchase of '" + item + "' Completed Successfully"
'     else
'         dialog.SetTitle("Order Failed")
'         str = "Your Purchase of '" + item + "' Failed"
'     end if
    
'     dialog.SetText(str)
'     dialog.AddButton(1, "OK")
'     dialog.EnableBackButton(true)
'     dialog.Show()

'     while true
'         dlgMsg = wait(0, dialog.GetMessagePort())
'         If type(dlgMsg) = "roMessageDialogEvent"
'             if dlgMsg.isButtonPressed()
'                 if dlgMsg.GetIndex() = 1
'                     exit while
'                 end if
'             else if dlgMsg.isScreenClosed()
'                 exit while
'             end if
'         end if
'     end while

' End Function

' Function invalidProductDialog(title)
'     dialog = CreateObject("roMessageDialog")
'     port = CreateObject("roMessagePort")
'     dialog.SetMessagePort(port)
'     dialog.SetTitle("Invalid Product")
'     str = "The product '" + title + "' is not available at the moment"

'     dialog.SetText(str)
'     dialog.AddButton(1, "OK")
'     dialog.EnableBackButton(true)
'     dialog.Show()

'     while true
'         dlgMsg = wait(0, dialog.GetMessagePort())
'         If type(dlgMsg) = "roMessageDialogEvent"
'             if dlgMsg.isButtonPressed()
'                 if dlgMsg.GetIndex() = 1
'                     exit while
'                 end if
'             else if dlgMsg.isScreenClosed()
'                 exit while
'             end if
'         end if
'     end while
' End Function