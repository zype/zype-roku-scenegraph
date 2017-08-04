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
    if url <> invalid and url <> ""
      url = RafService().ReplaceMacros(url)
      m.raf.setAdUrl(url)
    end if

    ' ***************************************************************************************
    '   Nielsen DAR configuration
    '
    '   Note: DO NOT delete this. Nielsen DAR is required for Roku if advertising
    ' ***************************************************************************************
    m.raf.setNielsenAppId("P2871BBFF-1A28-44AA-AF68-C7DE4B148C32") ' Use Roku's Nielsen app id. You can swap this out if you have your own
    m.raf.setNielsenProgramId(video_player_info.title)
    m.raf.setContentLength(video_player_info.duration)
    m.raf.setNielsenGenre("GV")

    ads = m.raf.getAds()

    ' If no ads from ad tag, try again with Roku ads
    if ads.count() = 0 then m.raf.setAdUrl("") : ads = m.raf.GetAds()

    ad_success = m.raf.showAds(ads)

    return ad_success
  end function

  ' ********************************************
  ' Parameters:
  '     url - ad tag url
  ' ********************************************
  this.ReplaceMacros = function(url)
    manifest = readManifest()
    
    url = strReplace(url, "[uuid]", "ROKU_ADS_TRACKING_ID")
    url = strReplace(url, "[app_name]", manifest.title)
    ' Replace app[bundle]
    ' Replace app[domain]
    url = strReplace(url, "[device_type]", "7")
    url = strReplace(url, "[device_make]", "Roku")
    url = strReplace(url, "[device_model]", "ROKU_ADS_DEVICE_MODEL")
    url = strReplace(url, "[device_ifa]", "ROKU_ADS_TRACKING_ID")
    url = strReplace(url, "[vpi]", "ROKU")
    url = strReplace(url, "[app_id]", "ROKU_ADS_APP_ID")
    
    print url
    return url
  end function

  return this
end function
