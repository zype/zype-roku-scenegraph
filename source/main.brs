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

    m.current_user = CurrentUser()

    SetTheme()
    SetFeatures()
    SetMonetizationSettings()

    m.scene = screen.CreateScene("HomeScene")
    m.port = CreateObject("roMessagePort")
    screen.SetMessagePort(m.port)
    screen.Show()

    m.store = CreateObject("roChannelStore")
    ' m.store.FakeServer(true)
    m.store.SetMessagePort(m.port)
    m.purchasedItems = []
    m.productsCatalog = []
    m.playlistRows = []
    m.videosList = []

    m.roku_store_service = RokuStoreService(m.store, m.port)
    m.auth_state_service = AuthStateService()
    m.bifrost_service = BiFrostService()
    m.raf_service = RafService()

    SetGlobalAuthObject()

    m.LoadingScreen = m.scene.findNode("LoadingScreen")

    m.loadingIndicator = m.scene.findNode("loadingIndicator")
    m.loadingIndicator1 = m.scene.findNode("loadingIndicator1")


    m.playlistsRowItemSizes = []
    m.playlistRowsSpacings = []

    ' Start loader if deep linked
    if contentID <> invalid
      m.loadingIndicator.control = "stop"
      StartLoader()
    end if

    ' getUserPurchases()
    ' getProductsCatalog()

    m.contentID = contentID

    m.detailsScreen = m.scene.findNode("DetailsScreen")

    'm.scene.gridContent = ParseContent(GetContent()) ' Uses featured categories (depreciated)
    m.gridContent = ParseContent(GetPlaylistsAsRows(m.app.featured_playlist_id))

    m.gridScreen = m.scene.findNode("GridScreen")
    rowlist = m.gridScreen.findNode("RowList")
    rowlist.rowItemSize = m.playlistsRowItemSizes
    rowlist.rowSpacings = m.playlistRowsSpacings

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

    m.detailsScreen.observeField("itemSelected", m.port)
    m.detailsScreen.productsCatalog = m.productsCatalog
    m.detailsScreen.observeField("triggerPlay", m.port)
    m.detailsScreen.dataArray = m.playlistRows

    m.scene.videoliststack = [m.videosList]
    m.detailsScreen.videosTree = m.scene.videoliststack.peek()
    m.detailsScreen.autoplay = m.app.autoplay

    m.AuthSelection = m.scene.findNode("AuthSelection")
    m.AuthSelection.plans = m.roku_store_service.GetNativeSubscriptionPlans()
    m.AuthSelection.observeField("itemSelected", m.port)
    m.AuthSelection.observeField("planSelected", m.port)

    m.UniversalAuthSelection = m.scene.findNode("UniversalAuthSelection")
    m.UniversalAuthSelection.observeField("itemSelected", m.port)

    m.SignInScreen = m.scene.findNode("SignInScreen")
    m.SignInScreen.header = "Sign in to existing account"
    m.SignInScreen.observeField("itemSelected", m.port)

    m.SignUpScreen = m.scene.findNode("SignUpScreen")
    m.SignUpScreen.header = "Create an account"
    m.SignUpScreen.observeField("itemSelected", m.port)

    m.AccountScreen = m.scene.findNode("AccountScreen")
    m.AccountScreen.observeField("itemSelected", m.port)

    m.scene.observeField("SearchString", m.port)

    m.scene.observeField("playlistItemSelected", m.port)
    m.scene.observeField("TriggerDeviceUnlink", m.port)

    user_info = m.current_user.getInfo()

    m.deviceLinking = m.scene.findNode("DeviceLinking")
    m.deviceLinking.DeviceLinkingURL = m.app.device_link_url
    m.deviceLinking.isDeviceLinked = user_info.linked
    m.deviceLinking.observeField("show", m.port)
    m.deviceLinking.observeField("itemSelected", m.port)

    m.TestInfoScreen = m.scene.findNode("TestInfoScreen")

    if m.global.auth.isLoggedIn
      if m.global.auth.isLinked then GetAndSaveNewToken("device_linking") else GetAndSaveNewToken("login")
    end if

    LoadLimitStream() ' Load LimitStream Object

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
            if isLoggedIn() = true OR (linkedVideo.subscription_required = false and linkedVideo.purchase_required = false)
              if m.app.avod = true
                playVideoWithAds(m.detailsScreen, {"app_key": GetApiConfigs().app_key})
              else
                playVideo(m.detailsScreen, {"app_key": GetApiConfigs().app_key})
              end if
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

    while(true)
        msg = wait(0, m.port)
        msgType = type(msg)

        print "msg.getField(): "; msg.getField()
        print "msg.getData(): "; msg.getData()
        print "msg.getNode(): "; msg.getNode()

        if msgType = "roSGNodeEvent"
            if m.app.autoplay = true AND msg.getField() = "triggerPlay" AND msg.getData() = true then
              RemakeVideoPlayer()
              RemoveVideoIdForResumeFromReg(m.detailsScreen.content.id)
              playRegularVideo(m.detailsScreen)
            else if msg.getField() = "playlistItemSelected" and msg.GetData() = true and m.gridScreen.focusedContent.contentType = 2 then
                m.loadingIndicator.control = "start"
                m.gridScreen.playlistItemSelected = false
                content = m.gridScreen.focusedContent

                ' Get Playlist object from the platform
                playlistObject = GetPlaylists({ id: content.id.tokenize(":")[0] })
                playlistThumbnailLayout = playlistObject[0].thumbnail_layout

                m.gridContent = ParseContent(GetPlaylistsAsRows(content.id, playlistThumbnailLayout))

                rowList = m.gridScreen.findNode("RowList")
                rowlist.rowItemSize = m.playlistsRowItemSizes
                rowlist.rowSpacings = m.playlistRowsSpacings
                rowlist.jumpToRowItem = [0,0]

                m.scene.gridContent = m.gridContent

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
            else if (msg.getNode() = "FavoritesDetailsScreen" or msg.getNode() = "SearchDetailsScreen" or msg.getNode() = "DetailsScreen" or msg.getNode() = "AuthSelection" or msg.getNode() = "UniversalAuthSelection" or msg.getNode() = "SignInScreen" or msg.getNode() = "SignUpScreen" or msg.getNode() = "AccountScreen") and msg.getField() = "itemSelected" then

                ' access component node content
                if msg.getNode() = "FavoritesDetailsScreen"
                    lclScreen = m.favoritesDetailsScreen
                else if msg.getNode() = "SearchDetailsScreen"
                    lclScreen = m.searchDetailsScreen
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
                else if msg.getNode() = "AccountScreen"
                    lclScreen = m.AccountScreen
                end if

                index = msg.getData()

                handleButtonEvents(index, lclscreen)

            else if msg.getNode() = "AuthSelection" and msg.getField() = "planSelected" then
              app_info = CreateObject("roAppInfo")

              plan = m.AuthSelection.currentPlanSelected
              already_purchased = m.roku_store_service.alreadyPurchased(plan.code)

              already_purchased_message = "It appears you have already purchased this plan before. If you cancelled your subscription, please renew your subscription on the Roku website. " + chr(10) + chr(10) + "Then you can sign in with your " + app_info.getTitle() + " account to sync your subscription."

              if already_purchased
                CreateDialog(m.scene, "Already purchased", already_purchased_message, ["Close"])
              else
                if m.global.auth.isLoggedIn then handleNativeToUniversal() else m.scene.transitionTo = "SignUpScreen"
              end if

            else if msg.getField() = "position"
                print m.videoPlayer.position
                if(m.videoPlayer.position >= 30 and m.videoPlayer.content.onAir = false)
                    AddVideoIdForResumeToReg(m.gridScreen.focusedContent.id,m.videoPlayer.position.ToStr())
                    AddVideoIdTimeSaveForResumeToReg(m.gridScreen.focusedContent.id,startDate.asSeconds().ToStr())
                end if
                ' if(m.on_air)
                '   if GetLimitStreamObject() <> invalid
                '     GetLimitStreamObject().played = GetLimitStreamObject().played + 1
                '     if IsPassedLimit(GetLimitStreamObject().played, GetLimitStreamObject().limit)
                '         if IsLinked({"linked_device_id": GetUdidFromReg(), "type": "roku"}).linked = false
                '             m.videoPlayer.visible = false
                '             m.videoPlayer.control = "stop"
                '             dialog = createObject("roSGNode", "Dialog")
                '             dialog.title = "Limit Reached"
                '             dialog.optionsDialog = true
                '             dialog.message = GetLimitStreamObject().message
                '             m.scene.dialog = dialog
                '         else
                '             oauth = GetAccessTokenWithPin(GetApiConfigs().client_id, GetApiConfigs().client_secret, GetUdidFromReg(), GetPin(GetUdidFromReg()))
                '             if oauth <> invalid
                '                 id = m.videoPlayer.content.id.tokenize(":")[0]
                '                 if IsEntitled(id, {"access_token": oauth.access_token}) = false
                '                     m.videoPlayer.visible = false
                '                     m.videoPlayer.control = "stop"
                '                     dialog = createObject("roSGNode", "Dialog")
                '                     dialog.title = "Limit Reached"
                '                     dialog.optionsDialog = true
                '                     dialog.message = GetLimitStreamObject().message
                '                     m.scene.dialog = dialog
                '                 end if
                '             else
                '                 print "No OAuth available"
                '             end if
                '         end if
                '     end if
                '   end if
                ' end if
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

                if res <> invalid
                  m.scene.TriggerDeviceUnlink = false
                  m.auth_state_service.updateAuthWithUserInfo(m.current_user.getInfo())

                  m.scene.gridContent = m.gridContent

                  m.deviceLinking.isDeviceLinked = true
                  m.deviceLinking.setFocus(true)
                end if
            end if ' end of field checking

        end if ' end of msgType = "roSGNodeEvent"
    end while

    print "You are exiting the app"

    if screen <> invalid then
        screen.Close()
        screen = invalid
    end if
End Sub

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

              ' get updated user info and update global auth state
              user_info = m.current_user.getInfo()

              ' if no universal subs, check if native sub purchase exists.
              ' if native sub purchased, call bifrost to check
              if user_info.subscription_count = 0
                native_sub_purchases = m.roku_store_service.getUserNativeSubscriptionPurchases()
                if native_sub_purchases.count() > 0
                  valid_native_subs = m.bifrost_service.validSubscriptions(user_info, native_sub_purchases)

                  if valid_native_subs.count() > 0 then m.auth_state_service.incrementNativeSubCount()
                end if
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
              CreateDialog(m.scene, "Success", "Your device is linked", ["Continue"])
              exit while
          end if
      end if

      sleep(5000)
  end while
end function

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

' sub playLiveVideo(screen as Object)
'     if HasUDID() = false or IsLinked({"linked_device_id": GetUdidFromReg(), "type": "roku"}).linked = false
'         playVideo(screen, {"app_key": GetApiConfigs().app_key})
'     else
'         oauth = GetAccessTokenWithPin(GetApiConfigs().client_id, GetApiConfigs().client_secret, GetUdidFromReg(), GetPin(GetUdidFromReg()))
'         if oauth <> invalid
'
'             if IsEntitled(screen.content.id, {"access_token": oauth.access_token}) = true
'                 playVideo(screen, {"access_token": oauth.access_token})
'             else
'                 playVideo(screen, {"app_key": GetApiConfigs().app_key})
'             end if
'         else
'             print "No OAuth available"
'         end if
'     end if
' end sub

sub playRegularVideo(screen as Object)
    print "PLAY REGULAR VIDEO"
    di = CreateObject("roDeviceInfo")
    user_info = m.current_user.getInfo()

    if user_info.subscription_count <> invalid and user_info.subscription_count > 0
      oauth = m.current_user.getOAuth()
      auth = {"access_token": oauth.access_token, "uuid": di.GetDeviceUniqueId()}
    else
      auth = {"app_key": GetApiConfigs().app_key, "uuid": di.GetDeviceUniqueId()}
    end if

    if m.app.avod = true
      playVideoWithAds(screen, auth)
    else
      playVideo(screen, auth)
    end if
end sub

sub playVideo(screen as Object, auth As Object)
    playerInfo = GetPlayerInfo(screen.content.id, auth)

    screen.content.stream = playerInfo.stream
    screen.content.streamFormat = playerInfo.streamFormat
    screen.content.url = playerInfo.url

    ' If video source is not available
    if(screen.content.streamFormat = "(null)")
      CloseVideoPlayer()
      CreateVideoUnavailableDialog()
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
    playerInfo = GetPlayerInfo(screen.content.id, auth)

    print "screen.content.streamFormat: "; type(screen.content.streamFormat)
    screen.content.stream = playerInfo.stream
    screen.content.streamFormat = playerInfo.streamFormat
    screen.content.url = playerInfo.url

    ' If video source is not available
    if(screen.content.streamFormat = "(null)")
      CloseVideoPlayer()
      CreateVideoUnavailableDialog()
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

        if m.global.auth.nativeSubCount > 0 or m.global.auth.universalSubCount > 0 then is_subscribed = true else is_subscribed = false

        no_ads = (m.global.swaf and is_subscribed)

        ' Getting ad timings from video's scheduled ads
        preroll_ad = invalid
        midroll_ads = []
        if playerInfo.scheduledAds.count() > 0 and no_ads = false
          for each ad in playerInfo.scheduledAds
            if ad.offset = 0
              preroll_ad = {
                url: ad.url,
                offset: ad.offset
              }
            else
              midrollAd = {
                url: ad.url,
                offset: ad.offset,
              }
              midroll_ads.push(midrollAd)
            end if
          end for
        end if

        m.loadingIndicator.control = "stop"

        playContent = true

        ' preroll ad
        if preroll_ad <> invalid
          playContent = m.raf_service.playAds(playerInfo.video, preroll_ad.url)
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
            if midroll_ads.count() > 0
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

            end if ' end of midroll ad if statement

        else
          CloseVideoPlayer()
        end if ' end of if playContent
    end if
end sub

sub CloseVideoPlayer()
  m.detailsScreen.videoPlayer.visible = false
  m.detailsScreen.videoPlayer.setFocus(false)
  m.detailsScreen.videoPlayerVisible = false

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

    if m.global.auth.isLoggedIn
        user_info = m.current_user.getInfo()
        oauth_info = m.current_user.getOAuth()

        videoFavorites = GetVideoFavorites(user_info._id, {"access_token": oauth_info.access_token, "per_page": "100"})

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

    if m.global.auth.isLoggedIn
        user_info = m.current_user.getInfo()
        oauth_info = m.current_user.getOAuth()

        videoFavorites = GetVideoFavorites(user_info._id, {"access_token": oauth_info.access_token, "per_page": "100"})

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
    playlist_id = playlist_id.tokenize(":")[0]
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
    parent_id = parent_id.tokenize(":")[0]
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

    parent_id = parent_id.tokenize(":")[0]
    if m.app.per_page <> invalid
      per_page = m.app.per_page
    else
      per_page = 500
    end if

    m.playlistsRowItemSizes = []
    m.playlistRowsSpacings = []

    rawPlaylists = GetPlaylists({"parent_id": parent_id, "dpt": "true", "sort": "priority", "order": "dsc", "per_page": per_page, "page": 1})

    favs = GetFavoritesIDs()

    if rawPlaylists.count() = 0
      if thumbnail_layout = "poster"
        m.playlistsRowItemSizes.push( [ 147, 262 ] )
        m.playlistrowsSpacings.push( 60 )
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
              m.playlistrowsSpacings.push( 60 )
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
    button_target = screen.itemSelectedTarget

    ? chr(10)
    ? tab(4) "main >>> handleButtonEvents()"
    ? tab(4) "screen: "; screen.id
    ? tab(4) "button role: "; button_role
    ? tab(4) "button target: "; button_target
    ? chr(10)

    if button_role = "play"
      RemakeVideoPlayer()
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
    else if button_role = "swaf"
      m.scene.transitionTo = "AuthSelection"
    else if button_role = "device_linking"
      m.DeviceLinking.show = true

    else if button_role = "signout"
      user_info = m.current_user.getInfo()
      pin = GetPin(GetUdidFromReg())
      if user_info.linked then UnlinkDevice(user_info._id, pin, {})

      LogOut()
      user_info = m.current_user.getInfo()
      m.auth_state_service.updateAuthWithUserInfo(user_info)

      m.AccountScreen.resetText = true
      m.scene.goBackToNonAuth = true

      ' Reset details screen buttons
      m.detailsScreen.content = m.detailsScreen.content

      sleep(500)
      CreateDialog(m.scene, "Success", "You have been signed out.", ["Close"])
    else if button_role = "submitCredentials" and screen.id = "SignInScreen"
      if screen.email <> "" and screen.password <> "" then login_response = Login(GetApiConfigs().client_id, GetApiConfigs().client_secret, screen.email, screen.password) else login_response = invalid

      if login_response <> invalid
        m.SignInScreen.reset = true

        ' get recent user info and update global auth state
        user_info = m.current_user.getInfo()

        ' if no universal subs, check if native sub purchase exists.
        ' if native sub purchased, call bifrost to check
        if user_info.subscription_count = 0
          native_sub_purchases = m.roku_store_service.getUserNativeSubscriptionPurchases()
          if native_sub_purchases.count() > 0
            valid_native_subs = m.bifrost_service.validSubscriptions(user_info, native_sub_purchases)

            if valid_native_subs.count() > 0 then m.auth_state_service.incrementNativeSubCount()
          end if
        end if

        user_info = m.current_user.getInfo()
        m.auth_state_service.updateAuthWithUserInfo(user_info)

        m.scene.gridContent = m.gridContent

        ' m.scene.transitionTo = "AccountScreen"
        m.scene.goBackToNonAuth = true

        ' Reset details screen
        m.detailsScreen.content = m.detailsScreen.content

        sleep(500)
        CreateDialog(m.scene, "Success", "Signed in as: " + user_info.email, ["Close"])
      else
        sleep(500)
        CreateDialog(m.scene, "Error", "Could not find user with that email and password.", ["Close"])
      end if

    else if button_role = "submitCredentials" and screen.id = "SignUpScreen"
      if screen.email = "" or screen.password = ""
        CreateDialog(m.scene, "Error", "Email or Password is empty. Cannot create account", ["Close"])
      else
        create_consumer_response = CreateConsumer({ "consumer[email]": screen.email, "consumer[password]": screen.password, "consumer[name]": "" })

        if create_consumer_response <> invalid
          login_response = Login(GetApiConfigs().client_id, GetApiConfigs().client_secret, screen.email, screen.password)
          m.SignUpScreen.reset = true
          m.scene.goBackToNonAuth = true

          handleNativeToUniversal()
        else
          CreateDialog(m.scene, "Error", "It appears that email was taken.", ["Close"])
        end if

      end if
    else if button_role = "transition" and button_target = "AuthSelection"
      m.scene.transitionTo = "AuthSelection"
    else if button_role = "transition" and button_target = "UniversalAuthSelection"
      m.scene.transitionTo = "UniversalAuthSelection"
    else if button_role = "transition" and button_target = "DeviceLinking"
      m.DeviceLinking.show = true
      m.DeviceLinking.setFocus(true)
    else if button_role = "transition" and button_target = "SignInScreen"
      m.scene.transitionTo = "SignInScreen"
    end if
end function

function handleNativeToUniversal() as void
  ' Get updated user info
  user_info = m.current_user.getInfo()
  m.auth_state_service.updateAuthWithUserInfo(user_info)

  plan = m.AuthSelection.currentPlanSelected

  order = [{
    code: plan.code,
    qty: 1
  }]

  ' Make nsvod purchase
  purchase_subscription = m.roku_store_service.makePurchase(order)

  if purchase_subscription.success
    m.auth_state_service.incrementNativeSubCount()

    ' Get recent purchase
    recent_purchase = purchase_subscription.receipt

    bifrost_params = {
      app_key: GetApiConfigs().app_key,
      consumer_id: user_info._id,
      site_id: GetApiConfigs().zype_api_key,
      subscription_plan_id: recent_purchase.code,
      roku_api_key: GetApiConfigs().roku_api_key,
      transaction_id: UCase(recent_purchase.purchaseId),
      device_type: "roku"
    }

    ' Check is subscription went through with BiFrost. BiFrost should validate then create universal subscription
    native_sub_status = GetNativeSubscriptionStatus(bifrost_params)

    if native_sub_status <> invalid and native_sub_status.is_valid
        user_info = m.current_user.getInfo()

        ' Create new access token. Creating sub does not update entitlements for access tokens created before subscription
        if user_info.linked then GetAndSaveNewToken("device_linking") else GetAndSaveNewToken("login")
        m.auth_state_service.updateAuthWithUserInfo(user_info)

        ' Refresh lock icons with grid screen content callback
        m.scene.gridContent = m.gridContent

        m.scene.goBackToNonAuth = true

        ' details screen should update self
        m.detailsScreen.content = m.detailsScreen.content

        sleep(500)
        CreateDialog(m.scene, "Welcome", "Hi, " + user_info.email + ". Thanks for signing up.", ["Close"])
    end if ' native_sub_status.valid

  ' User cancelled purchase or error from Roku store
  else
    CreateDialog(m.scene, "Incomplete", "Was not able to complete purchase. Please try again later.", ["Close"])
  end if
end function


' Seting details screen's RemakeVideoPlayer value to true recreates Video component
'     Roku Video component performance degrades significantly after multiple uses, so we make a new one
function RemakeVideoPlayer() as void
    m.detailsScreen.RemakeVideoPlayer = true
    m.detailsScreen.VideoPlayer.seek = 0.0
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

Function markFavoriteButton(lclScreen)
    idParts = lclScreen.content.id.tokenize(":")
    id = idParts[0]

    if m.global.auth.isLoggedIn
        favs = GetFavoritesIDs()

        user_info = m.current_user.getInfo()
        oauth_info = m.current_user.getOAuth()

        if lclScreen.content.inFavorites = false
            print "CreateVideoFavorite"
            CreateVideoFavorite(user_info._id, {"access_token": oauth_info.access_token, "video_id": id })
            lclScreen.content.inFavorites = true
        else
            print "DeleteVideoFavorite"
            DeleteVideoFavorite(user_info._id, favs[id], {"access_token": oauth_info.access_token, "video_id": id, "_method": "delete"})
            lclScreen.content.inFavorites = false
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
    swaf: configs.subscribe_to_watch_ad_free,
    enable_lock_icons: configs.enable_lock_icons
    test_info_screen: configs.test_info_screen
  })
end function

' Called at startup. Sets up m.global.auth
function SetGlobalAuthObject() as void
  current_user_info = m.current_user.getInfo()
  if current_user_info._id <> invalid and current_user_info._id <> "" then is_logged_in = true else is_logged_in = false
  if current_user_info.email <> invalid then user_email = current_user_info.email else user_email = ""

  native_sub_purchases = m.roku_store_service.getUserNativeSubscriptionPurchases()

  valid_native_subs = []

  if current_user_info.subscription_count <> invalid then universal_sub_count = current_user_info.subscription_count else universal_sub_count = 0

  ' If native sub purchases, check for valid native subscriptions
  if native_sub_purchases.count() > 0 and is_logged_in and universal_sub_count = 0
    valid_native_subs = m.bifrost_service.validSubscriptions(current_user_info, native_sub_purchases)
    current_user_info = m.current_user.getInfo()
  end if

  m.global.addFields({ auth: {
    nativeSubCount: valid_native_subs.count(),
    universalSubCount: universal_sub_count,
    isLoggedIn: is_logged_in,
    isLinked: current_user_info.linked,
    email: user_email
  } })
end function
