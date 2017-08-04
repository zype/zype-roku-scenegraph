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
    return m.helpers.filterCatalog(catalog, ["MonthlySub", "YearlySub"])
  end function

  this.getConsumables = function() as object
    catalog = m.getCatalog()
    return m.helpers.filterCatalog(catalog, ["Consumable"])
  end function

  this.getNonconsumables = function() as object
    catalog = m.getCatalog()
    return m.helpers.filterCatalog(catalog, ["NonConsumable"])
  end function

  ' Get all IAPs user has purchased
  this.getPurchases = function() as object
    m.store.GetPurchases()
    return m.helpers.getStoreResponse(m.port)
  end function

  ' Accepts and purchases array of IAP items
  '
  ' order = [ { code: iap_code, qty: quantity }, ...  ]
  this.makePurchase = function(order) as boolean
    m.store.SetOrder(order)
    m.store.DoOrder()

    order = m.helpers.getStoreResponse(m.port)
    return order
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
