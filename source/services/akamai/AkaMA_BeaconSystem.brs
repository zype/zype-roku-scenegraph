'Beacon system will handle operations related to sending a beacons

'Function       :   AkaMA_isBeaconInOrder
'Params         :   None.
'Return         :   Returns BeaconOrders which defines valid order for the beacons 
'Description    :   Use this as a reference for beacon order
function AkaMA_isBeaconInOrder()
return {    
    BeaconReported:{
    iLineReported   :   &H0001
    sLineReported   :   &H0002
    pLineReported   :   &H0004
    cLineReported   :   &H0008
    eLineReported   :   &H0010
    vLineReported   :   &H0020
    }
}
end function 


'Function       :   AkaMA_MABeacons
'Params         :   None.
'Return         :   Returns function sendBeacon to send beacon 
'Description    :   Use this while sending beacons 
function AkaMA_MABeacons()
return {        
    'Function       :   sendBeacon
    'Params         :   iBeacon. string with complete URL which will be sent to
    '                   back end
    'Return         :   Returns an error code if failed else success 
    'Description    :   Send's I-Line and sets beacon status to iLineSent 
    '                   Which maintains the status of the beacon system
    '                   this can be used to check if it is right time to send
    '                   a particular beacon
    sendBeacon : function(beacon as string) as integer
        beaconRequest = AkaMA_NewHttp(beacon)
        if (beaconRequest.Http.AsyncGetToString())
            event = wait(0, beaconRequest.Http.GetPort())
            if type(event) = "roUrlEvent"
                str = event.GetString()
                'print "Returned string = ";str
                if event.getResponseCode() <> 200
                    print "Http Request failed"
                    return AkaMAErrors().ERROR_CODES.AKAM_beacon_request_failed
                else if event.getResponseCode() = 200
                    print "Beacon sent successfully!!!"
                endif        
            else if event = invalid
                beaconRequest.Http.AsyncCancel()
                ' reset the connection on timeouts
            else
                print "roUrlTransfer::AsyncGetToString(): unknown event"
            endif
        endif
        return AkaMAErrors().ERROR_CODES.AKAM_Success
    end function
    
}
end function