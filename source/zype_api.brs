REM ******************************************************
REM Author: Khurshid Fayzullaev
REM Copyright Zype 2016.
REM All Rights Reserved
REM ******************************************************

REM This file has no dependencies on other common and custom files.
REM
REM Functions in this file:
REM     GetApiConfigs
REM     GetAppKey
REM     GetApiEndpoint
REM     GetPlayerEndpoint
REM     GetApiVersion
REM     MakeRequest
REM     AppendParamsToUrl
REM     AppendAppKeyToParams
REM     GetAppConfigs
REM     GetZObjects
REM     GetVideo
REM     GetVideos
REM     GetCategory
REM     GetPlans
REM     GetPlan
REM     SaveSubscriptionData  (Work in progress)

'******************************************************
'Get API configurations
'******************************************************
Function GetApiConfigs() As Object
  rawConfig = ReadAsciiFile("pkg:/source/config.json")
  api = ParseJson(rawConfig)
  return api
End Function

'******************************************************
'Get text label configurations
'******************************************************
Function GetTextConfigs() As Object
  rawConfig = ReadAsciiFile("pkg:/source/text_labels_config.json")
  api = ParseJson(rawConfig)
  return api
End Function

'******************************************************
'Make a request to an url with parameters
'
'Function returns:
'   Parsed JSON if 200
'   Otherwise invalid
'******************************************************
Function MakeRequest(src As String, params As Object) As Object
  request = CreateObject("roUrlTransfer")
  port = CreateObject("roMessagePort")
  request.setMessagePort(port)
  url = AppendParamsToUrl(src, params)
  if url.InStr(0, "https") = 0
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.AddHeader("X-Roku-Reserved-Dev-Id", "")
    request.InitClientCertificates()
  end if

  ' print url ' uncomment to debug
  request.SetUrl(url)
?"the url is ==>"url
  if request.AsyncGetToString()
    while true
      msg = wait(0, port)
      if type(msg) = "roUrlEvent"
        code = msg.GetResponseCode()
        ?"the code is=>"code
        if code = 200
          response = ParseJson(msg.GetString())
          return response
        else
          return invalid
        end if
        exit while
      else if event = invalid
        request.AsyncCancel()
      end if
    end while
  end if

  return invalid
End Function


'******************************************************
'Make a request to an url with parameters POST
'
'Function returns:
'   Parsed JSON if 200
' Parsed JSON if 201
'   Otherwise invalid
'******************************************************
Function MakeDeleteRequest(src As String, params As Object) As Boolean
  request = CreateObject("roUrlTransfer")
  request.SetRequest("DELETE")
  port = CreateObject("roMessagePort")
  request.setMessagePort(port)
  url = AppendParamsToUrl(src, params)

  if url.InStr(0, "https") = 0
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.AddHeader("X-Roku-Reserved-Dev-Id", "")
    request.InitClientCertificates()
  end if

  ' print url ' uncomment to debug
  request.SetUrl(url)

  if request.AsyncGetToString()
    while true
      msg = wait(0, port)
      if type(msg) = "roUrlEvent"
        code = msg.GetResponseCode()
        if code = 200 or code = 201 or code = 202 or code = 203 or code = 204
          print "Success"
          return true
        end if
        exit while
      else if event = invalid
        request.AsyncCancel()
      end if
    end while
  end if

  print "Error"
  return false
End Function


'******************************************************
'Make a request to an url with parameters PUT
'
'Function returns:
'   Parsed JSON if 200
' Parsed JSON if 201
'   Otherwise invalid
'******************************************************
Function MakePutRequest(src As String, params As Object) As Object
  request = CreateObject("roUrlTransfer")
  request.SetRequest("PUT")
  port = CreateObject("roMessagePort")
  request.setMessagePort(port)
  url = AppendParamsToUrl(src, params)
  print "URL: "; url

  if url.InStr(0, "https") = 0
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.AddHeader("X-Roku-Reserved-Dev-Id", "")
    request.InitClientCertificates()
  end if

  ' print url ' uncomment to debug
  request.SetUrl(url)

  if request.AsyncGetToString()
    while true
      msg = wait(0, port)
      if type(msg) = "roUrlEvent"
        code = msg.GetResponseCode()
        if code = 200 or code = 201 or code = 202 or code = 203 or code = 204
          print "Success"
          response = ParseJson(msg.GetString())
          return response
          'return true
        end if
        exit while
      else if event = invalid
        request.AsyncCancel()
      end if
    end while
  end if

  print "Error"
  return invalid
  'return false
End Function


'******************************************************
'Make a request to an url with parameters POST
'
'Function returns:
'   Parsed JSON if 200
' Parsed JSON if 201
'   Otherwise invalid
'******************************************************
Function MakePostRequest(src As String, params As Object) As Object
  request = CreateObject("roUrlTransfer")
  port = CreateObject("roMessagePort")
  request.setMessagePort(port)
  url = src
  ' url = AppendParamsToUrl(src, params)

  bodyData = paramsToString(params)

  if url.InStr(0, "https") = 0
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.AddHeader("X-Roku-Reserved-Dev-Id", "")
    request.InitClientCertificates()
  end if

  ' print url ' uncomment to debug
  request.SetUrl(url)
  ?"the url is ==>"url
  ?"the bodyData is ==>"bodyData

  if request.AsyncPostFromString(bodyData)
    while true
      msg = wait(0, port)
      if type(msg) = "roUrlEvent"
        code = msg.GetResponseCode()
        ?"the code is ==>"code
        if code = 200 or code = 201
          response = ParseJson(msg.GetString())
          ?"the response is ==>"response
          return response
        end if
        exit while
      else if event = invalid
        request.AsyncCancel()
      end if
    end while
  end if

  return invalid
End Function

function paramsToString(obj as Object) as String
  result = ""

  for each i in obj
    result = result + i + "=" + obj[i] + "&"
  end for

  return result
end function

'******************************************************
'Append parameters to an url
'
'Function returns:
'   New url with params
'******************************************************
Function AppendParamsToUrl(src As String, params As Object) As String
  url = src
  args = params
  request = CreateObject("roUrlTransfer")

  if args <> invalid and args.count() > 0
    for each a in args
      if url.InStr(0, "?") = -1
        separator = "?"
      else
        separator = "&"
      end if
      url = url + separator + request.escape(a.tostr()) + "=" + request.escape(args[a].tostr())
    end for
  end if

  return url
End Function

'******************************************************
'Append App Key to parameters
'
'Function returns:
' New parameters with `app_key`
'******************************************************
Function AppendAppKeyToParams(params As Object) As Object
  newParams = params

  appKey = {
    app_key: GetApiConfigs().app_key
  }
  newParams.Append(appKey)

  return newParams
End Function

'******************************************************
'Get app onfigurations
'
'Function returns:
' An object with configurations
'******************************************************
Function GetAppConfigs(urlParams = {} As Object) As Object
  data = {}

  url = GetApiConfigs().endpoint + "app/"
  params = AppendAppKeyToParams(urlParams)
  response = MakeRequest(url, params)
  if response <> invalid
    data = response.response
  end if

  return data
End Function

'******************************************************
'Get a ZObjects
'
'Function returns:
' ZObjects as an object
'******************************************************
Function GetZObjects(urlParams = {} As Object) As Object
  data = {}

  url = GetApiConfigs().endpoint + "zobjects/"
  params = AppendAppKeyToParams(urlParams)
  response = MakeRequest(url, params)
  if response <> invalid
    data = response.response
  end if

  return data
End Function

'******************************************************
'Get a video
'
'Function returns:
' A video as an object
'******************************************************
Function GetVideo(id as String, urlParams = {} As Object) As Object
  data = {}

  url = GetApiConfigs().endpoint + "videos/" + id
  params = AppendAppKeyToParams(urlParams)
  response = MakeRequest(url, params)
  if response <> invalid
    data = response.response
  end if

  return data
End Function

'******************************************************
'Get videos
'
'Function returns:
' Videos as an object
'******************************************************
Function GetVideos(urlParams = {} As Object) As Object
  data = {}

  url = GetApiConfigs().endpoint + "videos/"
  params = AppendAppKeyToParams(urlParams)

  response = MakeRequest(url, params)
  if response <> invalid
    data = response.response
  end if

  return data
End Function

'******************************************************
'Get a category
'******************************************************
Function GetCategory(id as String, urlParams = {} As Object) As Object
  data = {}

  url = GetApiConfigs().endpoint + "categories/" + id
  params = AppendAppKeyToParams(urlParams)
  response = MakeRequest(url, params)
  if response <> invalid
    data = response.response
  end if

  return data
End Function


'******************************************************
'Get EPG
'******************************************************
Function GetProgramGuides(urlParams = {} As Object) As Object
  data = []
  url = GetApiConfigs().endpoint + "program_guides/"
  params = AppendAppKeyToParams(urlParams)
  response = MakeRequest(url, params)
  if response <> invalid and response.response <> invalid
    data = response.response
  end if
  return data
End Function


Function GetProgramGuide(id as String, urlParams = {} As Object) As Object
  data = {response: []}
  url = GetApiConfigs().endpoint + "program_guides/" + id + "/entries"
  params = AppendAppKeyToParams(urlParams)
  response = MakeRequest(url, params)
  if response <> invalid and response.response <> invalid
    data = response  '.response
  end if
  return data
End Function


Function ViewProgramGuide(id as String, urlParams = {} As Object) As Object
  data = {response: {}}
  url = GetApiConfigs().endpoint + "program_guides/" + id
  response = MakeRequest(url, AppendAppKeyToParams(urlParams))
  if response <> invalid and response.response <> invalid
    data = response
  end if
  return data
End Function


function MakeGetRequest(src, params) as object
    resp = {}

    request = CreateObject("roUrlTransfer")
    request.RetainBodyOnError(true) ' Need this for error messages
    port = CreateObject("roMessagePort")
    request.setMessagePort(port)
    url = AppendParamsToUrl(src, params)

    if url.InStr(0, "https") = 0
      request.SetCertificatesFile("common:/certs/ca-bundle.crt")
      request.AddHeader("X-Roku-Reserved-Dev-Id", "")
      request.InitClientCertificates()
    end if

    print url ' uncomment to debug
    request.SetUrl(url)

    if request.AsyncGetToString()
      while true
        msg = wait(0, port)
        if type(msg) = "roUrlEvent"
          code = msg.GetResponseCode()

          resp.body = ParseJson(msg.GetString())
          resp.status = code

          exit while
        else if event = invalid
          request.AsyncCancel()
          exit while
        end if
      end while
    end if

    return resp
end function

Function MakePostRequestWithStatus(src As String, params As Object) As Object
  resp = {}

  request = CreateObject("roUrlTransfer")
  request.RetainBodyOnError(true) ' Need this for error messages
  port = CreateObject("roMessagePort")
  request.setMessagePort(port)
  url = src

  bodyData = FormatJson(params)
  request.AddHeader("Content-Type", "application/json")
  request.AddHeader("Accept", "application/json")

  if url.InStr(0, "https") = 0
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.AddHeader("X-Roku-Reserved-Dev-Id", "")
    request.InitClientCertificates()
  end if

  ' print url ' uncomment to debug
  request.SetUrl(url)

  if request.AsyncPostFromString(ToStr(bodyData))
    while true
      msg = wait(0, port)
      if type(msg) = "roUrlEvent"
        code = msg.GetResponseCode()

        resp.body = ParseJson(msg.GetString())
        resp.status = code

        exit while
      else if event = invalid
        request.AsyncCancel()
      end if
    end while
  end if

  return resp
End Function

'******************************************************
'Get a player info
'******************************************************
Function GetPlayerInfo(videoid As String, urlParams = {} As Object) As Object
  print "Video ID: " + videoid
  info = {}
  info.stream = {url: ""}
  info.streamFormat = ""
  info.url = ""
  info.on_air = false
  info.has_access = false
  info.scheduledAds = []
  info.subtitles = []
  info.video = {}
  info.analytics = {}
  info.errorMessages = {}

  info.statusCode = invalid

  url = GetApiConfigs().player_endpoint + "embed/" + videoid + "/"
  params = urlParams

  params.uuid = getAdID() ''"ROKU_ADS_TRACKING_ID"
  params.app_name =  getTitle(true)
  params.app_bundle = getApplicationID()
  params.device_type = "7"
  params.device_make = "Roku"
  params.device_model = getModel(true) ''"ROKU_ADS_DEVICE_MODEL"
  params.device_ifa = getAdID() ''"ROKU_ADS_TRACKING_ID"
  params.vpi = "ROKU"
  params.app_id = getAdsAppID() ''"ROKU_ADS_APP_ID"<<GetChannelClientId

  print "GetPlayerInfo url > " url
  print "GetPlayerInfo params > " params

  response = MakeGetRequest(url, params)

  if response.status = 200
    response = response.body.response
    print "Beacon: "; response.body.analytics.beacon
    print "Dimensions: "; response.body.analytics.dimensions

    info.statusCode = 200

    if response.DoesExist("body")

      if response.body.DoesExist("on_air")
          info.on_air = response.body.on_air
      end if

      if(response.body.DoesExist("analytics"))
          analytics = response.body.analytics
          info.analytics = { beacon: analytics.beacon, device: analytics.dimensions.device, playerId: analytics.dimensions.player_id, siteId: analytics.dimensions.site_id, videoId: analytics.dimensions.video_id }
      end if

      if(response.body.DoesExist("advertising"))
        for each advertising in response.body.advertising
          if (advertising = "schedule")
            for each ad in response.body.advertising.schedule
              'print "DYNAMIC VAST URL"
              info.scheduledAds.push({offset: ad.offset / 1000, url: ad.tag, played: false})
            end for
          end if
        end for
      end if

      if response.body.DoesExist("subtitles")
        for each subtitle in response.body.subtitles
          info.subtitles.push({ url: subtitle.file, language: subtitle.label })
        end for
      end if

      if response.body.DoesExist("outputs")
        for each output in response.body.outputs
          streamUrl = output.url
          info.stream.url = streamUrl
          info.url = streamUrl
          if output.name = "hls"
            info.streamFormat = "hls"
          end if
          if output.name = "m3u8"
            info.streamFormat = "hls"
          end if
          if output.name = "mp4"
            info.streamFormat = "mp4"
          end if
        end for
      end if
    end if ' end of if body

    if response.DoesExist("video")
      video = response.video

      if video.DoesExist("title")
        info.video.title = video.title
      end if

      if video.DoesExist("duration")
        info.video.duration = video.duration
      end if

      ' Set VideoID'
      info.video.video_id = videoid
    end if ' end of if video

    ' print "Video Info : " info
    ' print "Video Info video : " info.video
  else
    info.statusCode = response.status
    print "response.body-----------------------------------ERROR--------------------------------------------------------------------------------------------------" response.body
    if (response.body <> invalid AND response.body.message <> invalid)
	    info.errorMessage = response.body.message
    else
      info.errorMessage = "There is some error. Please try after sometime."
      print "Saved crash.......................--------------------------zype_api.brs(604)-----------------------------..."
    end if
  end if

  return info
end function

'******************************************************
'Get playlists filter by 'id' or 'playlist_id'
'******************************************************

' Use case
' params = {
'     "parent_id": "579116fc6689bc0d1d00f092"
' }
' print GetPlaylists(params)

function GetPlaylists(urlParams = {} As Object) as Object
  data = {}

  url = GetApiConfigs().endpoint + "playlists/"
  params = AppendAppKeyToParams(urlParams)
  response = MakeRequest(url, params)
  if response <> invalid
    data = response.response
  end if

  return data
end function

function GetPlaylistVideos(playlist_id as String, urlParams = {} as Object) as Object
  data = {}

  url = GetApiConfigs().endpoint + "playlists/" + playlist_id + "/videos/"
  params = AppendAppKeyToParams(urlParams)
  response = MakeRequest(url, params)
  if response <> invalid
    data = response.response
  end if

  return data
end function

'******************************************************
'Check if a playlist has children or videos only
'******************************************************
function HasChildren(playlist as object) as Boolean
  pl = playlist
  if pl.playlist_item_count > 0 then
    return false
  else
    return true
  end if
end function

'******************************************************
'Check if a device is linked
'******************************************************
function PinStatus(urlParams as Object) as Object
  data = {}

  url = GetApiConfigs().endpoint + "pin/status/"
  params = AppendAppKeyToParams(urlParams)

  response = MakeRequest(url, params)
  if response <> invalid
    data = response.response
  else if response = invalid
    data = invalid
  end if

  return data
end function


'******************************************************
'Check if a device is linked
'******************************************************
function IsLinked(urlParams as Object) as Object
  result = {consumer_id: "", linked: false}

  src = GetApiConfigs().endpoint + "pin/status/"
  params = AppendAppKeyToParams(urlParams)

  request = CreateObject("roUrlTransfer")
  port = CreateObject("roMessagePort")
  request.setMessagePort(port)
  url = AppendParamsToUrl(src, params)

  if url.InStr(0, "https") = 0
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.AddHeader("X-Roku-Reserved-Dev-Id", "")
    request.InitClientCertificates()
  end if

  ' print url ' uncomment to debug
  request.SetUrl(url)

  if request.AsyncGetToString()
    while true
      msg = wait(0, port)
      if type(msg) = "roUrlEvent"
        code = msg.GetResponseCode()
        if code = 200
          response = ParseJson(msg.GetString())
          result = response.response
          print result
        end if
        exit while
      else if event = invalid
        request.AsyncCancel()
      end if
    end while
  end if

  return result
end function


'******************************************************
' Acquire PIN for a device
'******************************************************
function AcquirePin(urlParams as Object) as Object
  data = {}

  url = GetApiConfigs().endpoint + "pin/acquire/"
  params = AppendAppKeyToParams(urlParams)

  response = MakePostRequest(url, params)
  if response <> invalid
    data = response.response
  else if response = invalid
    data = invalid
  end if

  return data
end function


'******************************************************
' Is Entitled
'******************************************************
function IsEntitled(id as String, urlParams as Object) as Boolean
  url = GetApiConfigs().endpoint + "videos/" + id + "/entitled/"
  ' params = AppendAppKeyToParams(urlParams)
  params = urlParams

  print url
  response = MakeRequest(url, params)
  if response <> invalid
    return true
  end if

  return false
end function

'******************************************************
' List Video Favorites
'******************************************************
function GetVideoFavorites(consumer_id as String, urlParams as Object) as Object
  data = {}

  url = GetApiConfigs().endpoint + "consumers/" + consumer_id + "/video_favorites/"
  ' params = AppendAppKeyToParams(urlParams)
  params = urlParams

  response = MakeRequest(url, params)
  print url
  if response <> invalid
    data = response.response
  else if response = invalid
    data = invalid
  end if

  return data
end function

'******************************************************
' Create video favorite video_id
'******************************************************
function CreateVideoFavorite(consumer_id as String, urlParams as Object) as Object
  url = GetApiConfigs().endpoint + "consumers/" + consumer_id + "/video_favorites/"
  ' params = AppendAppKeyToParams(urlParams)
  params = urlParams

  response = MakePostRequest(url, params)
  if response <> invalid
    return true
  end if

  return false
end function

'*************************
' Delete video favorite
'*************************

function DeleteVideoFavorite(consumer_id as String, video_favorite_id as String, urlParams= {} as Object)
  url = GetApiConfigs().endpoint + "consumers/" + consumer_id + "/video_favorites/" + video_favorite_id
  ' params = AppendAppKeyToParams(urlParams)
  params = urlParams

  response = MakeDeleteRequest(url, params)
  if response = true
    return true
  end if

  return false
end function


'*************************
' Get Subscription Plans
'*************************
Function GetPlans(urlParams = {} as Object)
    url = GetApiConfigs().endpoint + "plans"
    params = AppendAppKeyToParams(urlParams)
    response = MakeRequest(url, params)
    if response <> invalid
      data = response.response
    else if response = invalid
      data = invalid
    end if
    return data
End Function

'****************************
' Get Subscription Plan By ID
'****************************
Function GetPlan(id as String, urlParams as Object)
  url = GetApiConfigs().endpoint + "plans/" + id
  params = AppendAppKeyToParams(urlParams)
  response = MakeRequest(url, params)
  print url
  if response <> invalid
    data = response.response
  else if response = invalid
    data = invalid
  end if

  return data
End Function

'****************************
' Unlink Device
'****************************
Function UnlinkDevice(consumer_id, pin, urlParams as Object)
    print "consumer_id: "; consumer_id; " pin: "; pin
    url = GetApiConfigs().endpoint + "pin/unlink"
    params = AppendAppKeyToParams(urlParams)
    params.consumer_id = consumer_id
    params.pin = pin
    response = MakePutRequest(url, params)
    if response <> invalid
      data = response.response
    else if response = invalid
      data = invalid
    end if
    return data
End Function

'****************************
' Consumer functions
'****************************
function GetConsumer(consumer_id, access_token) as object
  url = GetApiConfigs().endpoint + "consumers/" + consumer_id
  response = MakeRequest(url, {access_token: access_token})

  if response <> invalid
    return response.response
  else
    return invalid
  end if
end function

function CreateConsumer(urlParams as object) as object
  url = GetApiConfigs().endpoint + "consumers"
  params = AppendAppKeyToParams(urlParams)

  response = MakePostRequest(url, params)

  if response <> invalid then
    return response.response
  else
    return invalid
  end if
end function

' Calls BiFrost API to check if native subscription is valid
'   Return: { "success": true/false, "is_valid": true/false, "expired": true/false }
'
'   Required params: consumer_id, site_id, subscription_plan_id, device_type (roku), roku_api_key, transaction_id (from roku receipt)
'
function GetNativeSubscriptionStatus(params as object) as object
  url = GetApiConfigs().bifrost_endpoint + "api/v1/subscribe"
  response = MakePostRequest(url, params)

  print "bifrost response: "; response

  if response <> invalid then return response else return invalid
end function

' Create subscription for consumer
'
'   Required params: subscription[consumer_id], subscription[plan_id], subscription[third_party_id]
function CreateSubscription(params as object) as object
  url = GetApiConfigs().endpoint + "subscriptions"
  params.api_key = GetApiConfigs().zype_api_key

  response = MakePostRequest(url, params)

  if response <> invalid then return response.response else return invalid
End Function


function GetEntitledVideos(urlParams as object) as object
    url = GetApiConfigs().endpoint + "consumer/videos"
    response = MakeRequest(url, urlParams)

    print url
    print urlParams

    if response <> invalid then return response.response else return invalid
end function
