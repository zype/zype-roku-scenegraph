Function init()
	m.top.functionName = "DownloadImageAndSave"
End Function

Function DownloadImageAndSave()
	imageUrl = m.top.imageUrl
	newTempPath = m.top.newTempPath
	newCachePath = m.top.newCachePath

	' print "Downloading imageUrl : " imageUrl
	' print "Downloading newTempPath : " newTempPath
	' print "Downloading newCachePath : " newCachePath

	http = CreateObject("roUrlTransfer")
	port = CreateObject("roMessagePort")

	http.AddHeader("X-Roku-Reserved-Dev-Id", "")
	http.AddHeader("Connection", "Keep-Alive")

	http.EnableEncodings(true)
	http.InitClientCertificates()
	http.SetCertificatesFile("common:/certs/ca-bundle.crt")

  finalUrl = imageUrl.EncodeUri()

  http.SetUrl(finalUrl)
	http.SetPort(port)
	http.RetainBodyOnError(true)

	started = http.AsyncGetToFile(newTempPath)

	If (started)
		While (true)
			msg = wait(0, port)
			If (type(msg) = "roUrlEvent")
				code = msg.GetResponseCode()
				dataString = msg.GetString()
				If (code = 200)
						if (newCachePath <> invalid AND newCachePath <> "")
								' Copy file in cache
								copyfile(newTempPath,newCachePath)
						end if
						m.top.bAPIStatus = "Success"
				Else
					m.top.bAPIStatus = "APIFailed"
				End If
			Else If (event = invalid)
				http.AsyncCancel()
			End If
		End While
	else
		m.top.bAPIStatus = "APIFailed"
	End If
End Function
