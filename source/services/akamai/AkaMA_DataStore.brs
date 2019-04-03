'This file will hold media metrics and dimensions
'Provides data to the beacon system so that beaconing system
' can send beacons

'Function       :   AkaMA_createDataStore
'Params         :   dataStoreParams. initialization params which will initialize 
'                   mediaMetricConfig with key value pairs
'Return         :   Returns newly created data store 
'Description    :   creates and maintains key-value pairs of dimensions + metrics. 
'                   Provides set of functions for operations on dataStore
'
function AkaMA_createDataStore()
dataStore = {
    ' mediaMetrics is a key-value map which will be updated dynamically
    mediaMetrics : CreateObject("roAssociativeArray")
    
    ' mediaMetricsConfig will hold key-value pairs from configuration xml
    mmConfig : CreateObject("roAssociativeArray")

    'custom dimensions
    custDimension : CreateObject("roAssociativeArray")
    

    'Function       :   initializeConfigMediaMetrics
    'Params         :   XML as object. A parsed xml content (Nothing but roXMLElement)
    'Return         :   none (UGT:todo -  shall we return error codes) 
    'Description    :   Initialization of media metrics object with configuration xml
    '                   Setting logType, and other initializtion from configuration xml
    initializeConfigMediaMetrics: function(xml as object)
        m.mmConfig = mediaMetricsConfig()
        if m.mmConfig.initMetricsWithXMLContents(xml) <> 0
            print"error in parsing xml contents"
        endif
        print "logtype from xml = ";m.mmconfig.logTo["logType"]
        if m.mmconfig.logTo["logType"] = "relative"
            logTypeValue = "R"
        else if m.mmconfig.logTo["logType"] = "cumulative"
            logTypeValue = "C"
        end if 
        print "logTypeValue is = ";logTypeValue
        updateParams = {
                        logType         :   logTypeValue
                        logVersion      :   m.mmconfig.logTo["logVersion"]
                        formatVersion   :   m.mmconfig.logTo["formatVersion"]
                       }
         m.addUdpateMediaMetrics(updateParams)
    end function
        
    'Function       :   addUdpateMediaMetrics
    'Params         :   updatedValues. key-value pair(s) which needs to be added or updated to media metrics 
    'Return         :   none (UGT:todo -  shall we return error codes) 
    'Description    :   adds / updates values in media metrics array. Iterates through supplied
    '                   key-value pairs and adds/updates them in media metrics
    '                   Note if key is already there it will be over-writen with new values
    addUdpateMediaMetrics: function(updatedValues)
        for each key in updatedValues
            m.mediaMetrics.AddReplace(key, updatedValues[key])
        next
    end function
    
    'Function       :   addUdpateCustomMetrics
    'Params         :   updatedValues. key-value pair(s) which needs to be added or updated 
    'Return         :   none (UGT:todo -  shall we return error codes) 
    'Description    :   adds / updates values in custom media metrics array. Iterates through supplied
    '                   key-value pairs and adds/updates them in custom metrics
    addUdpateCustomMetrics: function(updatedValues)
        for each key in updatedValues
            m.custDimension.AddReplace(key, updatedValues[key])
        next
    end function

    'Function       :   deleteIfExist
    'Params         :   key which needs to be deleted from media metrics 
    'Return         :   none (UGT:todo -  shall we return error codes) 
    'Description    :   deletes values in media metrics array if it is exist
    deleteIfExist: function(key)
        if m.mediaMetrics.DoesExist(key)
            m.mediaMetrics.Delete(key)
        endif
    end function

    'Function       :   uniqueDimensionLookUp
    'Params         :   uniqueMetricName The Unique Dimension to be looked up.
    'Return         :   Will return the metric name associated with the unique dimension.
    'Description    :   Given a unique dimension provides it's associated metric name.
    'Warn           :   This method currently support "viewerinterval" and "viewertitleinterval". For any
    '                   other input it will send empty string.
    uniqueDimensionLookUp: function(uniqueMetricName as String) as String
        dimension = ""
        if uniqueMetricName =  "viewerInterval"
            dimension = "viewerId"
        else if uniqueMetricName =  "viewerTitleInterval"
            dimension = "title"
        endif
        return dimension
    end function


    'Function       :   calculateUniqueDimension
    'Params         :   uniqueMetricName The Unique Dimension to be used for calculations.
    'Params         :   expiryDuration  Time from current time to expire the data.
    'Return         :   None
    'Description    :   Calculates the time at which the Unique Dimension was previously used.
    'Warn           :   Will insert the last time the unique metric was used into mediaMetrics. It will insert "0.0"
    '                   into the mediaMetrics if records were not found.
    calculateUniqueDimension: function(uniqueMetricName as String, expiryDuration as String)  as void
        timeDifference = "0.0"
        metricName = m.uniqueDimensionLookUp(uniqueMetricName)

        if m.mediaMetrics.DoesExist(metricName)
            manager = AkaMA_createStorageManager()
            metricValue = m.mediaMetrics[metricName]
            time = CreateObject("roDateTime")
            currentTime% = time.asSeconds()
            if metricValue.Len() > 0
                lastAccessTime = manager.lastAccessTime(metricValue)
                if lastAccessTime > 0
                    timeDiff = currentTime% - lastAccessTime
                    if timeDiff > 0
                        timeDiff = (timeDiff/60)
                        timeDifference = str(timeDiff).Trim()
                    endif
                endif
            endif
            expiry% = expiryDuration.ToInt()
            ' Converting minutes to seconds
            expiry% = expiry% * 60
            manager.addOrUpdate(metricValue, currentTime%, (currentTime% + expiry%))
        endif
        m.mediaMetrics[uniqueMetricName] = timeDifference
    end function

    'Function       :   getILinedataAsString
    'Params         :   None
    'Return         :   Returns I line data as a string. String should have encoded key-value pairs
    '                   separated by a separator 
    'Description    :   This function constructs string from dimensions and metrics wchich will be sent 
    '                   as part of I line beacon
    getILinedataAsString : function() as string
        m.populateCustomeDimensions()
        ' Calculating unqiue viewers.
        viewerInternalObject = m.mmconfig.mmBeaconMetric.initMetrics["viewerInterval"]
        if viewerInternalObject <> invalid
            m.calculateUniqueDimension("viewerInterval", viewerInternalObject.expiry)
        endif
        iLineData = box("a=I~")'CreateObject("roString")
        iLineData = iLineData + "b=" + m.mmconfig.beaconId + "~" + "az=" + m.mmconfig.beaconVersion + "~"
        iLineData = iLineData + m.fillupCommonMetrics()
        for each key in m.mmconfig.mmBeaconMetric.initMetrics
            if m.mediaMetrics[key] <> invalid
                keyForMetrics = m.getKeyForElement(m.mmconfig.mmBeaconMetric.initMetrics, key)
                iLineData.ifstringops.AppendString(keyForMetrics, keyForMetrics.Len())
                iLineData = iLineData + "="
                iLineData.ifstringops.AppendString(m.getEncodedString(m.mediaMetrics[key]), m.getEncodedString(m.mediaMetrics[key]).len())
                iLineData = iLineData + "~"
            endif 
        next
         
        isPresent = m.isHTTPPresent(m.mmconfig.logTo["host"])
        if isPresent = true
            iBeaconURL = box("")
        else
            iBeaconURL = box("http://")
        endif
        iBeaconURL.ifstringops.AppendString(m.mmconfig.logTo["host"], m.mmconfig.logTo["host"].Len())
        iBeaconURL.ifstringops.AppendString(m.mmconfig.logTo["path"], m.mmconfig.logTo["path"].Len())
        iBeaconURL = iBeaconURL + "?" + iLineData'm.getEncodedString(iLineData) 
        return iBeaconURL.Left(Len(iBeaconURL)-1)
    end function
    
    'Function       :   getSLinedataAsString
    'Params         :   None
    'Return         :   Returns S line data as a string. String should have encoded key-value pairs
    '                   separated by a separator 
    'Description    :   This function constructs string from dimensions and metrics wchich will be sent 
    '                   as part of S line beacon
    getSLinedataAsString : function() as string
        m.populateCustomeDimensions()
        sLineData = box("a=S~")
        sLineData = sLineData + "b=" + m.mmconfig.beaconId + "~" + "az=" + m.mmconfig.beaconVersion + "~" 
        sLineData = sLineData + m.fillupCommonMetrics()
        for each key in m.mmconfig.mmBeaconMetric.playStartMetrics
        if m.mediaMetrics[key] <> invalid
            keyForMetrics = m.getKeyForElement(m.mmconfig.mmBeaconMetric.playStartMetrics, key)
            sLineData.ifstringops.AppendString(keyForMetrics, keyForMetrics.Len())
            sLineData = sLineData + "="
            sLineData.ifstringops.AppendString(m.getEncodedString(m.mediaMetrics[key]), m.getEncodedString(m.mediaMetrics[key]).len())
            sLineData = sLineData + "~"
        Endif     
        next
        isPresent = m.isHTTPPresent(m.mmconfig.logTo["host"])
        if isPresent = true
            sBeaconURL = box("")
        else
            sBeaconURL = box("http://")
        endif
       
        sBeaconURL.ifstringops.AppendString(m.mmconfig.logTo["host"], m.mmconfig.logTo["host"].Len())
        sBeaconURL.ifstringops.AppendString(m.mmconfig.logTo["path"], m.mmconfig.logTo["path"].Len())
        sBeaconURL = sBeaconURL + "?" + sLineData 'm.getEncodedString(sLineData) 
        return sBeaconURL.Left(Len(sBeaconURL)-1)
    end function

    'Function       :   getPLinedataAsString
    'Params         :   None
    'Return         :   Returns P line data as a string. String should have encoded key-value pairs
    '                   separated by a separator 
    'Description    :   This function constructs string from dimensions and metrics wchich will be sent 
    '                   as part of P line beacon
    getPLinedataAsString : function() as string
        m.populateCustomeDimensions()
        pLineData = box("a=P~")
        pLineData = pLineData + "b=" + m.mmconfig.beaconId + "~" + "az=" + m.mmconfig.beaconVersion + "~"
        pLineData = pLineData + m.fillupCommonMetrics()
        for each key in m.mmconfig.mmBeaconMetric.playingMetrics
            if m.mediaMetrics[key] <> invalid
                keyForMetrics = m.getKeyForElement(m.mmconfig.mmBeaconMetric.playingMetrics, key)
                pLineData.ifstringops.AppendString(keyForMetrics, keyForMetrics.Len())
                pLineData = pLineData + "="
                pLineData.ifstringops.AppendString(m.getEncodedString(m.mediaMetrics[key]), m.getEncodedString(m.mediaMetrics[key]).len())
                pLineData = pLineData + "~"
            endif  
        next
                
        isPresent = m.isHTTPPresent(m.mmconfig.logTo["host"])
        if isPresent = true
            pBeaconURL = m.mmconfig.logTo["host"] + m.mmconfig.logTo["path"] + "?" + pLineData'm.getEncodedString(pLineData)
        else
            pBeaconURL = "http://" + m.mmconfig.logTo["host"] + m.mmconfig.logTo["path"] + "?" + pLineData'm.getEncodedString(pLineData)
        endif
        
        return pBeaconURL.Left(Len(pBeaconURL)-1)
    end function

    'Function       :   getCLinedataAsString
    'Params         :   None
    'Return         :   Returns C line data as a string. String should have encoded key-value pairs
    '                   separated by a separator 
    'Description    :   This function constructs string from dimensions and metrics wchich will be sent 
    '                   as part of C line beacon
    getCLinedataAsString : function() as string
        m.populateCustomeDimensions()
        cLineData = box("a=C~")
        cLineData = cLineData + "b=" + m.mmconfig.beaconId + "~" + "az=" + m.mmconfig.beaconVersion + "~"
        cLineData = cLineData + m.fillupCommonMetrics()
        for each key in m.mmconfig.mmBeaconMetric.playbackCompletedMetrics
            if m.mediaMetrics[key] <> invalid
                keyForMetrics = m.getKeyForElement(m.mmconfig.mmBeaconMetric.playbackCompletedMetrics, key)
                cLineData.ifstringops.AppendString(keyForMetrics, keyForMetrics.Len())
                cLineData = cLineData + "="
                cLineData.ifstringops.AppendString(m.getEncodedString(m.mediaMetrics[key]), m.getEncodedString(m.mediaMetrics[key]).len())
                cLineData = cLineData + "~"
            endif  
        next
        
        for each key in m.mmconfig.mmBeaconMetric.playingMetrics
            if m.mmconfig.mmBeaconMetric.playbackCompletedMetrics.DoesExist(key) = false 
                if m.mediaMetrics[key] <> invalid
                    keyForMetrics = m.getKeyForElement(m.mmconfig.mmBeaconMetric.playingMetrics, key)
                    cLineData.ifstringops.AppendString(keyForMetrics, keyForMetrics.Len())
                    cLineData = cLineData + "="
                    cLineData.ifstringops.AppendString(m.getEncodedString(m.mediaMetrics[key]), m.getEncodedString(m.mediaMetrics[key]).len())
                    cLineData = cLineData + "~"
                endif
            endif  
        next
        
        isPresent = m.isHTTPPresent(m.mmconfig.logTo["host"])
        if isPresent = true
            cBeaconURL = m.mmconfig.logTo["host"] + m.mmconfig.logTo["path"] + "?" + cLineData'm.getEncodedString(cLineData)
        else
            cBeaconURL = "http://" + m.mmconfig.logTo["host"] + m.mmconfig.logTo["path"] + "?" + cLineData 'm.getEncodedString(cLineData)
        endif
        
        return cBeaconURL.Left(Len(cBeaconURL)-1)
    end function

    'Function       :   getELinedataAsString
    'Params         :   None
    'Return         :   Returns E line data as a string. String should have encoded key-value pairs
    '                   separated by a separator 
    'Description    :   This function constructs string from dimensions and metrics wchich will be sent 
    '                   as part of E line beacon
    getELinedataAsString : function() as string
        m.populateCustomeDimensions()
        eLineData = box("a=E~")
        eLineData = eLineData + "b=" + m.mmconfig.beaconId + "~" + "az=" + m.mmconfig.beaconVersion + "~"
        eLineData = eLineData + m.fillupCommonMetrics()
        for each key in m.mmconfig.mmBeaconMetric.errorMetrics
            if m.mediaMetrics[key] <> invalid
                keyForMetrics = m.getKeyForElement(m.mmconfig.mmBeaconMetric.errorMetrics, key)
                eLineData.ifstringops.AppendString(keyForMetrics, keyForMetrics.Len())
                eLineData = eLineData + "="
                eLineData.ifstringops.AppendString(m.getEncodedString(m.mediaMetrics[key]), m.getEncodedString(m.mediaMetrics[key]).len())
                eLineData = eLineData + "~"
            endif  
        next
        
        isPresent = m.isHTTPPresent(m.mmconfig.logTo["host"])
        if isPresent = true
            eBeaconURL = m.mmconfig.logTo["host"] + m.mmconfig.logTo["path"] + "?" + eLineData ' m.getEncodedString(eLineData)
        else
            eBeaconURL = "http://" + m.mmconfig.logTo["host"] + m.mmconfig.logTo["path"] + "?" + eLineData 'm.getEncodedString(eLineData)
        endif
        
        return eBeaconURL.Left(Len(eBeaconURL)-1)
    end function

    'Function       :   getVLinedataAsString
    'Params         :   None
    'Return         :   Returns V line data as a string. String should have encoded key-value pairs
    '                   separated by a separator 
    'Description    :   This function constructs string from dimensions and metrics wchich will be sent 
    '                   as part of V line beacon
    getVLinedataAsString : function() as string
        m.populateCustomeDimensions()
        vLineData = box("a=V~")
        vLineData = vLineData + "b=" + m.mmconfig.beaconId + "~" + "az=" + m.mmconfig.beaconVersion + "~"
        vLineData = vLineData + m.fillupCommonMetrics()
        for each key in m.mmconfig.mmBeaconMetric.visitMetrics
            if m.mediaMetrics[key] <> invalid
                keyForMetrics = m.getKeyForElement(m.mmconfig.mmBeaconMetric.visitMetrics, key)
                vLineData.ifstringops.AppendString(keyForMetrics, keyForMetrics.Len())
                vLineData = vLineData + "="
                vLineData.ifstringops.AppendString(m.getEncodedString(m.mediaMetrics[key]), m.getEncodedString(m.mediaMetrics[key]).len())
                vLineData = vLineData + "~"
            endif  
        next
        
        isPresent = m.isHTTPPresent(m.mmconfig.logTo["host"])
        if isPresent = true
            vBeaconURL = m.mmconfig.logTo["host"] + m.mmconfig.logTo["path"] + "?" + vLineData 'm.getEncodedString(vLineData)
        else
            vBeaconURL = "http://" + m.mmconfig.logTo["host"] + m.mmconfig.logTo["path"] + "?" + vLineData 'm.getEncodedString(vLineData)
        endif
        
        return vBeaconURL.Left(Len(vBeaconURL)-1)
    end function
    
    'Function       :   fillupCommonMetrics
    'Params         :   None
    'Return         :   Retruns box (string) with common section of xml from common metrics
    'Description    :   This function reads key-value from commonMetrics and puts it in the string  
    '                   for beacon request
    fillupCommonMetrics : function () as object
        commonData = box("")
        for each key in m.mmconfig.mmBeaconMetric.commonMetrics
            if m.mediaMetrics[key] <> invalid
                keyForMetrics = m.getKeyForElement(m.mmconfig.mmBeaconMetric.commonMetrics, key)
                commonData.ifstringops.AppendString(keyForMetrics, keyForMetrics.Len())
                commonData = commonData + "="
                commonData.ifstringops.AppendString(m.getEncodedString(m.mediaMetrics[key]), m.getEncodedString(m.mediaMetrics[key]).len())
                commonData = commonData + "~"
            endif  
        next
        return commonData
    end function
    
    'Function       :   populateCustomeDimensions
    'Params         :   None
    'Return         :   None 
    'Description    :   This function Populates custome dimensions from custDimenstion dictionary to mediaMetrics dictionary  
    populateCustomeDimensions : function ()
        for each key in m.custDimension
            m.mediaMetrics.AddReplace(key, m.custDimension[key])
        next
        
        if m.mediaMetrics.DoesExist("eventName") = false
            if m.mediaMetrics.DoesExist("streamName")
                m.mediaMetrics.AddReplace("eventName",m.mediaMetrics["streamName"])
            endif
        endif    
        if m.mediaMetrics.DoesExist("title") = false
            if m.mediaMetrics.DoesExist("streamName")
                m.mediaMetrics.AddReplace("title",m.mediaMetrics["streamName"])
            endif
        endif
    end function
    
    'Function       :   getEncodedString
    'Params         :   inString a string object which needs to be encoded
    'Return         :   returns encoded string
    'Description    :   This function encodes inString and returns encoded string  
    ' getEncodedString:function(inString as string) as string
    getEncodedString:function(inString) as string
        'print "not encoded beacon data = "; inString
        ue = CreateObject("roURLTransfer")        
        'encodedOutString = AkaMA_str8859toutf8(inString)
        
        'Replace ~ with *@*
        replaceTilda = AkaMA_strReplace(inString, "~", "*@*")
        encodedOutString = ue.UrlEncode(replaceTilda)
        
        'encodedOutString = ue.UrlEncode(inString)
        'print "encoded beacon request = "; encodedOutString
        'return AkaMA_strReplace(encodedOutString," ","%20")
        return encodedOutString
        
'        o = CreateObject("roUrlTransfer")
'        'encodedOutString = o.UrlEncode(AkaMA_HttpEncode(inString))
'        'encodedOutString = o.UrlEncode(inString)
'        encodedOutString = AkaMA_HttpEncode(inString)
'        'print "encoded beacon request = "; encodedOutString
        return encodedOutString
    end function 
   
    'Function       :   isHTTPPresent
    'Params         :   baseString in which to find if "http://" tag present or absent
    'Return         :   returns true / false based on the presence of http
    'Description    :   This function checks if "http://"  present in url at the beginning or not
    '                   As beacon xml's host value may have url with http:// or may not have. This
    '                   Needs to be taken care by plugin
    isHTTPPresent:function(baseString as string) as Boolean
    position = instr(1, baseString, "http://")
    if position = 1 
        return true
    else
        position = instr(1, baseString, "https://")
        if position = 1
            return true
        else
            return false
        endif
    endif       
   end function
    
    'Function       :   getKeyForElement
    'Params         :   metrics a media metrics object
    '                   Key : a key for which to get element
    'Return         :   returns correct key based on the value of useKey
    'Description    :   This function returns short key or long key based on the
    '                   value of useKey in beacon xml. Beacon xml has a swtich
    '                   to reprot short key or long key in beacons
   getKeyForElement:function(metrics as object, key as string) as string
     if m.mmconfig.useKey = 0
        return key
     else if m.mmconfig.useKey = 1
        return metrics[key].key
     endif
   end function 
}

return dataStore
end function


'Function       :   mediaMetricsConfig
'Params         :   configParams. initialization params which will initialize 
'                   from configuration xml with key value pairs
'Return         :   Returns newly created configuration media meatrics 
'Description    :   creates and maintains key-value pairs of configuration media metrics 
'
'UGT:Todo - do we need configParams and error  in this -- function mediaMetricsConfig(configParams, error)
function mediaMetricsConfig()
mmConfig = {
        mmBeaconMetric : {
            commonMetrics               :   {}
            initMetrics                 :   {}
            playStartMetrics            :   {}
            playingMetrics              :   {}
            playbackCompletedMetrics    :   {}
            errorMetrics                :   {}
            visitMetrics                :   {}
        }
        beaconInfo                      :   {}
        logTo                           :   CreateObject("roAssociativeArray")
        beaconId                        :   CreateObject("roString")
        beaconVersion                   :   CreateObject("roString")
        useKey                          :   0
        securityURLAuthInfo             :   invalid
        securityViewerDiagnosticsInfo   :   invalid
                
        'initialize from configuration xml
        'Function       :   initMetricsWithXMLContents
        'Params         :   xml parsed xml object 
        'Return         :   returns success or error code
        'Description    :   This function creates and fills up associative arrays from 
        '                   config xml. This provides more structured representation 
        '                   of xml contents and organizes for later use by the plugin
        initMetricsWithXMLContents : function(xml as object) as integer
            if xml = invalid
                return AkaMAErrors().ERROR_CODES.AKAM_Invalid_configuration_xml
            end if
            AkaMA_createStorageManager().deleteExpiredData()
            m.beaconId = xml.beaconId.getText()
            m.beaconVersion =   xml.beaconVersion.getText()
            
            'Populate logTo values
            element = xml.logTo
            m.logTo.addReplace("logInterval", element@logInterval)
            m.logTo.addReplace("secondaryLogTime", element@secondaryLogTime)
            m.logTo.addReplace("logType", element@logType)
            m.logTo.addReplace("maxLogLineLength", element@maxLogLineLength)
            m.logTo.addReplace("urlParamSeparator", element@urlParamSeparator)
            m.logTo.addReplace("encodedParamSeparator", element@encodedParamSeparator)
            m.logTo.addReplace("heartBeatInterval", element@heartBeatInterval)
            m.logTo.addReplace("visitTimeout", element@visitTimeout)
            
            hostElement = xml.logTo.host
            'print " host = ";hostElement.GetText()
            m.logTo.addReplace("host", hostElement.GetText())
            m.logTo.addReplace("path", xml.logTo.path.GetText())
            m.logTo.addReplace("logVersion", xml.logTo.logVersion.GetText())
            m.logTo.addReplace("formatVersion", xml.logTo.formatVersion.GetText())
            AkaMA_logger().AkaMA_print("========= Printing logTo key / value ===== ")
            'AkaMA_PrintAnyAA(3, m.logTo)
            AkaMA_logger().AkaMA_print("============End==============")
            
            'Populate key-valud pairs for URL authentication (Security tag)
            securityUrlAuthElement = xml.security.URLAuth1
            if securityUrlAuthElement <> invalid
                m.securityURLAuthInfo = CreateObject("roAssociativeArray")
                m.securityURLAuthInfo.addReplace("salt", securityUrlAuthElement.salt.GetText())
                m.securityURLAuthInfo.addReplace("window", securityUrlAuthElement.window.GetText())
                m.securityURLAuthInfo.addReplace("param", securityUrlAuthElement.param.GetText())
                print "========= Printing URL authentication key / value ===== "
                AkaMA_PrintAnyAA(3, m.securityURLAuthInfo)
                print "============End=============="
             end if   
            
            'Populate key-valud pairs for viewerdiagnostics (Security tag)
            securityViewerDiagInfo = xml.security.ViewerDiagnostics 
            if securityViewerDiagInfo <> invalid
                m.securityViewerDiagnosticsInfo = CreateObject("roAssociativeArray") 
                m.securityViewerDiagnosticsInfo.addReplace("version", securityViewerDiagInfo.salt@version)
                m.securityViewerDiagnosticsInfo.addReplace("value", securityViewerDiagInfo.salt@value)
                m.securityViewerDiagnosticsInfo.addReplace("iterations", securityViewerDiagInfo.salt@iterations)
                m.securityViewerDiagnosticsInfo.addReplace("bytes", securityViewerDiagInfo.salt@bytes)
                
                if securityViewerDiagInfo.iterations@value <> invalid
                    m.securityViewerDiagnosticsInfo.addReplace("iterations", securityViewerDiagInfo.iterations@value)
                end if   
                if securityViewerDiagInfo.bytes@value <> invalid
                    m.securityViewerDiagnosticsInfo.addReplace("bytes", securityViewerDiagInfo.bytes@value)
                end if
                print "========= Printing ViewerDiangostics key / value ===== "
                AkaMA_PrintAnyAA(3, m.securityViewerDiagnosticsInfo)
                print "============End=============="
            end if
            'Populate key-value pairs for common metrics
            statsElement = xml.statistics
            if statsElement@useKey = "1"
                m.useKey = 1
                print"setting useKey to 1"
            else if statsElement@useKey = "0"
                m.useKey = 0
                print"setting useKey to 0"
            endif    
            for each element in xml.statistics.common.dataMetrics.data
                m.mmBeaconMetric.commonMetrics.AddReplace(element@name, {key:element@key, value:AkaMA_validstr(element@value)})
            next
            AkaMA_logger().AkaMA_print("========= Printing Common key / value ===== ")
            'AkaMA_PrintAnyAA(3, m.mmBeaconMetric.commonMetrics)
            AkaMA_logger().AkaMA_print("============End==============")
            
            'Populate key-value pairs for init metrics
            m.mmBeaconMetric.initMetrics.AddReplace("eventCode", xml.statistics.init@eventCode)
            for each element in xml.statistics.init.dataMetrics.data
                m.mmBeaconMetric.initMetrics.AddReplace(element@name, {key:element@key, value:AkaMA_validstr(element@value), expiry:AkaMA_validstr(element@expiry)})
            next
            AkaMA_logger().AkaMA_print("========= Printing init key / value ===== ")
            'AkaMA_PrintAnyAA(3, m.mmBeaconMetric.initMetrics)
            AkaMA_logger().AkaMA_print("============End==============")
            
            'Populate key-value pairs for playStart metrics
            for each element in xml.statistics.playStart.dataMetrics.data  
                m.mmBeaconMetric.playStartMetrics.AddReplace(element@name, {key:element@key, value:AkaMA_validstr(element@value), expiry:AkaMA_validstr(element@expiry)})
            next
            AkaMA_logger().AkaMA_print("========= Printing Play start key / value ===== ")
            'print "========= Printing Play start key / value ===== "
            'AkaMA_PrintAnyAA(3, m.mmBeaconMetric.playStartMetrics)
           ' print "============End=============="
            AkaMA_logger().AkaMA_print("============End==============")

            'Populate key-value pairs for playing metrics
            for each element in xml.statistics.playing.dataMetrics.data
                m.mmBeaconMetric.playingMetrics.AddReplace(element@name, {key:element@key, value:AkaMA_validstr(element@value)})
            next
            AkaMA_logger().AkaMA_print("========= Printing Playing key / value ===== ")
            'AkaMA_PrintAnyAA(3, m.mmBeaconMetric.playingMetrics)
            AkaMA_logger().AkaMA_print("============End==============")

            'Populate key-value pairs for complete metrics
            for each element in xml.statistics.complete.dataMetrics.data
                m.mmBeaconMetric.playbackCompletedMetrics.AddReplace(element@name, {key:element@key, value:AkaMA_validstr(element@value)})
            next
            AkaMA_logger().AkaMA_print("========= Printing playback complete key / value ===== ")
            'AkaMA_PrintAnyAA(3, m.mmBeaconMetric.playbackCompletedMetrics)
            AkaMA_logger().AkaMA_print("============End==============")
            
            'Populate key-value pairs for error metrics
            for each element in xml.statistics.error.dataMetrics.data
                m.mmBeaconMetric.errorMetrics.AddReplace(element@name, {key:element@key, value:AkaMA_validstr(element@value)})
            next
            AkaMA_logger().AkaMA_print("========= Printing error key / value ===== ")
            'AkaMA_PrintAnyAA(3, m.mmBeaconMetric.errorMetrics)
            AkaMA_logger().AkaMA_print("============End==============")
            
            'Populate key-value pairs for visit metrics
            for each element in xml.statistics.visit.dataMetrics.data
                m.mmBeaconMetric.visitMetrics.AddReplace(element@name, {key:element@key, value:AkaMA_validstr(element@value)})
            next
            AkaMA_logger().AkaMA_print("========= Printing visit key / value ===== ")
            'AkaMA_PrintAnyAA(3, m.mmBeaconMetric.visitMetrics)
            AkaMA_logger().AkaMA_print("============End==============")    
            
            return AkaMAErrors().ERROR_CODES.AKAM_Success        
        end function        
}
return mmConfig
end function


'Function       :   customDimension
'Params         :   custDimenstionParams. initialization params which will initialize 
'                   custom dimenstions with key value pairs
'                   This should be key-value pairs
'Return         :   Returns newly created custome dimension 
'Description    :   creates and maintains key-value pairs of custome dimensions 
'
function customDimension(custDimensionParams)
return {
    customDimensions   :   custDimensionParams
}
end function
