'///////////////////////////////////////////////
' Order Status Dialog
Function orderStatusDialog(success as boolean, item as string) as void
    dialog = createObject("roSGNode", "Dialog")
    dialog.optionsDialog = true
    dialog.buttons = ["OK"]

    if success = true
      dialog.title = "Order Completed Successfully"
      dialog.message = "Your Purchase of '" + item + "' Completed Successfully"
    else
      dialog.title = "Order Failed"
      dialog.message = "Your Purchase of '" + item + "' Failed"
    end if

    m.scene.dialog = dialog
End Function

Function invalidProductDialog(title)
    dialog = createObject("roSGNode", "Dialog")
    dialog.optionsDialog = true
    dialog.buttons = ["OK"]

    dialog.title = "Invalid Product"
    dialog.message = "The product '" + title + "' is not available at the moment"

    m.scene.dialog = dialog
End Function
