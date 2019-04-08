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
    posterThumbnail: GetPosterThumbnail(properties),
    contenttype: "episode",
    releasedate: FormateDate(properties.created_at),
    inFavorites: properties.inFavorites,
    onAir: properties.on_air,
    subscriptionRequired: properties.subscription_required,
    purchaseRequired: properties.purchase_required,
    registrationRequired: properties.registration_required,
    rentalRequired: properties.rental_required,
    passRequired: properties.pass_required,
    trailers: properties.preview_ids,
    contentId: properties._id,
    mediaType: "movie",
    usePoster: properties.usePoster
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
    if item.DoesExist("width")
      if item.width <> invalid and item.width >= 250 and item.width <= 500
        src = item.url
        exit for
      end if
    end if
  end for

  ' Assign src if thumbnail available but src still unassigned.
  if src = "" and properties.thumbnails.count() > 0 and properties.thumbnails[0].url <> invalid
    src = properties.thumbnails[0].url
  else if src = ""
    src = "pkg:/images/placeholder.png"
  end if

  return src
End Function

'******************************************************
' Get the url for a video thumbnail as a background
'******************************************************
Function GetVideoBackgroundImage(attrs As Object) As Object
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
  else if src = ""
    src = "pkg:/images/placeholder.png"
  end if

  return src
End Function

'******************************************************
' Get the url for a video poster thumbnail as a background
'******************************************************
Function GetPosterThumbnail(attrs as Object) As Object
  properties = attrs
  src = ""
  if(properties.images <> invalid)
    for each item in properties.images
      if item.layout = "poster"
        src = item.url
        exit for
      end if
    end for
  end if

  if src = "" then src = "pkg:/images/placeholder.png"

  return src
End Function
