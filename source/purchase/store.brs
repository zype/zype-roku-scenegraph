'///////////////////////////////////////////////
' Make Purchase
' For SVOD there are going to be 2 products as per the Subscription plans in Zype Admin Panel
' 1) Monthly Subscription 
' 2) Yearly Subscription

Function makePurchase(title, code, store, port, products) as void
    if(isValidProduct(code, products) = false)
        invalidProductDialog(title)
        return
    end if
    result = store.GetUserData()
    if (result = invalid)
        return
    end if
    order = [{
        code: code
        qty: 1        
    }]
    
    val = store.SetOrder(order)
    res = store.DoOrder()

    purchaseDetails = invalid
    error = {}
    while (true)
        msg = wait(0, port)
        if (type(msg) = "roChannelStoreEvent")
            if(msg.isRequestSucceeded())
                ' purchaseDetails can be used for any further processing of the transactional information returned from roku store.
                purchaseDetails = msg.GetResponse()
            else
                error.status = msg.GetStatus()
                error.statusMessage = msg.GetStatusMessage()
            end if
            exit while
        end if
    end while

    if (res = true)
        orderStatusDialog(true, title)
    else
        orderStatusDialog(false, title)
    end if
End Function

' /////////////////////////////////////
' Is Valid Product
' Check to see if the product code is available in the products catalog

Function isValidProduct(code, products)
    valid = false
    for each item in products
	    if (code = item.code)
	        valid = true
		    exit for
	    end if
	end for
    return valid
End Function

' The logic for the following two functions can be combined and made dynamic. To-Do

Function monthlySubscription(plans, index, store, port, productsCatalog)
    'id = lclScreen.content.id.tokenize(":")
    'makePurchase(lclScreen.content.title, "svod-monthly", store, port, productsCatalog)
    print "plans: "; plans[index - 1]
    ' 584ac20e70d7637d5da333de
    makePurchase(plans[index - 1].name, plans[index - 1]._id, store, port, productsCatalog)
End Function

Function yearlySubscription(plans, index, store, port, productsCatalog)
    'id = lclScreen.content.id.tokenize(":")
    print "plans: "; plans[index - 1]
    ' 584ac20e70d7637d5da333df
    makePurchase(plans[index - 1].name, plans[index - 1]._id, store, port, productsCatalog)
End Function