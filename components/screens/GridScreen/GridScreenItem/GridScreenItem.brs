function init() as void
  m.itemImage = m.top.findNode("itemImage")
  m.itemImage.observeField("bitmapWidth", "OnItemImageLoaded")
  m.itemText = m.top.findNode("itemText")
  if (m.global.theme <> invalid)
    m.itemText.color = m.global.theme.primary_text_color
  end if
  m.statusImage = m.top.findNode("statusImage")
end function

' When Row Item image loaded
Sub OnItemImageLoaded()
    'print "======> ROW Item ImageNow loaded............................."
End Sub

function itemContentChanged() as void
  itemData = m.top.itemContent

  if m.itemImage <> invalid
    m.itemImage.loadDisplayMode = "scaleToFit"

    ' Poster thumbnails
    uriToSet = ""
    if itemData.usePoster
      m.itemImage.loadWidth = 147
      m.itemImage.loadHeight = 262
      if itemData.posterThumbnail <> invalid AND itemData.posterThumbnail <> ""
        uriToSet = itemData.posterThumbnail
      else
        uriToSet = itemData.HDPOSTERURL
      end if
    else
      m.itemImage.loadWidth = 262
      m.itemImage.loadHeight = 147
      uriToSet = itemData.HDPOSTERURL
    end if

    if (m.global.image_caching_support = "2")
        sha1OfImageUrl = GetEncryptedUrlString(uriToSet)
        pathObj = CheckAndGetImagePathIfAvailable(sha1OfImageUrl)
        if (pathObj.foundPath = invalid OR pathObj.foundPath = "")
            'm.itemImage.loadSync = false
            m.itemImage.uri = uriToSet
            DownloadImage(uriToSet, pathObj.newCachePath, pathObj.newTempPath)
        else
            print "===============================================================================> Grid itemImage---> found in local"
            'm.itemImage.loadSync = true
            m.itemImage.uri = pathObj.foundPath
        end if
    else
        m.itemImage.uri = uriToSet
    end if

    ' Lock icons
    offset = m.itemImage.loadwidth - 32 - 5
    if m.statusImage <> invalid
      m.statusImage.translation = [offset, 5]
      m.statusImage.visible = false
    end if

    if (m.global.inline_title_text_display = true AND itemData.TITLE <> invalid)
        m.itemText.text = itemData.TITLE
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

Function DownloadImage(imageUrl as String, newCachePath as String, newTempPath as String)
  downloadImageTask = createObject("roSGNode", "DownloadImageTask")
  downloadImageTask.bAPIStatus = "None"
  downloadImageTask.imageUrl = imageUrl
  downloadImageTask.newCachePath = newCachePath
  downloadImageTask.newTempPath = newTempPath
  downloadImageTask.observeField("bAPIStatus", "DownloadImageTaskCompleted")
  downloadImageTask.control = "RUN"
end Function

Function DownloadImageTaskCompleted(event as Object)
  task = event.GetRoSGNode()
  print "Grid Screen : DownloadImageTaskCompleted....................................." task.bAPIStatus
  task = invalid
end Function
