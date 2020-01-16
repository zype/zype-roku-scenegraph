' ********** Copyright 2016 Zype.  All Rights Reserved. **********
 'setting top interfaces
Sub Init()
    m.top.observeField("focusedChild", "OnFocusedChildChange")

    m.content_helpers = ContentHelpers()

    m.buttons = m.top.findNode("MenuButtons")

    ' Set theme
    m.shade = m.top.findNode("Shade")
    m.shade.color = m.global.theme.background_color

    m.buttons.color = m.global.theme.primary_text_color
    m.buttons.focusedColor = m.global.theme.secondary_text_color
    m.buttons.focusBitmapUri = m.global.theme.button_focus_uri

    InitSidebarButtons()
End Sub

Function InitSidebarButtons()
    result = []
    print "[Menu] InitSidebarButtons"
    print "m.top.isDeviceLinkingEnabled: "; m.top.isDeviceLinkingEnabled
    menuButtons = [
        { title: m.global.labels.menu_search_button, role: "transition", target: "Search"},
        { title: m.global.labels.menu_info_button, role: "transition", target: "InfoScreen" }
    ]

    if m.global.enable_epg = true then menuButtons.push( { title: m.global.labels.menu_my_tv_button, role: "transition", target: "EPGScreen" } )

    if(m.global.device_linking = true )
        menuButtons.push( { title: m.global.labels.menu_account_button, role: "transition", target: "AccountScreen" } )
    end if

    if m.global.auth<>invalid
        if (m.global.auth.isLoggedIn <> invalid and m.global.auth.isLoggedIn <> false)
            menuButtons.push( { title: m.global.labels.menu_account_button, role: "transition", target: "AccountScreen" } )
        end if
    end if

    menuButtons.push({ title: m.global.labels.menu_favorites_button, role: "transition", target: "Favorites" })

    if m.global.universal_tvod
        menuButtons.push({ title: m.global.labels.menu_my_library_button, role: "transition", target: "MyLibrary" })
    end if

    if m.global.test_info_screen
      menuButtons.push( {title: "Test Info", role: "transition", target: "TestInfoScreen" } )
    end if

    m.buttons.content = m.content_helpers.oneDimList2ContentNode(menuButtons, "ButtonNode")
End Function

' on Menu Button press handler
Sub onItemSelected()
    ? "[Menu] Button selected"
    index = m.top.itemSelected
    m.top.itemSelectedRole = currentButtonRole(index)
    m.top.itemSelectedTarget = currentButtonTarget(index)
End Sub

' set proper focus to Buttons in case if return from Video PLayer
Sub OnFocusedChildChange()
    if m.top.isInFocusChain() and not m.buttons.hasFocus() then
        m.buttons.setFocus(true)
    end if
End Sub

function currentButtonRole(index as integer) as string
    return m.buttons.content.getChild(index).role
end function

function currentButtonTarget(index as integer) as string
    return m.buttons.content.getChild(index).target
end function
