' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********
Function init()
	m.top.functionName = "callAPI"
End Function

Function callAPI()
  	print "callAPI--- for " m.top.idVal
		result = GetPlaylistVideos(m.top.idVal, {"per_page": m.top.perPage})
		m.top.videoResult = result
End Function
