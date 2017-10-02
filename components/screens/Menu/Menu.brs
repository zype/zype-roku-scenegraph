' ********** Copyright 2016 Zype.  All Rights Reserved. **********
 'setting top interfaces
Sub Init()
    m.content_helpers = ContentHelpers()


    m.top.observeField("focusedChild", "OnFocusedChildChange")

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
        { title: "Search", role: "transition", target: "Search"},
        { title: "About", role: "transition", target: "InfoScreen" }
    ]

    if(m.top.isDeviceLinkingEnabled = true)
        menuButtons.push({ title: "Link Device", role: "transition", target: "DeviceLinking" })
    end if

    if m.top.isDeviceLinkingEnabled = true or (m.global.local_favorites <> invalid and m.global.local_favorites = true)
        menuButtons.push({ title: "Favorites", role: "transition", target: "Favorites" })
    end if

    m.buttons.content = m.content_helpers.oneDimList2ContentNode(menuButtons, "ButtonNode")
End Function

Function GetRowListContent() as object
    'Populate the RowList content here
    data = CreateObject("roSGNode", "ContentNode")

    row = data.CreateChild("ContentNode")
    row.title = "Menu Buttons"

    return data
End Function

' on Menu Button press handler
Sub onItemSelected()
    ? "[Menu] Button selected"
    index = m.top.itemSelected
    m.top.itemSelectedRole = currentButtonRole(index)
    m.top.itemSelectedTarget = currentButtonTarget(index)
End Sub

' on Row List content change
Sub onContentChange()
    ? "[Menu] Row List content changed"
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
