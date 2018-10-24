' **************************************************
' Auth State Service
'   - Service for managing authentication state in app
'   - No dependencies
'
' Functions in service
'     incrementNativeSubCount
'     updateAuthWithUserInfo
'     setCurrentNativePlan
'
' Usage
'     akamai_service = AkamaiService()
' **************************************************
function AuthStateService() as object
  this = {}
  this.global = m.global

  ' Called after user purchases native subscription
  this.incrementNativeSubCount = function() as void
    global_auth = m.global.auth
    global_auth.nativeSubCount = global_auth.nativeSubCount + 1

    m.global.setField("auth", global_auth)
  end function

  ' Used to update m.global.auth variables related to universal authentication (oauth/device linking)
  '   - Updates: isLinked, isLoggedIn, universalSubCount, email
  '   - isLinked            => Did user authenticate with device linking
  '   - isLoggedIn          => Did user sign in or link device
  '   - universalSubCount   => Number of subscriptions linked to user via Zype platform
  '   - email               => Email linked to user on Zype platform. No correlation to user's Roku email
  '   - entitlements        => What videos the user is entitled to
  this.updateAuthWithUserInfo = function(user_info) as void
    global_auth = m.global.auth
    global_auth.isLinked = user_info.linked

    if user_info._id <> invalid and user_info._id <> "" then global_auth.isLoggedIn = true else global_auth.isLoggedIn = false
    if user_info.subscription_count <> invalid then global_auth.universalSubCount = user_info.subscription_count else global_auth.universalSubCount = 0
    if user_info.email <> invalid then global_auth.email = user_info.email else global_auth.email = ""

    if user_info.entitlements <> invalid and user_info.entitlements <> {}
      global_auth.entitlements = user_info.entitlements
    else
      entitlements = {}
      oauth = RegReadAccessToken()

      if oauth <> invalid and oauth.access_token <> invalid
        videoEntitlements = GetEntitledVideos({
          access_token: oauth.access_token,
          per_page: 500,
          page: 1
          sort: "created_at",
          order: "desc"
        })

        if videoEntitlements <> invalid
          for each entitlement in videoEntitlements
            videoId = entitlement["video_id"]
            entitlements[videoId] = videoId
          end for
        end if
      end if

      global_auth.entitlements = entitlements
    end if

    m.global.setField("auth", global_auth)
  end function

  this.setCurrentNativePlan = function(plan as object) as void
    m.global.setField("nsvod", {
      currentPlan: plan
    })
  end function

  return this
end function
