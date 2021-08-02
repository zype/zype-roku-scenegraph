Function LoadImaSdk()
    m.sdkTask = createObject("roSGNode", "ImaSdkTask")
    m.sdkTask.observeField("sdkLoaded", "onSdkLoaded")
    m.sdkTask.observeField("errors", "onSdkLoadedError")
    m.sdkTask.observeField("urlData", "urlLoadRequested")
    m.sdkTask.video = m.top.videoPlayer
End Function
  
Sub urlLoadRequested(message as Object)
    print "IMA Url Load Requested: " message
    data = message.getData()

    playStream(data.manifest)
End Sub

Sub playStream(url as Object)
    print "IMA Url loaded: " url
    m.top.videoPlayer.content.url = url
    m.top.videoPlayer.setFocus(true)
    m.top.videoPlayer.visible = true
    m.top.videoPlayer.control = "play"
    m.top.videoPlayer.EnableCookies()
End Sub

Sub onSdkLoaded(message as Object)
    print "IMA onSdkLoaded --- control: " message
End Sub

Sub onSdkLoadedError(message as Object)
    m.scene.callFunc("CreateDialog", m.scene, "Error", "There was an error loading the ad", ["Close"])
    print "IMA errors in the sdk loading process: " message
End Sub

Function StartPlayer(streamData)
    m.sdkTask.streamData = streamData
    ' Setting control to run starts the task thread.
    m.sdkTask.control = "RUN"
End Function