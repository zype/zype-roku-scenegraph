function init() as void
  m.itemImage = m.top.findNode("itemImage")
  m.itemImage.observeField("bitmapWidth", "OnItemImageLoaded")
  m.itemText = m.top.findNode("itemText")
  m.statusImageGroup = m.top.findNode("statusImageGroup")
  m.statusImageBG = m.top.findNode("statusImageBG")
  m.itemText.color = m.global.theme.primary_text_color
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
    offset = m.itemImage.loadwidth - 48 - 5
    if m.statusImageGroup <> invalid
      m.statusImageGroup.translation = [offset, 5]
      m.statusImageGroup.visible = false
    end if

    if (m.global.inline_title_text_display = true AND itemData.TITLE <> invalid)
        m.itemText.text = itemData.TITLE
    end if

    if (itemData.isLock = false) then
      if(m.statusImageGroup <> invalid AND itemData.ContentType = 4 AND m.global.enable_lock_icons = true)
          videoRequiresEntitlement = (itemData.SubscriptionRequired = true OR itemData.purchaseRequired = true)
          if (videoRequiresEntitlement)
              isSubscribed = (m.global.auth.nativeSubCount > 0 or m.global.auth.universalSubCount > 0)

              userIsEntitled = false
              if m.global.auth.entitlements <> invalid
                if m.global.auth.entitlements.DoesExist(itemData.contentId) then userIsEntitled = true
              end if

              m.statusImageGroup.visible = true

              if userIsEntitled or isSubscribed
                if m.global.enable_unlock_transparent = false then
                  m.statusImageBG.blendColor = m.global.custom_unlock_color
                else
                  m.statusImageGroup.visible = false
                end if
                m.statusImage.uri = "pkg:/images/iconUnlocked.png"
              else
                 m.statusImageBG.blendColor = m.global.custom_lock_color
                m.statusImage.uri = "pkg:/images/iconLocked.png"
              end if
          end if
        end if
      else
          m.statusImageGroup.visible = true
          m.statusImageBG.blendColor = m.global.custom_lock_color
          m.statusImage.uri = "pkg:/images/iconLocked.png"
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
