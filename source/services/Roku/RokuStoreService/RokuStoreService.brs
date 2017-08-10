'****************************************************
' RokuStoreService
'   - Initialize with store object and associated message port
'
' Dependencies
'     source/services/Roku/RokuStoreService/RokuStoreServiceHelpers.brs
'****************************************************
function RokuStoreService(store, message_port) as object
  this = {}
  this.store = store
  this.port = message_port
  this.helpers = RokuStoreServiceHelpers()

  ' Get all channel IAP items from store
  this.getCatalog = function() as object
    m.store.GetCatalog()
    return m.helpers.getStoreResponse(m.port)
  end function

  this.getNativeSubscriptionPlans = function() as object
    catalog = m.getCatalog()
    return m.helpers.filterItems(catalog, ["MonthlySub", "YearlySub"])
  end function

  this.getConsumables = function() as object
    catalog = m.getCatalog()
    return m.helpers.filterItems(catalog, ["Consumable"])
  end function

  this.getNonconsumables = function() as object
    catalog = m.getCatalog()
    return m.helpers.filterItems(catalog, ["NonConsumable"])
  end function

  ' Get all IAPs user has purchased
  this.getPurchases = function() as object
    m.store.GetPurchases()
    return m.helpers.getStoreResponse(m.port)
  end function

  this.getUserNativeSubscriptionPurchases = function() as object
    native_subscriptions = m.helpers.filterItems(m.getPurchases(), ["MonthlySub", "YearlySub"])
    valid_native_subscriptions = []

    for each subscription in native_subscriptions
      if m.helpers.isExpired(subscription.expirationDate) = false then valid_native_subscriptions.push(subscription)
    end for

    return valid_native_subscriptions
  end function

  ' Accepts and purchases array of IAP items
  '
  ' order = [ { code: iap_code, qty: quantity }, ...  ]
  this.makePurchase = function(order) as object
    m.store.SetOrder(order)
    m.store.DoOrder()

    order_response = m.helpers.getStoreResponse(m.port)

    if order_response <> invalid then return {receipt: invalid, success: false}

    ' If order failed, roku store returns 0, else roku store returns roArray of receipt
    success = (type(order_response) <> "Integer" and type(order_response) <> "roInt")

    if success then return { receipt: order_response[0], success: true} else return {receipt: invalid, success: false}
  end function

  this.getRecentPurchase = function() as object
    purchases = m.getPurchases()

    if purchases.count() = 0 then return invalid

    recent_purchase = purchases[0]

    for each purchase in purchases
      purchase_dt = CreateObject("roDateTime")
      purchase_dt.FromISO8601String(purchase.purchaseDate)

      recent_dt = CreateObject("roDateTime")
      recent_dt.FromISO8601String(recent_purchase.purchaseDate)

      ' Found more recent purchase
      if purchase_dt.asSeconds() > recent_dt.asSeconds() then recent_purchase = purchase
    end for

    return recent_purchase
  end function

  return this
end function
