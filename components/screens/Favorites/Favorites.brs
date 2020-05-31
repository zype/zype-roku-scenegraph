' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********
 ' inits search
 ' creates all children
 ' sets all observers
Function Init()
    ? "[Favorites] Init"

    m.gridScreen = m.top.findNode("Grid")
    m.gridScreen.content = invalid
    m.gridScreen.visible = false
    m.detailsScreen = m.top.findNode("FavoritesDetailsScreen")

    m.top.observeField("visible", "OnTopVisibilityChange")
    m.top.observeField("rowItemSelected", "OnRowItemSelected")

    m.videoTitle = m.top.findNode("VideoTitle")
    m.NoItems = m.top.findNode("NoItems")
    m.videoTitle.text = ""
    m.NoItems.text = ""

    ' Set theme
    m.AppBackground = m.top.findNode("AppBackground")
    m.AppBackground.color = m.global.theme.background_color

    m.gridScreen.focusBitmapUri = m.global.theme.focus_grid_uri
    m.gridScreen.rowLabelColor = m.global.theme.primary_text_color

    m.videoTitle.color = m.global.theme.secondary_text_color
    m.NoItems.color = m.global.theme.secondary_text_color

    if (m.global.inline_title_text_display = true)
        m.videoTitle.visible = false
    end if

    m.resultsString = m.top.findNode("ResultsString")
    m.resultsString.color = m.global.theme.secondary_text_color
End Function

Function OnRowItemSelected()
    ' On select any item on home scene, show Details node and hide Grid
    m.gridScreen.visible = false
    m.detailsScreen.content = m.top.focusedContent
    m.detailsScreen.setFocus(true)
    m.detailsScreen.visible = true
    m.detailsScreen.IsOptionsLabelVisible = "false"
    m.detailsScreen.autoplay = false

    m.top.isChildrensVisible = true
End Function

sub OnContentChange()
    ? "[Favorites] On Content Change"
    if (m.top.content <> invalid AND m.top.content.getChild(0) <> invalid)

      print "m.top.content.getChildcount : " m.top.content.getChild(0).getChildcount()

      if (m.top.content.getChild(0).getChildcount() = 0)
          m.gridScreen.visible = false
          m.NoItems.setFocus(true)
      else
          m.NoItems.text = ""
          m.gridScreen.visible = true
          m.gridScreen.setFocus(true)
      end if
    end if

end sub

' handler of focused item in RowList
Sub OnItemFocused()
    itemFocused = m.top.itemFocused
    ' item focused should be an intarray with row and col of focused element in RowList
    If itemFocused.Count() = 2 then
        focusedContent = m.top.content.getChild(itemFocused[0]).getChild(itemFocused[1])
        if focusedContent <> invalid then
            m.top.focusedContent    = focusedContent
            'm.videoTitle.text = focusedContent.title
        end if
    end if
End Sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    ? ">>> Favorites >> onKeyEvent"
    result = false
    if press then
        ? "key == ";  key
        if key = "options" then
            result = true
        else if key = "back"
            ' if Details opened
            if m.gridScreen.visible = false and m.detailsScreen.videoPlayerVisible = false and m.NoItems.text = "" then
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
        if (m.top.content <> invalid AND m.top.content.getChild(0) <> invalid)
          if (m.top.content.getChild(0).getChildcount() > 0)
              m.gridScreen.visible = true
          end if
       end if
    else
        m.NoItems.text = ""
    end if
End Sub
