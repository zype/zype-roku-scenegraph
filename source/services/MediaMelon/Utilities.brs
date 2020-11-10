
function setDeviceInfo()
    device=CreateObject("roDeviceInfo")
    deviceinfo={
                "model":device.getModel(),
                "nwType":device.getConnectionInfo().type,
                "video_mode":device.GetVideoMode(),
                "ipAddress":device.getIPAddrs().eth1,
                "width":device.GetDisplaySize().w,
                "height":device.GetDisplaySize().h
                }
    if device.getConnectionInfo().type="WiFiConnection"
        deviceinfo.AddReplace("ssid",device.getConnectionInfo().ssid)
    end if
    return deviceinfo
end function

function setAppInfo()
    info=CreateObject("roAppInfo")
    appinfo={
        "ID":info.GetID(),
        "appDev":info.IsDev()
        }
    return appinfo
end function

function _createConnection(port as Object) as Object
  connection = CreateObject("roUrlTransfer")
  connection.SetPort(port)
  connection.SetCertificatesFile("common:/certs/ca-bundle.crt")
  connection.AddHeader("Content-Type", "application/json")
  connection.AddHeader("Accept", "application/json")
  connection.AddHeader("Expect", "")
  connection.AddHeader("Connection", "keep-alive")
  'connection.AddHeader("Accept-Encoding", "gzip, deflate, br")
  'connection.EnableEncodings(true)
  return connection
end function

function _createPort() as Object
  return CreateObject("roMessagePort")
end function

function _createByteArray() as Object
  return CreateObject("roByteArray")
end function

function _createEVPDigest() as Object
  return CreateObject("roEVPDigest")
end function

function _getStreamFormat(url as String) as String

    ismRegex = CreateObject("roRegex", "\.isml?\/manifest", "i")
    if ismRegex.IsMatch(url)
      return "ism"
    end if

    hlsRegex = CreateObject("roRegex", "\.m3u8", "i")
    if hlsRegex.IsMatch(url)
      return "HLS"
    end if

    dashRegex = CreateObject("roRegex", "\.mpd", "i")
    if dashRegex.IsMatch(url)
      return "DASH"
    end if
''
    formatRegex = CreateObject("roRegex", "\*?\.([^\.]*?)(\?|\/$|$|#).*", "i")
    if formatRegex <> Invalid
      extension = formatRegex.Match(url)
      if extension <> Invalid AND extension.count() > 1
        return extension[1]
      end if
    end if

    return "unknown"
end function

function _getVideoFormat(url as String) as String
    formatRegex = CreateObject("roRegex", "\*?\.([^\.]*?)(\?|\/$|$|#).*", "i")
    if formatRegex <> Invalid
      extension = formatRegex.Match(url)
      if extension <> Invalid AND extension.count() > 1
        return extension[1]
      end if
    end if

    return "unknown"
end function

function _generateVideoId(src as String) as String
    hostAndPath =_getHostnameAndPath(src)
    'byteArray = _createByteArray()
    'byteArray.FromAsciiString(hostAndPath)
    'bigString = byteArray.ToBase64String()
    'smallString = bigString.split("=")[0]
    return hostAndPath
end function

function _getHostnameAndPath(src as String) as String
    hostAndPath = src
    hostAndPathRegEx = CreateObject("roRegex", "^https?://", "")
    parts = hostAndPathRegEx.split(src)
    if parts <> Invalid AND parts.count() > 0
      if parts.count() > 1
        parts.shift()
      end if
      if parts.count() > 1
        hostAndPath = parts.join()
      else
        hostAndPath = parts[0]
      end if
      hostAndPathRegEx = CreateObject("roRegex", "\?|#", "")
      parts = hostAndPathRegEx.split(hostAndPath)
      if parts.count() > 1
        hostAndPath = parts[0]
      end if
    end if
    return hostAndPath
end function

function _getDomain(url as String) as String
    domain = ""
    strippedUrl = url.Split("//")
    if strippedUrl.count() = 1
      url = strippedUrl[0]
    else if strippedUrl.count() > 1
      if strippedUrl[0].len() > 7
        url = strippedUrl[0]
      else
        url = strippedUrl[1]
      end if
    end if
    splitRegex = CreateObject("roRegex", "[\/|\?|\#]", "")
    strippedUrl = splitRegex.Split(url)
    if strippedUrl.count() > 0
      url = strippedUrl[0]
    end if
    domainRegex = CreateObject("roRegex", "([a-z0-9\-]+)\.([a-z]+|[a-z]{2}\.[a-z]+)$", "i")
    matchResults = domainRegex.Match(url)
    if matchResults.count() > 0
      domain = matchResults[0]
    end if
    return domain
end function

function _getHostname(url as String) as String
    host = ""
    hostRegex = CreateObject("roRegex", "([a-z]{1,})(\.)([a-z.]{1,})", "i")
    matchResults = hostRegex.Match(url)
    if matchResults.count() > 0
      host = matchResults[0]
    end if
    return host
end function

function _getDateTime() as Object
    return CreateObject("roDateTime")
end function

function _generatePid(src as String) as String
    ba=_createByteArray()
    ba.FromAsciiString(src)
    digest=_createEVPDigest()
    digest.setup("md5")
    result=digest.process(ba)
    part1=result.mid(8,8)
    part2=result.right(8)
    part3=result.left(8)
    part4=result.Mid(16,8)
    result=part1+part2+part3+part4
    return result
end function

function _generateSubId(src as string) as string
  return src
  ' ba = _createByteArray()
  ' ba.FromAsciiString(src)
  ' digest = _createEVPDigest()
  ' digest.setup("md5")
  ' result = digest.process(ba)
  ' return result
end function
