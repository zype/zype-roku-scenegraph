
' **************************************************
' Video Service
'   - Service for functions related to video playback
'
' Functions in service
'     
'
' Usage
'     video_service = VideoService()
'     video_service.PrepareAds()
' **************************************************

Function VideoService() as object
    this = {}
    this.PrepareAds = function(playerInfo, no_ads)
        ads = {
            preroll: invalid
            midroll: []
        }
        if playerInfo.scheduledAds.count() > 0 and no_ads = false
        for each ad in playerInfo.scheduledAds
            if ad.offset = 0
            ads.preroll = {
                url: ad.url,
                offset: ad.offset
            }
            else
            midrollAd = {
                url: ad.url,
                offset: ad.offset,
            }
            ads.midroll.push(midrollAd)
            end if
        end for
        end if
        return ads
    end function

    this.GetSubtitles = function(playerInfo)
        subtitleTracks = []

        for each subtitle in playerInfo.subtitles
            subtitleTracks.push({
                TrackName: subtitle.url,
                Language: subtitle.language
            })
        end for
        
        return subtitleTracks
    end function

    return this
End Function