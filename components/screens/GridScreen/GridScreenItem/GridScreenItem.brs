function init() as void
  m.itemImage = m.top.findNode("itemImage")
  m.statusImage = m.top.findNode("statusImage")
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

    ' Lock icons
    offset = m.itemImage.loadwidth - 32 - 5
    if m.statusImage <> invalid
      m.statusImage.translation = [offset, 5]
      m.statusImage.visible = false
    end if

    if(m.statusImage <> invalid AND itemData.ContentType = 4 AND itemData.SubscriptionRequired = true AND m.global.enable_lock_icons = true)
      m.statusImage.visible = true

      if m.global.auth.nativeSubCount > 0 OR m.global.auth.universalSubCount > 0
        m.statusImage.uri = "pkg:/images/iconUnlocked.png"
      else
        m.statusImage.uri = "pkg:/images/iconLocked.png"
      end if
    end if
  end if
end function
