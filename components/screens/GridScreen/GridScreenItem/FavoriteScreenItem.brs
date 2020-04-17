function init() as void
  m.itemImage = m.top.findNode("itemImage")
  m.statusImage = m.top.findNode("statusImage")
  m.itemText=m.top.findNode("itemText")
  m.itemText.color = m.global.theme.primary_text_color
  m.statusImageGroup = m.top.findNode("statusImageGroup")
  m.statusImageBG = m.top.findNode("statusImageBG")
end function

function itemContentChanged() as void
  itemData = m.top.itemContent
  if m.itemImage <> invalid
    m.itemImage.loadDisplayMode = "scaleToFit"

    ' Poster thumbnails
    if itemData.usePoster
      m.itemImage.loadWidth = 147
      m.itemImage.loadHeight = 262
      if itemData.posterThumbnail <> invalid AND itemData.posterThumbnail <> ""
        m.itemImage.uri = itemData.posterThumbnail
      else
        m.itemImage.uri = itemData.HDPOSTERURL
      end if
    else
      m.itemImage.loadWidth = 262
      m.itemImage.loadHeight = 147
      m.itemImage.uri = itemData.HDPOSTERURL
    end if

    if (m.global.inline_title_text_display = true AND itemData.TITLE <> invalid)
        m.itemText.text = itemData.TITLE
    end if

    ' Lock icons
    offset = m.itemImage.loadwidth - 48 - 5
    if m.statusImageGroup <> invalid
      m.statusImageGroup.translation = [offset, 5]
      m.statusImageGroup.visible = false
    end if

    if(m.statusImageGroup <> invalid AND itemData.ContentType = 4 AND itemData.SubscriptionRequired = true AND m.global.enable_lock_icons = true)
      m.statusImageGroup.visible = true

      if m.global.auth.nativeSubCount > 0 OR m.global.auth.universalSubCount > 0
        if m.global.enable_unlock_transparent = false then
          m.statusImageGroup.visible = true
          m.statusImageBG.blendColor = m.global.custom_unlock_color
        else
          m.statusImageGroup.visible = false
        end if
      else
        m.statusImageBG.blendColor = m.global.custom_lock_color
        m.statusImage.uri = "pkg:/images/iconLocked.png"
      end if
    end if
  end if
end function
