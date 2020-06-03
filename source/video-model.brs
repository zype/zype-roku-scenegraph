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
  ' print "CreateVideoObject : " ' properties
  ' print "CreateVideoObject.keywords : " ' keywords
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
    on_Air: properties.on_air,
    subscriptionRequired: properties.subscription_required,
    purchaseRequired: properties.purchase_required,
    marketplace_ids: properties.marketplace_ids,
    registrationRequired: properties.registration_required,
    rentalRequired: properties.rental_required,
    passRequired: properties.pass_required,
    trailers: properties.preview_ids,
    contentId: properties._id,
    mediaType: "movie",
    usePoster: properties.usePoster,
    episodeNumber: properties.episode,
    seasonNumber: properties.season,

    created_at: properties.created_at,
    published_at: properties.published_at,
    updated_at: properties.updated_at,
    keywords: properties.keywords
  }

  return video
End Function

'******************************************************
' Get the url for a video thumbnail
'******************************************************
Function GetVideoThumbnail(attrs As Object) As Object
  properties = attrs
  src = "pkg:/images/placeholder.png"

  if (properties.thumbnails <> invalid)
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
      end if
  end if
  return src
End Function

'******************************************************
' Get the url for a video thumbnail as a background
'******************************************************
Function GetVideoBackgroundImage(attrs As Object) As Object
  properties = attrs
  src = "pkg:/images/placeholder.png"

  maxWidth = 0

  if (properties.thumbnails <> invalid)
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

      if properties.images <> invalid and properties.images.count() > 0
        for each image in properties.images
          if image.title <> invalid and image.title = "featured-thumbnail" then src = image.url
        end for
      end if
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
