Library "Roku_Ads.brs"

' ********** Copyright 2016 Zype Inc.  All Rights Reserved. **********
Function Main (args as Dynamic) as Void
    if (args.ContentID <> invalid) and (args.MediaType <> invalid)
        if (args <> invalid)
            contentID   = args.contentID
            mediaType   = args.mediatype
            SetHomeScene(contentID)
        end if
    else
        SetHomeScene()
    end if
End Function

Sub SetHomeScene(contentID = invalid)
    screen = CreateObject("roSGScreen")

    m.app = GetAppConfigs()

    m.global = screen.getGlobalNode()

    SetTheme()

    m.scene = screen.CreateScene("HomeScene")
    m.port = CreateObject("roMessagePort")
    screen.SetMessagePort(m.port)
    screen.Show()
    m.app = GetAppConfigs()

    m.LoadingScreen = m.scene.findNode("LoadingScreen")

    m.loadingIndicator = m.scene.findNode("loadingIndicator")
    m.loadingIndicator1 = m.scene.findNode("loadingIndicator1")

    ' Start loader if deep linked
    if contentID <> invalid
      m.loadingIndicator.control = "stop"
      StartLoader()
    end if

    m.store = CreateObject("roChannelStore")
    ' m.store.FakeServer(true)
    m.store.SetMessagePort(m.port)
    m.purchasedItems = []
    m.productsCatalog = []
    m.app = GetAppConfigs()
    m.playlistRows = []
    m.videosList = []

    'm.scene.gridContent = ParseContent(GetContent())
    m.contentID = contentID

    m.scene.gridContent = ParseContent(GetPlaylistsAsRows(m.app.featured_playlist_id))
    print "gridContent: "; m.scene.gridContent
    print "m.playlistRows: "; m.playlistRows[0]
    print "m.app: "; m.app
    getUserPurchases()
    getProductsCatalog()

    m.plans = GetPlans({}, m.app.in_app_purchase, m.productsCatalog)

    m.Menu = m.scene.findNode("Menu")
    m.Menu.isDeviceLinkingEnabled = m.app.device_linking

    print "[Main] Init"

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

    m.detailsScreen = m.scene.findNode("DetailsScreen")
    m.detailsScreen.observeField("itemSelected", m.port)
    'm.detailsScreen.SubscriptionPlans = m.plans
    'm.detailsScreen.SubscriptionPlans = m.productsCatalog
    m.detailsScreen.productsCatalog = m.productsCatalog
    m.detailsScreen.JustBoughtNativeSubscription = false
    m.detailsScreen.isLoggedIn = isLoggedIn()
    m.detailsScreen.observeField("triggerPlay", m.port)
    m.detailsScreen.dataArray = m.playlistRows
    m.detailsScreen.videosTree = m.videosList
    m.detailsScreen.autoplay = m.app.autoplay

    m.favorites.isLoggedIn = isLoggedIn()

    deviceLinked = IsLinked({"linked_device_id": GetUdidFromReg(), "type": "roku"}).linked
    m.detailsScreen.isDeviceLinked = deviceLinked

    print "m.detailsScreen.isLoggedIn: "; m.detailsScreen.isLoggedIn
    InitAuthenticationParams()

    m.scene.observeField("SearchString", m.port)

    m.gridScreen = m.scene.findNode("GridScreen")

    m.scene.observeField("playlistItemSelected", m.port)
    m.scene.observeField("TriggerDeviceUnlink", m.port)

    m.deviceLinking = m.scene.findNode("DeviceLinking")
    m.deviceLinking.DeviceLinkingURL = m.app.device_link_url
    m.deviceLinking.isDeviceLinked = deviceLinked
    m.deviceLinking.observeField("show", m.port)
    m.deviceLinking.observeField("itemSelected", m.port)

    LoadLimitStream() ' Load LimitStream Object
    'print GetLimitStreamObject()

    'isAuthViaUniversalSVOD()

    startDate = CreateObject("roDateTime")

    ' Deep Linking
    if (contentID <> invalid)
      ' Get video object and create VideoNode
      linkedVideo = GetVideo(contentID)

      ' If contentID is for active video
      if linkedVideo.DoesExist("_id") and linkedVideo.active = true
        linkedVideoObject =  CreateVideoObject(linkedVideo)
        linkedVideoNode = createObject("roSGNode", "VideoNode")

        for each key in linkedVideoObject
          linkedVideoNode[key] = linkedVideoObject[key]
        end for

        ' Set focused content to linkedVideoNode
        m.gridScreen.focusedContent = linkedVideoNode
        m.gridScreen.visible = "false"
        m.detailsScreen.content = m.gridScreen.focusedContent
        m.detailsScreen.setFocus(true)
        m.detailsScreen.visible = "true"

        ' Trigger listener to push detailsScreen into HomeScene screenStack
        m.scene.DeepLinkedID = contentID

        ' Start playing video if no monetization
        if linkedVideo.subscription_required = false and linkedVideo.purchase_required = false
          if m.app.avod = true
            playVideoWithAds(m.detailsScreen, {"app_key": GetApiConfigs().app_key})
          else
            playVideo(m.detailsScreen, {"app_key": GetApiConfigs().app_key})
          end if
        end if
      end if

      ' Close loading screen if still visible
      if m.LoadingScreen.visible = true
        EndLoader()

        ' Trigger grid screen refocus if visible
        if m.gridScreen.visible = true
          m.scene.gridContent = m.scene.gridContent
        end if
      end if
    end if

    while(true)
        msg = wait(0, m.port)
        msgType = type(msg)

        print "msg.getField(): "; msg.getField()
        print "msg.getData(): "; msg.getData()

        if msgType = "roSGNodeEvent"
            if m.app.autoplay = true AND msg.getField() = "triggerPlay" AND msg.getData() = true then
                m.detailsScreen.RemakeVideoPlayer = true
                playRegularVideo(m.detailsScreen)
            else if msg.getField() = "playlistItemSelected" and msg.GetData() = true and m.gridScreen.focusedContent.contentType = 2 then
                m.loadingIndicator.control = "start"
                m.gridScreen.playlistItemSelected = false
                content = m.gridScreen.focusedContent
                m.gridScreen.content = ParseContent(GetPlaylistsAsRows(content.id))

                rowList = m.gridScreen.findNode("RowList")
                rowlist.jumpToRowItem = [0,0]

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

                ' print "THIS IS THE CONTENT"; lclScreen.content

                ' detailScreenIdFull = lclScreen.content.id
                ' detailScreenIdObj = detailScreenIdFull.tokenize(":")
                ' detailScreenId = detailScreenIdObj[0]
                '_isSubscribed = isSubscribed(detailScreenId)
                _isSubscribed = isSubscribed(lclScreen.content.subscription_required)

                handleButtonEvents(1, _isSubscribed, lclScreen)

            else if (msg.getNode() = "FavoritesDetailsScreen" or msg.getNode() = "SearchDetailsScreen" or msg.getNode() = "DetailsScreen") and msg.getField() = "itemSelected" and msg.getData() = 1 then
                print "[Main] Add to favorites"

                ' print msg.getNode()

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

                ' print lclSreen

                ' detailScreenIdFull = lclScreen.content.id
                ' detailScreenIdObj = detailScreenIdFull.tokenize(":")
                ' detailScreenId = detailScreenIdObj[0]
                '_isSubscribed = isSubscribed(detailScreenId)
                _isSubscribed = isSubscribed(lclScreen.content.subscription_required)

                handleButtonEvents(2, _isSubscribed, lclScreen)
            else if (msg.getNode() = "DetailsScreen") and msg.getField() = "itemSelected" and (msg.getData() = 2) then
                print "resume button clicked"

                if msg.getNode() = "DetailsScreen"
                    print "Screen"
                    lclScreen = m.detailsScreen
                end if

                detailScreenIdFull = lclScreen.content.id
                detailScreenIdObj = detailScreenIdFull.tokenize(":")
                detailScreenId = detailScreenIdObj[0]
                '_isSubscribed = isSubscribed(detailScreenId)
                _isSubscribed = isSubscribed(lclScreen.content.subscription_required)

                handleButtonEvents(3, _isSubscribed, lclScreen)
            else if msg.getField() = "position"
                ' print m.videoPlayer.position
                ' print GetLimitStreamObject().limit
                print m.videoPlayer.position
                if(m.videoPlayer.position >= 30 and m.videoPlayer.content.onAir = false)
                    AddVideoIdForResumeToReg(m.gridScreen.focusedContent.id,m.videoPlayer.position.ToStr())
                    AddVideoIdTimeSaveForResumeToReg(m.gridScreen.focusedContent.id,startDate.asSeconds().ToStr())
                end if
                if(m.on_air)
                  if GetLimitStreamObject() <> invalid
                    GetLimitStreamObject().played = GetLimitStreamObject().played + 1
                    'print  GetLimitStreamObject().played
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

                                id = m.videoPlayer.content.id.tokenize(":")[0]
                                if IsEntitled(id, {"access_token": oauth.access_token}) = false
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

                                deviceLinkingObj = IsLinked({"linked_device_id": GetUdidFromReg(), "type": "roku"})
                                if deviceLinkingObj.linked then
                                    pin.text = "You are linked!"

                                    m.detailsScreen.isDeviceLinked = true
                                    m.detailsScreen.UniversalSubscriptionsCount = deviceLinkingObj.subscription_count
                                    m.detailsScreen.isLoggedIn = true
                                    m.favorites.isLoggedIn = true
                                    m.deviceLinking.isDeviceLinked = true
                                    m.deviceLinking.setUnlinkFocus = true
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

                    while true
                        if m.deviceLinking.show = false
                            exit while
                        else
                            print "refreshing PIN"

                            deviceLinkingObj = IsLinked({"linked_device_id": GetUdidFromReg(), "type": "roku"})
                            if deviceLinkingObj.linked then
                                pin.text = "The device is linked"

                                m.detailsScreen.isDeviceLinked = true
                                m.detailsScreen.UniversalSubscriptionsCount = deviceLinkingObj.subscription_count
                                m.detailsScreen.isLoggedIn = true
                                m.favorites.isLoggedIn = true
                                exit while
                            end if
                        end if

                        sleep(5000)
                    end while
                end if
            else if msg.getNode() = "DeviceLinking" AND msg.getField() = "itemSelected" then
                print "[Main] Device Linking -> Item Selected"

                sleep(500)

                m.scene.dialog = invalid
                dialog = createObject("roSGNode", "Dialog")
                dialog.title = "Device Unlink Confirmation"
                dialog.message = "Are you sure you want to unlink your device? You will need to link your device again in order to access premium content."
                dialog.optionsDialog = true
                dialog.buttons = ["Yes", "No"]
                m.scene.dialog = dialog

            else if msg.getField() = "TriggerDeviceUnlink" AND msg.GetData() = true then
                isDeviceLinked = IsLinked({"linked_device_id": GetUdidFromReg(), "type": "roku"})
                res = UnlinkDevice(isDeviceLinked.consumer_id, isDeviceLinked.pin, {})
                if(res <> invalid)
                    print "Unlink Completed"
                    m.scene.TriggerDeviceUnlink = false
                    m.deviceLinking.isDeviceLinked = false
                    m.detailsScreen.isDeviceLinked = false
                    m.detailsScreen.isLoggedIn = isLoggedIn()
                    m.favorites.isLoggedIn = isLoggedIn()
                end if
            end if

        end if
    end while

    print "You are exiting the app"

    if screen <> invalid then
        screen.Close()
        screen = invalid
    end if
End Sub

sub playLiveVideo(screen as Object)
    'print "THE KEY: "; GetApiConfigs()
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

' Play button should only appear in the following scenarios:
'     1- No subscription required for video
'     2- NSVOD only and user has already purchased a native subscription
'     3- Both NSVOD and USVOD. User either purchased a native subscription or is linked
sub playRegularVideo(screen as Object)
    print "PLAY REGULAR VIDEO"
    consumer = IsLinked({"linked_device_id": GetUdidFromReg(), "type": "roku"})

    ' Video requires subscription, device linking is true and user does not have native subscription
    if screen.content.subscriptionRequired = true AND m.app.device_linking = true AND consumer.linked = true
        print "SUBSCRIPTION REQUIRED"

        ' Check if consumer is linked and has subscription
        if consumer.subscription_count > 0 OR m.detailsScreen.isLoggedInViaNativeSVOD = true OR m.detailsScreen.JustBoughtNativeSubscription = true
          playVideo(screen, {"app_key": GetApiConfigs().app_key})
        else
          dialog = createObject("roSGNode", "Dialog")
          dialog.title = "Subscription Required"
          dialog.optionsDialog = true
          dialog.message = "You are not subscribed to watch this content. Press * To Dismiss."
          m.scene.dialog = dialog
        end if

    ' Has purchased native subscription or video does not require subscription
    else
        print "FREE VIDEO"

        ' m.detailsScreen.RemakeVideoPlayer = true

        if m.app.avod = true
          playVideoWithAds(screen, {"app_key": GetApiConfigs().app_key})
        else
          playVideo(screen, {"app_key": GetApiConfigs().app_key})
        end if
    end if
end sub

sub playVideo(screen as Object, auth As Object)

    'print "FUNC: PlayVideo: ", screen.content
    playerInfo = GetPlayerInfo(screen.content.id, auth)

    screen.content.stream = playerInfo.stream
    screen.content.streamFormat = playerInfo.streamFormat
    screen.content.url = playerInfo.url

    ' If video source is not available
    if(screen.content.streamFormat = "(null)")
        dialog = createObject("roSGNode", "Dialog")
        dialog.title = "Error!"
        dialog.optionsDialog = true
        dialog.message = "We're sorry, that video is no longer available. Please try another video."
        dialog.buttons = ["OK"]
        dialog.focusButton = 0
        m.scene.dialog = dialog
    else
        ' show loading indicator before requesting ad and playing video
        m.loadingIndicator.control = "start"
        m.on_air = screen.content.onAir

        m.VideoPlayer = screen.VideoPlayer
        m.VideoPlayer.observeField("position", m.port)
        m.videoPlayer.content = screen.content

        if playerInfo.subtitles.count() > 0
          subtitleTracks = []

          for each subtitle in playerInfo.subtitles
            subtitleTracks.push({
              TrackName: subtitle.url,
              Language: subtitle.language
            })
          end for

          m.videoPlayer.content.subtitleTracks = subtitleTracks
        else
          m.videoPlayer.content.subtitleTracks = []
        end if

        m.VideoPlayer.seek = m.VideoPlayer.seek

        if screen.content.onAir = true
            m.VideoPlayer.content.live = true
            m.VideoPlayer.content.playStart = 1000000000
        end if

        m.loadingIndicator.control = "stop"
        print "[Main] Playing video"

        m.videoPlayer.visible = true
        screen.videoPlayerVisible = true

        if m.LoadingScreen.visible = true
          EndLoader()
        end if

        m.videoPlayer.setFocus(true)
        m.videoPlayer.control = "play"
    end if
end sub

sub playVideoWithAds(screen as Object, auth as Object)

    'print "FUNC: PlayVideoWithAds: ", screen.content
    playerInfo = GetPlayerInfo(screen.content.id, auth)

    print "screen.content.streamFormat: "; type(screen.content.streamFormat)
    screen.content.stream = playerInfo.stream
    screen.content.streamFormat = playerInfo.streamFormat
    screen.content.url = playerInfo.url

    ' If video source is not available
    if(screen.content.streamFormat = "(null)")
        dialog = createObject("roSGNode", "Dialog")
        dialog.title = "Error!"
        dialog.optionsDialog = true
        dialog.message = "We're sorry, that video is no longer available. Please try another video."
        dialog.buttons = ["OK"]
        dialog.focusButton = 0
        m.scene.dialog = dialog
    else
        ' show loading indicator before requesting ad and playing video
        m.loadingIndicator.control = "start"
        m.on_air = playerInfo.on_air

        if m.VideoPlayer = invalid
          m.VideoPlayer = screen.findNode("VideoPlayer")
        end if

        m.VideoPlayer = screen.VideoPlayer
        m.VideoPlayer.observeField("position", m.port)
        m.videoPlayer.content = screen.content

        if playerInfo.subtitles.count() > 0
          subtitleTracks = []

          for each subtitle in playerInfo.subtitles
            subtitleTracks.push({
              TrackName: subtitle.url,
              Language: subtitle.language
            })
          end for

          m.videoPlayer.content.subtitleTracks = subtitleTracks
        else
          m.videoPlayer.content.subtitleTracks = []
        end if

        m.VideoPlayer.seek = m.VideoPlayer.seek

        adIface = Roku_Ads() 'RAF initialize
        'print "Roku_Ads library version: " + adIface.getLibVersion()
        adIface.setAdPrefs(true, 2)
        adIface.setDebugOutput(true) 'for debug pupropse

        ' Normally, would set publisher's ad URL here.
        ' Otherwise uses default Roku ad server (with single preroll placeholder ad)
        if playerInfo.scheduledAds.count() > 0
            url = playerInfo.scheduledAds[0].url
            adIface.setAdUrl(url)
        end if

        ' Getting midroll ads info from video's scheduled ads
        midrollAds = []
        if playerInfo.scheduledAds.count() > 1
          for each ad in playerInfo.scheduledAds
            midrollAd = {
              url: ad.url,
              offset: ad.offset,
            }
            midrollAds.push(midrollAd)
          end for

          ' Remove first ad object since it will be preroll
          midrollAds.shift()
        end if

        ' Fetch preroll ad
        prerollAdPod = adIface.getAds()

        playContent = true
        'render pre-roll ads
        if GetAppConfigs().avod = true and prerollAdPod.count() > 0 then
            m.loadingIndicator.control = "stop"
            playContent = adIface.showAds(prerollAdPod)
        end if

        ' Start playing video
        if playContent then
            m.loadingIndicator.control = "stop"
            print "[Main] Playing video"
            m.videoPlayer.visible = true
            screen.videoPlayerVisible = true

            if m.LoadingScreen.visible = true
              EndLoader()
            end if

            m.videoPlayer.setFocus(true)
            m.videoPlayer.control = "play"

            sleep(500)
            ' If midroll ads exist, watch for midroll ads
            if midrollAds.count() > 0
              while midrollAds.count() > 0
                currPos = m.videoPlayer.position

                timeDiff = Abs(midrollAds[0].offset - currPos)
                print "Next midroll ad: "; midrollAds[0].offset
                print "Time until next midroll ad: "; timeDiff

                ' Within half second of next midroll ad timing
                if timeDiff <= 0.500
                  m.videoPlayer.control = "stop"

                  ' Get ad pod for mid roll ad
                  adIface.setAdUrl(midrollAds[0].url)
                  midrollAdPod = adIface.getAds()

                  ' Show midroll ad
                  adIface.showAds(midrollAdPod)

                  ' Remove midroll ad from array
                  midrollAds.shift()

                  ' Start playing video at back from currPos just before midroll ad started
                  m.videoPlayer.seek = currPos
                  m.videoPlayer.control = "play"

                ' In case they fast forwarded or resumed watching, remove unnecessary midroll ads
                ' Keep removing the first midroll ad in array until no midroll ads before current position
                else if midrollAds.count() > 0 and currPos > midrollAds[0].offset
                  while midrollAds.count() > 0 and currPos > midrollAds[0].offset
                    midrollAds.shift()
                  end while
                else if m.videoPlayer.visible = false
                  m.videoPlayer.control = "none"
                  exit while
                end if

              end while ' end of midroll ad loop

            end if ' end of midroll ad if statement

        end if ' end of if playContent
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
    video_index = 0
    for each video in GetVideos(params)
        video.inFavorites = favs.DoesExist(video._id)
        'print video
        video.playlist_id = 0
        video.playlist_name = invalid
        video.video_index = video_index
        print video
        videos.push(CreateVideoObject(video))
        video_index = video_index + 1
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
        'print "Consumer ID: "; deviceLinking.consumer_id
        oauth = GetAccessToken(GetApiConfigs().client_id, GetApiConfigs().client_secret, GetUdidFromReg(), GetPin(GetUdidFromReg()))
        videoFavorites = GetVideoFavorites(deviceLinking.consumer_id, {"access_token": oauth.access_token, "per_page": "100"})

        if videoFavorites <> invalid
            if videoFavorites.count() > 0
                row = {}
                row.title = "Favorites"
                row.ContentList = []
                video_index = 0
                for each fav in videoFavorites
                    vid = GetVideo(fav.video_id)
                    vid.inFavorites = favs.DoesExist(vid._id)
                    vid.video_index = video_index
                    row.ContentList.push(CreateVideoObject(vid))
                    video_index = video_index + 1
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
            'print itemAA
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
        video_index = 0
        for each video in GetVideos(params)
            video.inFavorites = favs.DoesExist(video._id)
            video.playlist_id = 0
            video.playlist_name = invalid
            video.video_index = video_index
            print video
            videos.push(CreateVideoObject(video))
            video_index = video_index + 1
        end for

        row.ContentList = videos
        list.push(row)
    end for

    return list
End Function

function GetPlaylistContent(playlist_id as String)
    playlist_id = playlist_id.tokenize(":")[0]
    pl = GetPlaylists({"id": playlist_id})[0]

    favs = GetFavoritesIDs()

    if pl.playlist_item_count > 0 then
        list = []
        row = {}
        row.title = pl.title
        videos = []
        video_index = 0
        for each video in GetPlaylistVideos(pl._id, {"dpt": "true", "per_page": GetAppConfigs().per_page})
            video.inFavorites = favs.DoesExist(video._id)
            video.playlist_id = 0
            video.playlist_name = invalid
            video.video_index = video_index
            print video
            videos.push(CreateVideoObject(video))
            video_index = video_index + 1
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
    parent_id = parent_id.tokenize(":")[0]
    if GetAppConfigs().per_page <> invalid
      per_page = GetAppConfigs().per_page
    else
      per_page = 500
    end if

    rawPlaylists = GetPlaylists({"parent_id": parent_id, "dpt": "true", "sort": "priority", "order": "dsc", "per_page": per_page, "page": 1})

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
    parent_id = parent_id.tokenize(":")[0]
    if GetAppConfigs().per_page <> invalid
      per_page = GetAppConfigs().per_page
    else
      per_page = 500
    end if

    rawPlaylists = GetPlaylists({"parent_id": parent_id, "dpt": "true", "sort": "priority", "order": "dsc", "per_page": per_page, "page": 1})

    favs = GetFavoritesIDs()

    if rawPlaylists.count() = 0
      return GetPlaylistContent(parent_id)
    end if

    list = []
    for each item in rawPlaylists
        row = {}
        row.title = item.title
        row.ContentList = []
        ' row.ContentList.push(CreatePlaylistObject(item))
        if item.playlist_item_count > 0
            row.ContentList = []
            videos = []
            video_index = 0
            for each video in GetPlaylistVideos(item._id, {"per_page": GetAppConfigs().per_page})
                print "Playlist: "; item
                video.inFavorites = favs.DoesExist(video._id)
                print "video.id";video._id
                video.playlist_id = item._id
                video.playlist_name = item.title
                video.video_index = video_index
                print video
                videos.push(CreateVideoObject(video))
                video_index = video_index + 1
            end for
            row.ContentList = videos
            m.videosList.push(videos)
        else
            pls = GetPlaylists({"parent_id": item._id, "dpt": "true", "sort": "priority", "order": "dsc", "per_page": per_page, "page": 1})
            for each pl in pls
                row.ContentList.push(CreatePlaylistObject(pl))
            end for
            m.videosList.push(row.ContentList)
        end if
        list.push(row)
    end for
	m.playlistRows = list
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
    m.purchasedItems = []
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
        if(isPlanPurchased(pi.code)) ' Means the user has subscribed to atleast one of these
            subscribed = true
            exit for
        end if
    end for
    return subscribed
End Function

' ///////////////////////////////////////////////////////////////////////////////////
' Check to see if the purchased product returned from roku store matches one of the
' subscription plans we have. Plan ID is being used as the roku product code here.
Function isPlanPurchased(code)
    plans = m.productsCatalog   ' Using this one instead of the above one to get products from Roku Store instead of Zype API
    isPurchased = false
    for each p in plans
        if(p.code = code)
            isPurchased = true
            exit for
        end if
    end for
    return isPurchased
End Function

'///////////////////////////////////
' LabelList click handlers go here
'///////////////////////////////////

Function handleButtonEvents(index, _isSubscribed, lclScreen)
    print "Handle Event: "; isSubscribed
    'if((isLoggedIn() AND _isSubscribed = true) OR lclScreen.content.subscriptionRequired = false)    ' Play / Favorite buttons
    if(m.detailsScreen.NoAuthenticationEnabled = true OR (m.detailsScreen.isLoggedIn = true AND m.detailsScreen.UniversalSubscriptionsCount > 0) OR lclScreen.content.subscriptionRequired = false OR m.detailsScreen.JustBoughtNativeSubscription = true OR m.detailsScreen.isLoggedInViaNativeSVOD = true)    ' Play / Favorite buttons
        print "Play/Favorite"
        m.detailsScreen.SubscriptionButtonsShown = false
        ' This is going to be the Play button
        'if(index = 1 and (_isSubscribed = true OR lclScreen.content.subscriptionRequired = false))
        if(index = 1)
        'if(index = 1 and _isSubscribed)
            ' m.VideoPlayer = lclScreen.findNode("VideoPlayer")
            m.detailsScreen.RemakeVideoPlayer = true
            m.VideoPlayer = m.detailsScreen.VideoPlayer


            m.VideoPlayer.seek = 0.00
            RemoveVideoIdForResumeFromReg(lclScreen.content.id)
            playVideoButton(lclScreen)

        else if(index = 2)  ' This is going to be the favorites button
            markFavoriteButton(lclScreen)
        else if(index = 3)  ' This is going to be the resume button from detail screen
            videoId = GetVideoIdForResumeFromReg(lclScreen.content.id)

            ' m.VideoPlayer = lclScreen.findNode("VideoPlayer")
            m.detailsScreen.RemakeVideoPlayer = true
            m.VideoPlayer = m.detailsScreen.VideoPlayer

            m.VideoPlayer.seek = videoId
            playVideoButton(lclScreen)        ' Resume button clicked

        end if

    else    ' Subscribe / Sign In buttons
        print "Subscribe/Device Linking"
        if(index = 1)   ' Subscribe

            ' Do an extra check if the device is linked and there was any new subscription on the server
            if(m.app.device_linking = true AND m.detailsScreen.isDeviceLinked = true)
                m.detailsScreen.DontShowSubscriptionPackages = true
                consumer = IsLinked({"linked_device_id": GetUdidFromReg(), "type": "roku"})

                'consumer.subscription_count = 1

                if(consumer.subscription_count > 0) ' There was a new subscription found
                    m.detailsScreen.isDeviceLinked = true
                    m.detailsScreen.UniversalSubscriptionsCount = consumer.subscription_count
                    m.detailsScreen.isLoggedIn = true
                    m.favorites.isLoggedIn = true
                    return false
                else
                    ' Find a way to show packages
                    m.detailsScreen.ShowSubscriptionPackagesCallback = true
                end if
            end if

            if(m.detailsScreen.SubscriptionPackagesShown = false)
                ' All subscription button code goes here
                m.detailsScreen.SubscriptionPackagesShown = true
                m.detailsScreen.ShowSubscriptionPackagesCallback = true
            else
                m.detailsScreen.SubscriptionPackagesShown = false
                ' First package was selected by the user. Start the wizard.
                StartLoader()
                result = startSubscriptionWizard(m.plans, index, m.store, m.port, m.productsCatalog)
                EndLoader()
                'm.detailsScreen.SubscriptionPackagesShown = false

                 if(result = true)
                     m.detailsScreen.JustBoughtNativeSubscription = true
                     m.detailsScreen.isLoggedIn = true
                     m.favorites.isLoggedIn = true
                '     getUserPurchases()  ' Update the user purchased inventory
                 end if
            end if


        else            ' Device Linking
            m.detailsScreen.SubscriptionButtonsShown = true
            if(m.detailsScreen.SubscriptionPackagesShown = false)
                m.deviceLinking.show = true
                m.deviceLinking.setFocus(true)
            else
                StartLoader()
                result = startSubscriptionWizard(m.plans, index, m.store, m.port, m.productsCatalog)
                EndLoader()

                 if(result = true)
                    m.detailsScreen.JustBoughtNativeSubscription = true
                    m.detailsScreen.isLoggedIn = true
                    m.favorites.isLoggedIn = true
                 end if
            end if
        end if
    end if
End Function

Function StartLoader()
    m.LoadingScreen.show = true
    m.LoadingScreen.setFocus(true)
    m.loadingIndicator1.control = "start"
End Function

Function EndLoader()
    m.loadingIndicator1.control = "stop"
    m.LoadingScreen.show = false
    m.LoadingScreen.setFocus(false)
    m.detailsScreen.setFocus(true)
End Function

Function InitAuthenticationParams()

    ' Case 1: No Authentication
    if(m.app.device_linking = false AND m.app.in_app_purchase = false)
        m.detailsScreen.NoAuthenticationEnabled = true
        m.detailsScreen.OnlyNativeSVOD = false
        m.detailsScreen.BothActive = false

    ' Case 2: Only Native SVOD
    else if(m.app.device_linking = false AND m.app.in_app_purchase = true)
        m.detailsScreen.NoAuthenticationEnabled = false
        m.detailsScreen.OnlyNativeSVOD = true
        m.detailsScreen.BothActive = false

    ' Case 3: Both Native SVOD and Device Linking
    else if(m.app.device_linking = true AND m.app.in_app_purchase = true)
        m.detailsScreen.NoAuthenticationEnabled = false
        m.detailsScreen.OnlyNativeSVOD = false
        m.detailsScreen.BothActive = true

    end if

End Function

Function isLoggedIn()
    if(m.detailsScreen.NoAuthenticationEnabled = true)
        return true
    end if

    if(isAuthViaNativeSVOD())
        m.detailsScreen.isLoggedInViaNativeSVOD = true
        m.detailsScreen.isLoggedInViaUniversalSVOD = false
        return true
    else if (isAuthViaUniversalSVOD())
        m.detailsScreen.isLoggedInViaNativeSVOD = false
        m.detailsScreen.isLoggedInViaUniversalSVOD = true
        return true
    end if
    return false
End Function

Function playVideoButton(lclScreen)
    if lclScreen.content.onAir = false
        playRegularVideo(lclScreen)
    else
        playLiveVideo(lclScreen)
    end if
End Function

Function markFavoriteButton(lclScreen)
    print "lclScreen: ";lclScreen.content
    idParts = lclScreen.content.id.tokenize(":")
    id = idParts[0]
    deviceLinking = IsLinked({"linked_device_id": GetUdidFromReg(), "type": "roku"})
    'deviceLinking.linked = false
    if HasUDID() = true and deviceLinking.linked = true
        favs = GetFavoritesIDs()
        print "Consumer ID: "; deviceLinking.consumer_id
        oauth = GetAccessToken(GetApiConfigs().client_id, GetApiConfigs().client_secret, GetUdidFromReg(), GetPin(GetUdidFromReg()))
        if lclScreen.content.inFavorites = false
            print "CreateVideoFavorite"
            CreateVideoFavorite(deviceLinking.consumer_id, {"access_token": oauth.access_token, "video_id": id })
            lclScreen.content.inFavorites = true
        else
            print "DeleteVideoFavorite"
            DeleteVideoFavorite(deviceLinking.consumer_id, favs[id], {"access_token": oauth.access_token, "video_id": id, "_method": "delete"})
            lclScreen.content.inFavorites = false
        end if
    else
        ' Means device is not linked. Show a message dialog
        dialog = createObject("roSGNode", "Dialog")
        dialog.title = "Link Your Device"
        dialog.optionsDialog = true
        dialog.message = "Please link your device in order to add this video to favorites."
        dialog.buttons = ["OK"]
        m.scene.dialog = dialog
    end if
End Function

'////////////////////////////////////////////////////////////////////
'   Authentication Mechanisms
'////////////////////////////////////////////////////////////////////

'   Native SVOD - Check if user bought from native SVOD which is Roku Store
'   Need to check if there are bought subscriptions associated with Roku Account
Function isAuthViaNativeSVOD()
    subscribed = false
    for each pi in m.purchasedItems
        if(isPlanPurchased(pi.code)) ' Means the user has subscribed to atleast one of these
            subscribed = true
            exit for
        end if
    end for
    return subscribed
End Function

' ////////////////////////////////////////////////////////////////////////////////////////////////////////////
' Universal SVOD - Check via Device Linking if the API server returns a count that says user bought something
' Need to check device linking and subscription_count here.
Function isAuthViaUniversalSVOD()
    if(m.app.device_linking = false)
        return false
    end if

    deviceLinking = IsLinked({"linked_device_id": GetUdidFromReg(), "type": "roku"})
    m.detailsScreen.UniversalSubscriptionsCount = deviceLinking.subscription_count
    if(deviceLinking.linked = false)
        return false
    end if

    if(HasUDID() = true)
        return true
    end if

    return false
End Function

' ////////////////////////////////////////////////////////////////////////////////////////////////////////////
'   Accepts theme and brand_color values from source/config and stores values in global variable (accessible to all components under HomeScene)
'   Values are used to set component colors on initialization
'   Theme functions come from source/themes.brs
'
'   Themes accepts 3 values: "dark", "light" and "custom"
'     - If theme is none of those colors, components have the dark theme colors by default
'     - If set to "custom", the color values should be inside CustomTheme() in source/themes.brs
'
'   Brand color is string with a hex color, like so: "#FFFFFF"
Function SetTheme()
  theme = GetApiConfigs().theme
  brand_color = GetApiConfigs().brand_color

  if m.global <> invalid
    m.global.addFields({ brand_color: brand_color })

    if theme = "dark"
      m.global.addFields({ theme: DarkTheme() })
    else if theme = "light"
      m.global.addFields({ theme: LightTheme() })
    else if theme = "custom"
      m.global.addFields({ theme: DarkTheme() })
    end if
  end if
End Function
