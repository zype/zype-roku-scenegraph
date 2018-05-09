' ***************************************************
' HttpClient provides a base SDK for making HTTP requests
' - intended to be used with JSON apis
' 
' Methods:
'   MakeRequest
'   Get
'   Post
'   Put
'   Delete
' ***************************************************
function HttpClient() as object
  this = {}
  this.private = {}

  ' ***************************************************
  ' ParamsToString() takes parameters and returns them as a string
  ' - private method
  ' 
  ' @param params {roAssociateArray}  associate array with parameters as keys and values as parameter values
  ' @return {String}  the parameters formated into a string
  ' ***************************************************
  this.private.ParamsToString = function(params as object) as string
    paramsString = ""

    if params <> invalid and params.count() > 0
      request = CreateObject("roUrlTransfer")
      i = 1

      for each p in params
        paramsString = paramsString + request.escape(p.toStr()) + "=" + request.escape(params[p].tostr())
        if i <> params.count() then paramsString = paramsString + "&"

        i = i + 1
      end for
    end if

    return paramsString
  end function

  ' ***************************************************
  ' MakeRequest() makes an HTTP request
  ' - makes GET request by default
  ' 
  ' @param  method {String}  the HTTP method for the request
  ' @param  url {String}     the endpoint you are making the request to
  ' @param  params {Object}  associative array of params to send
  ' 
  ' @return {Object}  associative array with return body and status code
  ' ***************************************************
  this.MakeRequest = function(method as string, url as string, params as object) as object
      request = CreateObject("roUrlTransfer")
      port = CreateObject("roMessagePort")
      request.RetainBodyOnError(true)
      request.setMessagePort(port)

      paramsString = m.private.ParamsToString(params)
      requestUrl = url + "?" + paramsString

      ' for debugging
      appInfo = CreateObject("roAppInfo")
      if appInfo.IsDev() then print requestUrl

      ' set certificates if https
      if url.InStr(0, "https") = 0
        request.SetCertificatesFile("common:/certs/ca-bundle.crt")
        request.AddHeader("X-Roku-Reserved-Dev-Id", "")
        request.InitClientCertificates()
      end if

      lMethod = LCase(method)
      resp = {}

      if lMethod = "post"
        request.SetRequest("POST")
        request.SetUrl(requestUrl)
      else if lMethod = "put"
        request.SetRequest("PUT")
        request.SetUrl(requestUrl)
      else if lMethod = "delete"
        request.SetRequest("DELETE")
        request.SetUrl(requestUrl)
      else ' GET
        request.SetUrl(requestUrl)
      end if

      if request.AsyncGetToString()
        while true
          msg = wait(0, port)
          eventType = type(msg)

          if eventType = "roUrlEvent"
            code = msg.GetResponseCode()
            body = ParseJson(msg.GetString())

            resp.body = body
            resp.status = code
            exit while
          end if
        end while
      end if

      return resp
  end function

  ' ***************************************************
  ' Get() makes an GET request
  ' - shortcut for MakeRequest() with GET method
  ' ***************************************************
  this.Get = function(url as string, params as object) as object
    return m.MakeRequest("GET", url, params)
  end function

  ' ***************************************************
  ' Post() makes an POST request
  ' - shortcut for MakeRequest() with POST method
  ' ***************************************************
  this.Post = function(url as string, params as object) as object
    return m.MakeRequest("POST", url, params)
  end function

  ' ***************************************************
  ' Put() makes an PUT request
  ' - shortcut for MakeRequest() with PUT method
  ' ***************************************************
  this.Put = function(url as string, params as object) as object
    return m.MakeRequest("PUT", url, params)
  end function

  ' ***************************************************
  ' Delete() makes an DELETE request
  ' - shortcut for MakeRequest() with DELETE method
  ' ***************************************************
  this.Delete = function(url as string, params as object) as object
    return m.MakeRequest("DELETE", url, params)
  end function

  return this
end function