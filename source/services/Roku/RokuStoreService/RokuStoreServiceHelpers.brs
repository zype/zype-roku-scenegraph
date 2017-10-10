'****************************************************
' RokuStoreServiceHelpers
'   - helpers for RokuStoreService
'
' Dependencies
'     none for now
'****************************************************
function RokuStoreServiceHelpers() as object
  this = {}

  ' Accepts a port and listens for store events to be broadcasted
  '   Returns store response or invalid
  this.getStoreResponse = function(port) as object
    while true
      msg = wait(0, port)
      store_responded = (type(msg) = "roChannelStoreEvent")

      if store_responded
        ' Success
        if msg.isRequestSucceeded()
          return msg.getResponse()


        ' Failure
        else if msg.isRequestFailed()
          print "***** Failure: " + msg.GetStatusMessage() + " Status Code: " + stri(msg.GetStatus()) + " *****"
          return invalid
        end if

        exit while
      end if ' end store_responded

    end while
  end function

  ' Accepts array of roku store items and array of product types to filter by
  this.filterItemsByType = function(items as object, product_types as object) as object
    filtered_items = []

    for each item in items
      for each product_type in product_types
        if item.productType = product_type then filtered_items.push(item)
      end for
    end for

    return filtered_items
  end function

  ' Accepts array of roku store items and array of product types to filter by
  this.filterItemsByCode = function(items as object, code as string) as object
    filtered_items = []

    for each item in items
      if item.code = code then filtered_items.push(item)
    end for

    return filtered_items
  end function

  ' Accepts Iso 8601 date string and checks if expired
  this.isExpired = function(date_string as string) as boolean
    current_date = CreateObject("roDateTime")
    current_date_as_seconds = current_date.asSeconds()

    date = CreateObject("roDateTime")
    date.FromISO8601String(date_string)
    date_as_seconds = date.asSeconds()

    return current_date_as_seconds > date_as_seconds
  end function

  this.latestExpirationPurchase = function(purchases as object) as object
    if purchases.count() = 0 then return {}

    latest_purchase = purchases[0]

    for each item in purchases
      datetime1 = CreateObject("roDateTime")
      datetime1.FromISO8601String(latest_purchase.expirationDate)
      latest_item_date_as_secs = datetime1.asSeconds()

      datetime2 = CreateObject("roDateTime")
      datetime2.FromISO8601String(item.expirationDate)
      current_item_date_as_secs = datetime2.asSeconds()

      if current_item_date_as_secs > latest_item_date_as_secs then latest_purchase = item
    end for

    return latest_purchase
  end function

  return this
end function
