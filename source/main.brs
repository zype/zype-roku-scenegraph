Library "Roku_Ads.brs"

' ********** Copyright 2016 Zype Inc.  All Rights Reserved. **********
Function Main (args as Dynamic) as Void
    if (args.ContentID <> invalid) and (args.MediaType <> invalid)
        if (args <> invalid)
            contentID   = args.contentID
            mediaType   = LCase(args.mediatype)
            SetHomeScene(contentID, mediaType)
        end if
    else
        SetHomeScene()
    end if
End Function

Sub SetHomeScene(contentID = invalid, mediaType = invalid)
    screen = CreateObject("roSGScreen")

    m.app = GetAppConfigs()

    m.global = screen.getGlobalNode()

    SetTheme()


    m.scene = screen.CreateScene("HomeScene")
    m.port = CreateObject("roMessagePort")
    screen.SetMessagePort(m.port)
    screen.Show()

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
    m.playlistRows = []
    m.videosList = []

    m.playlistsRowItemSizes = []
    m.playlistRowsSpacings = []

    'm.scene.gridContent = ParseContent(GetContent())
    m.contentID = contentID

    ' m.scene.gridContent = ParseContent(GetPlaylistsAsRows(m.app.featured_playlist_id))

    ' m.gridScreen = m.scene.findNode("GridScreen")

    ' print "gridContent: "; m.scene.gridContent
    ' print "m.playlistRows: "; m.playlistRows[0]

    getUserPurchases()
    getProductsCatalog()

    m.detailsScreen = m.scene.findNode("DetailsScreen")
    ' m.global.addFields({ HasNativeSubscription: false, isLoggedIn: false, UniversalSubscriptionsCount: 0 })
    ' _isLoggedIn = isLoggedIn()
    ' m.global.isLoggedIn = _isLoggedIn AND (m.detailsScreen.UniversalSubscriptionsCount > 0 OR m.detailsScreen.isLoggedInViaNativeSVOD = true)
    ' m.global.UniversalSubscriptionsCount = m.detailsScreen.UniversalSubscriptionsCount
    ' InitGlobalVars()
    print "m.global Before = "; m.global
    state_service = StateService(m.global)
    vars = state_service.InitGlobalVars()
    print "m.global After = "; m.global
    ' stop
    ' m.global = vars.global

    m.gridContent = ParseContent(GetPlaylistsAsRows(m.app.featured_playlist_id))
    m.scene.gridContent = m.gridContent

    m.plans = GetPlans({}, m.app.in_app_purchase, m.productsCatalog)

    m.Menu = m.scene.findNode("Menu")
    m.Menu.isDeviceLinkingEnabled = m.app.device_linking

    print "[Main] Init"

    m.infoScreen = m.scene.findNode("InfoScreen")
    m.infoScreenText = m.infoScreen.findNode("Info")
    m.infoScreenText.text = m.app.about_page

    m.search = m.scene.findNode("Search")
    m.searchDetailsScreen = m.search.findNode("SearchDetailsScreen")
    m.searchDetailsScreen.observeField("itemSelected", m.port)

    m.favorites = m.scene.findNode("Favorites")
    m.favorites.observeField("visible", m.port)

    m.favoritesDetailsScreen = m.favorites.findNode("FavoritesDetailsScreen")
    m.favoritesDetailsScreen.observeField("itemSelected", m.port)

    ' m.detailsScreen = m.scene.findNode("DetailsScreen")
    m.detailsScreen.observeField("itemSelected", m.port)
    'm.detailsScreen.SubscriptionPlans = m.plans
    'm.detailsScreen.SubscriptionPlans = m.productsCatalog
    m.detailsScreen.productsCatalog = m.productsCatalog
    m.detailsScreen.JustBoughtNativeSubscription = false
    ' m.detailsScreen.isLoggedIn = m.global.auth.isLoggedIn
    m.detailsScreen.observeField("triggerPlay", m.port)
    m.detailsScreen.dataArray = m.playlistRows

    m.scene.videoliststack = [m.videosList]
    m.detailsScreen.videosTree = m.scene.videoliststack.peek()
    m.detailsScreen.autoplay = m.app.autoplay

    if m.app.in_app_purchase or m.app.device_linking
      svod_enabled = true
    else
      svod_enabled = false
    end if

    current_consumer = currentConsumer()

    if isAuthViaNativeSVOD() or (current_consumer.linked and current_consumer.subscription_count > 0)
      is_subscribed = true
    else
      is_subscribed = false
    end if

    m.global.addFields({ svod_enabled: svod_enabled })
    m.global.addFields({ is_subscribed: is_subscribed })

    ' m.favorites.isLoggedIn = m.global.auth.isLoggedIn

    deviceLinked = IsLinked({"linked_device_id": GetUdidFromReg(), "type": "roku"}).linked
    m.detailsScreen.isDeviceLinked = deviceLinked

    ' print "m.detailsScreen.isLoggedIn: "; m.detailsScreen.isLoggedIn
    InitAuthenticationParams()


    m.scene.observeField("SearchString", m.port)

    m.gridScreen = m.scene.findNode("GridScreen")

    if contentID = invalid
      ' Keep loader spinning. App not done loading yet
      m.gridScreen.setFocus(false)
      m.loadingIndicator.control = "start"
    end if

    rowlist = m.gridScreen.findNode("RowList")
    rowlist.rowItemSize = m.playlistsRowItemSizes
    rowlist.rowSpacings = m.playlistRowsSpacings

    m.scene.observeField("playlistItemSelected", m.port)
    m.scene.observeField("TriggerDeviceUnlink", m.port)

    m.deviceLinking = m.scene.findNode("DeviceLinking")
    m.deviceLinking.DeviceLinkingURL = m.app.device_link_url
    m.deviceLinking.isDeviceLinked = deviceLinked
    m.deviceLinking.observeField("show", m.port)
    m.deviceLinking.observeField("itemSelected", m.port)

    m.raf_service = RafService()

    LoadLimitStream() ' Load LimitStream Object
    'print GetLimitStreamObject()

    'isAuthViaUniversalSVOD()

    startDate = CreateObject("roDateTime")

    ' Deep Linking
    if (contentID <> invalid)
        if mediaType <> "season" and mediaType <> "series"
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

            ' Start playing video if logged in or no monetization
            if m.global.auth.isLoggedIn = true OR (linkedVideo.subscription_required = false and linkedVideo.purchase_required = false)
              playVideo(m.detailsScreen, {"app_key": GetApiConfigs().app_key}, m.app.avod)
            end if
          end if

        else if mediaType = "season" or mediaType = "series"
          transitionToNestedPlaylist(contentID)
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

    if contentID = invalid
      ' Stop loader and refocus
      m.gridScreen.setFocus(true)
      m.loadingIndicator.control = "stop"
    end if

    print "App done loading"

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

                ' Get Playlist object from the platform
                playlistObject = GetPlaylists({ id: content.id })
                ' print "playlistObject: "; playlistObject[0]
                playlistThumbnailLayout = playlistObject[0].thumbnail_layout
                m.gridScreen.content = ParseContent(GetPlaylistsAsRows(content.id, playlistThumbnailLayout))

                rowlist = m.gridScreen.findNode("RowList")
                rowlist.rowItemSize = m.playlistsRowItemSizes
                rowlist.rowSpacings = m.playlistRowsSpacings

                rowlist.jumpToRowItem = [0,0]

                current_video_list_stack = m.scene.videoliststack
                current_video_list_stack.push(m.videosList)
                m.scene.videoliststack = current_video_list_stack

                m.detailsScreen.videosTree = m.scene.videoliststack.peek()

                m.loadingIndicator.control = "stop"
            else if msg.getNode() = "Favorites" and msg.getField() = "visible" and msg.getData() = true
                m.loadingIndicator.control = "start"
                m.scene.favoritesContent = ParseContent(GetFavoritesContent())
                m.loadingIndicator.control = "stop"
            else if msg.getField() = "SearchString"
                m.loadingIndicator.control = "start"
                SearchQuery(m.scene.SearchString)
                m.loadingIndicator.control = "stop"
            else if (msg.getNode() = "FavoritesDetailsScreen" or msg.getNode() = "SearchDetailsScreen" or msg.getNode() = "DetailsScreen") and msg.getField() = "itemSelected" then

                ' access component node content
                if msg.getNode() = "FavoritesDetailsScreen"
                    lclScreen = m.favoritesDetailsScreen
                else if msg.getNode() = "SearchDetailsScreen"
                    lclScreen = m.searchDetailsScreen
                else if msg.getNode() = "DetailsScreen"
                    lclScreen = m.detailsScreen
                end if

                index = msg.getData()

                handleButtonEvents(index, lclscreen)
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
                                id = m.videoPlayer.content.id
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

                                consumer = IsLinked({"linked_device_id": GetUdidFromReg(), "type": "roku"})
                                if consumer.linked then
                                    pin.text = "You are linked!"

                                    if consumer.subscription_count > 0 then m.global.is_subscribed = true

                                    m.detailsScreen.isDeviceLinked = true
                                    ' m.global.usvod.UniversalSubscriptionsCount = consumer.subscription_count

                                    global_usvod = m.global.usvod
                                    global_usvod.UniversalSubscriptionsCount = consumer.subscription_count
                                    m.global.setField("usvod", global_usvod)

                                    global_auth = m.global.auth
                                    global_auth.isLoggedIn = true
                                    global_auth.isLoggedInWithSubscription = true
                                    m.global.setField("auth", global_auth)

                                    m.detailsScreen.redrawContent = true
                                    ' m.favorites.isLoggedIn = true
                                    m.deviceLinking.isDeviceLinked = true
                                    m.deviceLinking.setUnlinkFocus = true

                                    ' m.global.isLoggedIn = true
                                    ' m.global.usvod.UniversalSubscriptionsCount = m.detailsScreen.UniversalSubscriptionsCount
                                    m.scene.gridContent = m.gridContent
                                    ' m.deviceLinking.show = true
                                    m.deviceLinking.setFocus(true)
                                    m.deviceLinking.setUnlinkFocus = true

                                    ' Deep linked
                                    if contentID <> invalid
                                        di = CreateObject("roDeviceInfo")
                                        ip_address = di.GetConnectionInfo().ip
                                        url = "http://" + ip_address + ":8060/keydown/back"
                                        MakePostRequest(url, {})
                                    end if

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

                            consumer = IsLinked({"linked_device_id": GetUdidFromReg(), "type": "roku"})
                            if consumer.linked = true
                                pin.text = "The device is linked"

                                if consumer.subscription_count > 0 then m.global.is_subscribed = true

                                m.detailsScreen.isDeviceLinked = true

                                global_usvod = m.global.usvod
                                global_usvod.UniversalSubscriptionsCount = consumer.subscription_count
                                m.global.setField("usvod", global_usvod)

                                global_auth = m.global.auth
                                global_auth.isLoggedIn = true
                                global_auth.isLoggedInWithSubscription = true
                                m.global.setField("auth", global_auth)

                                print "m.global.auth.isLoggedInWithSubscription:: "; m.global.auth.isLoggedInWithSubscription
                                m.scene.gridContent = m.gridContent
                                print "m.global.auth.isLoggedInWithSubscription::: "; m.global.auth.isLoggedInWithSubscription

                                m.detailsScreen.redrawContent = true
                                ' m.favorites.isLoggedIn = true
                                m.deviceLinking.isDeviceLinked = true
                                m.deviceLinking.setUnlinkFocus = true
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
                    m.global.is_subscribed = isLoggedIn()

                    m.scene.TriggerDeviceUnlink = false
                    m.deviceLinking.isDeviceLinked = false
                    m.detailsScreen.isDeviceLinked = false
                    ' m.global.auth.isLoggedIn = isLoggedIn()

                    global_auth = m.global.auth
                    global_auth.isLoggedIn = isLoggedIn()
                    global_auth.isLoggedInWithSubscription = false
                    m.global.setField("auth", global_auth)

                    m.detailsScreen.redrawContent = true
                    ' m.favorites.isLoggedIn = isLoggedIn()

                    ' m.global.isLoggedIn = false
                    ' m.global.UniversalSubscriptionsCount = m.detailsScreen.UniversalSubscriptionsCount
                    m.scene.gridContent = m.gridContent
                    ' m.deviceLinking.show = true
                    m.deviceLinking.setFocus(true)
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

function transitionToNestedPlaylist(id) as void
  m.scene.callFunc("AddCurrentPositionToTracker", invalid)
  m.scene.callFunc("PushContentIntoContentStack", m.gridScreen.content)
  m.scene.callFunc("PushScreenIntoScreenStack", m.gridScreen)

  m.gridScreen.playlistItemSelected = false

  m.gridScreen.content = ParseContent(GetPlaylistsAsRows(id))

  rowList = m.gridScreen.findNode("RowList")
  rowlist.jumpToRowItem = [0,0]

  current_video_list_stack = m.scene.videoliststack
  current_video_list_stack.push(m.videosList)
  m.scene.videoliststack = current_video_list_stack

  m.detailsScreen.videosTree = m.scene.videoliststack.peek()
end function

' Play button should only appear in the following scenarios:
'     1- No subscription required for video
'     2- NSVOD only and user has already purchased a native subscription
'     3- Both NSVOD and USVOD. User either purchased a native subscription or is linked
sub playRegularVideo(screen as Object)
    print "PLAY REGULAR VIDEO"
    di = CreateObject("roDeviceInfo")
    consumer = IsLinked({"linked_device_id": GetUdidFromReg(), "type": "roku"})
        if consumer.subscription_count <> invalid and consumer.subscription_count > 0
          oauth = GetAccessToken(GetApiConfigs().client_id, GetApiConfigs().client_secret, GetUdidFromReg(), GetPin(GetUdidFromReg()))
          auth = {"access_token": oauth.access_token, "uuid": di.GetDeviceUniqueId()}
        else
          auth = {"app_key": GetApiConfigs().app_key, "uuid": di.GetDeviceUniqueId()}
        end if

        playVideo(screen, auth, m.app.avod)
end sub

sub playVideo(screen as Object, auth As Object, adsEnabled = false)
	playerInfo = GetPlayerInfo(screen.content.id, auth)

    screen.content.stream = playerInfo.stream
    screen.content.streamFormat = playerInfo.streamFormat
    screen.content.url = playerInfo.url

    video_service = VideoService()

	' If video source is not available
    if(screen.content.streamFormat = "(null)")
      CloseVideoPlayer()
      CreateVideoUnavailableDialog()
    else
		PrepareVideoPlayerWithSubtitles(screen, playerInfo.subtitles.count() > 0, playerInfo)
		playContent = true

		if(adsEnabled)
			no_ads = (m.global.swaf and m.global.is_subscribed)
			ads = video_service.PrepareAds(playerInfo, no_ads)

      if screen.content.onAir = true then ads.midroll = []

			m.loadingIndicator.control = "stop"

			' preroll ad
			if ads.preroll <> invalid
			  playContent = m.raf_service.playAds(playerInfo.video, ads.preroll.url)
			end if
		end if

		' Start playing video
		if playContent then
			m.loadingIndicator.control = "stop"
			print "[Main] Playing video"

      ' if live stream, set position at end of stream
      ' roku video player does not automatically detect if live stream
      if screen.content.onAir = true
        m.videoPlayer.content.live = true
        m.videoPlayer.content.playStart = 100000000000
      end if

			m.videoPlayer.visible = true
			screen.videoPlayerVisible = true

			if m.LoadingScreen.visible = true
			  EndLoader()
			end if

			m.videoPlayer.setFocus(true)
			m.videoPlayer.control = "play"

			sleep(500)
			' If midroll ads exist, watch for midroll ads
			if adsEnabled AND ads.midroll.count() > 0
				AttachMidrollAds(ads.midroll, playerInfo)
			end if ' end of midroll ad if statement
		else
		  CloseVideoPlayer()
		end if ' end of if playContent
    end if
end sub

sub PrepareVideoPlayerWithSubtitles(screen, subtitleEnabled, playerInfo)
	' show loading indicator before requesting ad and playing video
	m.loadingIndicator.control = "start"
	m.on_air = screen.content.onAir

	m.VideoPlayer = screen.VideoPlayer
	m.VideoPlayer.observeField("position", m.port)
	m.videoPlayer.content = screen.content

  video_service = VideoService()

	if subtitleEnabled
	  m.videoPlayer.content.subtitleTracks = video_service.GetSubtitles(playerInfo)
	else
	  m.videoPlayer.content.subtitleTracks = []
	end if

	m.VideoPlayer.seek = m.VideoPlayer.seek
end sub

sub AttachMidrollAds(midroll_ads, playerInfo)
	while midroll_ads.count() > 0
		currPos = m.videoPlayer.position

		timeDiff = Abs(midroll_ads[0].offset - currPos)
		print "Next midroll ad: "; midroll_ads[0].offset
		print "Time until next midroll ad: "; timeDiff

		' Within half second of next midroll ad timing
		if timeDiff <= 0.500
		  m.videoPlayer.control = "stop"

		  m.raf_service.playAds(playerInfo.video, midroll_ads[0].url)

		  ' Remove midroll ad from array
		  midroll_ads.shift()

		  ' Start playing video at back from currPos just before midroll ad started
		  m.videoPlayer.seek = currPos
		  m.videoPlayer.control = "play"

		' In case they fast forwarded or resumed watching, remove unnecessary midroll ads
		' Keep removing the first midroll ad in array until no midroll ads before current position
		else if midroll_ads.count() > 0 and currPos > midroll_ads[0].offset
		  while midroll_ads.count() > 0 and currPos > midroll_ads[0].offset
			midroll_ads.shift()
		  end while
		else if m.videoPlayer.visible = false
		  m.videoPlayer.control = "none"
		  exit while
		end if

	end while ' end of midroll ad loop
end sub

sub CloseVideoPlayer()
  m.detailsScreen.videoPlayer.visible = false
  m.detailsScreen.videoPlayer.setFocus(false)

  if m.LoadingScreen.visible = true
    EndLoader()
  end if

  m.detailsScreen.visible = true
  m.detailsScreen.setFocus(true)
end sub

sub CreateVideoUnavailableDialog()
  dialog = createObject("roSGNode", "Dialog")
  dialog.title = "Error!"
  dialog.optionsDialog = true
  dialog.message = "We're sorry, that video is no longer available. Please try another video."
  dialog.buttons = ["OK"]
  dialog.focusButton = 0
  m.scene.dialog = dialog
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
        video.playlist_id = 0
        video.playlist_name = invalid
        video.video_index = video_index
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

            ' Get the ID element from itemAA and check if the product against that id was subscribed
            ' if(isSubscribed(itemAA["subscriptionrequired"]))
            '     isSub = "True"
            ' else
            '     isSub = "False"
            ' end if

            ' item["id"] = item["id"] + ":" + isSub

            row.appendChild(item)
        end for

        RowItems.appendChild(row)
    end for

    return RowItems
End Function

Function GetContent()
    rowTitles = GetCategory(m.app.category_id).values
    categoryTitle = GetCategory(m.app.category_id).title
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
            videos.push(CreateVideoObject(video))
            video_index = video_index + 1
        end for

        row.ContentList = videos
        list.push(row)
    end for

    return list
End Function

function GetPlaylistContent(playlist_id as String)
    ' playlist_id = playlist_id.tokenize(":")[0]
    pl = GetPlaylists({"id": playlist_id})[0]

    favs = GetFavoritesIDs()

    if pl.playlist_item_count > 0 then
        list = []
        row = {}
        row.title = pl.title
        videos = []
        video_index = 0
        for each video in GetPlaylistVideos(pl._id, {"dpt": "true", "per_page": m.app.per_page})
            video.inFavorites = favs.DoesExist(video._id)
            video.playlist_id = 0
            video.playlist_name = invalid
            video.video_index = video_index

            if pl.thumbnail_layout = "poster"
              video.usePoster = true
            else
              video.usePoster = false
            end if

            videos.push(CreateVideoObject(video))
            video_index = video_index + 1
        end for
        row.ContentList = videos

        list.push(row)
        m.videosList.push(videos)
        return list
    else
        return GetContentPlaylists(pl._id)
    end if
end function

function GetContentPlaylists(parent_id as String)
    ' parent_id = parent_id.tokenize(":")[0]
    if m.app.per_page <> invalid
      per_page = m.app.per_page
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

function GetPlaylistsAsRows(parent_id as String, thumbnail_layout = "")
    m.videosList = []

    ' parent_id = parent_id.tokenize(":")[0]
    if m.app.per_page <> invalid
      per_page = m.app.per_page
    else
      per_page = 500
    end if

    m.playlistsRowItemSizes = []
    m.playlistRowsSpacings = []

    rawPlaylists = GetPlaylists({"parent_id": parent_id, "dpt": "true", "sort": "priority", "order": "dsc", "per_page": per_page, "page": 1})

    favs = GetFavoritesIDs()

    ' the case where the playlist does not have any more children. that means it is a video playlist
    if rawPlaylists.count() = 0
      'if parent_id = "59496bec60caab12fa007821" OR parent_id = "594bde3af273a31371000480"
      if thumbnail_layout = "poster"
        m.playlistsRowItemSizes.push( [ 147, 262 ] )
        m.playlistrowsSpacings.push( 50 )
      else
        m.playlistsRowItemSizes.push( [ 262, 147 ] )
        m.playlistrowsSpacings.push( 0 )
      end if

      return GetPlaylistContent(parent_id)
    end if

    list = []
    for each item in rawPlaylists
        row = {}
        row.title = item.title
        row.ContentList = []
        if item.playlist_item_count > 0
            row.ContentList = []
            videos = []

            if item.thumbnail_layout = "poster"
              m.playlistsRowItemSizes.push( [ 147, 262 ] )
              m.playlistrowsSpacings.push( 50 )
            else
              m.playlistsRowItemSizes.push( [ 262, 147 ] )
              m.playlistrowsSpacings.push( 0 )
            end if

            video_index = 0
            for each video in GetPlaylistVideos(item._id, {"per_page": m.app.per_page})
                if item.thumbnail_layout = "poster"
                  video.usePoster = true
                else
                  video.usePoster = false
                end if

                video.inFavorites = favs.DoesExist(video._id)
                video.playlist_id = item._id
                video.playlist_name = item.title
                video.video_index = video_index
                videos.push(CreateVideoObject(video))
                video_index = video_index + 1
            end for
            row.ContentList = videos
            m.videosList.push(videos)
        else
            m.playlistsRowItemSizes.push( [ 262, 147 ] )
            m.playlistrowsSpacings.push( 0 )

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
function handleButtonEvents(index, screen)
    button_role = screen.itemSelectedRole

    if button_role = "play"
      RemakeVideoPlayer()
      m.VideoPlayer = m.detailsScreen.VideoPlayer

      m.VideoPlayer.seek = 0.00
      RemoveVideoIdForResumeFromReg(screen.content.id)
      playRegularVideo(screen)
    else if button_role = "resume"
      resume_time = GetVideoIdForResumeFromReg(screen.content.id)
      RemakeVideoPlayer()

      m.VideoPlayer = m.detailsScreen.VideoPlayer
      m.VideoPlayer.seek = resume_time
      playRegularVideo(screen)
    else if button_role = "favorite"
      markFavoriteButton(screen)
    else if button_role = "subscribe"
      consumer = IsLinked({"linked_device_id": GetUdidFromReg(), "type": "roku"})
      if m.app.device_linking and consumer.linked and consumer.subscription_count > 0
        print "role subscribe if"
        m.detailsScreen.DontShowSubscriptionPackages = true
        m.detailsScreen.isDeviceLinked = true

        global_usvod = m.global.usvod
        global_usvod.UniversalSubscriptionsCount = consumer.subscription_count
        m.global.setField("usvod", global_usvod)

        global_auth = m.global.auth
        global_auth.isLoggedIn = true
        m.global.setField("auth", global_auth)

        ' m.detailsScreen.isLoggedIn = true
        ' m.favorites.isLoggedIn = true
      else
        print "role subscribe else"
        m.detailsScreen.ShowSubscriptionPackagesCallback = true
      end if

    else if button_role = "swaf"
      ' Add "Subscribe" and "Link Device"
      m.detailsScreen.ShowSubscribeButtons = true
    else if button_role = "native_sub"
      StartLoader()
      result = startSubscriptionWizard(m.plans, index, m.store, m.port, m.productsCatalog)
      EndLoader()

       if(result = true)
            print "m.global: "; m.global
            print "m.global.auth1: "; m.global.auth
            m.global.is_subscribed = true
            '   m.global.auth.isLoggedIn = true
            global_auth = m.global.auth
            global_auth.isLoggedIn = true
            global_auth.isLoggedInWithSubscription = true
            m.global.setField("auth", global_auth)

            global_nsvod = m.global.nsvod
            global_nsvod.HasNativeSubscription = true
            m.global.setField("nsvod", global_nsvod)
            ' m.global.nsvod.HasNativeSubscription = true
            print "m.global: "; m.global
            print "m.global.auth2: "; m.global.auth


            m.detailsScreen.JustBoughtNativeSubscription = true
            m.detailsScreen.redrawContent = true
            ' m.favorites.isLoggedIn = true
            m.scene.gridContent = m.gridContent
            m.detailsScreen.setFocus(true)
            m.detailsScreen.ReFocusButtons = true
            print "m.global.auth3: "; m.global.auth
       end if
    else if button_role = "device_linking"
      m.deviceLinking.show = true
      m.deviceLinking.setFocus(true)
    end if
end function

' Seting details screen's RemakeVideoPlayer value to true recreates Video component
'     Roku Video component performance degrades significantly after multiple uses, so we make a new one
function RemakeVideoPlayer() as void
    m.detailsScreen.RemakeVideoPlayer = true
end function

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
    ' print "inside isLoggedIn"
    if(m.detailsScreen.NoAuthenticationEnabled = true)
        return true
    end if

    if(isAuthViaNativeSVOD())
        m.global.nsvod.isLoggedInViaNativeSVOD = true
        ' m.global.usvod.isLoggedInViaUniversalSVOD = false

        global_nsvod = m.global.nsvod
        global_nsvod.isLoggedInViaNativeSVOD = true
        global_nsvod.HasNativeSubscription = true
        m.global.setField("nsvod", global_nsvod)

        global_usvod = m.global.usvod
        global_usvod.isLoggedInViaUniversalSVOD = false
        m.global.setField("usvod", global_usvod)

        ' m.global.nsvod.HasNativeSubscription = true
        ' print "isAuthViaNativeSVOD"
        return true
    else if (isAuthViaUniversalSVOD())
        ' m.global.nsvod.isLoggedInViaNativeSVOD = false
        ' m.global.usvod.isLoggedInViaUniversalSVOD = true

        global_nsvod = m.global.nsvod
        global_nsvod.isLoggedInViaNativeSVOD = false
        m.global.setField("nsvod", global_nsvod)

        global_usvod = m.global.usvod
        global_usvod.isLoggedInViaUniversalSVOD = true
        m.global.setField("usvod", global_usvod)

        ' print "isAuthViaUniversalSVOD"
        return true
    end if
    ' print "leaving isLoggedIn"
    return false
End Function

Function markFavoriteButton(lclScreen)
    ' idParts = lclScreen.content.id.tokenize(":")
    ' id = idParts[0]
    id = lclScreen.content.id
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
    ' print "inside isAuthViaNativeSVOD function"
    subscribed = false
    for each pi in m.purchasedItems
        ' print "pi: "; pi
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
    ' m.detailsScreen.UniversalSubscriptionsCount = deviceLinking.subscription_count
    print "m.global: "; m.global
    ' m.global.usvod.UniversalSubscriptionsCount = deviceLinking.subscription_count

    global_usvod = m.global.usvod
    global_usvod.UniversalSubscriptionsCount = deviceLinking.subscription_count
    m.global.setField("usvod", global_usvod)

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

  if m.app.theme <> invalid
    theme = m.app.theme
  else
    theme = m.app.theme
  end if

  if m.app.brand_color <> invalid
    brand_color = m.app.brand_color
  else
    brand_color = m.app.brand_color
  end if

  if m.global <> invalid
    m.global.addFields({ brand_color: brand_color })
    m.global.addFields({ enable_lock_icons: GetApiConfigs().enable_lock_icons })
    m.global.addFields({ swaf: GetApiConfigs().subscribe_to_watch_ad_free })

    if theme = "dark"
      m.global.addFields({ theme: DarkTheme() })
    else if theme = "light"
      m.global.addFields({ theme: LightTheme() })
    else if theme = "custom"
      m.global.addFields({ theme: DarkTheme() })
    end if
  end if
End Function
