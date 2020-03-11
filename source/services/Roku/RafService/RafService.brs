Library "Roku_Ads.brs"

' **************************************************
' RAF Service
'   - Service for Roku Ad Framework
'
' Functions in service
'     replaceMacros
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
  'this.raf.enableNielsenDAR(true)
  this.raf.enableAdMeasurements(true)

  ' ********************************************
  ' Parameters:
  '     url - ad tag url
  ' ********************************************
  this.replaceMacros = function(url)
    url = strReplace(url, "[uuid]", "ROKU_ADS_TRACKING_ID")
    url = strReplace(url, "[lat]", "ROKU_ADS_LIMIT_TRACKING")
    url = strReplace(url, "[app_name]", getTitle(true))
    url = strReplace(url, "[app_bundle]", getApplicationID())
    url = strReplace(url, "[device_type]", "7")
    url = strReplace(url, "[device_make]", "Roku")
    url = strReplace(url, "[device_model]", "ROKU_ADS_DEVICE_MODEL")
    url = strReplace(url, "[device_ifa]", "ROKU_ADS_TRACKING_ID")
    url = strReplace(url, "[vpi]", "ROKU")
    url = strReplace(url, "[app_id]", "ROKU_ADS_APP_ID")

    return url
  end function

  ' ********************************************
  ' Parameters:
  '     video_player_info - response from Zype player API
  '     url               - ad tag url
  ' ********************************************
  this.playAds = function(video_player_info, url = invalid) as boolean
    if url <> invalid and url <> ""
      ad_url = m.replaceMacros(url)
      m.raf.setAdUrl(ad_url)
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

    print "===============RAF=================="
    print "===============video_player_info.title ==================> " video_player_info.title
    print "===============video_player_info.video_content_genre ==================> " video_player_info.video_content_genre
    print "===============video_player_info.video_id ==================> " video_player_info.video_id
    print "===============video_player_info.duration ==================> " video_player_info.duration

    m.raf.setContentGenre(video_player_info.video_content_genre)
    m.raf.setContentId(video_player_info.video_id)

    ads = m.raf.getAds()

    ' If no ads from ad tag, try again with Roku ads
    if ads.count() = 0 then m.raf.setAdUrl("") : ads = m.raf.GetAds()

    ad_success = m.raf.showAds(ads)

    return ad_success
  end function

  return this
end function
