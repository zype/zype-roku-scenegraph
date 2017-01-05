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
        m.contentStack.push(m.gridScreen.content)
        m.top.playlistItemSelected = true
    else
        ? "[HomeScene] Detail Screen"
        m.gridScreen.visible = "false"
        m.detailsScreen.content = m.gridScreen.focusedContent
        m.detailsScreen.setFocus(true)
        m.detailsScreen.visible = "true"
        m.screenStack.push(m.detailsScreen)
    end if
End Function

' On Menu Button Selected
Function OnMenuButtonSelected()
    ? "[HomeScene] Menu Button Selected"
    ? m.Menu.itemSelected

    ' Menu is visible - it must be last element
    menu = m.screenStack.pop()
    menu.visible = false
    if m.Menu.itemSelected = -1 then ' Home
        if m.detailsScreen.visible = true or m.gridScreen.visible = true then ' if Details or Grid (Home) opened 
            m.screenStack.peek().visible = true
            m.screenStack.peek().setFocus(true)
        else ' must be Search or About opened
            screen = m.screenStack.pop()
            screen.visible = false
            
            m.screenStack.peek().visible = true
            m.screenStack.peek().setFocus(true)
        end if
    else if m.Menu.itemSelected = 3 then ' Favorites
        m.screenStack.peek().visible = false ' hide last opened screen
        
        ' add Favorites screen to Screen stack
        m.screenStack.push(m.Favorites)

        ' show and focus Favorites
        m.Favorites.visible = true
        m.Favorites.setFocus(true)

    else if m.Menu.itemSelected = 0 then ' Search
        m.screenStack.peek().visible = false ' hide last opened screen
        
        ' add Search screen to Screen stack
        m.screenStack.push(m.Search)

        ' show and focus Search
        m.Search.visible = true
        m.Search.setFocus(true)

        m.top.SearchString = ""
                m.top.ResultsText = ""
    else if m.Menu.itemSelected = 2 then ' Device Linking
        m.screenStack.peek().visible = false ' hide last opened screen

        ' add Device Linking screen to screen stack
        m.screenStack.push(m.deviceLinking)

        ' show and focus Device Linking
        m.deviceLinking.show = true
        m.deviceLinking.setFocus(true)
    else if m.Menu.itemSelected = 1 then ' About
        m.screenStack.peek().visible = false ' hide last opened screen

        ' add Search screen to Screen stack
        m.screenStack.push(m.infoScreen)
        ' show and focus Search
        m.infoScreen.visible = true
        m.infoScreen.setFocus(true)
    end if
End Function

' Main Remote keypress event loop
Function OnKeyEvent(key, press) as Boolean
    ? ">>> HomeScene >> OnkeyEvent"
    result = false
    if press then
        if key = "options" then
            ' option key handler

            if m.Menu.visible = false then ' Prevent multiple menu clicks
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
            
            ' if Details opened
            if m.detailsScreen.visible = true and m.gridScreen.visible = false and m.detailsScreen.videoPlayerVisible = false and m.Search.visible = false and m.infoScreen.visible = false and m.deviceLinking.visible = false and m.Menu.visible = false then
                ? "1"
                ' if detailsScreen is open and video is stopped, details is lastScreen
                details = m.screenStack.pop()
                details.visible = false
                m.screenStack.peek().visible = true
                m.screenStack.peek().setFocus(true)
                result = true

            ' if video player opened
            else if m.detailsScreen.videoPlayerVisible = true then
                ? "2"
                m.detailsScreen.videoPlayerVisible = false
                result = true

            ' if search opened
            else if m.Search.visible = true and m.Search.isChildrensVisible = false then
                ? "3"
                ' if Search is visible - it must be last element
                search = m.screenStack.pop()
                search.visible = false

                ' after search pop m.screenStack.peek() == last opened screen (gridScreen or detailScreen),
                ' open last screen before search and focus it
                m.screenStack.peek().visible = true
                m.screenStack.peek().setFocus(true)
                result = true
            
            ' if favorites opened
            else if m.Favorites.visible = true and m.Favorites.isChildrensVisible = false then

                ? "6"
                ' if Search is visible - it must be last element
                favorites = m.screenStack.pop()
                favorites.visible = false

                ' after favorites pop m.screenStack.peek() == last opened screen (gridScreen or detailScreen),
                ' open last screen before favorites and focus it
                m.screenStack.peek().visible = true
                m.screenStack.peek().setFocus(true)
                result = true

            else if m.infoScreen.visible = true
                ? "4"
                ' if Info is visible - it must be last element
                info = m.screenStack.pop()
                info.visible = false

                ' after info pop m.screenStack.peek() == last opened screen (gridScreen or detailScreen),
                ' open last screen before info and focus it
                m.screenStack.peek().visible = true
                m.screenStack.peek().setFocus(true)
                result = true

            ' if menu opened
            else if m.Menu.visible = true then
                ? "5"
                ' if Menu is visible - it must be last element
                menu = m.screenStack.pop()
                menu.visible = false

                ' after menu pop m.screenStack.peek() == last opened screen (gridScreen or detailScreen),
                ' open last screen before search and focus it
                m.screenStack.peek().visible = true
                m.screenStack.peek().setFocus(true)
                result = true

            else if m.contentStack.count() > 0 and m.gridScreen.visible = true then
                previousContent = m.contentStack.pop()
                m.gridScreen.content = previousContent 
                m.top.rowItemFocused = [0, 0]
                result = true

            else if m.deviceLinking.visible = true
                ' if Device Linking is visible - it must be last element
                search = m.screenStack.pop()
                search.show = false

                m.deviceLinking.show = false
                m.deviceLinking.setFocus(false)

                ' after Device Linking screen pop m.screenStack.peek() == last opened screen (gridScreen or detailScreen),
                ' open last screen before search and focus it
                m.screenStack.peek().visible = true
                m.screenStack.peek().setFocus(true)
                result = true
            end if

        end if
    end if
    return result
End Function
