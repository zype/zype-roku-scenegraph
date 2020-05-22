function init() as void
  m.itemImage = m.top.findNode("itemImage")
  m.itemText=m.top.findNode("itemText")
  if (m.global.theme <> invalid)
    m.itemText.color = m.global.theme.primary_text_color
  end if
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
  end if
end function
