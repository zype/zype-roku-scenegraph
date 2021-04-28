Library "Roku_Ads.brs"

' ********** Copyright 2016 Zype Inc.  All Rights Reserved. **********
Function Main (args as Dynamic) as Void
    m.appStartSource = args.source
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

function SetHomeScene(contentID = invalid, mediaType = invalid)
    screen = CreateObject("roSGScreen")

    m.app = GetAppConfigs()

    if (m.app <> invalid AND (m.app.count() = 0 OR m.app.theme = invalid OR m.app.theme = ""))
      m.scene = screen.CreateScene("DummyScene")
      m.port = CreateObject("roMessagePort")
      screen.SetMessagePort(m.port)
      screen.Show()
      m.scene.observeField("outRequest", m.port)
      while(true)
          msg = wait(0, m.port)
          msgType = type(msg)

          if msgType = "roSGScreenEvent"
              if msg.isScreenClosed() then return ""
          else if msgType = "roSGNodeEvent"
              print "msgType : " msgType
              print "msg.GetField() : " msg.GetField()
              ' When The AppManager want to send command back to Main
              if (msg.GetField() = "outRequest")
                  request = msg.GetData()
                  if (request <> invalid)
                    print "Request : " request
                      if (request.DoesExist("ExitApp") AND (request.ExitApp = true))
                          print "ExitApp :  Closing Screen."
                          screen.close()
                      end if
                  end if
              end if
          end if
      end while
    end if

    m.global = screen.getGlobalNode()

    m.current_user = CurrentUser()

    ' if RegReadAccessToken() <> invalid
    '   if m.current_user.isLinked() then GetAndSaveNewToken("device_linking") else GetAndSaveNewToken("login")
    ' end if

    ' Disabled for now : in future we can enable this when fully supporting SSO'
    ' store = CreateObject("roChannelStore")
    ' storedCreds = store.GetChannelCred()
    ' if storedCreds.channelID <> "dev"
    '   if storedCreds.json <> invalid and storedCreds.json <> ""
    '     data = ParseJSON(storedCreds.json)
    '     if data <> invalid and data.channel_data <> invalid and data.channel_data <> ""
    '       channelData = ParseJSON(data.channel_data)
    '       refreshTokenParams = {
    '         "client_id": GetApiConfigs().client_id,
    '         "client_secret": GetApiConfigs().client_secret,
    '         "refresh_token": channelData.refresh_token,
    '         "grant_type": "refresh_token"
    '       }
    '
    '       ' Refresh token and store new oauth tokens
    '       refreshTokenResp = RefreshToken(refreshTokenParams)
    '       if refreshTokenResp <> invalid
    '         RegWriteAccessToken(refreshTokenResp)
    '         newCreds = {
    '           "access_token": refreshTokenResp.access_token
    '           "refresh_token": refreshTokenResp.refresh_token
    '         }
    '
    '         ' Save udid for unlinking device on logout
    '         if channelData.udid <> invalid and channelData.udid <> "" and channelData.udid <> "Invalid"
    '           newCreds["udid"] = channelData.udid
    '           RemoveUdidFromReg()
    '           AddUdidToReg(channelData.udid)
    '         end if
    '
    '         store.StoreChannelCredData(FormatJson(newCreds))
    '       end if
    '     else
    '       LogOut()
    '       isDeviceLinked = IsLinked({"linked_device_id": GetUdidFromReg(), "type": "roku"})
    '       if isDeviceLinked <> invalid and isDeviceLinked.linked = true
    '         res = UnlinkDevice(isDeviceLinked.consumer_id, isDeviceLinked.pin, {})
    '         RemoveUdidFromReg()
    '       end if
    '       store.StoreChannelCredData("") ' clear out Universal SSO data
    '     end if
    '   end if
    ' end if

    m.favorites_storage_service = FavoritesStorageService()
    m.favorites_management_service = FavoritesManagementService()

    SetTheme()
    SetFeatures()
    SetMonetizationSettings()
    SetVersion()
    SetTextLabels()

    m.scene = screen.CreateScene("HomeScene")
    m.port = CreateObject("roMessagePort")

    print "m.app.theme::: " m.app.theme

    if m.app.theme = "dark"
       theme=DarkTheme()
    else if m.app.theme = "light"
      theme=LightTheme()
    else if m.app.theme = "custom"
      theme=CustomTheme()
    end if

    m.scene.backgroundColor=theme.background_color

    inputObject = CreateObject("roInput")
    inputObject.SetMessagePort(m.port)

    screen.SetMessagePort(m.port)
    screen.Show()

    m.TestInfoScreen = m.scene.findNode("TestInfoScreen")

    m.store = CreateObject("roChannelStore")

    m.channelStore =  m.scene.channelStore

    '' m.store.FakeServer(true)
    m.store.SetMessagePort(m.port)
    m.purchasedItems = []
    m.productsCatalog = []
    m.playlistRows = []
    m.videosList = []

    ' Set up services
    m.roku_store_service = RokuStoreService(m.store, m.channelStore, m.port)
    m.auth_state_service = AuthStateService()
    m.bifrost_service = BiFrostService()
    m.raf_service = RafService()
    m.marketplaceConnect = MarketplaceConnectService()

    m.native_email_storage =  NativeEmailStorageService()

    SetGlobalAuthObject()
    m.akamai_service = AkamaiService()
    m.mediamelon_service = MediaMelonService()
    m.google_analytics_service = GoogleAnalyticsService()

    m.LoadingScreen = m.scene.findNode("LoadingScreen")

    m.loadingIndicator = m.scene.loadingIndicator
    m.loadingIndicator1 = m.scene.findNode("loadingIndicator1")

    ' HB: sending app launch trigger from here
    m.scene.sentLaunchCompleteEvent = true

    ' Google Analytics'
    if(m.global.google_analytics_enable = true)
        params = {
          category: "AppStart"
          action: m.appStartSource
        }
        customParams = {
          siteId: m.app.site_id
          deviceId: m.global.UATracker.cid
        }
        m.google_analytics_service.SendGATrackEvent(params, customParams)
    end if

    print "1=============================================================================================================================>"

    m.playlistsRowItemSizes = []
    m.playlistRowsSpacings = []


    m.contentID = contentID
    ' Start loader if deep linked
    if m.contentID <> invalid
      EndLoader()
      StartLoadingScreen()
    end if

    m.detailsScreen = m.scene.findNode("DetailsScreen")

    'm.scene.gridContent = ParseContent(GetContent()) ' Uses featured categories (depreciated)
    m.gridContent = ParseContent(GetPlaylistsAsRows(m.app.featured_playlist_id))
    m.gridScreen = m.scene.findNode("GridScreen")
    rowlist = m.gridScreen.findNode("RowList")
    rowlist.rowItemSize = m.playlistsRowItemSizes
    rowlist.rowSpacings = m.playlistRowsSpacings

    m.scene.InitialAutoPlay = false

    autoPlayHero = LoadAutoPlayHero()
    'print "autoPlayHero :: " autoPlayHero[0]
    for each item in autoPlayHero
        if item.active and item.zobject_type_title = "autoplay_hero"
          m.scene.IsShowAutoPlayBackground = true
          exit for
        end if
    end for

    if m.contentID = invalid
      ' Keep loader spinning. App not done loading yet
      ' m.gridScreen.setFocus(false)
       StartLoader()
    end if

    m.Menu = m.scene.findNode("Menu")
    m.Menu.isRefreshMenu = m.global.marketplace_connect_svod or m.global.auth.isLoggedIn or m.app.device_linking

    print "[Main] Init"

    m.infoScreen = m.scene.findNode("InfoScreen")
    m.infoScreenText = m.infoScreen.findNode("Info")
    m.infoScreenText.text = m.app.about_page

    m.epgScreen = m.scene.findNode("EPGScreen")
    m.epgScreen.observeField("startStream", m.port)

    m.search = m.scene.findNode("Search")
    m.searchDetailsScreen = m.search.findNode("SearchDetailsScreen")
    m.searchDetailsScreen.observeField("itemSelected", m.port)

    m.favorites = m.scene.findNode("Favorites")
    m.favorites.observeField("visible", m.port)

    m.favoritesDetailsScreen = m.favorites.findNode("FavoritesDetailsScreen")
    m.favoritesDetailsScreen.observeField("itemSelected", m.port)

    m.detailsScreen.observeField("itemSelected", m.port)
    m.detailsScreen.productsCatalog = m.productsCatalog
    m.detailsScreen.observeField("triggerPlay", m.port)
    m.detailsScreen.dataArray = m.playlistRows

    m.scene.videoliststack = [m.videosList]
    m.scene.ObserveField("carouselSelectData",m.port)
    m.scene.ObserveField("setPurchasePlan",m.port)

    m.detailsScreen.videosTree = m.scene.videoliststack.peek()
    m.detailsScreen.autoplay = m.app.autoplay

    m.AuthSelection = m.scene.findNode("AuthSelection")
    m.AccountScreen = m.scene.findNode("AccountScreen")

    ' TODO: Add logic here to filter native plans by matching marketplace connect ids
    ' rokuPlans = m.roku_store_service.GetNativeSubscriptionPlans()
    ' filteredPlans = m.marketplaceConnect.getSubscriptionPlans(rokuPlans)
    ' m.AuthSelection.plans = filteredPlans

    print "marketplace_connect_svod----------------> " m.global.marketplace_connect_svod
    print "subscription_plan_ids----------------> " m.global.subscription_plan_ids

    if (m.global.marketplace_connect_svod = true AND m.global.subscription_plan_ids <> invalid AND m.global.subscription_plan_ids.count() > 0)
      setUpPurchasePlan()
    else
      m.AuthSelection.plans = m.roku_store_service.GetNativeSubscriptionPlans()
	    m.AccountScreen.plans = m.roku_store_service.GetNativeSubscriptionPlans()
    end if

    m.AuthSelection.observeField("itemSelected", m.port)
    m.AuthSelection.observeField("currentPlanSelected", m.port)
    m.AuthSelection.observeField("thankYouCloseSelected", m.port)


    m.AccountScreen.observeField("oAuthItemSelected", m.port)
    m.AccountScreen.observeField("signInItemSelected", m.port)
    m.AccountScreen.observeField("currentPlanSelected", m.port)

    m.PurchaseScreen = m.scene.findNode("PurchaseScreen")
    m.PurchaseScreen.observeField("itemSelected", m.port)
    m.PurchaseScreen.observeField("purchaseButtonSelected", m.port)

    m.MyLibrary = m.scene.findNode("MyLibrary")
    m.MyLibrary.observeField("visible", m.port)
    m.MyLibrary.observeField("paginatorSelected", m.port)

    m.MyLibraryDetailsScreen = m.MyLibrary.findNode("MyLibraryDetailsScreen")
    m.MyLibraryDetailsScreen.observeField("itemSelected", m.port)

    m.my_library_content = []

    m.UniversalAuthSelection = m.scene.findNode("UniversalAuthSelection")
    m.UniversalAuthSelection.observeField("itemSelected", m.port)

    m.SignInScreen = m.scene.findNode("SignInScreen")
    m.SignInScreen.isSignup = false
    m.SignInScreen.header = m.global.labels.sign_in_screen_header
    m.SignInScreen.helperMessage = m.global.labels.sign_in_helper_message
    m.SignInScreen.submitButtonText = m.global.labels.sign_in_submit_button
    m.SignInScreen.observeField("itemSelected", m.port)

    m.RegistrationScreen = m.scene.findNode("RegistrationScreen")
    m.RegistrationScreen.observeField("itemSelected", m.port)

    m.SignUpScreen = m.scene.findNode("SignUpScreen")
    m.SignUpScreen.isSignup = true
    m.SignUpScreen.header = m.global.labels.sign_up_screen_header
    m.SignUpScreen.helperMessage = m.global.labels.sign_up_helper_message
    m.SignUpScreen.submitButtonText = m.global.labels.sign_up_submit_button
    m.SignUpScreen.observeField("itemSelected", m.port)

    m.scene.observeField("SearchString", m.port)

    m.scene.observeField("playlistItemSelected", m.port)
    m.scene.observeField("TriggerDeviceUnlink", m.port)

    user_info = m.current_user.getInfo()

    m.deviceLinking = m.scene.findNode("DeviceLinking")
    m.deviceLinking.DeviceLinkingURL = m.app.device_link_url
    m.deviceLinking.isDeviceLinked = user_info.linked
    m.deviceLinking.observeField("show", m.port)
    m.deviceLinking.observeField("itemSelected", m.port)

    LoadLimitStream() ' Load LimitStream Object

    fav_ids = GetFavoritesIDs()
    m.favorites_management_service.setFavoriteIds(fav_ids)

    startDate = CreateObject("roDateTime")

    ' Deep Linking
    if (m.contentID <> invalid)
        HandleDeeplinkEvent(m.contentID, mediaType, false)
    end if

    heroCarousels = LoadHeroCarousels()
    if heroCarousels <> invalid
        m.gridScreen.heroCarouselShow=true
        m.gridScreen.heroCarouselAllowedToShow=true
        m.scene.heroCarouselData = heroCarousels
    else
        m.gridScreen.heroCarouselShow=false
        m.gridScreen.heroCarouselAllowedToShow=false
    end if

    m.scene.gridContent = m.gridContent

    if m.contentID = invalid
      ' Stop loader and refocus
      m.gridScreen.setFocus(true)
      EndLoader()
      if m.global.enable_top_navigation = true then
          m.scene.callFunc("ShowMenuAndStartHideMenuTimer")
      end if
    end if

    'autoPlayHero = LoadAutoPlayHero()
    'print "autoPlayHero :: " autoPlayHero[0]
    if autoPlayHero <> invalid then
	    for each item in autoPlayHero
	        if item.active and item.zobject_type_title = "autoplay_hero"

	            'append message
	            appInfo = CreateObject("roAppInfo")
	            'appTitle = appInfo.GetTitle()

	            autoplayMessage           = createObject("RoSGNode", "Label")
	            autoplayMessage.id        = "autoplayMessage"
	            autoplayMessage.color     = "#FFFFFF"
	            autoplayMessage.wrap      = true
	            autoplayMessage.text      = m.global.labels.autoplay_message '.Replace("<app title>",appTitle)
	            autoplayMessage.width     = 1280
	            autoplayMessage.maxLines  = 2
	            autoplayMessage.lineSpacing = "0"
	            autoplayMessage.font = CreateObject("roSGNode", "Font")
	            autoplayMessage.font.uri = "pkg:/fonts/Roboto-Regular.ttf"
	            autoplayMessage.font.size = 22
	            autoplayMessage.translation = [0, 620]
	            autoplayMessage.horizAlign = "center"
	            autoplayMessage.visible = false

	            m.scene.appendChild(autoplayMessage)
	            'm.scene.autoplaytimer = 1

	                StartLoadingScreen()
	            linkedVideoObject=CreateVideoObject(GetVideo(item.videoid))
	            auth1 = getAuth(linkedVideoObject)

	            content = createObject("RoSGNode","VideoNode")
	            content.setFields(linkedVideoObject)
	            m.scene.IsShowAutoPlayBackground = false
	            m.scene.InitialAutoPlay = true
	            playVideo(m.gridScreen, auth1, m.app.avod, content)
	                EndLoader()

	            exit for
	        end if
	    end for
    end if

    print "App done loading=============================================================================================================================>"
    ' HB: Actually we have finished all loading here
    ' m.scene.sentLaunchCompleteEvent = true

    m.scene.observeField("outRequest", m.port)

    while(true)
        msg = wait(0, m.port)
        msgType = type(msg)

        if msgType = "roSGNodeEvent"
            print "msg.getField(): "; msg.getField()
            print "msg.getData(): "; msg.getData()
            print "msg.getNode(): "; msg.getNode()
            ' When The AppManager want to send command back to Main
            if (msg.GetField() = "outRequest")
                request = msg.GetData()
                if (request <> invalid)
                  	print "Request : " request
                    if (request.DoesExist("ExitApp") AND (request.ExitApp = true))
                        print "ExitApp :  Closing Screen."
                        screen.close()
                    end if
                end if
            else if m.app.autoplay = true AND msg.getField() = "triggerPlay" AND msg.getData() = true then
              RemakeVideoPlayer(m.detailsScreen)
              RemoveVideoIdForResumeFromReg(m.detailsScreen.content.id)
              m.akamai_service.setPlayStartedOnce(true)
              playRegularVideo(m.detailsScreen)
            else if msg.getField()="carouselSelectData" then
                if msg.GetData()<>invalid
                    if msg.GetData().autoplay=invalid or msg.GetData().autoplay=false
                        if msg.GetData().videoid<>invalid
                            StartLoader()
                            m.gridScreen.visible = false
                            m.detailsScreen.autoplay = false
                            linkedVideoNode = createObject("roSGNode", "VideoNode")
                            linkedVideoObject=CreateVideoObject(GetVideo(msg.GetData().videoid))
                            for each key in linkedVideoObject
                                linkedVideoNode[key] = linkedVideoObject[key]
                            end for
                            m.scene.DeepLinkToDetailPage = linkedVideoNode
                            EndLoader()
                        else if msg.GetData().playlistid<>invalid
                            StartLoader()
                            m.gridScreen.playlistItemSelected = false
                            content = m.gridScreen.focusedContent

                            ' Get Playlist object from the platform

                            playlists = GetPlaylists({ id: msg.GetData().playlistid })
                            validPlaylist = (playlists.count() > 0 and playlists[0].active)
                            if (validPlaylist = true)
                                playlistThumbnailLayout = playlists[0].thumbnail_layout
                                m.gridScreen.content = ParseContent(GetPlaylistsAsRows(msg.GetData().playlistid, playlistThumbnailLayout))
                                m.gridContent = m.gridScreen.content
                                rowlist = m.gridScreen.findNode("RowList")
                                rowlist.rowItemSize = m.playlistsRowItemSizes
                                rowlist.rowSpacings = m.playlistRowsSpacings

                                rowlist.jumpToRowItem = [0,0]

                                m.scene.gridContent = m.gridContent

                                current_video_list_stack = m.scene.videoliststack
                                current_video_list_stack.push(m.videosList)
                                m.scene.videoliststack = current_video_list_stack

                                m.detailsScreen.videosTree = m.scene.videoliststack.peek()
                            else
                                print "Saved crash.......................--------------------------main.brs(389)-----------------------------..."
                            end if
                            EndLoader()
                        end if
                    else
                        StartLoadingScreen()
                        linkedVideoObject=CreateVideoObject(GetVideo(msg.GetData().videoid))
                        auth1 = getAuth(linkedVideoObject)

                        content = createObject("RoSGNode","VideoNode")
                        content.setFields(linkedVideoObject)
                        playVideo(m.gridScreen, auth1, m.app.avod, content)
                        EndLoader()
                    end if
                end if
            else if msg.getField() = "playlistItemSelected" and msg.GetData() = true and m.gridScreen.focusedContent.contentType = 2 then
                StartLoader()
                m.gridScreen.playlistItemSelected = false
                content = m.gridScreen.focusedContent

                ' Get Playlist object from the platform

                playlists = GetPlaylists({ id: content.id })
                validPlaylist = (playlists.count() > 0 and playlists[0].active)

                if (validPlaylist = true)
                    playlistThumbnailLayout = playlists[0].thumbnail_layout

                    m.gridScreen.content = ParseContent(GetPlaylistsAsRows(content.id, playlistThumbnailLayout))
                    m.gridContent = m.gridScreen.content

                    rowlist = m.gridScreen.findNode("RowList")
                    rowlist.rowItemSize = m.playlistsRowItemSizes
                    rowlist.rowSpacings = m.playlistRowsSpacings

                    rowlist.jumpToRowItem = [0,0]

                    m.scene.gridContent = m.gridContent

                    current_video_list_stack = m.scene.videoliststack
                    current_video_list_stack.push(m.videosList)
                    m.scene.videoliststack = current_video_list_stack

                    m.detailsScreen.videosTree = m.scene.videoliststack.peek()
                else
                    print "Saved crash.......................--------------------------main.brs(426)-----------------------------..."
                end if
                EndLoader()
            else if msg.getNode() = "Favorites" and msg.getField() = "visible" and msg.getData() = true
                StartLoader()
                favorites_content = GetFavoritesContent()
                m.scene.favoritesContent = ParseContent(favorites_content)
                hasNoContent = true

                if (favorites_content <> invalid AND favorites_content.count() > 0 and favorites_content[0].contentlist <> invalid and favorites_content[0].contentlist.count() > 0)
                    hasNoContent = false
                end if

                if hasNoContent = true then m.Favorites.NoItemsText = m.global.labels.no_favorites_message.replace("{{chr(10)}}", chr(10))

                EndLoader()

            else if msg.getNode() = "MyLibrary" and msg.getField() = "visible" and msg.getData() = true
                sign_in_button = m.MyLibrary.findNode("SignInButton")
                my_library_gridscreen = m.MyLibrary.findNode("Grid")
                my_library_gridscreen.setFocus(false)

                if m.global.auth.isLoggedIn
                    sign_in_button.visible = false
                    StartLoader()
                else
                    sign_in_button.visible = true
                    sign_in_button.setFocus(true)
                end if

                my_library_count = ContentHelpers().CountTwoDimContentNodeAtIndex(m.scene.myLibraryContent, 0)

                if m.global.auth.isLoggedIn
                    sign_in_button.setFocus(false)

                    ' MyLibrary was set
                    if my_library_count > 0
                        my_library_gridscreen.setFocus(true)

                    ' get MyLibrary first time
                    else
                        my_library = GetMyLibraryContent(true)

                        m.my_library_content = ArrayHelpers().RemoveDuplicatesBy(my_library[0].contentList, "id")

                        my_library_content = {
                            contentList: m.my_library_content,
                            title: my_library[0].title
                        }

                        if m.my_library_content.count() > 0
                            ' Push paginator to get next page
                            my_library_content.contentList.push(Paginator(2))

                            m.scene.myLibraryContent = ParseContent([my_library_content])
                            my_library_gridscreen.setFocus(true)
                        else
                            m.scene.myLibraryContent = ParseContent([my_library_content])
                            my_library_gridscreen.setFocus(false)
                        end if
                    end if

                else
                    m.scene.myLibraryContent = ParseContent(GetMyLibraryContent(false))
                    my_library_gridscreen.setFocus(false)
                    sign_in_button.setFocus(true)
                end if

                EndLoader()
                m.MyLibrary.setFocus(true)

            else if msg.getField() = "paginatorSelected" and msg.getData() = true and msg.getNode() = "MyLibrary"
                my_library_focused = m.MyLibrary.focusedContent

                my_library_next_page = GetMyLibraryContent(true, my_library_focused.nextPage)
                my_library_next_page_count = my_library_next_page[0].contentList.count()

                ' Remove Paginator
                m.my_library_content.pop()

                m.my_library_content.append(my_library_next_page[0].contentList)
                m.my_library_content = ArrayHelpers().RemoveDuplicatesBy(m.my_library_content, "id")

                new_my_library = {
                    title: m.scene.myLibraryContent.GetChild(0).title,
                    contentList: m.my_library_content
                }

                ' add paginator only if next page is next page content is not empty
                if my_library_next_page_count > 0 then new_my_library.contentList.push(Paginator(my_library_focused.nextPage + 1))


                m.scene.myLibraryContent = ParseContent([new_my_library])
                m.MyLibrary.setFocus(true)
            else if msg.getField() = "SearchString"
                StartLoader()
                SearchQuery(m.scene.SearchString)
                EndLoader()
            else if msg.getField() = "startStream"
                RemakeVideoPlayer(m.epgScreen)
                m.VideoPlayer = m.epgScreen.VideoPlayer
                m.akamai_service.setPlayStartedOnce(true)
                content = createObject("RoSGNode","VideoNode")
                content.setFields(msg.getData())
                playLiveStream(m.epgScreen, content)
            else if ((msg.getNode() = "FavoritesDetailsScreen" or msg.getNode() = "GridScreen" or msg.getNode() = "SearchDetailsScreen" or msg.getNode() = "MyLibraryDetailsScreen" or msg.getNode() = "DetailsScreen" or msg.getNode() = "AuthSelection" or msg.getNode() = "UniversalAuthSelection" or msg.getNode() = "SignInScreen" or msg.getNode() = "SignUpScreen" or msg.getNode() = "AccountScreen" or msg.getNode() = "PurchaseScreen" or msg.getNode() = "RegistrationScreen") and msg.getField() = "itemSelected") then

                ' access component node content
                if msg.getNode() = "FavoritesDetailsScreen"
                    lclScreen = m.favoritesDetailsScreen
                else if msg.getNode() = "SearchDetailsScreen"
                    lclScreen = m.searchDetailsScreen
                else if msg.getNode() = "GridScreen"
                    print "GridScreen========================================================0000000000000000000000000"
                    lclScreen = m.gridScreen
                else if msg.getNode() = "MyLibraryDetailsScreen"
                    lclScreen = m.MyLibraryDetailsScreen
                else if msg.getNode() = "DetailsScreen"
                    lclScreen = m.detailsScreen
                else if msg.getNode() = "AuthSelection"
                    lclScreen = m.AuthSelection
                else if msg.getNode() = "UniversalAuthSelection"
                    lclScreen = m.UniversalAuthSelection
                else if msg.getNode() = "SignInScreen"
                    lclScreen = m.SignInScreen
                else if msg.getNode() = "SignUpScreen"
                    lclScreen = m.SignUpScreen
                else if msg.getNode() = "RegistrationScreen"
                    lclScreen = m.RegistrationScreen
                else if msg.getNode() = "PurchaseScreen"
                    lclScreen = m.PurchaseScreen
                end if

                index = msg.getData()

                handleButtonEvents(index, lclscreen)
            else if (msg.getNode() = "AccountScreen" and (msg.getField() = "oAuthItemSelected" or msg.getField() = "signInItemSelected"))
                if msg.getNode() = "AccountScreen"
                    lclScreen = m.AccountScreen
                end if
                index = msg.getData()
                handleButtonEvents(index, lclscreen)
            else if (msg.getNode() = "AuthSelection" and (msg.getField() = "thankYouCloseSelected"))
                if msg.getNode() = "AuthSelection"
                    lclScreen = m.AuthSelection
                end if
                index = msg.getData()
                handleButtonEvents(index, lclscreen)
            else if (msg.getNode() = "AuthSelection" or msg.getNode() = "AccountScreen") and msg.getField() = "currentPlanSelected" then
              app_info = CreateObject("roAppInfo")
              SelectedAuthScreen = true
              if (msg.getNode() = "AccountScreen") then
                SelectedAuthScreen = false
              end if
              plan = msg.GetData()

              already_purchased = m.roku_store_service.alreadyPurchased(plan.code)

              already_purchased_message = "It appears you have already purchased this plan before. If you cancelled your subscription, please renew your subscription on the Roku website. " + chr(10) + chr(10) + "Then you can sign in with your " + app_info.getTitle() + " account."

              if already_purchased
                m.scene.callFunc("CreateDialog",m.scene, "Already purchased", already_purchased_message, ["Close"])
              else
                if m.global.auth.isLoggedIn or (m.global.native_to_universal_subscription = false AND m.global.marketplace_connect_svod <> true) then
                    handleNativeToUniversal(SelectedAuthScreen)
                else
                    m.scene.transitionTo = "SignUpScreen"
                end if
              end if
            else if msg.getNode() = "PurchaseScreen" and msg.getField() = "purchaseButtonSelected" then
              buttonRole = m.PurchaseScreen.itemSelectedRole
              buttonTarget = m.PurchaseScreen.itemSelectedTarget
               if buttonRole = "confirm_purchase"
                if m.global.auth.isLoggedIn or m.global.native_tvod = false then handleNativePurchase() else m.scene.transitionTo = "SignUpScreen"
              else if buttonRole = "cancel"
                m.detailsScreen.content = m.detailsScreen.content
                m.scene.goBackToNonAuth = true
              end if

            else if msg.getField() = "state"
                state = msg.getData()
                if m.scene.focusedChild.id = "DetailsScreen"
                  ' autoplay
                  next_video = m.detailsScreen.videosTree[m.detailsScreen.PlaylistRowIndex][m.detailsScreen.CurrentVideoIndex]
                  if state = "finished" and m.detailsScreen.autoplay = true and m.detailsScreen.canWatchVideo = true and next_video <> invalid
                      m.detailsScreen.triggerPlay = true
                  end if
                end if
            else if msg.getField() = "position"
                print m.videoPlayer.position
                if(m.videoPlayer.position >= 30 and m.videoPlayer.content.on_Air = false)
                    AddVideoIdForResumeToReg(m.videoPlayer.content.id,m.videoPlayer.position.ToStr())
                    AddVideoIdTimeSaveForResumeToReg(m.videoPlayer.content.id,startDate.asSeconds().ToStr())
                end if

	            ' If midroll ads exist, watch for midroll ads
	            if m.midroll_ads <> invalid and m.midroll_ads.count() > 0
                    handleMidrollAd()
	            end if ' end of midroll ad if statement
            else if msg.getNode() = "DeviceLinking" and msg.getField() = "show" and msg.GetData() = true then
                m.scene.transitionTo = "DeviceLinking"
                goIntoDeviceLinkingFlow()
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
                RemoveUdidFromReg()

                if res <> invalid
                  m.scene.TriggerDeviceUnlink = false
                  m.auth_state_service.updateAuthWithUserInfo(m.current_user.getInfo())

                  m.scene.gridContent = m.gridContent

                  m.deviceLinking.isDeviceLinked = true
                  m.deviceLinking.setFocus(true)

                  ' Clear favorites
                  m.favorites_storage_service.ClearFavorites()
                  m.favorites_management_service.SetFavoriteIds({})
                end if
            else if msg.GetField() = "setPurchasePlan" then
                setUpPurchasePlan()
            end if ' end of field checking
            ' end of msgType = "roSGNodeEvent"
        else if msgType = "roInputEvent" then
            print "msg : " msg
            if (msg.isInput() = true) then
                messageInfo = msg.GetInfo()
                print "messageInfo : " messageInfo
                if (messageInfo.contentId <> invalid and messageInfo.mediaType <> invalid) then
                    HandleDeeplinkEvent(messageInfo.contentId, messageInfo.mediaType, true)
                end if
            end if
        end if
    end while

    print "You are exiting the app"

    if screen <> invalid then
        screen.Close()
        screen = invalid
    end if
    return ""
End function

function setUpPurchasePlan()

    m.current_user_info = m.current_user.getInfo()
    allowed_trialed_plan = true
    if m.current_user_info <> invalid then
      if (m.current_user_info.has_trialed <> invalid and m.current_user_info.has_trialed) then
          allowed_trialed_plan = false
      end if
    end if

    rokuAllPlans = m.roku_store_service.GetNativeSubscriptionPlans()
    m.filteredAllPlans = m.marketplaceConnect.getSubscriptionPlans(rokuAllPlans, m.global.subscription_plan_ids)
    rokuPlans = m.roku_store_service.GetNativeSubscriptionPlans(allowed_trialed_plan, false)
    m.filteredPlans = m.marketplaceConnect.getSubscriptionPlans(rokuPlans, m.global.subscription_plan_ids)

    rokuPurchasePlans = m.roku_store_service.getPurchases()
    if allowed_trialed_plan = false then
      m.filteredPlans = m.marketplaceConnect.FilteredPurchasedPlan(m.filteredPlans, rokuPurchasePlans)
    end if
    allPurchasePlan = m.roku_store_service.getAllPurchases()
    m.filterPurchasePlan = m.marketplaceConnect.GetRokuFilteredZypePurchasePlans(m.filteredAllPlans, rokuPurchasePlans)
    m.filterAllPurchasePlan = m.marketplaceConnect.GetRokuFilteredZypePurchasePlans(m.filteredAllPlans, allPurchasePlan)
    m.AuthSelection.plans = m.filteredPlans
    m.AccountScreen.plans = m.filteredPlans
    m.AuthSelection.allPlans = m.filteredAllPlans
    m.AccountScreen.allPlans = m.filteredAllPlans
    m.AuthSelection.purchasePlans = m.filterPurchasePlan
    m.AccountScreen.purchasePlans = m.filterPurchasePlan
    m.AccountScreen.allPurchasePlans = m.filterAllPurchasePlan
end function

function goIntoDeviceLinkingFlow() as void
  pin = m.DeviceLinking.findNode("Pin")
  user_info = m.current_user.getInfo()

  if user_info.linked then pin.text = "You are linked" else pin.text = GetPin(GetUdidFromReg())

  website = m.DeviceLinking.findNode("LinkText2")
  website.text = m.app.device_link_url

  while true
    if m.deviceLinking.show = false
      exit while
    else
      print "refreshing PIN"
      pin_status = PinStatus({"linked_device_id": GetUdidFromReg()})

      if pin_status.linked then
        pin.text = "The device is linked"

        ' get and store access token locally
        GetAccessTokenWithPin(GetApiConfigs().client_id, GetApiConfigs().client_secret, GetUdidFromReg(), GetPin(GetUdidFromReg()))
        oauth = RegReadAccessToken()
        if oauth <> invalid
          udid = GetUdidFromReg()
          dataAsJson = FormatJson({
            "access_token": oauth.access_token,
            "refresh_token": oauth.refresh_token,
            "udid": udid
          })

          store = CreateObject("roChannelStore")
          store.StoreChannelCredData(dataAsJson) ' store Universal SSO data
        end if

        user_info = m.current_user.getInfo()
        m.auth_state_service.updateAuthWithUserInfo(user_info)

        m.deviceLinking.isDeviceLinked = true
        m.deviceLinking.setUnlinkFocus = true

        m.scene.gridContent = m.gridContent

        m.scene.goBackToNonAuth = true

        ' Reset details screen buttons
        m.detailsScreen.content = m.detailsScreen.content

        sleep(500)

        data = store.GetChannelCred()

        m.scene.callFunc("CreateDialog",m.scene, "Success", "Your device is linked", ["Continue"])
        exit while
      end if
    end if

    sleep(5000)
  end while
end function

' Used in video deep linking (movie, episode, short-form, special, live)
function transitionToVideoPlayer(videoObject as object) as void
    linkedVideoObject =  CreateVideoObject(videoObject)
    linkedVideoNode = createObject("roSGNode", "VideoNode")

    for each key in linkedVideoObject
        linkedVideoNode[key] = linkedVideoObject[key]
    end for

    ' Set focused content to linkedVideoNode
    m.gridScreen.focusedContent = linkedVideoNode
    m.gridScreen.visible = false
    m.detailsScreen.content = m.gridScreen.focusedContent
    m.detailsScreen.setFocus(true)
    m.detailsScreen.visible = true

    ' Trigger listener to push detailsScreen into HomeScene screenStack
    m.scene.DeepLinkedID = videoObject._id

    is_subscribed = (m.global.auth.nativeSubCount > 0 or m.global.auth.universalSubCount)

    ' Start playing video if logged in or no monetization
    if is_subscribed = true or ((videoObject.subscription_required = invalid or (videoObject.subscription_required <> invalid and videoObject.subscription_required = false)) and (videoObject.purchase_required = invalid or (videoObject.purchase_required <> invalid and videoObject.purchase_required = false)))
        m.akamai_service.setPlayStartedOnce(true)
        playRegularVideo(m.detailsScreen, true)
    end if
end function

' Used in playlist deep linking (season, series, episode)
function transitionToNestedPlaylist(id, index = 0 as integer) as void
  m.scene.callFunc("AddCurrentPositionToTracker")
  m.scene.callFunc("PushContentIntoContentStack", m.gridScreen.content)
  m.scene.callFunc("PushScreenIntoScreenStack", m.gridScreen)

  m.gridScreen.playlistItemSelected = false

  m.gridScreen.content = ParseContent(GetPlaylistsAsRows(id))

  rowList = m.gridScreen.findNode("RowList")
  rowlist.jumpToRowItem = [0, index]

  current_video_list_stack = m.scene.videoliststack
  current_video_list_stack.push(m.videosList)
  m.scene.videoliststack = current_video_list_stack

  m.detailsScreen.videosTree = m.scene.videoliststack.peek()
end function

' Play button should only appear in the following scenarios:
'     1- No subscription required for video
'     2- NSVOD only and user has already purchased a native subscription
'     3- Both NSVOD and USVOD. User either purchased a native subscription or is linked
sub playRegularVideo(screen as Object, isDeepLink = false as boolean)
    print "PLAY REGULAR VIDEO"
    StartLoadingScreen()
    adsEnable = m.app.avod
    if isDeepLink then adsEnable = false
    playVideo(screen, getAuth(screen.content), adsEnable)
end sub


sub playTrailerVideo(screen as Object, content = invalid)
  print "PLAY TRAILER VIDEO"
  StartLoadingScreen()
  playVideo(screen, getAuth(content), false, content)
end sub


sub playLiveStream(screen as Object, content = invalid)
  print "PLAY LIVE"
  StartLoadingScreen()
  playVideo(screen, getAuth(content), false, content)
end sub

sub playAutoPlayHero(screen as Object, content = invalid)
  print "PLAY Autoplay Hero"
  StartLoadingScreen()
  playVideo(screen, getAuth(content), false, content)
end sub

function getAuth(content)
  di = CreateObject("roDeviceInfo")
  consumer = m.current_user.getInfo()
  if consumer._id <> invalid and consumer._id <> ""
    oauth = m.current_user.getOAuth()
    if content <> invalid and IsEntitled(content.id, {access_token: oauth.access_token})
      auth = {"access_token": oauth.access_token, "uuid": di.GetChannelClientid()}
    else
      auth = {"app_key": GetApiConfigs().app_key, "uuid": di.GetChannelClientid()}
    end if
  else
    auth = {"app_key": GetApiConfigs().app_key, "uuid": di.GetChannelClientid()}
  end if

  print "auth --------------------------------------> " auth
  return auth
end function


sub playVideo(screen as Object, auth As Object, adsEnabled = false, content = invalid)

  if screen.hasField("videoPlayerVisible") then screen.videoPlayerVisible = true

  print "----------------------------------------------------------------------------0 : screen.videoPlayerVisible : " screen.videoPlayerVisible

  if content = invalid then content = screen.content

  print "--------------------------------------------------------------------------1"
  playerInfo = GetPlayerInfo(content.id, auth)
  print "--------------------------------------------------------------------------2"
  if playerInfo.video.duration <> invalid then content.length = playerInfo.video.duration
  if playerInfo.video.title <> invalid then content.title = playerInfo.video.title

  print "--------------------------------------------------------------------------3"
  playerInfo.video.video_content_genre = ""
  if (m.global.video_content_genre <> invalid)
      playerInfo.video.video_content_genre = m.global.video_content_genre
  end if

  if (playerInfo.bif <> invalid)
      content.SDBifUrl = playerInfo.bif.sd
      content.HDBifUrl = playerInfo.bif.hd
      content.FHDBifUrl = playerInfo.bif.fhd
  else
      content.SDBifUrl = ""
      content.HDBifUrl = ""
      content.FHDBifUrl = ""
  end if
  print "--------------------------------------------------------------------------4"

  content.stream = playerInfo.stream
  content.streamFormat = playerInfo.streamFormat
  if content.start = invalid or content["end"] = invalid or content.start = "" or content["end"] = ""
    urlSuffix = ""
  else
    urlSuffix = "&start=" + content.start + "&end=" + content["end"]
  end if
  content.url = playerInfo.url + urlSuffix

  print "--------------------------------------------------------------------------6"
  video_service = VideoService()
  print "--------------------------------------------------------------------------7"

  ' If video source is not available
  if(playerInfo.statusCode <> 200 or content.streamFormat = "(null)")
        print "--------------------------------------------------------------------------8 - Closed"
    CloseVideoPlayer(screen)
        if m.LoadingScreen.visible = true
          EndLoadingScreen(screen)
        end if
      m.scene.callFunc("CreateDialog",m.scene, "Error", playerInfo.errorMessage, ["Close"])
  else
        print "--------------------------------------------------------------------------9 - Play"
    PrepareVideoPlayerWithSubtitles(screen, playerInfo, content)
    playContent = true

'    m.VideoPlayer = screen.VideoPlayer
'    m.VideoPlayer.observeField("position", m.port)

    'if screen.id = m.detailsScreen.id  '(content.on_Air <> true) or urlSuffix <> ""
    if (screen.id = m.detailsScreen.id) '' or urlSuffix <> ""
      m.VideoPlayer.observeField("state", m.port)
    end if

    if screen.hasField("squareImageUrl") then screen.squareImageUrl = playerInfo.squareImageUrl
    if screen.hasField("squareImageWH") then screen.squareImageWH = playerInfo.squareImageWH

    m.videoPlayer.content = content

        if(adsEnabled AND (not screen.videoPlayerVisible = false))
            'As per client's requirement : Set 9999 for Live stream '
            if (playerInfo.on_Air = true)
                playerInfo.video.duration = 9999
            end if

            print "playerInfo.on_Air------------------------> " playerInfo.on_Air
            print "playerInfo.video.duration ------------------------> " playerInfo.video.duration

            is_subscribed = (m.global.auth.nativeSubCount > 0 or m.global.auth.universalSubCount > 0)
            no_ads = (m.global.swaf and is_subscribed)

            print "--------------------------------------------------------------------------10"
            ads = video_service.PrepareAds(playerInfo, no_ads)

            if playerInfo.on_Air = true then m.midroll_ads = [] else m.midroll_ads = ads.midroll
            EndLoader()

            print "--------------------------------------------------------------------------11"

            ' preroll ad
            if ads.preroll <> invalid
              playContent = m.raf_service.playAds(playerInfo.video, ads.preroll.url)
            end if
            print "--------------------------------------------------------------------------12"
        end if

    ' Start playing video
        if playContent AND (not screen.videoPlayerVisible = false) then
            EndLoader()

            print "--------------------------------------------------------------------------13"
      print "[Main] Playing video"

      ' if live stream, set position at end of stream
      ' roku video player does not automatically detect if live stream
      if playerInfo.on_Air = true
        m.videoPlayer.content.live = true
        m.videoPlayer.content.playStart = 100000000000
        m.videoPlayer.enableTrickPlay = false
      else
        m.videoPlayer.enableTrickPlay = true
      end if

      m.videoPlayer.visible = true

            print "--------------------------------------------------------------------------14"
            ' if screen.hasField("videoPlayerVisible") then screen.videoPlayerVisible = true

      if m.LoadingScreen.visible = true
        EndLoadingScreen(screen)
      end if

      m.currentVideoInfo = playerInfo.video
      if m.videoPlayer.seek<>invalid
        if m.videoPlayer.seek>0
            m.videoPlayer.seek=m.videoPlayer.seek
        end if
      end if

      ' Akamai Analytics'
      if(playerInfo.analytics.beacon <> invalid AND playerInfo.analytics.beacon <> "")
          if auth.access_token <> invalid then token_info = RetrieveTokenStatus({ access_token: auth.access_token }) else token_info = invalid
          if token_info <> invalid then consumer_id = token_info.resource_owner_id else consumer_id = ""

          cd = {
            siteId: playerInfo.analytics.siteid,
            videoId: playerInfo.analytics.videoid,
            title: content.title,
            deviceType: playerInfo.analytics.device,
            playerId: playerInfo.analytics.playerId,
            contentLength: content.length,
            consumerId: consumer_id
          }
          print "Custom Dimensions: "; cd
          print "PlayerInfo.analytics: "; playerInfo.analytics
          m.akamai_service.InitializeAkamaiLibrary(cd, playerInfo.analytics.beacon, m.videoPlayer)
          m.akamai_service.StartAkamaiEvents()
      end if

      ' Advance Analytics (MediaMelon)'
      if(m.global.advanced_analytics_enabled = true and m.global.advanced_analytics_customerid <> invalid and m.global.advanced_analytics_customerid <> 0)
          if auth.access_token <> invalid then token_info = RetrieveTokenStatus({ access_token: auth.access_token }) else token_info = invalid
          if token_info <> invalid then consumer_id = token_info.resource_owner_id else consumer_id = ""

          mediamelonCustomerID = m.global.advanced_analytics_customerid

          playerNameString =  "Roku Player"
          app_info = CreateObject("roAppInfo")
          subscriberID = "unknown"
          subscriberType = ""
          subscriptionId = ""
          appTitle = ""
          siteID = ""
          if app_info.GetTitle() <> invalid then appTitle = app_info.GetTitle()
          if playerInfo.analytics.siteid <> invalid then siteID = playerInfo.analytics.siteid


          if content.subscriptionRequired then
              if subscriberType = "" then subscriberType ="subscription" else subscriberType = subscriberType + "|subscription"
          end if

          currentUser = m.current_user.getInfo()
          if (currentUser <> invalid and currentUser.subscription_ids <> invalid and currentUser.subscription_ids.count() > 0)
              subscriptionId = currentUser.subscription_ids[0]
          end if

          if content.passRequired then
              if subscriberType = "" then subscriberType ="pass" else subscriberType = subscriberType + "|pass"
          end if
          if content.purchaseRequired then
              if subscriberType = "" then subscriberType ="purchase" else subscriberType = subscriberType + "|purchase"
          end if
          if content.redemptionCodeRequired then
              if subscriberType = "" then subscriberType ="redemption" else subscriberType = subscriberType + "|redemption"
          end if
          if content.rentalRequired then
              if subscriberType = "" then subscriberType ="rental" else subscriberType = subscriberType + "|rental"
          end if

          If consumer_id <> invalid and consumer_id <> "" then subscriberID = consumer_id

          if subscriberType = "" then
             subscriberType ="free"
          end if

          if subscriptionId = invalid then subscriptionId = ""

          MMConfig = {
              customerID : mediamelonCustomerID
              subscriberId : subscriberID
              subscriberType: subscriberType
              subscriberTag: invalid
              disableManifestFetch: false
              domainName: appTitle
              playerName: playerNameString
          }

          Custom = {
            "siteId" : siteID
            "subscriptionId" : subscriptionId
          }
          print "=========================================================="
          print "   MMStream Video FROM MAIN "
          print "   MMConfig  "  MMConfig
          print "   Custom    "  Custom
          print "=========================================================="
          m.mediamelon_service.InitializeMediaMelonService(MMConfig, Custom, m.videoPlayer)

          m.mediamelon_service.StartMediaMelonEvents()

      end if

            print "--------------------------------------------------------------------------15"
      m.videoPlayer.control = "play"
      m.videoPlayer.setFocus(true)

      if playerInfo.on_Air <> invalid and playerInfo.on_Air = true
        print "seeking live time"
        m.videoPlayer.seek = 100000000000
      end if
            print "--------------------------------------------------------------------------16"
    else
            print "--------------------------------------------------------------------------17 - Close"
      CloseVideoPlayer(screen)
            if m.LoadingScreen.visible = true
        EndLoadingScreen(screen)
            end if
      m.currentVideoInfo = invalid
    end if ' end of if playContent
  end if

  if m.LoadingScreen.visible = true
    EndLoadingScreen(screen)
  end if
  EndLoader()
  print "------------------------------------LAST---------------------------------------- : screen.videoPlayerVisible : " screen.videoPlayerVisible
end sub

sub PrepareVideoPlayerWithSubtitles(screen, playerInfo, content = invalid)
  if content = invalid then content = screen.content
	' show loading indicator before requesting ad and playing video
	StartLoader()
	m.on_air = content.on_Air

	m.VideoPlayer = screen.VideoPlayer
	m.VideoPlayer.observeField("position", m.port)
	m.videoPlayer.content = content

  video_service = VideoService()

  ' This will contains both WEBVTT + 608 captions'
  m.videoPlayer.content.subtitleTracks = video_service.GetSubtitles(playerInfo)
end sub

sub handleMidrollAd()
	currPos = m.videoPlayer.position

	timeDiff = Abs(m.midroll_ads[0].offset - currPos)
	print "Next midroll ad: "; m.midroll_ads[0].offset
	print "Time until next midroll ad: "; timeDiff

	' Within half second of next midroll ad timing
	if timeDiff <= 0.500
	  m.videoPlayer.control = "stop"

	  finished_ad = m.raf_service.playAds(m.currentVideoInfo, m.midroll_ads[0].url)

	  if finished_ad = false then CloseVideoPlayer()

	  ' Remove midroll ad from array
	  m.midroll_ads.shift()

	  ' Start playing video at back from currPos just before midroll ad started
	  m.videoPlayer.seek = currPos
	  m.akamai_service.setPlayStartedOnce(true)
	  m.videoPlayer.control = "play"

	' In case they fast forwarded or resumed watching, remove unnecessary midroll ads
	' Keep removing the first midroll ad in array until no midroll ads before current position
	else if m.midroll_ads.count() > 0 and currPos > m.midroll_ads[0].offset
	  while m.midroll_ads.count() > 0 and currPos > m.midroll_ads[0].offset
		m.midroll_ads.shift()
	  end while
	else if m.videoPlayer.visible = false
	  m.videoPlayer.control = "none"
	  m.midroll_ads = invalid
	  m.currentVideoInfo = invalid
	end if
end sub

sub CloseVideoPlayer(screen=m.detailsScreen)
  screen.videoPlayer.visible = false
  screen.videoPlayer.setFocus(false)
  screen.videoPlayerVisible = false

  if m.LoadingScreen.visible = true
    EndLoadingScreen()
  end if

  screen.visible = true
  screen.setFocus(true)
end sub

sub CreateVideoUnavailableDialog(errorMessage as String)
  dialog = createObject("roSGNode", "Dialog")
  dialog.title = ""
  dialog.optionsDialog = true
  dialog.message = errorMessage
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
    params.AddReplace("playlist_id.inclusive", m.app.featured_playlist_id)
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

    if m.global.favorites_via_api = true and m.global.auth <> invalid and m.global.auth.isLoggedIn
        user_info = m.current_user.getInfo()
        oauth_info = m.current_user.getOAuth()

        if (user_info <> invalid AND oauth_info <> invalid)
            videoFavorites = GetVideoFavorites(user_info._id, {"access_token": oauth_info.access_token, "per_page": "100"})

            ' print videoFavorites
            if videoFavorites <> invalid
                if videoFavorites.count() > 0
                    for each fav in videoFavorites
                        videoFavs.AddReplace(fav.video_id, fav._id)
                    end for
                end if
            end if
        else
          print "Saved crash.......................--------------------------main.brs(1077)-----------------------------..."
        end if
    else
        favorite_ids = m.favorites_storage_service.GetFavoritesIDs()

        for each id in favorite_ids
            videoFavs.AddReplace(id, id)
        end for
    end if

    return videoFavs
end function

function GetFavoritesContent()
    list = []

    favs = GetFavoritesIDs()

    if m.global.favorites_via_api = true and m.global.auth <> invalid and m.global.auth.isLoggedIn
        user_info = m.current_user.getInfo()
        oauth_info = m.current_user.getOAuth()

        if (user_info <> invalid AND oauth_info <> invalid)
            videoFavorites = GetVideoFavorites(user_info._id, {"access_token": oauth_info.access_token, "per_page": "100"})

            if videoFavorites <> invalid
                if videoFavorites.count() > 0
                    row = {}
                    row.title = m.global.labels.favorite_screen_label
                    row.ContentList = []
                    video_index = 0
                    for each fav in videoFavorites
                        vid = GetVideo(fav.video_id)
                        if vid._id <> invalid and favs.DoesExist(vid._id)
                            vid.inFavorites = favs.DoesExist(vid._id)
                            vid.video_index = video_index
                            row.ContentList.push(CreateVideoObject(vid))
                            video_index = video_index + 1
                        end if
                    end for
                    list.push(row)
                end if
            end if
        else
            print "Saved crash.......................--------------------------main.brs(XXXX)-----------------------------..."
        end if
    else
        if favs.count() > 0
            row = {}
            row.title = m.global.labels.favorite_screen_label
            row.ContentList = []
            video_index = 0
            for each id in favs
                vid = GetVideo(id)
                if vid._id <> invalid and favs.DoesExist(vid._id)
                    vid.inFavorites = true
                    vid.video_index = video_index
                    row.ContentList.push(CreateVideoObject(vid))
                    video_index = video_index + 1
                end if
            end for
            list.push(row)
        end if
    end if

    return list
end function

function GetMyLibraryContent(is_linked as boolean, page = 1 as integer)
    list = []

    if is_linked
        oauth = m.current_user.getOAuth()
        video_entitlements = GetEntitledVideos({
            access_token: oauth.access_token,
            per_page: 20,
            page: page
            sort: "created_at",
            order: "desc"
        })

        row = { title: "", ContentList: [] }

        if video_entitlements <> invalid
            if video_entitlements.count() > 0
                row.title = m.global.labels.my_library_catalog_message
                favs = GetFavoritesIDs()
                video_index = 0
                for each entitled_vid in video_entitlements
                    vid = GetVideo(entitled_vid.video_id)
                    if vid._id <> invalid
                        vid.inFavorites = favs.DoesExist(vid._id)
                        vid.video_index = video_index
                        row.ContentList.push(CreateVideoObject(vid))
                        video_index = video_index + 1
                    end if
                end for
            else
                row.title = m.global.labels.empty_my_library_catalog_message
            end if
        end if

        list.push(row)
    else
        row = {
            title: m.global.labels.my_library_signin_message,
            contentList: []
        }
        list.push(row)
    end if

    return list
end function

Function ParseContent(list As Object)

  	' Get consumables from ROKU Store'
  	consumables = m.roku_store_service.getConsumables()

    RowItems = createObject("RoSGNode","ContentNode")

    for each rowAA in list
        row = createObject("RoSGNode","ContentNode")
        row.Title = rowAA.Title
        if rowAA.purchase_price<>invalid
            'consumables = m.roku_store_service.getConsumables()
            isConsumableFound = false
            if (rowAA.marketplace_ids <> invalid AND rowAA.marketplace_ids.roku <> invalid)
              print "Playlist => rowAA.marketplace_ids.roku : " rowAA.marketplace_ids.roku
              print "Playlist => title : " rowAA.title
              for each rokuItem in consumables
                  if (rokuItem.code = rowAA.marketplace_ids.roku)
                    purchaseItem = rokuItem
                    isConsumableFound = true
                    exit for
                  end if
              end for
            end if

            if (isConsumableFound = false)
	            purchaseItem = consumables[0]
            end if

            row.NumEpisodes=rowAA.playlist_item_count
            row.Description=rowAA.purchase_price
            row.id=rowAA.playListID
            row.shortDescriptionLine1=FormatJSON(purchaseItem)
        end if

        for each itemAA in rowAA.ContentList
            item = createObject("RoSGNode","VideoNode")

            ' We don't use item.setFields(itemAA) as doesn't cast streamFormat to proper value
            for each key in itemAA
                item[key] = itemAA[key]
            end for

            if item.purchaseRequired
              isConsumableFound = false

              if (item.marketplace_ids <> invalid AND item.marketplace_ids.roku <> invalid)
                'print "marketplace_ids ==> item : " item.marketplace_ids.roku
                'print "title : " item.title
                for each rokuItem in consumables
                    if (rokuItem.code = item.marketplace_ids.roku)
                      purchaseItem = rokuItem
                      isConsumableFound = true
                      exit for
                    end if
                end for
              end if

              if (isConsumableFound = false)
	              purchaseItem = consumables[0]
              end if

              item.storeProduct = purchaseItem
            else
              item.storeProduct = invalid
            end if

            row.appendChild(item)
        end for

        RowItems.appendChild(row)
    end for

    print "consumables[0] ==> " consumables[0]
    print "consumables[1] ==> " consumables[1]
    print "consumables=====================> " consumables

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

function GetPlaylistContent(playlist_id as String, thumbnail_layout as string)
    playlists = GetPlaylists({"id": playlist_id})

    if (playlists = invalid OR playlists.count() = 0)
      print "Saved crash.......................--------------------------main.brs(1309)-----------------------------..."
      return []
    end if

    pl = playlists[0]

    favs = GetFavoritesIDs()

    if pl.playlist_item_count > 0 then
        list = []
        row = {}
        row.title = pl.title
        if pl.purchase_required<>invalid
            if pl.purchase_required=true
                row.playlist_item_count=pl.playlist_item_count
                row.marketplace_ids=pl.marketplace_ids ' TODO : Verify this'
                row.purchase_price=pl.purchase_price
                row.playListID=pl._id
            end if
        end if
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
        return GetContentPlaylists(pl._id, thumbnail_layout)
    end if
end function

function GetContentPlaylists(parent_id as String, thumbnail_layout as string)
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
        row.ContentList.push(CreatePlaylistObject(item, thumbnail_layout))
    end for

    list.push(row)

    return list
end function

function GetPlaylistsAsRows(parent_id as String, thumbnail_layout = "")
    m.videosList = []

    print "GetPlaylistsAsRows.................1"
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
      if thumbnail_layout = "poster"
        m.playlistsRowItemSizes.push( [ 147, 207 ] )
        m.playlistrowsSpacings.push( 50 )
      else
        m.playlistsRowItemSizes.push( [ 262, 147 ] )
        m.playlistrowsSpacings.push( 0 )
      end if

      return GetPlaylistContent(parent_id, thumbnail_layout)
    end if

    ' Call function which internally creates all tasks in parallel to get data to speedup things'
    m.scene.callFunc("GetPlaylistVideosFunc",rawPlaylists,m.app.per_page)

    while true
        if (m.scene.allDataReceived = true)
          exit while
        end if

        Sleep(1000)' as Void
    end while

    ' Refer this flas as it will used in recursive functions'
    m.scene.allDataReceived = false

    print "All data trigger back to main thread"

    myVideosArray = m.scene.myVideosArray

    list = []
    for each item in rawPlaylists
        row = {}
        row.title = item.title
        if item.purchase_required<>invalid
            if item.purchase_required=true
                row.playlist_item_count=item.playlist_item_count
                row.purchase_price=item.purchase_price
                row.marketplace_ids=item.marketplace_ids
                row.playListID=item._id
            end if
        end if

        row.ContentList = []
        if item.playlist_item_count > 0
            row.ContentList = []
            videos = []

            if item.thumbnail_layout = "poster"
              m.playlistsRowItemSizes.push( [ 147, 207 ] )
              m.playlistrowsSpacings.push( 50 )
            else
              m.playlistsRowItemSizes.push( [ 262, 147 ] )
              m.playlistrowsSpacings.push( 0 )
            end if

            video_index = 0

            'for each video in GetPlaylistVideos(item._id, {"per_page": m.app.per_page})
            for each video in myVideosArray[item._id]
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
            print "---------------------------else----------------------------------------------------------"
            if item.thumbnail_layout = "poster"
              m.playlistsRowItemSizes.push( [ 147, 207 ] )
              m.playlistrowsSpacings.push( 20 )
            else
              m.playlistsRowItemSizes.push( [ 262, 147 ] )
              m.playlistrowsSpacings.push( 0 )
            end if

            pls = GetPlaylists({"parent_id": item._id, "dpt": "true", "sort": "priority", "order": "dsc", "per_page": per_page, "page": 1})
            for each pl in pls
                row.ContentList.push(CreatePlaylistObject(pl, item.thumbnail_layout))
            end for
            m.videosList.push(row.ContentList)
        end if
        list.push(row)
    end for
  	m.playlistRows = list
    return list
end function



'///////////////////////////////////
' LabelList click handlers go here
'///////////////////////////////////
function handleButtonEvents(index, screen)
    button_role = screen.itemSelectedRole
    button_target = screen.itemSelectedTarget

    ? chr(10)
    ? tab(4) "main >>> handleButtonEvents()"
    ? tab(4) "screen: "; screen.id
    ? tab(4) "button role: "; button_role
    ? tab(4) "button target: "; button_target
    ? chr(10)

    if button_role = "play"
      RemakeVideoPlayer(screen)
      m.VideoPlayer = screen.VideoPlayer

      RemoveVideoIdForResumeFromReg(screen.content.id)
      m.akamai_service.setPlayStartedOnce(true)
      playRegularVideo(screen)
    else if button_role = "resume"
      resume_time = GetVideoIdForResumeFromReg(screen.content.id)
      RemakeVideoPlayer(screen)

      m.VideoPlayer = screen.VideoPlayer
      m.VideoPlayer.seek = resume_time
      playRegularVideo(screen)
    else if button_role = "trailer"
      RemakeVideoPlayer(screen)
      m.VideoPlayer = screen.VideoPlayer
      m.akamai_service.setPlayStartedOnce(true)
      content = screen.content.clone(true)
      content.id = button_target
      content.title = content.title + " - Trailer"
      playTrailerVideo(screen, content)
    else if button_role = "favorite"
      markFavoriteButton(screen)
    else if button_role = "swaf"
      m.scene.transitionTo = "AuthSelection"
    else if button_role = "device_linking"
      m.DeviceLinking.show = true

    else if button_role = "signout"
      user_info = m.current_user.getInfo()
      pin = GetPin(GetUdidFromReg())
      if user_info.linked then UnlinkDevice(user_info._id, pin, {})
      RemoveUdidFromReg()
      StartLoader()
      LogOut()
      store = CreateObject("roChannelStore")
      store.StoreChannelCredData("") ' clear out Universal SSO data

      user_info = m.current_user.getInfo()
      m.auth_state_service.updateAuthWithUserInfo(user_info)

      m.scene.gridContent = m.gridContent

      m.scene.goBackToNonAuth = true

      m.scene.resetFocus = true
      ' Reset details screen buttons
      m.detailsScreen.content = m.detailsScreen.content
      m.RegistrationScreen.isSignin = false
      m.RegistrationScreen.isRegister = true
      sleep(500)

      if m.AccountScreen.itemSelectedRole = "signout" AND m.AccountScreen.itemSelectedTarget = ""
          EndLoadingScreen(m.AccountScreen)
          m.scene.transitionTo = "AccountScreen"
      else
        EndLoader()
        sleep(500)
      	m.scene.callFunc("CreateDialog",m.scene, "Success", "You have been signed out.", ["Close"])
      end if

    else if button_role = "submitCredentials" and screen.id = "SignInScreen"

      if screen.email = ""
        sleep(500)
        m.scene.callFunc("CreateDialog",m.scene, "Error", "Email is empty", ["Close"])
      else if screen.password = ""
        sleep(500)
        m.scene.callFunc("CreateDialog",m.scene, "Error", "Password is empty", ["Close"])
      else
          if screen.email <> "" and screen.password <> ""
            StartLoader()
            login_response = Login(GetApiConfigs().client_id, GetApiConfigs().client_secret, screen.email, screen.password)
            oauth = RegReadAccessToken()
            if oauth <> invalid
              dataAsJson = FormatJson({
                "access_token": oauth.access_token,
                "refresh_token": oauth.refresh_token,
                "email": oauth.email,
                "password": oauth.password
              })
              store = CreateObject("roChannelStore")
              store.StoreChannelCredData(dataAsJson) ' store Universal SSO data
            end if
          else
            login_response = invalid
          end if
          if login_response <> invalid
            user_info = m.current_user.getInfo()
            m.auth_state_service.updateAuthWithUserInfo(user_info)

            m.scene.gridContent = m.gridContent

            ' m.scene.transitionTo = "AccountScreen"
            m.scene.goBackToNonAuth = true

            print "Calling Reset------------------------------------------------"
            m.SignInScreen.reset = true
            m.RegistrationScreen.reset = true
            m.RegistrationScreen.isRegister = true
            m.SignUpScreen.reset = true

            m.scene.resetFocus = true

            ' Reset details screen
            m.detailsScreen.content = m.detailsScreen.content


            if m.AccountScreen.itemSelectedRole = "transition" AND m.AccountScreen.itemSelectedTarget = "UniversalAuthSelection"
                setUpPurchasePlan()
                m.scene.transitionTo = "AccountScreen"
                EndLoadingScreen(m.AccountScreen)
                sleep(500)
                m.scene.callFunc("CreateDialog",m.scene, "Success", "Signed in as: " + user_info.email, ["Close"])
            else
                setUpPurchasePlan()
                EndLoader()
                sleep(500)
                m.scene.callFunc("CreateDialog",m.scene, "Success", "Signed in as: " + user_info.email, ["Close"])
            end if
          else
            EndLoader()
            sleep(500)
            m.scene.callFunc("CreateDialog",m.scene, "Error", "Could not find user with that email and password.", ["Close"])
          end if
      end if ' end of email/password validation

    else if button_role = "submitCredentials" and screen.id = "SignUpScreen"
      signUpChecked = screen.callFunc("isSignupChecked")

      if screen.email = ""
        m.scene.callFunc("CreateDialog",m.scene, "Error", "Email is empty. Cannot create account", ["Close"])
      else if screen.password = ""
        m.scene.callFunc("CreateDialog",m.scene, "Error", "Password is empty. Cannot create account", ["Close"])
      else if signUpChecked = false
        m.scene.callFunc("CreateDialog",m.scene, "Error", "You must agree with the terms of service in order to proceed.", ["Close"])
      else
        StartLoadingScreen()
        create_consumer_response = CreateConsumer({ "consumer[email]": screen.email, "consumer[password]": screen.password, "consumer[name]": "" })

        if create_consumer_response <> invalid
          login_response = Login(GetApiConfigs().client_id, GetApiConfigs().client_secret, screen.email, screen.password)
          oauth = RegReadAccessToken()
          if oauth <> invalid
            dataAsJson = FormatJson({
              "access_token": oauth.access_token,
              "refresh_token": oauth.refresh_token,
              "email": oauth.email,
              "password": oauth.password
            })
            store = CreateObject("roChannelStore")
            store.StoreChannelCredData(dataAsJson) ' store Universal SSO data
          end if

          user_info = m.current_user.getInfo()
          m.auth_state_service.updateAuthWithUserInfo(user_info)

          m.SignUpScreen.reset = true
          m.scene.goBackToNonAuth = true

          if m.detailsScreen.itemSelectedRole = "transition"
            print "m.detailsScreen.itemSelectedTarget===> " m.detailsScreen.itemSelectedTarget
            if m.detailsScreen.itemSelectedTarget = "AuthSelection" ' SVOD
              handleNativeToUniversal()
            else if m.detailsScreen.itemSelectedTarget = "PurchaseScreen" ' TVOD
              handleNativePurchase()
            end if
          end if
        else
          EndLoadingScreen()
          m.SignUpScreen.setFocus(true)
          m.SignUpScreen.findNode("SubmitButton").setFocus(true)

          m.scene.callFunc("CreateDialog",m.scene, "Error", "It appears that email was taken.", ["Close"])
        end if

      end if

    else if button_role = "submitCredentials" and screen.id = "RegistrationScreen"
      signUpChecked = screen.callFunc("isSignupChecked")
      if screen.email = ""
        sleep(500)
        m.scene.callFunc("CreateDialog",m.scene, "Error", "Email is empty. Cannot create account", ["Close"])
      else if screen.password = ""
        sleep(500)
        m.scene.callFunc("CreateDialog",m.scene, "Error", "Password is empty. Cannot create account", ["Close"])
      else if signUpChecked = false
        sleep(500)
        m.scene.callFunc("CreateDialog",m.scene, "Error", "You must agree with the terms of service in order to proceed.", ["Close"])
      else
        StartLoadingScreen()
        if not m.RegistrationScreen.isSignin
          create_consumer_response = CreateConsumer({ "consumer[email]": screen.email, "consumer[password]": screen.password, "consumer[name]": "" })
        end if
        if m.RegistrationScreen.isSignin or create_consumer_response <> invalid
          oauth = Login(GetApiConfigs().client_id, GetApiConfigs().client_secret, screen.email, screen.password)
          'oauth = RegReadAccessToken()
          if oauth <> invalid
            dataAsJson = FormatJson({
              "access_token": oauth.access_token,
              "refresh_token": oauth.refresh_token,
              "email": oauth.email,
              "password": oauth.password
            })
            store = CreateObject("roChannelStore")
            store.StoreChannelCredData(dataAsJson) ' store Universal SSO data
            user_info = m.current_user.getInfo()
            m.auth_state_service.updateAuthWithUserInfo(user_info)
            'm.scene.gridContent = m.gridContent
            m.RegistrationScreen.isSignin = false
            m.RegistrationScreen.reset = true
            m.detailsScreen.content = m.detailsScreen.content
            m.scene.goBackToNonAuth = true
            setUpPurchasePlan()
            EndLoadingScreen()

            ' HB : MarketPlaceConnect With RegistrationScreen'
            isSubscribed = (m.global.auth.nativeSubCount > 0 or m.global.auth.universalSubCount > 0)
            if isSubscribed = false and m.detailsScreen.itemSelectedRole = "transition" AND m.detailsScreen.itemSelectedTarget = "RegistrationScreen" AND m.global.marketplace_connect_svod = true
                m.scene.transitionTo = "AuthSelection"
            else
            	sleep(500)
            	m.scene.callFunc("CreateDialog",m.scene, "Success", "Signed in as: " + user_info.email, ["Close"])
            end if

            m.Menu.isRefreshMenu = true
          else
            EndLoadingScreen()
            m.RegistrationScreen.setFocus(true)
            m.RegistrationScreen.findNode("SubmitButton").setFocus(true)
            sleep(500)
            m.scene.callFunc("CreateDialog",m.scene, "Error", "Could not find user with that email and password.", ["Close"])
          end if
        else
          EndLoadingScreen()
          m.RegistrationScreen.setFocus(true)
          m.RegistrationScreen.findNode("SubmitButton").setFocus(true)
          sleep(500)
          m.scene.callFunc("CreateDialog",m.scene, "Error", "It appears that email was taken.", ["Close"])
        end if
      end if
    else if button_role = "syncNative"
        StartLoader()
        'user_info = m.current_user.getInfo()
        latest_native_sub = m.roku_store_service.latestNativeSubscriptionPurchase()

        print "latest_native_sub---> " latest_native_sub
        access_token = ""
        if (m.current_user.getOAuth() <> invalid AND m.current_user.getOAuth().access_token <> invalid)
          access_token = m.current_user.getOAuth().access_token
        else
          access_token = ""
        end if

        consumer_id = m.current_user.getInfo()._id

        matchingZypePlanId = m.marketplaceConnect.getZypePlanIDFromRokuPlanCode(latest_native_sub.code, m.global.subscription_plan_ids)

        print "access_token : " access_token
        print "consumer_id : " consumer_id
        print "purchase_subscription.receipt.purchaseId : " latest_native_sub.purchaseId
        print "plan.zypePlanId : " matchingZypePlanId
        print "m.app._id : " m.app._id
        print "m.app.site_id : " m.app.site_id

        marketplaceParams = {
            access_token: access_token,
            consumer_id: consumer_id,
            transaction_id: latest_native_sub.purchaseId,
            plan_id: matchingZypePlanId,
            app_id: m.app._id,
            site_id: m.app.site_id
      }

        print "marketplaceParams ---> " marketplaceParams

        if (matchingZypePlanId <> "")
            marketPlaceConnectSVODVerificationStatus = m.marketplaceConnect.verifyMarketplaceSubscription(marketplaceParams)
            print "======> marketPlaceConnectSVODVerificationStatus : ===> " marketPlaceConnectSVODVerificationStatus

            if marketPlaceConnectSVODVerificationStatus = true
                updated_user_info = m.current_user.getInfo()
                print "updated_user_info ==> " updated_user_info
                ' native subscription sync success
                if updated_user_info.subscription_count > 0
                  ' Re-login. Get new access token
                  m.auth_state_service.updateAuthWithUserInfo(updated_user_info)
                  ' Refresh lock icons with grid screen content callback
                  m.scene.gridContent = m.gridContent

                  ' details screen should update self
                  m.detailsScreen.content = m.detailsScreen.content

                  m.native_email_storage.WriteEmail(updated_user_info.email)

                  EndLoadingScreen(m.AccountScreen)
                  EndLoader()
                  sleep(500)
                  m.scene.transitionTo = "GridScreen"
                  m.scene.callFunc("CreateDialog",m.scene, "Success", "Was able to validate subscription.", ["Close"])
                else
                  stored_email = m.native_email_storage.ReadEmail()
                  if stored_email = "" or stored_email = invalid then
                      message = "Please sign in with the correct email to sync your subscription."
                  else
                      message = "Please sign in as " + stored_email + " to sync your subscription."
                  end if
                  EndLoadingScreen(m.AccountScreen)
                  EndLoader()
                  sleep(500)
                  m.scene.callFunc("CreateDialog",m.scene, "Error", message, ["Close"])
                end if
            else
               EndLoadingScreen(m.AccountScreen)
               EndLoader()
               sleep(500)
               m.scene.callFunc("CreateDialog",m.scene, "Error", "There was an error validating your subscription.", ["Close"])
            end if
        else
            EndLoadingScreen(m.AccountScreen)
            EndLoader()
            sleep(500)
            m.scene.callFunc("CreateDialog",m.scene, "Error", "There was an error validating your subscription.", ["Close"])
        end if
    else if button_role = "transition" and button_target = "DetailsScreen"
        m.scene.transitionTo = "DetailsScreen"
    else if button_role = "transition" and button_target = "AuthSelection"
      m.scene.transitionTo = "AuthSelection"
    else if button_role = "transition" and button_target = "GridScreen"
      m.scene.transitionTo = "GridScreen"
    else if button_role = "backScreen" and button_target = "AuthSelection"
      m.scene.backScreen = "AuthSelection"
    else if button_role = "transition" and button_target = "AccountScreen"
      m.scene.transitionTo = "AccountScreen"
    else if button_role = "transition" and button_target = "SignUpScreen"
      m.scene.transitionTo = "SignUpScreen"
    else if button_role = "transition" and button_target = "PurchaseScreen"
      if screen.content.storeProduct<>invalid
          m.PurchaseScreen.purchaseItem = screen.content.storeProduct
          m.PurchaseScreen.itemName = screen.content.title
          m.PurchaseScreen.videoId = screen.content.id
      else if screen.rowTVODInitiateContent.DESCRIPTION<>""
        m.PurchaseScreen.isPlayList=true
        m.PurchaseScreen.playListVideoCount = screen.rowTVODInitiateContent.NUMEPISODES.toStr()
        m.PurchaseScreen.purchaseItem = parseJSON(screen.rowTVODInitiateContent.SHORTDESCRIPTIONLINE1)
        m.PurchaseScreen.itemName = screen.rowTVODInitiateContent.title
        m.PurchaseScreen.videoId = screen.rowTVODInitiateContent.id
      end if
      m.scene.transitionTo = "PurchaseScreen"
    else if button_role = "transition" and button_target = "UniversalAuthSelection"
      if m.global.enable_device_linking = false then m.scene.transitionTo = "SignInScreen" else m.scene.transitionTo = "UniversalAuthSelection"
    else if button_role = "transition" and button_target = "DeviceLinking"
      m.DeviceLinking.show = true
      m.DeviceLinking.setFocus(true)
    else if button_role = "transition" and button_target = "SignInScreen"
      m.scene.transitionTo = "SignInScreen"
    else if button_role = "transition" and button_target = "RegistrationScreen"
      m.scene.transitionTo = "RegistrationScreen"
    end if
end function

function handleNativeToUniversal(authselection = true as boolean) as void
  if authselection then
  	m.AuthSelection.visible = false
  else
    m.AccountScreen.findNode("confirmPlanGroup").visible = false
    m.AccountScreen.visible = false
  end if
  StartLoadingScreen()

  ' Get updated user info
  user_info = m.current_user.getInfo()
  m.auth_state_service.updateAuthWithUserInfo(user_info)

  print "user_info : " user_info

  if authselection then
  	plan = m.AuthSelection.currentPlanSelected
  else
    plan = m.AccountScreen.currentPlanSelected
  end if
  purchaseOrderAction = GetPurchaseOrderAction(m.filterPurchasePlan, plan)
  purchase_subscription = invalid
  order_change = invalid

  if purchaseOrderAction = "" then
      order = [{
        code: plan.code,
        qty: 1
      }]

      print "makePurchase-C--For Plan-> " plan.code
      ' Make nsvod purchase
      purchase_subscription = m.roku_store_service.makePurchase(order)
      subscribePlanFromRoku = m.roku_store_service.getPurchases()
      print "makePurchase--R--> "  purchase_subscription
  else

     myOrder = CreateObject("roSGNode", "ContentNode")
     myItem = myOrder.createChild("ContentNode")
     myItem.addFields({ "code": plan.code, "qty": 1})
     myOrder.action = purchaseOrderAction ' action is Upgrade or Downgrade
     order_change = m.roku_store_service.orderChange(myOrder)

     marketplaceParams = {
       app_id: m.app._id,
       site_id: m.app.site_id,
       consumer_id: user_info._id,
       old_subscription: { id: m.filterPurchasePlan[0].purchaseId , plan_id: m.filterPurchasePlan[0].zypePlanId },
       new_subscription: { id: order_change.transactionId , plan_id: plan.zypePlanId }
       action: LCase(purchaseOrderAction),
     }
     print " >>>>>>>>>>>> request market "marketplaceParams
     print " >>>>>>>>>>>> request old_subscription "marketplaceParams.old_subscription
     print " >>>>>>>>>>>> request new_subscription "marketplaceParams.new_subscription
     subscribePlanFromRoku = m.roku_store_service.getPurchases()

  end if

  if purchase_subscription <> invalid and purchase_subscription.success
      m.auth_state_service.incrementNativeSubCount()
      isCheckMarketPlaceConnectSVOD = false

      if (m.global.marketplace_connect_svod = true AND m.global.subscription_plan_ids <> invalid AND m.global.subscription_plan_ids.count() > 0)
          isCheckMarketPlaceConnectSVOD = true
      end if

      if m.global.native_to_universal_subscription = true OR isCheckMarketPlaceConnectSVOD = true

        ' Store email used for purchase. For sync subscription later
        if (user_info.email <> invalid AND user_info.email <> "")
        	m.native_email_storage.DeleteEmail()
        	m.native_email_storage.WriteEmail(user_info.email)
        end if

        ' Get recent purchase
        recent_purchase = purchase_subscription.receipt

        print "recent_purchase====================> " recent_purchase

        ' Check if MarketPlaceConnect SVOD or NOT'
        if (isCheckMarketPlaceConnectSVOD)
              print "isCheck MarketPlaceConnectSVOD================================================================================>"
              print "m.current_user : " m.current_user
              print "m.current_user.getOAuth() : " m.current_user.getOAuth()
              print "m.current_user.getInfo() : " m.current_user.getInfo()

              access_token = ""
              if (m.current_user.getOAuth() <> invalid AND m.current_user.getOAuth().access_token <> invalid)
                access_token = m.current_user.getOAuth().access_token
              else
                access_token = ""
              end if

              consumer_id = m.current_user.getInfo()._id

              print "access_token : " access_token
              print "consumer_id : " consumer_id
              print "purchase_subscription.receipt-----> " purchase_subscription.receipt
              print "purchase_subscription.receipt.purchaseId : " purchase_subscription.receipt.purchaseId
              print "plan.zypePlanId : " plan.zypePlanId
              print "m.app._id : " m.app._id
              print "m.app.site_id : " m.app.site_id

              marketplaceParams = {
                access_token: access_token,
                consumer_id: consumer_id,
                transaction_id: purchase_subscription.receipt.purchaseId,
                plan_id: plan.zypePlanId,
                app_id: m.app._id,
                site_id: m.app.site_id
              }
              marketPlaceConnectSVODVerificationStatus = m.marketplaceConnect.verifyMarketplaceSubscription(marketplaceParams)
              print "======> marketPlaceConnectSVODVerificationStatus : ===> " marketPlaceConnectSVODVerificationStatus
        else
              print "isCheck bifrost================================================================================>"

              ' We will call Biforst like previously it was calling'
              third_party_id = GetPlan(recent_purchase.code, {}).third_party_id
              bifrost_params = {
                app_key: GetApiConfigs().app_key,
                consumer_id: user_info._id,
                third_party_id: third_party_id,
                roku_api_key: GetApiConfigs().roku_api_key,
                transaction_id: UCase(recent_purchase.purchaseId),
                device_type: "roku"
              }
              ' Check is subscription went through with BiFrost. BiFrost should validate then create universal subscription
              native_sub_status = GetNativeSubscriptionStatus(bifrost_params)
        end if

        isReceiptValidated = false
        if (isCheckMarketPlaceConnectSVOD)
            isReceiptValidated = marketPlaceConnectSVODVerificationStatus
        else
        if native_sub_status <> invalid and native_sub_status.is_valid <> invalid and native_sub_status.is_valid
                print "-----BiFrost---------------Success Validation"
                isReceiptValidated = true
            end if
        end if

        if isReceiptValidated = true
            setUpPurchasePlan()
            user_info = m.current_user.getInfo()

            ' Create new access token. Creating sub does not update entitlements for access tokens created before subscription
            ' if user_info.linked then GetAndSaveNewToken("device_linking") else GetAndSaveNewToken("login")
            m.auth_state_service.updateAuthWithUserInfo(user_info)

            current_native_plan = m.roku_store_service.latestNativeSubscriptionPurchase()
            m.auth_state_service.setCurrentNativePlan(current_native_plan)

            ' Refresh lock icons with grid screen content callback
            m.scene.gridContent = m.gridContent

            m.scene.goBackToNonAuth = true

            ' details screen should update self
            m.detailsScreen.content = m.detailsScreen.content

            if authselection then
              m.AuthSelection.planSubscribeDetail = subscribePlanFromRoku[0].description
              EndLoadingScreen(m.AuthSelection)
              m.AuthSelection.planSubscribeSuccess = true
              m.scene.transitionTo = "AuthSelection"
            else
              m.AccountScreen.planSubscribeDetail = subscribePlanFromRoku[0].description
              EndLoadingScreen(m.AccountScreen)
              m.AccountScreen.planSubscribeSuccess = true

              m.scene.transitionTo = "AccountScreen"
            end if

            ' sleep(500)
            ' if (user_info.email <> invalid AND user_info.email <> "")
            ' m.scene.callFunc("CreateDialog",m.scene, "Welcome", "Hi, " + user_info.email + ". Thanks for signing up.", ["Close"])

        else ' Receipt verification failed
            EndLoadingScreen()
            sleep(500)
            m.scene.callFunc("CreateDialog",m.scene, "Error", "Could not verify your purchase with Roku. You can cancel your subscription on the Roku website.", ["Close"])
        end if ' native_sub_status.valid

      ' regular nsvod
      else
        EndLoader()
        current_native_plan = m.roku_store_service.latestNativeSubscriptionPurchase()
        m.auth_state_service.setCurrentNativePlan(current_native_plan)

        ' Refresh lock icons with grid screen content callback
        m.scene.gridContent = m.gridContent

        m.scene.goBackToNonAuth = true

        ' details screen should update self
        m.detailsScreen.content = m.detailsScreen.content

        sleep(500)
        m.scene.callFunc("CreateDialog",m.scene, "Success", "Thank you for purchasing the subscription.", ["Dismiss"])
      end if ' end if global.native_to_universal_subscription

  else if order_change <> invalid and order_change.success

      if (m.global.marketplace_connect_svod = true AND m.global.subscription_plan_ids <> invalid AND m.global.subscription_plan_ids.count() > 0)
          isCheckMarketPlaceConnectSVOD = true
      end if

      if m.global.native_to_universal_subscription = true OR isCheckMarketPlaceConnectSVOD = true

        ' Store email used for purchase. For sync subscription later
        if (user_info.email <> invalid AND user_info.email <> "")
          m.native_email_storage.DeleteEmail()
          m.native_email_storage.WriteEmail(user_info.email)
        end if

        ' Get recent order_change
        recent_order_change = order_change

        print "recent_order_change====================> " recent_order_change

        ' Check if MarketPlaceConnect SVOD or NOT'
        if (isCheckMarketPlaceConnectSVOD)
              print "isCheck MarketPlaceConnectSVOD================================================================================>"
              print "m.current_user : " m.current_user
              print "m.current_user.getOAuth() : " m.current_user.getOAuth()
              print "m.current_user.getInfo() : " m.current_user.getInfo()

              access_token = ""
              if (m.current_user.getOAuth() <> invalid AND m.current_user.getOAuth().access_token <> invalid)
                access_token = m.current_user.getOAuth().access_token
              else
                access_token = ""
              end if

              consumer_id = m.current_user.getInfo()._id

              print "access_token : " access_token
              print "consumer_id : " consumer_id

              print "plan.zypePlanId : " plan.zypePlanId
              print "m.app._id : " m.app._id
              print "m.app.site_id : " m.app.site_id

              marketPlaceOrderChangeVerification = m.marketplaceConnect.verifyMarketplaceOrderChange(marketplaceParams)
              'marketPlaceConnectSVODVerificationStatus = m.marketplaceConnect.verifyMarketplaceSubscription(marketplaceParams)
              print "======> marketPlaceOrderChangeVerification : ===> " marketPlaceOrderChangeVerification
        end if

        'isReceiptValidated = true
        isReceiptValidated = marketPlaceOrderChangeVerification


        if isReceiptValidated = true
            setUpPurchasePlan()
            user_info = m.current_user.getInfo()

            ' Create new access token. Creating sub does not update entitlements for access tokens created before subscription
            ' if user_info.linked then GetAndSaveNewToken("device_linking") else GetAndSaveNewToken("login")
            m.auth_state_service.updateAuthWithUserInfo(user_info)

            current_native_plan = m.roku_store_service.latestNativeSubscriptionPurchase()
            m.auth_state_service.setCurrentNativePlan(current_native_plan)

            ' Refresh lock icons with grid screen content callback
            m.scene.gridContent = m.gridContent

            m.scene.goBackToNonAuth = true

            m.detailsScreen.content = m.detailsScreen.content

            sleep(500)
            if authselection then
              EndLoader()
            else
              m.AccountScreen.planSubscribeDetail = subscribePlanFromRoku[0].description
              print " m.AccountScreen.planSubscribeDetail " subscribePlanFromRoku[0].description
              EndLoadingScreen(m.AccountScreen)
              m.AccountScreen.planSubscribeSuccess = true

              m.scene.transitionTo = "AccountScreen"
            end if

        else ' Receipt verification failed
            EndLoadingScreen()
          if authselection then
          else
            EndLoadingScreen(m.AccountScreen)
          end if

          m.scene.transitionTo = "AccountScreen"
            sleep(500)
            m.scene.callFunc("CreateDialog",m.scene, "Error", "Could not verify your purchase with Roku. You can cancel your subscription on the Roku website.", ["Close"])
        end if ' native_sub_status.valid

      ' regular nsvod
      else
        if authselection then
          EndLoadingScreen()
        else
          EndLoadingScreen(m.AccountScreen)
          m.scene.transitionTo = "AccountScreen"
        end if

        current_native_plan = m.roku_store_service.latestNativeSubscriptionPurchase()
        m.auth_state_service.setCurrentNativePlan(current_native_plan)

        ' Refresh lock icons with grid screen content callback
        m.scene.gridContent = m.gridContent

        m.scene.goBackToNonAuth = true

        ' details screen should update self
        m.detailsScreen.content = m.detailsScreen.content

        sleep(500)
        'm.scene.callFunc("CreateDialog",m.scene, "Success", "Thank you for purchasing the subscription.", ["Dismiss"])
      end if ' end if global.native_to_universal_subscription
  ' User cancelled purchase or error from Roku store
  else
    if authselection then
      '' EndLoader()
      EndLoadingScreen(m.AuthSelection)
      m.scene.resetTo = "AuthSelection"
      m.AuthSelection.setFocus(true)
      m.AuthSelection.findNode("Plans").setFocus(true)
    else
      EndLoadingScreen(m.AccountScreen)
      m.scene.resetTo = "AccountScreen"
      m.AccountScreen.setFocus(true)
      m.AccountScreen.findNode("Plans").setFocus(true)
    end if
    m.scene.callFunc("CreateDialog",m.scene, "Incomplete", "Was not able to complete purchase. Please try again later.", ["Close"])
  end if
end function

function handleNativePurchase() as void
  m.PurchaseScreen.visible = false
  StartLoadingScreen()

  ' Get updated user info
  userInfo = m.current_user.getInfo()
  m.auth_state_service.updateAuthWithUserInfo(userInfo)

  order = [{
    code: m.PurchaseScreen.purchaseItem.code,
    qty: 1
  }]

  purchase_item = m.roku_store_service.makePurchase(order)
  EndLoadingScreen()

  if purchase_item.success
    m.native_email_storage.DeleteEmail()
    m.native_email_storage.WriteEmail(userInfo.email)

    regex = CreateObject("roRegex", "[^\d\.]", "i") ' regex for non-digit and period characters

    appInfo = CreateObject("roAppInfo")
    rokuAppId = appInfo.GetID()

    marketplaceParams = {
      app_id: m.app._id,
      site_id: m.app.site_id,
      roku_id: rokuAppId,
      transaction_id: purchase_item.receipt.purchaseId,
      consumer_id: m.current_user.getInfo()._id,
      video_id: m.detailsScreen.content.id,
      transaction_type: "purchase",
      amount: regex.ReplaceAll(purchase_item.receipt.amount, "")
    }

    successfulVerification = m.marketplaceConnect.verifyMarketplacePurchase(marketplaceParams)

    if successfulVerification
      userInfo = m.current_user.getInfo()

      if userInfo.linked then GetAndSaveNewToken("device_linking") else GetAndSaveNewToken("login")
      m.auth_state_service.updateAuthWithUserInfo(userInfo)

      ' Refresh lock icons with grid screen content callback
      m.scene.gridContent = m.gridContent

      m.scene.goBackToNonAuth = true

      ' details screen should update self
      m.detailsScreen.content = m.detailsScreen.content

      EndLoadingScreen()
      sleep(500)
      m.scene.callFunc("CreateDialog",m.scene, "Success", "Thank you for purchasing the video.", ["Dismiss"])

    else ' failed
      ' Refresh lock icons with grid screen content callback
      m.scene.gridContent = m.gridContent

      m.scene.goBackToNonAuth = true

      ' details screen should update self
      m.detailsScreen.content = m.detailsScreen.content

      EndLoadingScreen()
      sleep(500)
      m.scene.callFunc("CreateDialog",m.scene, "Error", "Could not verify your purchase with Roku marketplace. Please try again later.", ["Close"])
    end if
  else
    m.PurchaseScreen.findNode("PurchaseButtons").setFocus(true)
    m.scene.callFunc("CreateDialog",m.scene, "Incomplete", "Was not able to complete purchase. Please try again later.", ["Close"])
  end if
end function

function GetPurchaseOrderAction(purchasePlans, newPlan) as string
    'print purchasePlans[0]
    action = ""
    if purchasePlans <> invalid AND purchasePlans.count() > 0
        if purchasePlans[0].costValue < newPlan.costValue
            action = "Upgrade"
        else
            action = "Downgrade"
        end if
    end if
    return action
end function
' Seting details screen's RemakeVideoPlayer value to true recreates Video component
'     Roku Video component performance degrades significantly after multiple uses, so we make a new one
function RemakeVideoPlayer(screen) as void
    screen.RemakeVideoPlayer = true
    screen.VideoPlayer.seek = 0.0
end function

Function StartLoadingScreen()
    m.LoadingScreen.show = true
    m.LoadingScreen.setFocus(true)
    m.loadingIndicator1.control = "start"
End Function

Function EndLoadingScreen(screen=m.detailsScreen)
  m.loadingIndicator1.control = "stop"
  m.LoadingScreen.show = false
  m.LoadingScreen.setFocus(false)
  m.scene.resetFocus = true
End Function


Function StartLoader()
    m.loadingIndicator.control = "start"
End Function

Function EndLoader()
  m.loadingIndicator.control = "stop"
End Function

Function markFavoriteButton(lclScreen)
    id = lclScreen.content.id
    in_favorites = lclScreen.content.inFavorites

    if m.global.favorites_via_api = true
        if m.global.auth.isLoggedIn
            favs = GetFavoritesIDs()
            user_info = m.current_user.getInfo()
            oauth_info = m.current_user.getOAuth()

            if in_favorites
                DeleteVideoFavorite(user_info._id, favs[id], {"access_token": oauth_info.access_token, "video_id": id, "_method": "delete"})
                m.favorites_management_service.RemoveFavorite(id)
                lclScreen.content.inFavorites = false

            else
                CreateVideoFavorite(user_info._id, {"access_token": oauth_info.access_token, "video_id": id })
                m.favorites_management_service.AddFavorite(id)
                lclScreen.content.inFavorites = true
            end if

        ' Not authenicated. Trying to favorite when favorites_via_api is on
        else
            m.scene.callFunc("CreateDialog",m.scene, "Sign In to Favorite", "Please sign in to your account or sign up to add this video to favorites.", ["OK"])
        end if

    ' local favorites
    else
        if in_favorites
            m.favorites_storage_service.DeleteFavorite(id)
            m.favorites_management_service.RemoveFavorite(id)
            lclScreen.content.inFavorites = false
        else
            m.favorites_storage_service.AddFavorite(id)
            m.favorites_management_service.AddFavorite(id)
            lclScreen.content.inFavorites = true
        end if
    end if
End Function

' ////////////////////////////////////////////////////////////////////////////////////////////////////////////
'   Called at startup. Sets up m.global.theme and m.global.brand_color
'   Accepts theme and brand color from app settings, otherwise accepts from config file.
'
'   If you want to customize your theme, you can:
'     1- set the "theme" inside the config file to "custom"
'     2- edit CustomTheme() inside source/themes.brs
'     3- add/update the images inside the images folder
Function SetTheme()

  if m.app.theme <> invalid
    theme = m.app.theme

    if GetApiConfigs().theme = "custom" then theme = "custom"
  else
    theme = GetApiConfigs().theme
  end if

  if m.app.brand_color <> invalid
    brand_color = m.app.brand_color
  else
    brand_color = GetApiConfigs().brand_color
  end if

  if m.global <> invalid
    m.global.addFields({ brand_color: brand_color })

    if theme = "dark"
      m.global.addFields({ theme: DarkTheme() })
    else if theme = "light"
      m.global.addFields({ theme: LightTheme() })
    else if theme = "custom"
      m.global.addFields({ theme: CustomTheme() })
    end if
  end if
End Function

function SetMonetizationSettings() as void
  if m.app <> invalid
    m.global.addFields({
      avod: m.app.avod,
      in_app_purchase: m.app.in_app_purchase,
      device_linking: m.app.device_linking
    })
  end if
end function

' Called at startup. Sets feature flags from config file
function SetFeatures() as void
  configs = GetApiConfigs()

  m.global.addFields({
    autoplay: m.app.autoplay,
    swaf: m.app.subscribe_to_watch_ad_free,
    enable_epg: configs.enable_epg,
    enable_lock_icons: m.app.enable_lock_icons,
    custom_lock_color: configs.custom_lock_color,
    custom_unlock_color: configs.custom_unlock_color,
    enable_unlock_transparent: configs.enable_unlock_transparent,
    inline_title_text_display: configs.inline_title_text_display,
    image_caching_support: configs.image_caching_support,
    native_to_universal_subscription: m.app.native_to_universal_subscription,
    native_tvod: configs.native_tvod,
    favorites_via_api: configs.favorites_via_api,
    universal_tvod: m.app.universal_tvod,
    confirm_signup: configs.confirm_signup,
    enable_device_linking: configs.enable_device_linking,
    video_content_genre: configs.video_content_genre,
    test_info_screen: configs.test_info_screen,
    marketplace_connect_svod: configs.marketplace_connect_svod,
    subscription_plan_ids: configs.subscription_plan_ids,
    enable_segment_analytics: configs.enable_segment_analytics,
    segment_source_write_key: configs.segment_source_write_key,
    advanced_analytics_enabled: configs.advanced_analytics_enabled,
    advanced_analytics_customerid: configs.advanced_analytics_customerid,
    enable_top_navigation: configs.enable_top_navigation
  })

  if configs.google_analytics_tracking_id <> invalid and configs.google_analytics_tracking_id <> "" then

      m.global.addFields({ google_analytics_tracking_id: configs.google_analytics_tracking_id,
                           google_analytics_enable : true
                         })
      SetGoogleAnalyticsTracker(configs.google_analytics_tracking_id)
  else
    m.global.addFields({ google_analytics_tracking_id: "",
                         google_analytics_enable : false
                       })
  end if

  if (configs.favorites_via_api = true)
      ' Clear local favorites
      m.favorites_storage_service.ClearFavorites()
      m.favorites_management_service.SetFavoriteIds({})
  end if
end function

' Called at startup. Sets up m.global.auth
function SetGlobalAuthObject() as void
  current_user_info = m.current_user.getInfo()
  if current_user_info._id <> invalid and current_user_info._id <> "" then is_logged_in = true else is_logged_in = false
  if current_user_info.email <> invalid then user_email = current_user_info.email else user_email = ""

  native_sub_purchases = m.roku_store_service.getUserNativeSubscriptionPurchases()

  valid_native_subs = []

  if current_user_info.subscription_count <> invalid then universal_sub_count = current_user_info.subscription_count else universal_sub_count = 0

  if m.global.native_to_universal_subscription = false
    valid_native_subs = m.roku_store_service.getUserNativeSubscriptionPurchases()
  end if

  entitlements = {}
  oauth = RegReadAccessToken()

  if oauth <> invalid and oauth.access_token <> invalid
    videoEntitlements = GetEntitledVideos({
      access_token: oauth.access_token,
      per_page: 500,
      page: 1
      sort: "created_at",
      order: "desc"
    })

    if videoEntitlements <> invalid
      for each entitlement in videoEntitlements
        videoId = entitlement["video_id"]
        entitlements[videoId] = videoId
      end for
    end if
  end if

  m.global.addFields({ auth: {
    nativeSubCount: valid_native_subs.count(),
    universalSubCount: universal_sub_count,
    isLoggedIn: is_logged_in,
    isLinked: current_user_info.linked,
    email: user_email,
    entitlements: entitlements,
    userId : current_user_info._id
  } })


  ' If active natve plan, set plan
  latest_native_sub = m.roku_store_service.latestNativeSubscriptionPurchase()

  m.global.addFields({ nsvod: {
    currentPlan: latest_native_sub
  } })
end function

function SetVersion() as void
    if m.global <> invalid then m.global.addFields({ version: GetApiConfigs().version })
end function

function SetTextLabels() as void
    if m.global <> invalid
        text_configs = GetTextConfigs()

        labels = {}
        for each label in text_configs
            labels[label] = text_configs[label]
        end for

        m.global.addFields({ labels: labels })
    end if
end function


function SetGoogleAnalyticsTracker(trackingId as string)

  device_info = CreateObject("roDeviceInfo")

  cid = device_info.GetChannelClientId()

  ui_res = device_info.GetUIResolution()
  sr = Substitute("{0}x{1}", ui_res.width.ToStr(), ui_res.height.ToStr())

  appName = CreateObject("roAppInfo").GetTitle()
  appVersion = CreateObject("roAppInfo").GetVersion()

  UATracker = CreateObject("roAssociativeArray")
  UATracker.cid = cid
  UATracker.sr = sr
  UATracker.appName = appName + "-Roku"
  UATracker.appVersion = appVersion
  UATracker.endpoint = "https://www.google-analytics.com/collect"
  UATracker.locale = device_info.GetCurrentLocale()
  UATracker.trackingId = trackingId
  m.global.addFields({ UATracker: UATracker })

end function

function HandleDeeplinkEvent(contentId as Dynamic, mediaType as Dynamic, isInputEvent as boolean)
    print "Handle DeeplinkEvent : " isInputEvent
    m.contentID = contentId
    mediaType = mediaType

    if (m.contentID <> invalid)
        if (isInputEvent) then
            StartLoader()
        end if

        if mediaType = "episode" or mediaType = "season"
          contentIds = DeepLinkingHelpers().parseContentId(m.contentID, "-")
          ' contentIds should be ["playlistId", "videoId"]

          if contentIds.count() >= 2
            playlists = GetPlaylists({ id: contentIds[0] })
            validPlaylist = (playlists.count() > 0 and playlists[0].active)

            linkedVideo = GetVideo(contentIds[1])
            validVideo = (linkedVideo.DoesExist("_id") and linkedVideo.active = true)

            if validPlaylist
              playlistVideos = GetPlaylistVideos(playlists[0]._id, {"dpt": "true", "per_page": m.app.per_page})

              index = 0
              for each video in playlistVideos
                if video._id = linkedVideo._id
                    exit for
                end if
                index = index + 1
              end for

              if index < playlistVideos.count() ' was able to find video in playlist videos
                transitionToNestedPlaylist(contentIds[0], index)
              else
                transitionToNestedPlaylist(contentIds[0], 0)
              end if

              if validVideo and mediatype = "episode"
                transitionToVideoPlayer(linkedVideo)
              end if
            end if
          end if
        else if mediaType = "series"
          playlists = GetPlaylists({ id: m.contentID })
          valid_playlist = (playlists.count() > 0 and playlists[0].active)

          if valid_playlist
            transitionToNestedPlaylist(m.contentID)
          end if
        else if mediaType <> invalid
          linkedVideo = GetVideo(m.contentID)
          ' If m.contentID is for active video
          if linkedVideo.DoesExist("_id") and linkedVideo.active = true
            transitionToVideoPlayer(linkedVideo)
          end if
        end if

      ' Close loading screen if still visible
      if m.LoadingScreen.visible = true
        EndLoadingScreen()

        ' Trigger grid screen refocus if visible
        if m.gridScreen.visible = true
          m.scene.gridContent = m.scene.gridContent
        end if
      end if

      if (isInputEvent) then
          EndLoader()
      end if
    end if
end function
