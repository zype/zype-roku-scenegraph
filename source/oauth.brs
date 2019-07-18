function GetAccessTokenWithPin(client_id as String, client_secret as String, udid as String, pin as String)
  oauth = RegReadAccessToken()


  if oauth = invalid
    ResetAccessToken()
    RequestToken(client_id, client_secret, udid, pin)
  else if IsExpired(oauth.created_at.ToInt(), oauth.expires_in.ToInt())
    ResetAccessToken()
    data = {
      "client_id": client_id,
      "client_secret": client_secret,
      "refresh_token": oauth.refresh_token,
      "grant_type": "refresh_token"
    }
    res = RefreshToken(data)
    if res <> invalid
      RegWriteAccessToken(res)
    end if
  end if

  return RegReadAccessToken()
end function

function RegReadAccessToken()
  oauth = CreateObject("roAssociativeArray")

  access_token = RegRead("AccessToken", "OAuth")
  if access_token <> invalid
    oauth.AddReplace("access_token", access_token)
    oauth.AddReplace("token_type", RegRead("TokenType", "OAuth"))
    oauth.AddReplace("expires_in", RegRead("ExpiresIn", "OAuth"))
    oauth.AddReplace("refresh_token", RegRead("RefreshToken", "OAuth"))
    oauth.AddReplace("scope", RegRead("Scope", "OAuth"))
    oauth.AddReplace("created_at", RegRead("CreatedAt","OAuth"))
    oauth.AddReplace("email", RegRead("Email","OAuth"))
    oauth.AddReplace("password", RegRead("Password","OAuth"))
    return oauth
  end if

  return invalid
end function


'******************************************************
' String Casting
'******************************************************
Function ToString(variable As Dynamic) As String
    If Type(variable) = "roInt" Or Type(variable) = "roInteger" Or Type(variable) = "roFloat" Or Type(variable) = "Float" Then
        Return Str(variable).Trim()
    Else If Type(variable) = "roBoolean" Or Type(variable) = "Boolean" Then
        If variable = True Then
            Return "True"
        End If
        Return "False"
    Else If Type(variable) = "roString" Or Type(variable) = "String" Then
        Return variable
    Else
        Return Type(variable)
    End If
End Function


function RegWriteAccessToken(data as object)
  ' print data
  access_token = ToString(data.access_token)
  token_type = ToString(data.token_type)
  expires_in = AnyToString(data.expires_in)
  refresh_token = ToString(data.refresh_token)
  scope = ToString(data.scope)
  created_at = AnyToString(data.created_at)

  email = ToString(data.email)
  password = ToString(data.password)

  RegWrite("AccessToken", access_token, "OAuth")
  RegWrite("TokenType", token_type, "OAuth")
  RegWrite("ExpiresIn", expires_in, "OAuth")
  RegWrite("RefreshToken", refresh_token, "OAuth")
  RegWrite("Scope", scope, "OAuth")
  RegWrite("CreatedAt", created_at, "OAuth")

  RegWrite("Email", email, "OAuth")
  RegWrite("Password", password, "OAuth")
end function

function RequestToken(client_id as String, client_secret as String, udid as String, pin as String)
  data = CreateObject("roAssociativeArray")
  data.AddReplace("client_id", client_id)
  data.AddReplace("client_secret", client_secret)
  data.AddReplace("linked_device_id", udid)
  data.AddReplace("pin", pin)
  data.AddReplace("grant_type", "password")

  res = RetrieveToken(data)
  if res <> invalid
    RegWriteAccessToken(res)
  end if
end function

function IsExpired(created_at as integer, expires_in as integer)
  dt = createObject("roDateTime")
  dt.mark()
  delta = dt.asSeconds() - created_at
  print "Checking is_expired"
  return delta > expires_in
end function

function ResetAccessToken()
  RegDelete("AccessToken", "OAuth")
  RegDelete("TokenType", "OAuth")
  RegDelete("ExpiresIn", "OAuth")
  RegDelete("RefreshToken", "OAuth")
  RegDelete("Scope", "OAuth")
  RegDelete("CreatedAt", "OAuth")
  RegDelete("Email", "OAuth")
  RegDelete("Password", "OAuth")
end function

function AddOAuth(data as object)
  m.oauth.access_token = data.access_token
  m.oauth.token_type = data.token_type
  m.oauth.expires_in = data.expires_in
  m.oauth.refresh_token = data.refresh_token
  m.oauth.scope = data.scope
  m.oauth.created_at = data.created_at
end function

function ClearOAuth()
  m.oauth = {
    access_token: invalid,
    token_type: invalid,
    expires_in: invalid,
    refresh_token: invalid,
    scope: invalid,
    created_at: invalid
  }
end function

function RetrieveToken(params as object) as object
    url = GetApiConfigs().oauth_endpoint + "oauth/token"
    req = RequestPost(url, params)
    return req
end function

function RetrieveTokenStatus(params as object) as object
    url = GetApiConfigs().oauth_endpoint + "oauth/token/info"
    req = MakeRequest(url, params)
    return req
end function

function RefreshToken(params as dynamic) as object
    url = GetApiConfigs().endpoint + "oauth/token"
    req = RequestPost(url, params)
    return req
end function

Function RequestPost(url As String, data As dynamic)
    if validateParam(data, "roAssociativeArray", "RequestPost") = false return -1

    roUrlTransfer = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    roUrlTransfer.SetPort(port)

    if url.InStr(0, "https") = 0
      roUrlTransfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
      roUrlTransfer.AddHeader("X-Roku-Reserved-Dev-Id", "")
      roUrlTransfer.InitClientCertificates()
    end if

    roUrlTransfer.SetUrl(url)
    roUrlTransfer.AddHeader("Content-Type", "application/json")
    roUrlTransfer.AddHeader("Accept", "application/json")
    json = FormatJson(data)
    print "Posting to "  roUrlTransfer.GetUrl()  ": "  json
    ?"the url is ==>"url
    if(roUrlTransfer.AsyncPostFromString(json))
      while(true)
        msg = wait(0, port)
        if(type(msg) = "roUrlEvent")
          code = msg.GetResponseCode()
          ?"the code is ==>"code
          if(code = 200)
            res = ParseJSON(msg.GetString())
            ' print "result: "; res
            return res
          else if code = 401
            ' print "401"
            return invalid
          end if
        else if(event = invalid)
          roUrlTransfer.AsyncCancel()
          exit while
        end if
      end while
    end if
    return invalid
End Function

Function RequestTokenByEmail(client_id as String, client_secret as String, email as String, password as String)
  print "client_id: "; client_id; " --- client_secret: "; client_secret; " --- email: "; email; " --- password: "; password
  data = CreateObject("roAssociativeArray")
  data.AddReplace("client_id", client_id)
  data.AddReplace("client_secret", client_secret)
  data.AddReplace("username", email)
  data.AddReplace("password", password)
  data.AddReplace("grant_type", "password")

  res = RetrieveToken(data)
  if res <> invalid
    res.email = email
    res.password = password
    RegWriteAccessToken(res)
  end if
End Function

Function Login(client_id as String, client_secret as String, email as String, password as String)
  oauth = RegReadAccessToken()
  if oauth = invalid
    ResetAccessToken()
    RequestTokenByEmail(client_id, client_secret, email, password)
  else if IsExpired(oauth.created_at.ToInt(), oauth.expires_in.ToInt())
    ResetAccessToken()
    data = {
      "client_id": client_id,
      "client_secret": client_secret,
      "refresh_token": oauth.refresh_token,
      "grant_type": "refresh_token"
    }
    res = RefreshToken(data)
    if res <> invalid
      res.email = email
      res.password = password

      RegWriteAccessToken(res)
    end if
  end if

  return RegReadAccessToken()
End Function

Function Logout()
  oauth = RegReadAccessToken()
  if oauth <> invalid
    ClearOAuth()
    ResetAccessToken()
  end if
End Function

function GetAndSaveNewToken(method as string) as void
  oauth = RegReadAccessToken()

  configs = GetApiConfigs()

  if method = "login"
    Logout()
    Login(configs.client_id, configs.client_secret, oauth.email, oauth.password)
  else if method = "device_linking"
    Logout()
    GetAccessTokenWithPin( configs.client_id, configs.client_secret, GetUdidFromReg(), GetPin(GetUdidFromReg()) )
  end if
end function
