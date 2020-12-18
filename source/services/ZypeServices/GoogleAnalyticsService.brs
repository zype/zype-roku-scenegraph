
Function GoogleAnalyticsService() as Object
      this = {}

      this.SendGATrackEvent = function(parameter as dynamic, customParams as dynamic)
          trackEvent = CreateObject("roSGNode", "GATrackEventTask")

          trackEvent.eventParams = parameter
          trackEvent.customParams = customParams
          trackEvent.control = "RUN"
      end function

      return this
end function
