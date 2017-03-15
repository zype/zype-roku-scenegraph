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
    
    ' dialog = CreateObject("roMessageDialog")
    ' port = CreateObject("roMessagePort")
    ' dialog.SetMessagePort(port)
    ' if (success = true)
    '     dialog.SetTitle("Order Completed Successfully")
    '     str = "Your Purchase of '" + item + "' Completed Successfully"
    ' else
    '     dialog.SetTitle("Order Failed")
    '     str = "Your Purchase of '" + item + "' Failed"
    ' end if
    '
    ' dialog.SetText(str)
    ' dialog.AddButton(1, "OK")
    ' dialog.EnableBackButton(true)
    ' dialog.Show()
    '
    ' while true
    '     dlgMsg = wait(0, dialog.GetMessagePort())
    '     If type(dlgMsg) = "roMessageDialogEvent"
    '         if dlgMsg.isButtonPressed()
    '             if dlgMsg.GetIndex() = 1
    '                 'RunUserInterface()
    '                 exit while
    '             end if
    '         else if dlgMsg.isScreenClosed()
    '             'RunUserInterface()
    '             exit while
    '         end if
    '     end if
    ' end while

End Function

Function invalidProductDialog(title)
    dialog = CreateObject("roMessageDialog")
    port = CreateObject("roMessagePort")
    dialog.SetMessagePort(port)
    dialog.SetTitle("Invalid Product")
    str = "The product '" + title + "' is not available at the moment"

    dialog.SetText(str)
    dialog.AddButton(1, "OK")
    dialog.EnableBackButton(true)
    dialog.Show()

    while true
        dlgMsg = wait(0, dialog.GetMessagePort())
        If type(dlgMsg) = "roMessageDialogEvent"
            if dlgMsg.isButtonPressed()
                if dlgMsg.GetIndex() = 1
                    exit while
                end if
            else if dlgMsg.isScreenClosed()
                exit while
            end if
        end if
    end while
End Function
