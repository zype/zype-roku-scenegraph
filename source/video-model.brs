REM ******************************************************
REM Author: Khurshid Fayzullaev
REM Copyright Zype 2016.
REM All Rights Reserved
REM ******************************************************

REM If you import this, you also need to import API
REM
REM Functions in this file:
REM     CreateVideoObject
REM

'******************************************************
' Create a video object that is compatible with Roku
'
'Function returns:
' A video as an object
'******************************************************
Function CreateVideoObject(attrs As Object) As Object
  properties = attrs

  ' print properties.title
  ' print properties.inFavorites

  video = {
    stream: {url: ""},
    streamformat: "str",
    url: "",
    id: properties._id,
    title: properties.title,
    hdposterurl: GetVideoThumbnail(properties),
    length: properties.duration,
    description: properties.description,
    hdbackgroundimageurl: GetVideoBackgroundImage(properties),
    contenttype: "episode",
    releasedate: FormateDate(properties.created_at),
    inFavorites: properties.inFavorites,
    onAir: properties.on_air,
    subscriptionRequired: properties.subscription_required
  }

  return video
End Function

'******************************************************
' Get the url for a video thumbnail
'******************************************************
Function GetVideoThumbnail(attrs As Object) As Object
  properties = attrs
  src = ""

  for each item in properties.thumbnails
    ' This is actually correct code
    if item.DoesExist("width")
      if item.width <> invalid and item.width >= 250
        src = item.url
        exit for
      else
        src = item.url
        exit for
      end if
    end if
  end for

  return src
End Function

'******************************************************
' Get the url for a video thumbnail as a background
'******************************************************
Function GetVideoBackgroundImage(attrs As Object) As Object
  properties = attrs
  src = ""

  for each item in properties.thumbnails
    ' This is actually correct code
    if item.DoesExist("width")
      if item.width <> invalid and item.width >= 500
        src = item.url
        exit for
      else
        src = item.url
        exit for
      end if
    end if
  end for

  return src
End Function
