' Dependencies
'     - source/zype_api.brs
function BiFrostService() as object
  this = {}
  this.app = m.app
  this.global = m.global

  ' get array of native subscription purchases and validate using Zype BiFrost API
  this.validSubscriptions = function(user_info as object, native_subs as object) as object
    valid_subs = []

    for each n_sub in native_subs
      bifrost_params = {
        consumer_id: user_info._id,
        site_id: GetApiConfigs().zype_api_key,
        subscription_plan_id: n_sub.code,
        roku_api_key: GetApiConfigs().roku_api_key,
        transaction_id: n_sub.purchaseId,
        device_type: "roku"
      }

      n_sub_status = GetNativeSubscriptionStatus(bifrost_params)

      if n_sub_status <> invalid and n_sub_status.is_valid then valid_subs.push(n_sub)
    end for

    return valid_subs
  end function

  return this
end function
