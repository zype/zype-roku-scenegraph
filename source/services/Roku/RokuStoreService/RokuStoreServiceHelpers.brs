'****************************************************
' RokuStoreServiceHelpers
'   - helpers for RokuStoreService
'
' Dependencies
'     none for now
'****************************************************
function RokuStoreServiceHelpers() as object
  this = {}

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

  this.filterCatalog = function(catalog as object, product_types as object) as object
    filtered_catalog = []

    for each item in catalog
      for each product_type in product_types
        if item.productType = product_type then filtered_catalog.push(item)
      end for
    end for

    return filtered_catalog
  end function

  return this
end function
