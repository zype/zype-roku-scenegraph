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
  '   local_subscription_plan_ids  - array of Local Plans from config.json
  '
  ' Return
  '   array of Roku subscription products that have a Zype subscription plan with matching Marketplace Connect ID
  this.getSubscriptionPlans = function(rokuPlans as object, local_subscription_plan_ids as object) as object
    filteredPlans = []

    ' Get all zype plans'
    zypePlans = GetPlans()

    ' Filter zype plans by local config zype plan ids'
    zypeFilteredPlans = GetLocalFilteredZypePlans(zypePlans, local_subscription_plan_ids)

    for each rokuPlan in rokuPlans
      for each zypePlan in zypeFilteredPlans
        print "=====================> Roku Plan : " rokuPlan
        print "Zype Plan : " zypePlan
        print "Zype Plan marketplace_ids : " zypePlan.marketplace_ids
        if zypePlan.marketplace_ids <> invalid and zypePlan.marketplace_ids.roku <> invalid
          print "Zype Plan roku : " zypePlan.marketplace_ids.roku
          if zypePlan.marketplace_ids.roku = rokuPlan.code
            rokuPlan.zypePlanId = zypePlan._id
            filteredPlans.push(rokuPlan)
            exit for ' exit zypePlans for loop
         end if
        end if
      end for
    end for

    print "Final Plans for Display =============================> " filteredPlans
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
    marketplaceConnectEndpoint = GetApiConfigs().marketplace_connect_endpoint
    verifiedSubscription = false

    response = MakePostRequestWithStatus(marketplaceConnectEndpoint, marketplaceParams)

    print "verifyMarketplaceSubscription : response--------------------> " response
    if response <> invalid
        if response.status <> invalid
          if response.status = 200
            return true
          else
            return false
          end if
        end if
    end if

    return false
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

function GetLocalFilteredZypePlans(zypePlans as object, localPlans as object)
    localFilteredPlans = []

    for each zypePlan in zypePlans
      for each localPlan in localPlans
          'print "zypePlan._id : " zypePlan._id
          if localPlan = zypePlan._id
            'print "localPlan ===> " localPlan
            localFilteredPlans.push(zypePlan)
            exit for ' exit localPlans for loop
         end if
      end for
    end for

    'print "localFilteredPlans =========FINAL Zype Plans====================> " localFilteredPlans
    return localFilteredPlans
end function
