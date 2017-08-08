function AuthStateService() as object
  this = {}
  this.global = m.global

  this.incrementNativeSubCount = function() as void
    global_auth = m.global.auth
    global_auth.nativeSubCount = global_auth.nativeSubCount + 1

    m.global.setField("auth", global_auth)
  end function

  this.updateAuthWithUserInfo = function(user_info) as void
    global_auth = m.global.auth
    global_auth.isLinked = user_info.linked

    if user_info._id <> invalid then global_auth.isLoggedIn = true else global_auth.isLoggedIn = false
    if user_info.subscription_count <> invalid then global_auth.universalSubCount = user_info.subscription_count else global_auth.universalSubCount = 0
    if user_info.email <> invalid then global_auth.email = user_info.email else global_auth.email = ""

    m.global.setField("auth", global_auth)
  end function

  return this
end function
