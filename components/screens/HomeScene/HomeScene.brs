' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********
 ' inits grid screen
 ' creates all children
 ' sets all observers
Function Init()
    ' listen on port 8089
    ? "[HomeScene] Init"

    ' GridScreen node with RowList
    m.gridScreen = m.top.findNode("GridScreen")

    ' DetailsScreen Node with description, Video Player
    m.detailsScreen = m.top.findNode("DetailsScreen")

    ' Menu
    m.Menu = m.top.findNode("Menu")
    ' Observer  to handle Menu Item selection inside Menu
    m.Menu.observeField("itemSelected", "OnMenuButtonSelected")

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
    m.loadingIndicator = m.top.findNode("loadingIndicator")

    m.TestInfoScreen = m.top.findNode("TestInfoScreen")

    ' Set theme
    m.loadingIndicator.backgroundColor = m.global.theme.background_color
    m.loadingIndicator.imageUri = m.global.theme.loader_uri

    ' For tracking position bwtn playlist levels
    m.IndexTracker = {}

    ' For tracking thumbnail sizes and row spacing bwtn levels
    m.rowItemSizes = {}
    m.rowSpacings  = {}

    m.nextVideoNode = CreateObject("roSGNode", "VideoNode")
End Function

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
    m.loadingIndicator.control = "stop"
End Function

' Row item selected handler
Function OnRowItemSelected()
    ' On select any item on home scene, show Details node and hide Grid
    ? m.gridScreen.focusedContent.contenttype
    if m.gridScreen.focusedContent.contentType = 2 then
        ? "[HomeScene] Playlist Selected"

        AddCurrentPositionToTracker()
        AddPosterPlaylists()

        m.contentStack.push(m.gridScreen.content)
        m.top.playlistItemSelected = true

    ' Video selected
    else
        ? "[HomeScene] Detail Screen"
        m.gridScreen.visible = "false"

        for each key in m.gridScreen.focusedContent.keys()
          m.nextVideoNode[key] = m.gridScreen.focusedContent[key]
        end for

        rowItemSelected = m.gridScreen.findNode("RowList").rowItemSelected
        m.detailsScreen.PlaylistRowIndex = rowItemSelected[0]
        m.detailsScreen.CurrentVideoIndex = rowItemSelected[1]
        m.detailsScreen.totalVideosCount = m.detailsScreen.videosTree[rowItemSelected[0]].count()

        m.gridScreen.focusedContent = m.nextVideoNode

        m.gridScreen.focusedContent.inFavorites = m.global.favorite_ids.DoesExist(m.gridScreen.focusedContent.id)

        m.detailsScreen.autoplay = m.global.autoplay
        m.detailsScreen.content = m.gridScreen.focusedContent
        m.detailsScreen.setFocus(true)
        m.detailsScreen.visible = "true"
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

  screen.visible = true
  screen.setFocus(true)
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

    ' Menu is visible - it must be last element
    menu = m.screenStack.pop()
    menu.visible = false

    if button_role = "transition" and button_target = "Search"
      m.top.SearchString = ""
      m.top.ResultsText = ""
      m.top.transitionTo = "Search"
    else if button_role = "transition" and button_target = "InfoScreen"
      m.top.transitionTo = "InfoScreen"
    else if button_role = "transition" and button_target = "Favorites"
      m.top.transitionTo = "Favorites"
    else if button_role = "transition" and button_target = "AccountScreen"
        m.top.transitionTo = "AccountScreen"
    else if button_role = "transition" and button_target = "TestInfoScreen"
        m.top.transitionTo = "TestInfoScreen"
    else if button_role = "transition" and button_target = "DeviceLinking"
        m.deviceLinking.show = true
        m.top.transitionTo = "DeviceLinking"
    else if button_role = "transition" and button_target = "MyLibrary"
        m.top.transitionTo = "MyLibrary"
    end if
End Function

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
    if press then
        if key = "options" then
            ' option key handler

            if m.detailsScreen.videoPlayer.hasFocus() then
                result = true
            else if m.Menu.visible = false then ' Prevent multiple menu clicks
                ' add Menu screen to Screen stack
                m.screenStack.push(m.Menu)

                ' show and focus Menu
                m.Menu.visible = true
                m.Menu.setFocus(true)
            else
                details = m.screenStack.pop()
                details.visible = false
                m.screenStack.peek().visible = true
                m.screenStack.peek().setFocus(true)
            end if
        else if key = "back"
            ? "isSpecialScreen(): "; isSpecialScreen()

            if isSpecialScreen()
                if m.detailsScreen.visible = true and m.gridScreen.visible = false and m.detailsScreen.videoPlayerVisible = false and m.Search.visible = false and m.infoScreen.visible = false and m.deviceLinking.visible = false and m.Menu.visible = false then
                    ? "1"
                    ' if detailsScreen is open and video is stopped, details is lastScreen
                    details = m.screenStack.pop()
                    details.visible = false
                    m.screenStack.peek().visible = true
                    m.screenStack.peek().setFocus(true)

                    if m.screenStack.peek().id = "Search"
                    SearchGrid = m.screenStack.peek().findNode("Grid")
                    SearchGrid.visible = false

                    SearchDetailsScreen = m.screenStack.peek().findNode("SearchDetailsScreen")
                    SearchDetailsScreen.videoPlayerVisible = false
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
                    m.detailsScreen.setFocus(true)
                    result = true
                else if m.contentStack.count() > 0 and m.gridScreen.visible = true then
                    previousContent = m.contentStack.pop()

                    lastPosition = GetLastPositionFromTracker()
                    lastRowItemSizes = GetLastRowItemSizes()
                    lastRowSpacings = GetLastRowSpacings()

                    m.gridScreen.content = previousContent

                    video_list_stack =  m.top.videoliststack
                    video_list_stack.pop()
                    m.top.videoliststack = video_list_stack

                    m.detailsScreen.videosTree = m.top.videoliststack.peek()

                    DeleteLastPositionFromTracker()
                    DeleteLastPosterPlaylists()

                    result = true

                    rowList = m.gridScreen.findNode("RowList")
                    rowList.rowItemSize = lastRowItemSizes
                    rowList.rowSpacings = lastRowSpacings
                    rowList.jumpToRowItem = [lastPosition.row, lastPosition.col]
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

                    ' after screen pop m.screenStack.peek() == last opened screen (gridScreen or detailScreen),
                    ' open last screen before it and focus it
                    m.screenStack.peek().visible = true
                    m.screenStack.peek().setFocus(true)
                    result = true
                end if
            end if
        end if
    end if

    ' Dialog boxes handler
    ' press = false when key event happens to component inside children
    if press = false then
        print "Dialog: "; m.top.dialog

        if(m.top.dialog <> invalid)
            buttonIndex = m.top.dialog.buttonSelected
            if(buttonIndex = 0 AND key = "OK" AND m.top.dialog.title = "Device Unlink Confirmation")
                m.top.TriggerDeviceUnlink = true
                m.top.dialog.close = true
                m.top.dialog = invalid
            else if((buttonIndex = 0 and key = "OK" AND m.top.dialog.title <> "Closed caption/audio configuration") OR (buttonIndex = 1 and key = "OK" AND m.top.dialog.title = "Device Unlink Confirmation"))
                m.top.dialog.close = true
                m.top.dialog = invalid
            end if
            print "buttonIndex: "; buttonIndex; " buttonKey: "; key
        end if

        if key = "OK" then
          ' Search open and RowList item was clicked
          '   - should copy over Search.content to DetailsScreen.content and refocus to DetailsScreen
          if m.Search.visible = true and m.Search.focusedChild.id = "SearchDetailsScreen"
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
            m.detailsScreen.setFocus(true)
          end if
        end if
    end if

    return result
End Function

Function isSpecialScreen()
    if m.screenStack.peek().id = "Menu"
        return false
    else if (m.detailsScreen.visible = true) OR (m.contentStack.count() > 0 and m.gridScreen.visible = true) OR (m.deviceLinking.visible = true)
        return true
    else
        return false
    end if
End Function
