Library "Roku_Ads.brs"

' **************************************************
' RAF Service
'   - Service for Roku Ad Framework
'
' Functions in service
'     playAds
'
' Usage
'     raf_service = RafService()
'     raf_service.playAds(video_info, ad_url)
' **************************************************
function RafService() as object
  this = {}
  this.raf = Roku_Ads()

  ' RAF configuration
  this.raf.setAdPrefs(true, 2)
  this.raf.setDebugOutput(true)
  this.raf.enableNielsenDAR(true)

  ' ********************************************
  ' Parameters:
  '     video_player_info - response from Zype player API
  '     url               - ad tag url
  ' ********************************************
  this.playAds = function(video_player_info, url = invalid) as boolean
    if url <> invalid and url <> "" then m.raf.setAdUrl(url)

    ' ***************************************************************************************
    '   Nielsen DAR configuration
    '
    '   Note: DO NOT delete this. Nielsen DAR is required for Roku if advertising
    ' ***************************************************************************************
    m.raf.setNielsenAppId("P2871BBFF-1A28-44AA-AF68-C7DE4B148C32") ' Use Roku's Nielsen app id. You can swap this out if you have your own
    m.raf.setNielsenProgramId(video_player_info.title)
    m.raf.setContentLength(video_player_info.duration)
    m.raf.setNielsenGenre("GV")

    ad = m.raf.getAds()
    ad_success = m.raf.showAds(ad)

    return ad_success
  end function

  return this
end function
