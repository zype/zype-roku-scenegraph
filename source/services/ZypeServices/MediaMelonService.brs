
Function MediaMelonService() as Object
      this = {}
      this.IsMediaMelonInitialized = false

      ' this.MediaMelonTask = CreateObject("roSGNode", "MMTask")


      this.InitializeMediaMelonService = function (MMConfig, Custom, videoNode)
          if m.MediaMelonTask <> invalid Then
              m.MediaMelonTask.control = "stop"
              m.MediaMelonTask = invalid
          end if
          m.MediaMelonTask = CreateObject("roSGNode", "MMTask")
          m.MediaMelonTask.setField("video", videoNode)
          m.MediaMelonTask.setField("config", MMConfig)
          m.MediaMelonTask.setField("customTags", Custom)
      end function

      this.StartMediaMelonEvents = function ()
          m.MediaMelonTask.control = "RUN"
          m.IsMediaMelonInitialized = true
      end function

      return this
end function
