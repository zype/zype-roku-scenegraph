REM ******************************************************
REM Author: Khurshid Fayzullaev
REM Copyright Zype 2016.
REM All Rights Reserved
REM ******************************************************

REM If you import this, you also need to import API
REM
REM Functions in this file:
REM     CreatePlaylistOject
REM

'******************************************************
' Create a playlist object that is compatible with Roku
'
'Function returns:
' A playlist as an object
'******************************************************
Function CreatePlaylistObject(attrs As Object) As Object
  properties = attrs

  playlist = {
    id: properties._id,
    title: properties.title,
    hdposterurl: GetPlaylistThumbnail(properties),
    description: properties.description,
    hdbackgroundimageurl: GetPlaylistBackgroundImage(properties),
    contenttype: "series",
    releasedate: " "
  }

  return playlist
End Function

'******************************************************
' Get the url for a playlist thumbnail
'******************************************************
Function GetPlaylistThumbnail(attrs As Object) As Object
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
' Get the url for a playlist thumbnail as a background
'******************************************************
Function GetPlaylistBackgroundImage(attrs As Object) As Object
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
