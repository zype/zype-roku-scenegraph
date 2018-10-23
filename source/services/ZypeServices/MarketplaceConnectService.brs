' **************************************************
' Marketplace Connect Service
'   - Service for Zype Marketplace Connect
'
' Functions in service
'   getSubscriptionPlans
'
' Usage
'   marketplaceConnect = MarketplaceConnectService()
' **************************************************
Function MarketplaceConnectService() as object
  this = {}

  ' getSubscriptionPlans() 
  ' - filters array of Roku subscription products by ids from Zype plans
  ' - relies on GetPlans() in zype_api.brs
  ' 
  ' Parameters
  '   rokuPlans - array of Roku products
  '
  ' Return
  '   array of Roku subscription products that have a Zype subscription plan with matching Marketplace Connect ID
  this.getSubscriptionPlans = function(rokuPlans as object) as object
    filteredPlans = []

    zypePlans = GetPlans()
    for each rokuPlan in rokuPlans
      for each zypePlan in zypePlans
        ' TODO: Update to look for roku marketplace id when implemented on platform
        if zypePlan.marketplace_ids <> invalid and zypePlan.marketplace_ids.itunes <> invalid
          if zypePlan.marketplace_ids.itunes = rokuPlan.code
            rokuPlan.zypePlanId = zypePlan._id
            filteredPlans.push(rokuPlan)
            exit for ' exit zypePlans for loop
         end if
        end if
      end for
    end for

    return filteredPlans
  end function

  return this
End Function