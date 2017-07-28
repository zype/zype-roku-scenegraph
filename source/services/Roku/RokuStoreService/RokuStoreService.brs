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

  return this
end function
