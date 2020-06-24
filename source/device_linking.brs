' generate unique device id
function GenerateUdid() as String
    di = CreateObject("roDeviceInfo")
    return di.GetChannelClientid() + di.GetRandomUUID()
end function

' has udid in the registry
function HasUdid() as Boolean
    result = false

    Udid = RegRead("UDID", "DeviceLinking")
    if Udid <> invalid
        result = true
    end if

    return result
end function

' get udid from the registry
function GetUdidFromReg() as String
    Udid = RegRead("UDID", "DeviceLinking")

    if Udid = invalid
        Udid = GenerateUdid()
        Udid = AddUdidToReg(Udid)
    end if

    return Udid
end function

' delete udid from the registry
function RemoveUdidFromReg() as Void
    Udid = RegDelete("UDID", "DeviceLinking")
end function

' add udid to the registry
function AddUdidToReg(param_udid as String) as String
    RegWrite("UDID", param_udid, "DeviceLinking")
    Udid = RegRead("UDID", "DeviceLinking")
    return Udid
end function

' has pin in the registry
function HasLinkingPin() as Boolean
    result = false

    pin = RegRead("PIN", "DeviceLinking")
    if pin <> invalid
        result = true
    end if

    return result
end function

' get pin from the registry
function GetLinkingPinFromReg()
    pin = RegRead("PIN", "DeviceLinking")
    return pin
end function

' add pin to the registry
function AddLinkingPinToReg(pin)
    RegWrite("PIN", "DeviceLinking")
    pin = RegRead("PIN", "DeviceLinking")
    return pin
end function

function GetPin(udid as string) as Object
    pinData = AcquirePin({"linked_device_id": udid, "type": "roku"})
    result = invalid

    if pinData <> invalid
        result = pinData.pin
    end if

    return result
end function
