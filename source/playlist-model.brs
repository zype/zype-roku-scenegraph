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
    releasedate: " ",
    poster: GetRandomBool()
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
    if item.DoesExist("width")
      if item.width <> invalid and item.width >= 250
        src = item.url
        exit for
      end if
    end if
  end for

  ' Assign src if thumbnail available but src still unassigned.
  if src = "" and properties.thumbnails.count() > 0 and properties.thumbnails[0].url <> invalid
    src = properties.thumbnails[0].url
  end if

  return src
End Function

'******************************************************
' Get the url for a playlist thumbnail as a background
'******************************************************
Function GetPlaylistBackgroundImage(attrs As Object) As Object
  properties = attrs
  src = ""

  maxWidth = 0

  ' Search through all thumbnails for largest image
  for each item in properties.thumbnails
    if item.DoesExist("width")
      if item.width <> invalid and item.width > maxWidth
        maxWidth = item.width
        src = item.url
      end if
    end if
  end for

  ' Assign src if thumbnail available but src still unassigned.
  ' Loop above does not assign src if it receives thumbnails without width assigned
  if src = "" and properties.thumbnails.count() > 0 and properties.thumbnails[0].url <> invalid
    src = properties.thumbnails[0].url
  end if

  return src
End Function
