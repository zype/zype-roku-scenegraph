' ********** Copyright 2016 Zype.  All Rights Reserved. **********
 'setting top interfaces
Sub Init()
    m.top.observeField("focusedChild", "OnFocusedChildChange")

    m.buttons = m.top.findNode("MenuButtons")

    ' Set theme
    m.shade = m.top.findNode("Shade")
    m.shade.color = m.global.theme.background_color

    m.buttons.color = m.global.theme.primary_text_color
    m.buttons.focusedColor = m.global.theme.secondary_text_color
    m.buttons.focusBitmapUri = m.global.theme.button_focus_uri

    ' m.rowButtons = m.top.findNode("RowList")
    ' m.rowButtons.content = GetRowListContent()

    InitSidebarButtons()
    ' create buttons
    ' result = []
    ' print "[Menu] Init"
    ' print "m.top.isDeviceLinkingEnabled: "; m.top.isDeviceLinkingEnabled
    ' menuButtons = ["Search", "About"]
    ' if(m.top.isDeviceLinkingEnabled = true)
    '     menuButtons.push("Link Device")
    '     menuButtons.push("Favorites")
    ' end if

    ' for each button in menuButtons
    '     result.push({title : button})
    ' end for
    ' m.buttons.content = ContentList2SimpleNode(result)
End Sub

Function InitSidebarButtons()
    result = []
    print "[Menu] InitSidebarButtons"
    print "m.top.isDeviceLinkingEnabled: "; m.top.isDeviceLinkingEnabled
    menuButtons = ["Search", "About"]

    if(m.top.isDeviceLinkingEnabled = true)
        menuButtons.push("Link Device")
        menuButtons.push("Favorites")
    end if

    for each button in menuButtons
        result.push({title : button})
    end for
    m.buttons.content = ContentList2SimpleNode(result)
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

'///////////////////////////////////////////'
' Helper function convert AA to Node
Function ContentList2SimpleNode(contentList as Object, nodeType = "ContentNode" as String) as Object
    result = createObject("roSGNode",nodeType)
    if result <> invalid
        for each itemAA in contentList
            item = createObject("roSGNode", nodeType)
            item.setFields(itemAA)
            result.appendChild(item)
        end for
    end if
    return result
End Function
