' This file will hold for storing data into "Registry".
' It provides methods for deleting, accessing and updating
' into the "Registry".

'Function       :   AkaMA_createStorageManager
'Params         :   None
'Return         :   Returns newly created Storage Manager
'Description    :   Provides a set of methods to access and modify the "Registry".
'
function AkaMA_createStorageManager()
storageManager = {

    'Function       :   lastAccessTime
    'Params         :   fieldName The field to be queried in the Registry.
    'Return         :   The time at which the field was last updated.
    'Description    :   Checks Registry to find out the last time the field was updated.
    'Warn           :   Will return 0 if data is not found.
    lastAccessTime: function(fieldName as String)  as Integer
        AkaMA_logger().AkaMA_print("========= lastAccessTime ===== ")
        lastUsedTime = 0
        registrySection = CreateObject("roRegistrySection", "UniqueViewers")
        if registrySection.Exists(fieldName)
            keyInformation = registrySection.Read(fieldName)
            regularExpression = CreateObject ("roRegex", "^.*accessTime:(.*?),", "i")
            matchingObjects = regularExpression.Match (keyInformation)
            if matchingObjects.Count() > 0
                accessTime = matchingObjects[1]
                lastUsedTime = accessTime.ToInt()
            endif
        endif
        return lastUsedTime
    end function

    'Function       :   deleteExpiredData
    'Params         :   None
    'Return         :   None
    'Description    :   Deletes any data that has stayed beyond it's expiry date.
    'Warn           :   If your data is missing. Check if this method was called.
    deleteExpiredData: function() as Void
        AkaMA_logger().AkaMA_print("========= deleteExpiredData ===== ")
        time = CreateObject("roDateTime")
        currentTime = time.AsSeconds()
        registrySection = CreateObject("roRegistrySection", "UniqueViewers")
        keyList = registrySection.GetKeyList()
        regularExpression = CreateObject ("roRegex", "^.*expiryTime:(.*?)$", "i")
 
        for each key in keyList
            keyInformation = registrySection.Read(key)
            matchingObjects = regularExpression.Match (keyInformation)
            if matchingObjects.Count() > 0
                expiryTime = matchingObjects[1]
                expiryTimeInt = expiryTime.ToInt()
                if (expiryTimeInt < currentTime)
                    registrySection.Delete(key)
                endif
            endif  
        next
    end function


    'Function       :   addOrUpdate
    'Params         :   fieldName The field to be added to the Registry.
    'Params         :   currentTime Current system time in seconds.
    'Params         :   expiryTime Future time on which the entry has to be deleted. (in seconds)
    'Return         :   None
    'Description    :   Adds/updates a new entry to the localStorage.
    'Warn           :   key has to be unique. If there is a previous entry with the  same name, it will be updated
    '                   with the new "currentTime" and "expiryTime".
    addOrUpdate: function(fieldName as String, currentTime as Integer, expiryTime as Integer)
        AkaMA_logger().AkaMA_print("========= addOrUpdate ===== ")
        tempTime% = currentTime
        registrySection = CreateObject("roRegistrySection", "UniqueViewers")
        if currentTime > 0 and expiryTime > 0
            expiringData = "accessTime:" + StrI(tempTime%).Trim() + ", expiryTime:" + StrI(expiryTime)
            opStatus = registrySection.Write(fieldName, expiringData)
            registrySection.Flush()
        endif
    end function
}

return storageManager
end function