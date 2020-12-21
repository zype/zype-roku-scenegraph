' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********
 ' inits grid screen
 ' creates all children
 ' sets all observers
Function Init()
    ' listen on port 8089
    ? "[HomeScene] Init"
    m.top.backgroundURI=""
    'm.top.backgroundColor="#000000"

    currentTime = CreateObject("roDateTime")
    m.top.uniqueSessionID = getAdsAppID() + "-" + currentTime.asSeconds().toStr()

    print "m.top.uniqueSessionID > " m.top.uniqueSessionID

    m.menuHideTimer = m.top.findNode("menuHideTimer")
    m.menuHideTimer.observeField("fire", "TriggerHideMenu")


    if (m.global.enable_segment_analytics = true)
        if (m.global.segment_source_write_key <> invalid AND m.global.segment_source_write_key <> "")
            print "[HomeScene] INFO : SEGMENT ANALYTICS ENABLED..."
            task = m.top.findNode("libraryTask")
            m.library = SegmentAnalyticsConnector(task)

            config = {
              writeKey: m.global.segment_source_write_key
              debug: false
              queueSize: 1
              retryLimit: 1
            }

            m.library.init(config)

            isInstalledKeyFound = RegRead("IsInstalled","IsInstalled")
            if (isInstalledKeyFound = invalid OR isInstalledKeyFound <> "1")
                RegWrite("IsInstalled", "1", "IsInstalled")

                ' Send application installed event only once when its not in registry'
                SendAppInstalledOrOpenedSegmentAnalyticsEvent(false)
            end if

            ' Send application opened event'
            SendAppInstalledOrOpenedSegmentAnalyticsEvent(true)
        else
            print "[HomeScene] ERROR : SEGMENT ANALYTICS > Missing Account ID. Please set 'segment_source_write_key' in config.json"
        end if
    else
        print "[HomeScene] INFO : SEGMENT ANALYTICS IS NOT ENABLED..."
    end if

    ' GridScreen node with RowList
    m.gridScreen = m.top.findNode("GridScreen")

    ' DetailsScreen Node with description, Video Player
    m.detailsScreen = m.top.findNode("DetailsScreen")

    ' Menu
    m.Menu = m.top.findNode("Menu")
    ' Observer  to handle Menu Item selection inside Menu
    m.Menu.observeField("itemSelected", "OnMenuButtonSelected")

    ' TopMenu
    m.TopMenu = m.top.findNode("TopMenu")

    ' Observer  to handle Menu Item selection inside Menu
    m.TopMenu.observeField("itemSelected", "OnTopMenuButtonSelected")
    m.TopMenu.observeField("menuHideAnimationCompleted", "HideTopMenu")
    m.TopMenu.observeField("menuShowAnimationCompleted", "ShowTopMenu")

    ' Device Linking
    m.deviceLinking = m.top.findNode("DeviceLinking")

    ' Search Screen with keyboard and RowList
    m.Search = m.top.findNode("Search")

    ' Favorites Screen RowList
    m.Favorites = m.top.findNode("Favorites")

    ' Info Screen
    m.infoScreen = m.top.findNode("InfoScreen")

    ' Auth Selection Screen - Confirm subscription + sign up or sign in
    m.AuthSelection = m.top.findNode("AuthSelection")

    ' Purchase Screen - Confirm purchase + sign up or sign in
    m.PurchaseScreen = m.top.findNode("PurchaseScreen")

    ' Universal Auth Selection (OAuth - signin / device link)
    m.UniversalAuthSelection = m.top.findNode("UniversalAuthSelection")

    m.SignInScreen = m.top.findNode("SignInScreen")
    m.SignUpScreen = m.top.findNode("SignUpScreen")
    m.RegistrationScreen = m.top.findNode("RegistrationScreen")

    m.AccountScreen = m.top.findNode("AccountScreen")

    ' My Library
    m.MyLibrary = m.top.findNode("MyLibrary")
    m.MyLibrary.observeField("SignInButtonSelected", "MyLibraryTriggerSignIn")

    ' Observer to handle Item selection on RowList inside GridScreen (alias="GridScreen.rowItemSelected")
    m.top.observeField("rowItemSelected", "OnRowItemSelected")

    ' array with nodes (screens) to proper handling of Search screen Open/Close
    m.screenStack = []

    ' content stack
    m.contentStack = []

    ' gridScreen is a Main Screen
    m.screenStack.push(m.gridScreen)

    ' loading indicator starts at initializatio of channel
    m.top.loadingIndicator = m.top.findNode("loadingIndicator")
    m.top.loadingScreen = m.top.findNode("LoadingScreen")
    m.TestInfoScreen = m.top.findNode("TestInfoScreen")

    'channel store'
    m.top.channelStore = m.top.findNode("store")

    ' Set theme
    m.top.loadingIndicator.backgroundColor = m.global.theme.background_color
    m.top.loadingIndicator.imageUri = m.global.theme.loader_uri

    m.autoPlayBackground = m.top.findNode("autoPlayBackground")
    m.autoPlayBackground.color = m.global.theme.background_color


    m.content_helpers = ContentHelpers()
    ' Exit confirm dialog'
    SetExitDialog()

    ' For tracking position bwtn playlist levels
    m.IndexTracker = {}

    ' For tracking thumbnail sizes and row spacing bwtn levels
    m.rowItemSizes = {}
    m.rowSpacings  = {}
    m.playListFromHeroSlider=false
    m.playListDetailFromHeroSlider=false

    m.nextVideoNode = CreateObject("roSGNode", "VideoNode")

    'timer for autoplay
    m.autoplayMessageTimer = m.top.findNode("autoplayMessageTimer")

    print "m.global.image_caching_support ============================> " m.global.image_caching_support
    if (m.global.image_caching_support = "1" OR m.global.image_caching_support = "2")
      CheckAndCreateCacheAndTempDirectories()
    end if

    m.appLaunchCompleteBeaconSent = false
End Function

Sub SendAppInstalledOrOpenedSegmentAnalyticsEvent(isOpened as boolean)
    m.top.segmentEvent = GetSegmentAppOpenedOrInstalledEventInfo(isOpened)
End Sub

function GetSegmentAppOpenedOrInstalledEventInfo(isOpened as boolean)
    eventStr = ""

    if (isOpened = true)
        eventStr = GetSegmentVideoStateEventString("appOpened")
        properties = {
                "from_background":   false,
                "referring_application": "Roku" + " " + createObject("roDeviceInfo").getModel() + " - " + getAppUniqueChannelID(),
                "url": ""
            }
    else
        eventStr = GetSegmentVideoStateEventString("appInstalled")
        appInfo = CreateObject("roAppInfo")
      	appMajorVersion = appInfo.GetValue("major_version")
      	appMinorVersion = appInfo.GetValue("minor_version")
      	appBuildVersion = appInfo.GetValue("build_version")
        properties = {
                "version":   appMajorVersion + "." + appMinorVersion, 'String (autogenerated for the user's session)
                "build":     appBuildVersion
            }
    end if

    trackObj = {
        "action": "track",
        "event": eventStr,
        "userId": getAppUniqueChannelID(), ' for Now we are setting unique ID as we are not using UserID as per requirement'
    }

    trackObj.properties = properties
    print "App Open/Installed trackObj : " trackObj
    print "App Open/Installed trackObj.properties : " trackObj.properties
    return trackObj
end function

Sub SetExitDialog()

    m.gExitDialog = m.top.findNode("gExitDialog")
    m.exitDialog = m.top.findNode("exitDialog")
    m.exitButtons = m.top.findNode("exitButtons")
    m.exitText = m.top.findNode("exitText")
    m.hiddentitle = m.top.findNode("hiddentitle")
    exitDialogRect = m.exitDialog.boundingRect()

    xPos = (1280 - exitDialogRect.width) /2
    yPos = (720 - exitDialogRect.height) /2
    app_info = CreateObject("roAppInfo")
    appTitle = app_info.GetTitle()
    if appTitle = invalid then appTitle = ""
    m.exitText.text = Substitute(m.global.labels.exit_dialog_message, appTitle)

    m.exitDialog.translation = [xPos, yPos]

    m.exitDialog.blendcolor =  m.global.theme.background_color
    print "exit background =================== > " m.global.theme.background_color
    m.exitText.color = m.global.theme.primary_text_color
    m.exitDialog.focusBitmapUri = m.global.theme.button_focus_uri

    yesLabel = m.global.labels.exit_yes_button
    noLabel = m.global.labels.exit_no_button
    exitButtons = [
          { title: yesLabel, ShortDescriptionLine1: yesLabel,  role: "transition", target: "exit" }
          { title: noLabel, ShortDescriptionLine1: noLabel,  role: "transition", target: "cancel" }
      ]

    m.hiddentitle.text = yesLabel
    yesWidth = m.hiddentitle.BoundingRect().width
    m.hiddentitle.text = noLabel
    noWidth = m.hiddentitle.BoundingRect().width
    spacing = 80
    m.exitButtons.columnWidths = [yesWidth, noWidth]
    m.exitButtons.itemSpacing = [spacing,0]
    m.exitButtons.itemSize = [0, noWidth]
    m.exitButtons.numColumns = 2
    m.exitButtons.content = m.content_helpers.oneDimList2ContentNode(exitButtons, "ExitNode")
    xPos = (800 - (yesWidth + noWidth + spacing ))/ 2
    m.exitButtons.translation = [xPos ,125]
    ' m.showMenuAnimation.control = "start"
    m.exitButtons.jumpToItem = 0

end sub

Sub onSegmentEventChanged()
    if m.top.segmentEvent<>invalid
        segmentEventInfo = m.top.segmentEvent
        segmentEventAction = segmentEventInfo.action
        segmentEventString = segmentEventInfo.event

        if (m.global.enable_segment_analytics = true)
            if (m.global.segment_source_write_key <> invalid AND m.global.segment_source_write_key <> "")
                if (segmentEventAction = "track")
                    ' Get ID'
                    anonymousId = getAdID()
                    if (anonymousId = "")
                        ' Try get using channelID'
                        anonymousId = getAdsAppID()
                        if (anonymousId = "")
                            ' Not able to find unique id - Should never occur but its error handling as Segment need atleast one options'
                            anonymousId = "anonymousId"
                        end if
                    end if
                    options = {
                      "anonymousId": anonymousId
                    }
                    print "options : " options
                    m.library.track(segmentEventString, segmentEventInfo.properties, options)
                end if
            else
                print "[HomeScene] ERROR : SEGMENT ANALYTICS > Missing Account ID. Please set 'segment_source_write_key' in config.json"
            end if
        else
           print "[HomeScene] INFO : SEGMENT ANALYTICS IS NOT ENABLED..."
        end if
    end if
End SUb

' Add positions based on index starting from 0
' If you add 2 positions: [1,3] and [2,4]
  ' It should look like this at the end:
    '  m.IndexTracker = {
    '     "0": {
    '       "row": 1,
    '       "col": 3
    '     },
    '     "1": {
    '       "row": 2,
    '       "col": 4
    '     }
    ' }
Function AddCurrentPositionToTracker(data = invalid) as Void
    rowList = m.gridScreen.findNode("RowList")
    rowItemSelected = rowList.rowItemSelected

    playlistLevel = Str(m.IndexTracker.count())

    m.IndexTracker[playlistLevel] = {}
    m.IndexTracker[playlistLevel].row = rowItemSelected[0]
    m.IndexTracker[playlistLevel].col = rowItemSelected[1]
End Function

Function GetLastPositionFromTracker() as Object
    index = Str(m.IndexTracker.count() - 1)
    return m.IndexTracker[index]
End Function

Function DeleteLastPositionFromTracker() as Void
    index = Str(m.IndexTracker.count() - 1)

    m.IndexTracker.Delete(index)
End Function

Function AddPosterPlaylists() as Void
    rowList = m.gridScreen.findNode("RowList")
    rowItemSizes = rowList.rowItemSize
    rowSpacings = rowList.rowSpacings

    playlistLevel = Str(m.rowItemSizes.count())

    m.rowItemSizes[playlistLevel] = rowItemSizes
    m.rowSpacings[playlistLevel] = rowSpacings
End Function

Function GetLastRowItemSizes() as Object
    index = Str(m.rowItemSizes.count() - 1)
    return m.rowItemSizes[index]
End Function

Function GetLastRowSpacings() as Object
    index = Str(m.rowSpacings.count() - 1)
    return m.rowSpacings[index]
End Function

Function DeleteLastPosterPlaylists() as Void
    index = Str(m.rowItemSizes.count() - 1)

    m.rowItemSizes.Delete(index)
    m.rowSpacings.Delete(index)
End Function

' if content set, focus on GridScreen and remove loading indicator
Function OnChangeContent()
    m.gridScreen.setFocus(true)
    if m.top.IsShowAutoPlayBackground = false
        m.top.loadingIndicator.control = "stop"
    end if
End Function

Function onAutoPlayBgChange()
  if m.top.IsShowAutoPlayBackground = false
      m.top.loadingIndicator.control = "stop"
  end if
End Function

Sub carouselSelectDataSelected()
    if m.top.carouselSelectData<>invalid
        if m.top.carouselSelectData.playlistid<>invalid
            m.playListFromHeroSlider=true
            m.gridScreen.heroCarouselShow=false
            m.contentStack.push(m.gridScreen.content)
        end if
    end if
End SUb

Sub CarouselDeepLinkToDetailPage()
    m.gridScreen.visible = false
    m.detailsScreen.autoplay = false
    m.detailsScreen.content = m.top.DeepLinkToDetailPage
    m.detailsScreen.setFocus(true)
    m.detailsScreen.visible = true
    m.screenStack.push(m.detailsScreen)
ENd SUb

sub sendAppLaunchCompleteBeacon()
	if (m.appLaunchCompleteBeaconSent = false)
			print "Sending AppLaunchComplete.................................................................."
			m.top.signalBeacon("AppLaunchComplete")
			m.appLaunchCompleteBeaconSent = true
	end if
end sub

' Row item selected handler
Function OnRowItemSelected()
    ' On select any item on home scene, show Details node and hide Grid
    if m.gridScreen.focusedContent.contentType = 2 then
        ? "[HomeScene] Playlist Selected"
        m.gridScreen.heroCarouselShow=false

        AddCurrentPositionToTracker()
        AddPosterPlaylists()

        m.contentStack.push(m.gridScreen.content)
        m.top.playlistItemSelected = true

    ' Video selected
    else
        ? "[HomeScene] Detail Screen"
        m.gridScreen.visible = false

        for each key in m.gridScreen.focusedContent.keys()
          if m.nextVideoNode[key] <> invalid
          m.nextVideoNode[key] = m.gridScreen.focusedContent[key]
          end if
        end for

        rowItemSelected = m.gridScreen.findNode("RowList").rowItemSelected
        m.detailsScreen.PlaylistRowIndex = rowItemSelected[0]
        m.detailsScreen.CurrentVideoIndex = rowItemSelected[1]

        if (m.detailsScreen.videosTree <> invalid and m.detailsScreen.videosTree[rowItemSelected[0]] <> invalid)
	         m.detailsScreen.totalVideosCount = m.detailsScreen.videosTree[rowItemSelected[0]].count()
        else
            m.detailsScreen.totalVideosCount = 0
            print "Saved crash.......................--------------------------HomeScene.brs(226)-----------------------------..."
        end if

        m.gridScreen.focusedContent = m.nextVideoNode

        m.gridScreen.focusedContent.inFavorites = m.global.favorite_ids.DoesExist(m.gridScreen.focusedContent.id)

        m.detailsScreen.autoplay = m.global.autoplay
        rowContent=m.gridScreen.content.getChild(m.gridScreen.rowItemSelected[0])

        if rowContent.DESCRIPTION<>invalid
            m.detailsScreen.rowTVODInitiateContent=rowContent
        end if
        m.detailsScreen.content = m.gridScreen.focusedContent
        m.detailsScreen.setFocus(true)
        m.detailsScreen.visible = true
        if m.playListFromHeroSlider = true then m.playListDetailFromHeroSlider = true
        m.screenStack.push(m.detailsScreen)
        print "m.gridScreen.focusedContent: "; type(m.gridScreen.focusedContent)
    end if
End Function

Function OnDeepLink()
  m.screenStack.push(m.detailsScreen)
End Function

function PushScreenIntoScreenStack(screen) as void
  m.screenStack.push(screen)
end function

function PushContentIntoContentStack(content) as void
  m.contentStack.push(content)
end function

function transitionToScreen() as void
  if focusedChild() = "GridScreen" then AddCurrentPositionToTracker() : PushContentIntoContentStack(m.gridScreen.content)

  m.screenStack.peek().setFocus(false)
  m.screenStack.peek().visible = false

  screen = m.top.findNode(m.top.transitionTo)

  PushScreenIntoScreenStack(screen)
  print "transitionToScreen 1 "
  screen.visible = true
  print "transitionToScreen 2 "
  screen.setFocus(true)
  print "transitionToScreen 3 "
end function

function resetFocusToScreen() as void
      prevScreen = m.screenStack.peek()
      if prevScreen <> invalid then
        prevScreen.visible = true
        prevScreen.setFocus(true)
      end if
end function

function resetToScreen() as void
    if m.top.resetTo = "AccountScreen" or m.top.resetTo = "AuthSelection" Then
      prevScreen = m.screenStack.peek()
      if prevScreen <> invalid then
        prevScreen.visible = true
        prevScreen.setFocus(true)
      end if
    end if
end function

function backToScreen() as void
    print " backToScreen "  m.top.backScreen
    if m.top.backScreen = "AccountScreen" or m.top.backScreen = "AuthSelection" Then
        screen = m.screenStack.pop()
        if screen <> invalid then screen.visible = false

        ' after screen pop m.screenStack.peek() == last opened screen (gridScreen or detailScreen),
        ' open last screen before it and focus it
        prevScreen = m.screenStack.peek()
        if prevScreen <> invalid then
          prevScreen.visible = true
          prevScreen.setFocus(true)
        end if
    end if

end function

function goBackToNonAuthCallback() as void

  ' keep removing and hiding auth related screens until reach last non auth screen
  while isAuthScreen(m.screenStack.peek().id)
    auth_screen = m.screenStack.pop()
    auth_screen.visible = false
    auth_screen.setFocus(false)
  end while

  ' show and refocus last non auth screen
  m.screenStack.peek().visible = true
  m.screenStack.peek().setFocus(true)
end function

function isAuthScreen(screen_id as string) as boolean
  auth_screen_ids = [
    "AccountScreen",
    "AuthSelection",
    "CredentialsInput",
    "DeviceLinking",
    "UniversalAuthSelection",
    "SignInScreen",
    "SignUpScreen",
    "RegistrationScreen",
    "PurchaseScreen"
  ]

  for each auth_id in auth_screen_ids
    if screen_id = auth_id then return true
  end for

  return false
end function

function focusedChild() as string
  return m.top.focusedChild.id
end function

' On Menu Button Selected
Function OnMenuButtonSelected()
    ? "[HomeScene] Menu Button Selected"
    ? m.Menu.itemSelected

    button_role = m.Menu.itemSelectedRole
    button_target = m.Menu.itemSelectedTarget
    MenuActionAsPerRoleTarget(button_role, button_target)
End Function

' On TopMenu Button Selected
Function OnTopMenuButtonSelected()
    ? "[HomeScene] Top Menu Button Selected"
    ? m.TopMenu.itemSelected

    button_role = m.TopMenu.itemSelectedRole
    button_target = m.TopMenu.itemSelectedTarget

    MenuActionAsPerRoleTarget(button_role, button_target)
end function

Function MenuActionAsPerRoleTarget(button_role as string, button_target as string)

    ' Menu is visible - it must be last element
    menu = m.screenStack.pop()
    menu.visible = false

    if button_role = "transition" and button_target = "Search"
      m.top.SearchString = ""
      m.top.ResultsText = ""
      m.top.transitionTo = "Search"
    else if button_role = "transition" and button_target = "EPGScreen"
'      m.top.findNode("EPGScreen").reset = true
      m.top.transitionTo = "EPGScreen"
    else if button_role = "transition" and button_target = "InfoScreen"
      m.top.transitionTo = "InfoScreen"
    else if button_role = "transition" and button_target = "Favorites"
      m.top.transitionTo = "Favorites"
    else if button_role = "transition" and button_target = "AccountScreen"
        m.top.transitionTo = "AccountScreen"
      else if button_role = "transition" and button_target = "GridScreen"
          m.top.transitionTo = "GridScreen"
    else if button_role = "transition" and button_target = "AuthSelection"
        m.top.transitionTo = "AuthSelection"
    else if button_role = "transition" and button_target = "TestInfoScreen"
        m.top.transitionTo = "TestInfoScreen"
    else if button_role = "transition" and button_target = "DeviceLinking"
        m.deviceLinking.show = true
        m.top.transitionTo = "DeviceLinking"
    else if button_role = "transition" and button_target = "MyLibrary"
        m.top.transitionTo = "MyLibrary"
    end if
end function

function TriggerHideMenu()
    m.TopMenu.callFunc("TriggerHideMenu")
end function

function TriggerShowMenu()
    m.TopMenu.callFunc("TriggerShowMenu")
end function

function ShowMenu()
    ' add Menu screen to Screen stack
    m.screenStack.push(m.Menu)

    ' show and focus Menu
    m.Menu.visible = true
    m.Menu.setFocus(true)


end function


function ShowTopMenu()

    if (m.TopMenu.menuShowAnimationCompleted = true)
        m.TopMenu.menuShowAnimationCompleted = false


       currentTopScreen = m.screenStack.peek()

       if (currentTopScreen <> invalid)
         if currentTopScreen.id = "Search"
             m.top.LastSelectedMenu = m.global.labels.menu_search_button
         else if currentTopScreen.id = "MyLibrary"
             m.top.LastSelectedMenu = m.global.labels.menu_my_library_button
         else if currentTopScreen.id = "Favorites"
             m.top.LastSelectedMenu = m.global.labels.menu_favorites_button
         else if currentTopScreen.id = "AccountScreen"
             m.top.LastSelectedMenu = m.global.labels.menu_account_button
         else if currentTopScreen.id = "GridScreen"
             m.top.LastSelectedMenu = m.global.labels.menu_home_button
         else if currentTopScreen.id = "InfoScreen"
             m.top.LastSelectedMenu = m.global.labels.menu_info_button
         else if currentTopScreen.id = "TestInfoScreen"
             m.top.LastSelectedMenu = m.global.labels.menu_test_info_button
         else if currentTopScreen.id = "AuthSelection"
             m.top.LastSelectedMenu = m.global.labels.menu_account_button
         else
             m.top.LastSelectedMenu = m.global.labels.menu_home_button
         end if
       end if


       ' m.global.labels.menu_live_button

      ' add Menu screen to Screen stack
        m.screenStack.push(m.TopMenu)
        m.top.appendChild(m.TopMenu)
        if (m.gridScreen <> invalid)
            m.gridScreen.visibleSliderSelector = false
        end if
        ' show and focus Top Menu
        m.TopMenu.visible = true
        m.TopMenu.setFocus(true)
    end if


end function

function HideMenu()
    details = m.screenStack.pop()
    details.visible = false

    lastScreen = m.screenStack.peek()
    print "Hidemenu " lastScreen
    if (lastScreen <> invalid)
      lastScreen.visible = true
      lastScreen.setFocus(true)
    end if
end function

function HideTopMenu()

    if (m.gridScreen <> invalid)
        m.gridScreen.visibleSliderSelector = true
    end if
    if (m.TopMenu.menuHideAnimationCompleted = true)
        m.TopMenu.menuHideAnimationCompleted = false
        if m.screenStack.peek() <> invalid AND m.screenStack.peek().id = "TopMenu"
            print ">>>>>>>>>>>>>>>>>>>> m.screenStack.peek().id ::: " m.screenStack.peek().id
            menu = m.screenStack.pop()
            menu.visible = false
            m.top.removeChild(m.TopMenu)
            lastScreen = m.screenStack.peek()
            ' print "lastscreen  " lastScreen
            if (lastScreen <> invalid)
              lastScreen.visible = true
              lastScreen.setFocus(true)
            end if
        end if
    end if
end function

function ShowMenuAndStartHideMenuTimer()
    m.menuHideTimer.control = "start"
    TriggerShowMenu()
end function

function StopHideMenuTimer()
    m.menuHideTimer.control = "stop"
end function

function MyLibraryTriggerSignIn() as void
    button_role = m.MyLibrary.itemSelectedRole
    button_target = m.MyLibrary.itemSelectedTarget

    if button_role = "transition" and button_target = "AuthSelection"
        m.top.transitionTo = button_target
    end if
end function

' Main Remote keypress event loop
Function OnKeyEvent(key, press) as Boolean
    ? ">>> HomeScene >> OnkeyEvent"
    ? "key: "; key
    ? "press: "; press
    ? "m.screenStack.count(): "; m.screenStack.count()
    result = false
    if m.gExitDialog.visible = true
        return true
    end if
    if press then
        if key = "options" then
            ' option key handler

            if m.detailsScreen.videoPlayer.hasFocus() then
                result = true
            else if m.global.enable_top_navigation = false
                if m.Menu.visible = false then ' Prevent multiple menu clicks
                  ShowMenu()
            else
                  HideMenu()
            end if
            else if m.global.enable_top_navigation = true
                if m.TopMenu.visible = false then ' Prevent multiple top menu clicks
                  TriggerShowMenu()
                else
                  TriggerHideMenu()
                end if
            end if
        else if key = "back" AND m.TopMenu.visible = true
          TriggerHideMenu()
          result = true
        else if key = "up"
          if m.detailsScreen.videoPlayer.visible = true
            result = true
          else if m.global.enable_top_navigation = true and m.TopMenu.visible = false then' Prevent multiple menu clicks
              ' add Menu screen to Screen stack
              TriggerShowMenu()
              result = true
          end if
        else if key = "back"
            isSpecialScreen = isSpecialScreen()
            ? "isSpecialScreen(): "; isSpecialScreen
            if m.top.loadingIndicator.control = "start" then
                return true
            end if
            if isSpecialScreen
                    m.gridScreen.heroCarouselShow=false
                if m.detailsScreen.visible = true and m.gridScreen.visible = false and m.detailsScreen.videoPlayerVisible = false and m.Search.visible = false and m.infoScreen.visible = false and m.deviceLinking.visible = false and m.Menu.visible = false and m.TopMenu.visible = false then
                    ? "1"
                    ' if detailsScreen is open and video is stopped, details is lastScreen
                    details = m.screenStack.pop()
                    if (details.videoPlayer <> invalid)
                      details.videoPlayer.control = "stop"
                      details.videoPlayer.visible = false
                      details.videoPlayer.setFocus(false)
                    end if

                    details.visible = false
                    ?"m.screenStack==>"m.screenStack
                    m.screenStack.peek().visible = true
                    m.screenStack.peek().setFocus(true)

                    if m.screenStack.peek().id = "Search"
                    SearchGrid = m.screenStack.peek().findNode("Grid")
                    SearchGrid.visible = false

                    SearchDetailsScreen = m.screenStack.peek().findNode("SearchDetailsScreen")
                    SearchDetailsScreen.videoPlayerVisible = false
                    end if
                    if m.playListFromHeroSlider=true and m.playListDetailFromHeroSlider = false then
                        contentStackCount = m.contentStack.count()
                        m.contentStack.pop()
                        m.playListFromHeroSlider=false
                        m.gridScreen.moveFocusToheroCarousel=true
                   end if
                    result = true

                ' if video player opened
                else if m.detailsScreen.videoPlayerVisible = true then
                    ? "2"
                    m.detailsScreen.videoPlayerVisible = false
                    m.detailsScreen.videoPlayer.control = "stop"
                    m.detailsScreen.videoPlayer.visible = false
                    m.detailsScreen.videoPlayer.setFocus(false)

                    m.detailsScreen.visible = true
                    if m.playListFromHeroSlider = true then m.playListDetailFromHeroSlider = true
                    m.detailsScreen.setFocus(true)
                    result = true
               else if  m.playListFromHeroSlider=true then
                    ?m.contentStack
                    previousContent = m.contentStack[0]
                    m.gridScreen.content = previousContent
                    m.contentStack.pop()
                    lastPosition = GetLastPositionFromTracker()
                    lastRowItemSizes = GetLastRowItemSizes()
                    lastRowSpacings = GetLastRowSpacings()

                    video_list_stack =  m.top.videoliststack
                    video_list_stack.pop()
                    m.top.videoliststack = video_list_stack

                    m.detailsScreen.videosTree = m.top.videoliststack.peek()
                    result = true
                    m.gridscreen.visible=true
                    m.gridScreen.heroCarouselShow=true
                    m.gridScreen.moveFocusToheroCarousel=true
                    m.playListFromHeroSlider=false
                else if m.contentStack.count() > 0 and m.gridScreen.visible = true then
                    previousContent = m.contentStack.pop()

                    lastPosition = GetLastPositionFromTracker()
                    if (lastPosition <> invalid)
	                    lastRowItemSizes = GetLastRowItemSizes()
	                    lastRowSpacings = GetLastRowSpacings()
	                    m.gridScreen.content = previousContent

	                    video_list_stack =  m.top.videoliststack
	                    video_list_stack.pop()
	                    m.top.videoliststack = video_list_stack

	                    m.detailsScreen.videosTree = m.top.videoliststack.peek()

	                    DeleteLastPositionFromTracker()
	                    DeleteLastPosterPlaylists()


	                    rowList = m.gridScreen.findNode("RowList")
	                    rowList.rowItemSize = lastRowItemSizes
	                    rowList.rowSpacings = lastRowSpacings
	                    rowList.jumpToRowItem = [lastPosition.row, lastPosition.col]
                      	result = true
                    else
                      	result = false
                    end if
                else if m.deviceLinking.visible = true
                    ' If link device was launched from detail screen, do not run the following two lines.
                    if (m.detailsScreen.visible = false)
                        screen = m.screenStack.pop()
                        screen.show = false
                    end if

                    m.deviceLinking.show = false
                    m.deviceLinking.setFocus(false)

                    m.screenStack.peek().visible = true
                    m.screenStack.peek().setFocus(true)

                    if m.screenStack.peek().id = "MyLibrary" then m.screenStack.peek().findNode("SignInButton").setFocus(true)

                    result = true
                end if
            else    ' For all other screens
                if(m.screenStack.peek().id <> "GridScreen")    ' All cases except when closing the app from the Grid Screen
                    ' if the screen is visible - it must be the last element
                    screen = m.screenStack.pop()
                    screen.visible = false
                    if m.playListFromHeroSlider = true and m.playListDetailFromHeroSlider = true and m.top.dialog = invalid then
                        m.playListDetailFromHeroSlider = false
                    end if
                    ' after screen pop m.screenStack.peek() == last opened screen (gridScreen or detailScreen),
                    ' open last screen before it and focus it
                    m.screenStack.peek().visible = true
                    m.screenStack.peek().setFocus(true)
                    result = true
                else
                    m.gExitDialog.visible = true
                    m.gridScreen.exitDialogOpen = true
                    m.exitButtons.setFocus(true)
                    result = true
                end if
            end if
        end if
    end if

    ' Dialog boxes handler
    ' press = false when key event happens to component inside children
    if press = false then

        print "Dialog: "; m.top.dialog
        if key = "back" and ((m.top.loadingIndicator.control = "start" or m.top.loadingScreen.visible = true) or m.gExitDialog.visible = true)then
              return true
        end if

        if key = "back" AND m.top.dialog = invalid and m.dialogdetail = invalid AND not isSpecialScreen()
            m.gridScreen.heroCarouselShow=true
        end if

        if(m.top.dialog <> invalid)
            buttonIndex = m.top.dialog.buttonSelected
            if(buttonIndex = 0 AND key = "OK" AND m.top.dialog.title = "Device Unlink Confirmation")
                m.top.TriggerDeviceUnlink = true
                m.top.dialog.close = true
                m.top.dialog = invalid
                m.dialogdetail = invalid
            else if((buttonIndex = 0 and key = "OK" AND m.top.dialog.title <> "Closed caption/audio configuration") OR (buttonIndex = 1 and key = "OK" AND m.top.dialog.title = "Device Unlink Confirmation"))
                m.top.dialog.close = true
                m.top.dialog = invalid
                m.dialogdetail = invalid
                m.screenStack.peek().visible = true
                m.screenStack.peek().setFocus(true)

            end if
            print "buttonIndex: "; buttonIndex; " buttonKey: "; key
        else
            if key = "back" AND (m.top.dialog = invalid and m.dialogdetail = invalid)
                m.screenStack.peek().visible = true
                m.screenStack.peek().setFocus(true)
                if m.dialogdetail <> invalid then m.dialogdetail = invalid
            end if
        end if

        if key = "OK" then
          ' Search open and RowList item was clicked
          '   - should copy over Search.content to DetailsScreen.content and refocus to DetailsScreen
          if m.Search.visible = true and m.Search.focusedChild <> invalid and m.Search.focusedChild.id = "SearchDetailsScreen"
            m.detailsScreen.content = m.Search.focusedContent

            ' Hide Search
            m.Search.visible = false
            SearchDetailsScreen = m.Search.findNode("SearchDetailsScreen")
            SearchDetailsScreen.visible = false
            SearchDetailsScreen.setFocus(false)
            m.Search.setFocus(false)


            ' Refocus on DetailsScreen
            m.screenStack.push(m.detailsScreen)

            m.detailsScreen.autoplay = false
            m.detailsScreen.visible = true
            if m.playListFromHeroSlider = true then m.playListDetailFromHeroSlider = true
            m.detailsScreen.setFocus(true)
          end if
        end if
    end if

    return result
End Function

Function OpenPreviousScreen()

  screen = m.screenStack.pop()
  screen.visible = false
  if m.playListFromHeroSlider = true and m.playListDetailFromHeroSlider = true and m.top.dialog = invalid then
      m.playListDetailFromHeroSlider = false
  end if
  ' after screen pop m.screenStack.peek() == last opened screen (gridScreen or detailScreen),
  ' open last screen before it and focus it
  m.screenStack.peek().visible = true
  m.screenStack.peek().setFocus(true)


end function

Function isSpecialScreen()
    ? " isSpecialScreen "
    ? m.screenStack.peek()
    if m.screenStack.peek().id = "Menu" or m.screenStack.peek().id = "TopMenu"
        return false
    else if m.playListFromHeroSlider = true and m.playListDetailFromHeroSlider = true then
            return false
    else if (m.detailsScreen.visible = true) OR (m.contentStack.count() > 0 and m.gridScreen.visible = true) OR (m.deviceLinking.visible = true)
        return true
    else
        return false
    end if
End Function

Sub exitButtonSelected()
    index = m.top.exitItemSelected
    selectedOption = m.exitButtons.itemFocused
    print "selectedOption " index
    if index = 0
      m.top.outRequest = {"ExitApp": true}
    else
      print " set visible false for exit"
      m.gExitDialog.visible = false
      m.gridScreen.exitDialogOpen = false
      resetFocusToScreen()
    end if
end sub

' Takes screen and creates dialog for it
function CreateDialog(screen, title, message, buttons, setDialogDetail = false)
  m.top.dialog = invalid
  m.dialogdetail = invalid
  dialog = createObject("roSGNode", "Dialog")
  dialog.title = title
  dialog.message = message
  dialog.optionsDialog = false
  dialog.buttons = buttons
  dialog.observeField("buttonSelected", "DialogButtonSelected")

  m.top.dialog = dialog
  if setDialogDetail = true then
    m.dialogdetail = dialog
  end if

end function

sub DialogButtonSelected()
    if (m.top.dialog <> invalid) then
        m.top.dialog.close = true
        m.top.dialog = invalid
        m.dialogdetail = invalid
    end if
end sub

sub SetAutoPlayTimer()
    print "m.top.autoplaytimer >> " m.top.autoplaytimer
    if m.top.autoplaytimer = 1
        msg = m.top.findNode("autoplayMessage")
        msg.visible = true
        m.autoplayMessageTimer.control = "start"
        m.autoplayMessageTimer.observeField("fire", "hideAutoplayMessage")
    else if m.top.autoplaytimer = 2
        hideAutoplayMessage()
    end if
end sub

sub hideAutoplayMessage()
    msg = m.top.findNode("autoplayMessage")
    if msg <> invalid
        msg.visible = false
    end if
end sub


Function GetPlaylistVideosFunc(data, perPage) as Void
    if (data <> invalid)
        m.myTaskCount = 0
        m.myCurrentFinishedTaskCount = 0
        m.myVideoList = {}
        for each item in data
            print "item.playlist_item_count------------- " item.playlist_item_count
            if item.playlist_item_count > 0
                print "Getting data for : " item.title
                m.myTaskCount ++
                GetPlaylistVideosThroughTask(item._id, perPage)
            end if
        end for

        if (m.myTaskCount = 0) then
            m.top.allDataReceived = true
        end if
    end if
End Function

function GetPlaylistVideosThroughTask(idVal as string, perPage as integer)
      getPlaylistVideosTask = createObject("roSGNode", "GetVideoListTask")
      getPlaylistVideosTask.idVal = idVal
      getPlaylistVideosTask.perPage = perPage
      getPlaylistVideosTask.observeField("videoResult", "GetVideoListTaskCompleted")
      getPlaylistVideosTask.control = "RUN"
end function

Function GetVideoListTaskCompleted(event as Object)
    task = event.GetRoSGNode()
    m.myVideoList[task.idVal] = task.videoResult

    m.myCurrentFinishedTaskCount++
    print "m.myCurrentFinishedTaskCount : " m.myCurrentFinishedTaskCount
    if (m.myCurrentFinishedTaskCount >= m.myTaskCount)
        print "All async task responses received......................................................... "
        m.top.myVideosArray = m.myVideoList
        m.top.allDataReceived = true
    end if
end Function
