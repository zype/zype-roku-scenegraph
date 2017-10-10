' this file provides functions for generating guid and client id for 
' MA plugin


'Function       :   AkaMA_GUID
'Params         :   None 
'Return         :   GUID string 
'Description    :   Creates a GUID 
'                   
function AkaMA_GUID() as string
    id1 = CreateObject("roDateTime").asSeconds()
    id2 = Rnd(0)
    di = CreateObject("roDeviceInfo")
    version = di.GetVersion()
    major = Mid(version, 3, 1)
    minor = Mid(version, 5, 2)
    build = Mid(version, 8, 5)
    'id3 =  major + minor + build
    print "Device unique id = ";di.GetDeviceUniqueId()
    print "Device model = "; di.GetModel()
    print "Device version = ";di.GetVersion()
    id3 = box("")
    id3 = id3 + di.GetDeviceUniqueId() + di.GetModel() + di.GetVersion() 
    
    print"id1 = "; id1
    print"id2 = "; id2
    print"id3 = "; id3
    
    digestSrc = CreateObject("roByteArray")
    digestSrcString = box("")
    digestSrcString = digestSrcString + AkaMA_itostr(id1) + AkaMA_itostr(id2) + id3
    
    digestSrc.FromAsciiString(digestSrcString)
    print "digestSrcString = "; digestSrcString; " and digestSrc = "; digestSrc
    digest = CreateObject("roEVPDigest")
    digest.Setup("sha1")
    result = digest.Process(digestSrc)
    print "Digested result = "; result
        
    return result
end function

'Function       :   AkaMA_ClienID
'Params         :   None 
'Return         :   GUID string 
'Description    :   Creates a GUID 
'                   
function AkaMA_ClientID() as string
    di = CreateObject("roDeviceInfo")
    digestSrc = CreateObject("roByteArray")
    digestSrc.FromAsciiString(di.GetDeviceUniqueId())
    print " digestSrc = "; digestSrc

    digest = CreateObject("roEVPDigest")
    digest.Setup("md5")
    digest.Update(digestSrc)
    result = digest.Final()
    print "Digested result = "; result
    return result
end function
