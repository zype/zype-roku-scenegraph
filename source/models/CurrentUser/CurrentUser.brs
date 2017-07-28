'****************************************************
' CurrentUser model
'
' Dependencies
'     source/oauth.brs
'     source/models/CurrentUser/Helpers/CurrentUserHelpers.brs
'****************************************************
function CurrentUser() as object
  this = {}
  this.helpers = CurrentUserHelpers()

  this.native_subscriptions = []

  ' Call after saving current user model
  this.init = function(params) as void
    if params.native_subscriptions <> invalid then this.native_subscriptions = params.native_subscriptions
  end function

  ' Get OAuth info from registry/local storage
  this.getOAuth = function() as object
    return RegReadAccessToken()
  end function

  ' Get user info from Zype platform using access token
  this.getInfo = function() as object
    auth = m.getOAuth()
    consumer = {linked: false}

    if auth <> invalid and auth.access_token <> invalid
      consumer = m.helpers.consumerFromAccessToken(auth.access_token)
      if m.helpers.linkedUser() <> invalid then consumer.linked = true else consumer.linked = false
    end if

    return consumer
  end function

  this.addNativeSubscription = function(plan) as void
    m.native_subscriptions.push(plan)
  end function

  this.hasNativeSubscription = function() as boolean
    if m.native_subscriptions.count() > 0 then return true else return false
  end function

  return this
end function
