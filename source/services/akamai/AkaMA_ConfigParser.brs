' ConfigParser - utility functions to parse plugin configuration 
' file

'******************************************************
' Returns plugin configuration object
' This holds parsed configuration xml
'
'******************************************************
FUNCTION getPluginConfig() as object
    configObject = {
        pluginConfig    :   pluginConfigObject
        }
    return configObject
END FUNCTION

'******************************************************
' Holds different components of configuration xml
' as an object
'******************************************************
FUNCTION pluginConfigObject () as object
    configComponents = {
        configCommon    :   configCommonComponent
        configInit      :   configInitComponent
        configPlayStart :   configPlayStartComponent
        configPlaying   :   configPlayingComponent
        configComplete  :   configCompleteComponent
        configVisit     :   configVisitComponent
        configHeartBeat :   configHeartBeatComponent
        configError     :   configErrorComponent
    }
    return configComponents
END FUNCTION

FUNCTION configCommonComponent () as void
    commonComponent = {
        setCommonComponent  :   function(val):m.commonArray=val:end function
        getCommonComponent  :   function():return m.commonArray:end function
        commonArray : CreateObject("roAssociativeArray")
    }
END FUNCTION

FUNCTION configInitComponent () as void
    initComponent = {
        setInitComponent  :   function(val):m.initArray=val:end function
        getInitComponent  :   function():return m.initArray:end function
        initArray : CreateObject("roAssociativeArray")
    }
END FUNCTION

FUNCTION configPlayStartComponent () as void
    playStartComponent = {
        setPlayStartComponent  :   function(val):m.playStartArray=val:end function
        getPlayStartComponent  :   function():return m.playStartArray:end function
        playStartArray : CreateObject("roAssociativeArray")
    }
END FUNCTION


FUNCTION configPlayingComponent () as void
    playingComponent = {
        setplayingComponent  :   function(val):m.playingArray=val:end function
        getplayingComponent  :   function():return m.playingArray:end function
        playingArray : CreateObject("roAssociativeArray")
    }
END FUNCTION


FUNCTION configCompleteComponent () as void
    completeComponent = {
        setCompleteComponent  :   function(val):m.completeArray=val:end function
        getCompleteComponent  :   function():return m.completeArray:end function
        completeArray : CreateObject("roAssociativeArray")
    }
END FUNCTION


FUNCTION configVisitComponent () as void
    visitComponent = {
        setVisitComponent  :   function(val):m.visitArray=val:end function
        getVisitComponent  :   function():return m.visitArray:end function
        visitArray : CreateObject("roAssociativeArray")
    }
END FUNCTION


FUNCTION configHeartBeatComponent () as void
    heartBeatComponent = {
        setHeartBeatComponent  :   function(val):m.heartBeatArray=val:end function
        getHeartBeatComponent  :   function():return m.heartBeatArray:end function
        heartBeatArray : CreateObject("roAssociativeArray")
    }
END FUNCTION


FUNCTION configErrorComponent () as void
    errorComponent = {
        setErrorComponent  :   function(val):m.errorArray=val:end function
        getErrorComponent  :   function():return m.errorArray:end function
        errorArray : CreateObject("roAssociativeArray")
    }
END FUNCTION
