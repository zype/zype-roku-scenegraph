' **************************************************
' Marketplace Connect Service
'   - Service for Zype Marketplace Connect
'
' Dependencies
'   - source/zype_api.brs
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

  ' verifyMarketplaceSubscription()
  ' - calls Zype Marketplace Connect to verify native subscription
  '
  ' Parameters
  '   marketplaceParams - associative array of parameters (access token, consumer id, plan id, transaction id, app id, site id)
  '
  ' Return
  '   Boolean for Marketplace Connect verification
  this.verifyMarketplaceSubscription = function(marketplaceParams = {} as object) as boolean
    marketplaceConnectEndpoint = GetApiConfigs().marketplace_connect_endpoint + "transactions"
    verifiedSubscription = false

    response = MakePostRequestWithStatus(marketplaceConnectEndpoint, marketplaceParams)
    if response <> invalid

    end if

    return true ' hardcoded for now
  end function

  ' verifyMarketplacePurchase()
  ' - calls Zype Marketplace Connect to verify native purchase (consumable)
  '
  ' Parameters
  '   marketplaceParams - associative array of parameters (access token, consumer id, video id, transaction id, app id, site id)
  '
  ' Return
  '   Boolean for Marketplace Connect verification
  this.verifyMarketplacePurchase = function(marketplaceParams = {} as object) as boolean
    marketplaceConnectEndpoint = GetApiConfigs().marketplace_connect_endpoint + "transactions"
    verifiedPurchase = false

    response = MakePostRequestWithStatus(marketplaceConnectEndpoint, marketplaceParams)
    if response <> invalid

      if response.status <> invalid
        if response.status = 200
          return true
        else
          return false
        end if
      end if
    end if

    return true ' hardcoded for now
  end function

  return this
End Function