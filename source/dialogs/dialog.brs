function CreateDialog(screen, title, message, buttons)
  screen.dialog = invalid

  dialog = createObject("roSGNode", "Dialog")
  dialog.title = title
  dialog.message = message
  dialog.optionsDialog = true
  dialog.buttons = buttons

  screen.dialog = dialog
end function
