' Dependencies
'   - source/zype_api.brs
function ZypeSubscriptionService() as object
  this = {}

  ' Takes a native subscription object and tries to create corresponding subscription on Zype platform
  '   - Returns true/false on universal subscription creation status
  this.createUniversalFromNative = function(user_info as object, native_sub as object) as boolean
    subscription_params = {
      "subscription[consumer_id]": user_info._id,
      "subscription[plan_id]": native_sub.code,
      "subscription[third_party_id]": "roku"
    }

    create_sub_response = CreateSubscription(subscription_params)

    if create_sub_response <> invalid then return true else return false
  end function

  return this
end function
