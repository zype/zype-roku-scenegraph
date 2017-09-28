' **************************************************
' Bifrost Service
'   - Service for connecting with Zype Bifrost for validating native subscriptions
'
' Dependencies
'     source/zype_api.brs
'
' Functions in service
'     hasValidSubscription
'
' Usage
'     bifrost_service = BiFrostService()
'     bifrost_service.hasValidSubscription(my_users_info, native_sub_purchases)
' **************************************************
function BiFrostService() as object
  this = {}
  this.app = m.app
  this.global = m.global

  ' validate native subscription purchases using Zype BiFrost API
  this.hasValidSubscription = function(user_info as object, native_subs as object) as boolean
    for each n_sub in native_subs
      third_party_id = GetPlan(n_sub.code, {}).third_party_id

      bifrost_params = {
        app_key: GetApiConfigs().app_key,
        consumer_id: user_info._id,
        third_party_id: third_party_id,
        roku_api_key: GetApiConfigs().roku_api_key,
        transaction_id: UCase(n_sub.purchaseId),
        device_type: "roku"
      }

      n_sub_status = GetNativeSubscriptionStatus(bifrost_params)

      ' Stop looking. BiFrost creates as well as validates subscriptions
      if n_sub_status <> invalid and n_sub_status.is_valid then return true
    end for

    return false
  end function

  return this
end function
