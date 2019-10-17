' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********
 ' setting top interfaces
 ' setting observers
Sub Init()
    m.background = m.top.findNode("background")
    m.oldBackground = m.top.findNode("oldBackground")
    m.oldbackgroundInterpolator = m.top.findNode("oldbackgroundInterpolator")
    ' m.shade = m.top.findNode("shade")
    m.fadeoutAnimation = m.top.findNode("fadeoutAnimation")
    m.fadeinAnimation = m.top.findNode("fadeinAnimation")
    m.backgroundColor = m.top.findNode("backgroundColor")

    m.background.observeField("bitmapWidth", "OnBackgroundLoaded")
    m.top.observeField("width", "OnSizeChange")
    m.top.observeField("height", "OnSizeChange")

    ' Set theme
    m.AppBackground = m.top.findNode("AppBackground")
    m.AppBackground.color = m.global.theme.background_color

    m.shade = m.top.findNode("shade")
    m.shade.color = m.global.theme.background_color

    m.overlay = m.top.findNode("thumbOverlay-details")
    m.overlay.uri = m.global.theme.overlay_uri
End Sub


' If background changes, start animation and populate fields
Sub OnBackgroundUriChange()
    oldUrl = m.background.uri

    if (m.global.image_caching_support = "1" or m.global.image_caching_support = "2")
        uriToSet = m.top.uri

        sha1OfImageUrl = GetEncryptedUrlString(uriToSet)
        pathObj = CheckAndGetImagePathIfAvailable(sha1OfImageUrl)
        if (pathObj.foundPath = invalid OR pathObj.foundPath = "")
            m.background.uri = uriToSet
            DownloadImage(uriToSet, pathObj.newCachePath, pathObj.newTempPath)
        else
            print "background---> found in local"
            m.background.uri = pathObj.foundPath
        end if
    else
        m.background.uri = m.top.uri
    end if

    if oldUrl <> "" then
        m.oldBackground.uri = oldUrl
        m.oldbackgroundInterpolator = [m.background.opacity, 0]
        m.fadeoutAnimation.control = "start"
    end if
End Sub

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
  print "FadingBackground : DownloadImageTaskCompleted....................................." task.bAPIStatus
  task = invalid
end Function

' If Size changed, change parameters to childrens
Sub OnSizeChange()
    size = m.top.size

    ' m.background.width = m.top.width
    ' m.oldBackground.width = m.top.width
    ' m.shade.width = m.top.width
    ' m.backgroundColor.width = m.top.width

    ' m.oldBackground.height = m.top.height
    ' m.background.height = m.top.height
    ' m.shade.height = m.top.height
    ' m.backgroundColor.height = m.top.height
End Sub


' When Background image loaded, start animation
Sub OnBackgroundLoaded()
    m.fadeinAnimation.control = "start"
End Sub
