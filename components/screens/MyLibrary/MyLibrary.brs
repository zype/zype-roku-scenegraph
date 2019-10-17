' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********
Function Init()
    m.content_helpers = ContentHelpers()

    m.gridScreen = m.top.findNode("Grid")
    m.gridScreen.content = invalid
    m.detailsScreen = m.top.findNode("MyLibraryDetailsScreen")

    m.videoTitle = m.top.findNode("VideoTitle")
    m.videoTitle.text = ""

    if (m.global.inline_title_text_display = true)
        m.gridScreen.itemComponentName = "MyLibraryItem"
        m.gridScreen.itemSize=[1327, 262]
        m.videoTitle.visible = false
    end if

    m.top.observeField("visible", "OnTopVisibilityChange")
    m.top.observeField("rowItemSelected", "OnRowItemSelected")

    ' Set theme
    m.AppBackground = m.top.findNode("AppBackground")
    m.AppBackground.color = m.global.theme.background_color

    m.gridScreen.focusBitmapUri = m.global.theme.focus_grid_uri
    m.gridScreen.rowLabelColor = m.global.theme.primary_text_color

    m.videoTitle = m.top.findNode("VideoTitle")
    m.videoTitle.color = m.global.theme.secondary_text_color

    m.resultsString = m.top.findNode("ResultsString")
    m.resultsString.color = m.global.theme.secondary_text_color

    m.SignInButton = m.top.findNode("SignInButton")
    m.SignInButton.color = m.global.theme.primary_text_color
    m.SignInButton.focusedColor = m.global.theme.primary_text_color
    m.SignInButton.focusBitmapUri = m.global.theme.button_focus_uri
    m.SignInButton.content = m.content_helpers.oneDimList2ContentNode([{ title: m.global.labels.sign_in_button, role: "transition", target: "AuthSelection" }], "ButtonNode")
    m.SignInButton.visible = false
End Function

Function OnRowItemSelected()
    if m.top.focusedContent.isPaginator <> invalid and m.top.focusedContent.isPaginator
        m.top.paginatorSelected = true
    else
        ' On select any item on home scene, show Details node and hide Grid
        m.gridScreen.visible = false
        m.detailsScreen.content = m.top.focusedContent
        ' m.detailsScreen.isLoggedIn = m.top.isLoggedIn
        m.detailsScreen.setFocus(true)
        m.detailsScreen.visible = true
        m.detailsScreen.IsOptionsLabelVisible = "false"
        m.detailsScreen.autoplay = false

        m.top.isChildrensVisible = true
    end if
End Function

sub OnContentChange()
    ? "[MyLibrary] On Content Change"
end sub

' handler of focused item in RowList
Sub OnItemFocused()
    itemFocused = m.top.itemFocused
    ' item focused should be an intarray with row and col of focused element in RowList
    If itemFocused.Count() = 2 then
        focusedContent = m.top.content.getChild(itemFocused[0]).getChild(itemFocused[1])
        if focusedContent <> invalid then
            m.top.focusedContent    = focusedContent
            m.videoTitle.text = focusedContent.title

            if focusedContent.isPaginator = true then m.top.paginate = true
        end if
    end if
End Sub

sub OnSignInButtonSelected()
    m.top.itemSelectedRole = "transition"
    m.top.itemSelectedTarget = "AuthSelection"
end sub

function currentButtonRole(index as integer) as string
    return m.SignInButton.content.getChild(index).role
end function

function currentButtonTarget(index as integer) as string
    return m.SignInButton.content.getChild(index).target
end function

function onKeyEvent(key as String, press as Boolean) as Boolean
    ? ">>> MyLibrary >> onKeyEvent"
    result = false
    if press then
        ? "key == ";  key
        if key = "options" then
            result = true
        else if key = "back"
            ' if Details opened
            if m.gridScreen.visible = false and m.detailsScreen.videoPlayerVisible = false then
                itemFocused = m.top.itemFocused

                m.detailsScreen.visible = false
                m.gridScreen.setFocus(true)

                m.gridScreen.jumpToRowItem = itemFocused

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
        m.gridScreen.setFocus(false)
    else
        m.videoTitle.text = ""
    end if
End Sub
