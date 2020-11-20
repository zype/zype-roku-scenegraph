Function init()
    m.top.functionName = "start"
    m.port = CreateObject("roMessagePort")
end Function

function start()
    ' print "eventParams - " m.top.eventParams

    UATracker = m.global.UATracker

    if (UATracker.cid = invalid)        
        return false
    end if

    payload = CreatePayload(UATracker)
    dataTransfer = createObject("roUrlTransfer")
    dataTransfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    dataTransfer.SetMessagePort(m.port)
    dataTransfer.setUrl(UATracker.endpoint)

    if (dataTransfer.AsyncPostFromString(payload)) then
        while true
            msg = wait(0, m.port)
            if type(msg) = "roUrlEvent" then
                exit while
            end if
        end while
    else
        dataTransfer.AsyncCancel()
        m.top.result = {}
    end if

end function

function CreatePayload(UATracker as dynamic) as string

  eventParams = m.top.eventParams

  EventCat = ""
  if eventParams.category <> invalid
    EventCat = eventParams.category
  end if

  EventAct = ""
  if eventParams.action <> invalid
    EventAct = eventParams.action
  end if

  EventLab = ""
  if  eventParams.label <> invalid
    EventLab = eventParams.label
  end if

  EventVal = 0
  if eventParams.value <> invalid and type(eventParams.value) = "roInt"
    EventVal = eventParams.value
  end if

  payload = "z="+GetRandomInt(10)
  payload = payload + "&v=1"
  payload = payload + "&cid=" + UATracker.cid
  payload = payload + "&tid=" + UATracker.trackingId

  payload = payload + "&sr=" + UATracker.sr
  payload = payload + "&an=" + UATracker.appName
  payload = payload + "&av=" + UATracker.appVersion

  payload = payload + "&t=event"
  If Len(EventCat) > 0
  payload = payload + "&ec=" + EventCat
  end if
  If Len(EventAct) > 0
  payload = payload + "&ea=" + EventAct
  end if
  ' If Len(EventLab) > 0
  ' payload = payload + "&el=" + EventLab
  ' end if
  ' If EventVal > 0
  ' payload = payload + "&ev=" + EventVal
  ' end if

  customParams = m.top.customParams

  If customParams.siteId <> invalid and customParams.siteId <> ""
    payload = payload + "&cd1=" + customParams.siteId
  end if

  If customParams.deviceId <> invalid and customParams.deviceId <> ""
    payload = payload + "&cd2=" + customParams.deviceId
  end if

  payload = payload.EncodeUri()
  return payload

end function

Function GetRandomInt(length As Integer) As String
    hexChars = "0123456789"
    hexString = ""
    For i = 1 to length
        hexString = hexString + hexChars.Mid(Rnd(16) - 1, 1)
    Next
    Return hexString
End Function
