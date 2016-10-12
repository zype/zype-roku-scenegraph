' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********
 ' inits search
 ' creates all children
 ' sets all observers
Function Init()
    ? "[Search] Init"

    m.keyboard = m.top.findNode("Keyboard")
    m.gridScreen = m.top.findNode("Grid")

    m.gridScreen.content = {}

    m.detailsScreen = m.top.findNode("SearchDetailsScreen")
    m.resultsText = m.top.findNode("resultsText")

    m.keyboard.textEditBox.textColor = "0x777777"
    m.top.observeField("visible", "OnTopVisibilityChange")
    m.top.observeField("rowItemSelected", "OnRowItemSelected")

    m.videoTitle = m.top.findNode("VideoTitle")
    m.videoTitle.text = ""
End Function

Function OnRowItemSelected()
    ' On select any item on home scene, show Details node and hide Grid
    m.gridScreen.visible = "false"
    m.detailsScreen.content = m.top.focusedContent
    m.detailsScreen.setFocus(true)
    m.detailsScreen.visible = "true"
    m.detailsScreen.IsOptionsLabelVisible = "false"

    m.top.isChildrensVisible = true
End Function

sub OnContentChange()
    m.keyboard.setFocus(true)
end sub

' handler of focused item in RowList
Sub OnItemFocused()
    itemFocused = m.top.itemFocused
    ' item focused should be an intarray with row and col of focused element in RowList
    If itemFocused.Count() = 2 then
        focusedContent = m.top.content.getChild(itemFocused[0]).getChild(itemFocused[1])
        if focusedContent <> invalid then
            m.top.focusedContent    = focusedContent

            ? "print: ", focusedContent
            m.videoTitle.text = focusedContent.title
        end if
    end if
End Sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    ? ">>> Search >> onKeyEvent"
    result = false
    if press then
        ? "key == ";  key
        if key="down" then
            m.gridScreen.setFocus(true)
            result = true
        else if key="up" then
            m.keyboard.setFocus(true)
            result = true
        else if key = "options" then
            result = true
        else if key = "back"
            ' if Details opened
            if m.gridScreen.visible = false and m.detailsScreen.videoPlayerVisible = false then
                m.detailsScreen.visible = false
                m.gridScreen.setFocus(true)
                m.gridScreen.visible = true
                m.top.isChildrensVisible = false
                result = true

            ' if video player opened
            else if m.detailsScreen.videoPlayerVisible = true then
                m.detailsScreen.videoPlayerVisible = false
                result = true
            end if

        end if
    end if
    return result
end function

Sub OnTopVisibilityChange()
    if m.top.visible = true
        m.keyboard.setFocus(true)
        m.gridScreen.visible = true
    end if
End Sub
