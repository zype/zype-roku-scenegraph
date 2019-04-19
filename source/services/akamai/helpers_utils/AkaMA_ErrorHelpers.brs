' this file contians error codes which can be used 
' by the plugin in different functions


FUNCTION AkaMAErrors()
return {
    ERROR_CODES : {
      AKAM_Success                      : 0
      AKAM_Configuration_url_failed     : 1
      AKAM_Invalid_configuration_xml    : 2
      AKAM_xml_parsing_failed           : 3
      AKAM_beacon_request_failed        : 4
      AKAM_InvalidBeaconSequence        : 5
      AKAM_StateIsNotValid              : 6
      AKAM_Unknown                      : 7
    }
   }
END FUNCTION 