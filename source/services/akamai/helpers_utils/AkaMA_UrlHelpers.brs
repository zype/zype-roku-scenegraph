'**********************************************************
'**  Video Player Example Application - URL Utilities 
'**  November 2009
'**  Copyright (c) 2009 Roku Inc. All Rights Reserved.
'**********************************************************

' ******************************************************
' Constucts a URL Transfer object
' ******************************************************

Function AkaMA_CreateURLTransferObject(url As String) as Object
    obj = CreateObject("roUrlTransfer")
    obj.SetPort(CreateObject("roMessagePort"))
    'obj.SetUrl(obj.UrlEncode(url))
    'obj.SetUrl(obj.Escape(url))
    obj.SetUrl(url)
    'obj.SetUrl(AkaMA_HttpEncode(url))

    'obj.SetCertificatesFile("pkg:/testCA.CRT")
    obj.SetCertificatesFile("common:/certs/ca-bundle.crt")
    obj.AddHeader("X-Roku-Reserved-Dev-Id", "")
    obj.InitClientCertificates()

    obj.AddHeader("Content-Type", "application/x-www-form-urlencoded")
    obj.EnableEncodings(true)
    return obj
End Function

' ******************************************************
' Url Query builder
' so this is a quick and dirty name/value encoder/accumulator
' ******************************************************

Function AkaMA_NewHttp(url As String) as Object
    obj = CreateObject("roAssociativeArray")
    obj.Http                        = AkaMA_CreateURLTransferObject(url)
    obj.FirstParam                  = true
    obj.AddParam                    = AkaMA_http_add_param
    obj.AddRawQuery                 = AkaMA_http_add_raw_query
    obj.GetToStringWithRetry        = AkaMA_http_get_to_string_with_retry
    obj.PrepareUrlForQuery          = AkaMA_http_prepare_url_for_query
    obj.GetToStringWithTimeout      = AkaMA_http_get_to_string_with_timeout
    obj.PostFromStringWithTimeout   = AkaMA_http_post_from_string_with_timeout

    if Instr(1, url, "?") > 0 then obj.FirstParam = false

    return obj
End Function


' ******************************************************
' Constucts a URL Transfer object 2
' ******************************************************

Function AkaMA_CreateURLTransferObject2(url As String, contentHeader As String) as Object
    obj = CreateObject("roUrlTransfer")
    obj.SetPort(CreateObject("roMessagePort"))
    'requestURL = obj.UrlEncode(obj.Escape(url))
    obj.SetUrl(url)
    obj.AddHeader("Content-Type", contentHeader)
    obj.EnableEncodings(true)
    return obj
End Function

' ******************************************************
' Url Query builder 2
' so this is a quick and dirty name/value encoder/accumulator
' ******************************************************

Function AkaMA_NewHttp2(url As String, contentHeader As String) as Object
    obj = CreateObject("roAssociativeArray")
    obj.Http                        = AkaMA_CreateURLTransferObject2(url, contentHeader)
    obj.FirstParam                  = true
    obj.AddParam                    = AkaMA_http_add_param
    obj.AddRawQuery                 = AkaMA_http_add_raw_query
    obj.GetToStringWithRetry        = AkaMA_http_get_to_string_with_retry
    obj.PrepareUrlForQuery          = AkaMA_http_prepare_url_for_query
    obj.GetToStringWithTimeout      = AkaMA_http_get_to_string_with_timeout
    obj.PostFromStringWithTimeout   = AkaMA_http_post_from_string_with_timeout

    if Instr(1, url, "?") > 0 then obj.FirstParam = false

    return obj
End Function


' ******************************************************
' AkaMA_HttpEncode - just encode a string
' ******************************************************

Function AkaMA_HttpEncode(str As String) As String
    o = CreateObject("roUrlTransfer")
    return o.Escape(str)
End Function

' ******************************************************
' Prepare the current url for adding query parameters
' Automatically add a '?' or '&' as necessary
' ******************************************************

Function AkaMA_http_prepare_url_for_query() As String
    url = m.Http.GetUrl()
    if m.FirstParam then
        url = url + "?"
        m.FirstParam = false
    else
        url = url + "&"
    endif
    m.Http.SetUrl(url)
    return url
End Function

' ******************************************************
' Percent encode a name/value parameter pair and add the
' the query portion of the current url
' Automatically add a '?' or '&' as necessary
' Prevent duplicate parameters
' ******************************************************

Function AkaMA_http_add_param(name As String, val As String) as Void
    q = m.Http.Escape(name)
    q = q + "="
    url = m.Http.GetUrl()
    if Instr(1, url, q) > 0 return    'Parameter already present
    q = q + m.Http.Escape(val)
    m.AddRawQuery(q)
End Function

' ******************************************************
' Tack a raw query string onto the end of the current url
' Automatically add a '?' or '&' as necessary
' ******************************************************

Function AkaMA_http_add_raw_query(query As String) as Void
    url = m.PrepareUrlForQuery()
    url = url + query
    m.Http.SetUrl(url)
End Function

' ******************************************************
' Performs Http.AsyncGetToString() in a retry loop
' with exponential backoff. To the outside
' world this appears as a synchronous API.
' ******************************************************

Function AkaMA_http_get_to_string_with_retry() as String
    timeout%         = 1500
    num_retries%     = 5

    str = ""
    while num_retries% > 0
'        print "httpget try " + AkaMA_itostr(num_retries%)
        if (m.Http.AsyncGetToString())
            event = wait(timeout%, m.Http.GetPort())
            if type(event) = "roUrlEvent"
                str = event.GetString()
                exit while        
            else if event = invalid
                m.Http.AsyncCancel()
                ' reset the connection on timeouts
                m.Http = AkaMA_CreateURLTransferObject(m.Http.GetUrl())
                timeout% = 2 * timeout%
            else
                print "roUrlTransfer::AsyncGetToString(): unknown event"
            endif
        endif

        num_retries% = num_retries% - 1
    end while
    
    return str
End Function

' ******************************************************
' Performs Http.AsyncGetToString() with a single timeout in seconds
' To the outside world this appears as a synchronous API.
' ******************************************************

Function AkaMA_http_get_to_string_with_timeout(seconds as Integer) as String
    timeout% = 1000 * seconds

    str = ""
    m.Http.EnableFreshConnection(true) 'Don't reuse existing connections
    if (m.Http.AsyncGetToString())
        event = wait(timeout%, m.Http.GetPort())
        if type(event) = "roUrlEvent"
            print "received response code = "; event.GetResponseCode()
            print "received failure reason code = ";event.GetFailureReason()
            print "received response header = ";event.GetResponseHeaders()
            str = event.GetString()
        elseif event = invalid
            AkaMA_Dbg("AsyncGetToString timeout")
            m.Http.AsyncCancel()
        else
            AkaMA_Dbg("AsyncGetToString unknown event", event)
        endif
    endif

    return str
End Function

' ******************************************************
' Performs Http.AsyncPostFromString() with a single timeout in seconds
' To the outside world this appears as a synchronous API.
' ******************************************************

Function AkaMA_http_post_from_string_with_timeout(val As String, seconds as Integer) as String
    timeout% = 1000 * seconds

    str = ""
'    m.Http.EnableFreshConnection(true) 'Don't reuse existing connections
    if (m.Http.AsyncPostFromString(val))
        event = wait(timeout%, m.Http.GetPort())
        if type(event) = "roUrlEvent"
            print "1"
            str = event.GetString()
        elseif event = invalid
            print "2"
            AkaMA_Dbg("AsyncPostFromString timeout")
            m.Http.AsyncCancel()
        else
            print "3"
            AkaMA_Dbg("AsyncPostFromString unknown event", event)
        endif
    endif

    return str
End Function
