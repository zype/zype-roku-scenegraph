sub init()
  m.private = {}

  m.content_helpers = ContentHelpers()
  m.helpers = helpers()
  m.initializers = initializers()

  m.initializers.initChildren(m)
end sub

function onKeyEvent(key as string, press as boolean) as boolean
  ? ">>> InputKeyboard >>> onKeyEvent"
  result = false

  if press
    if key = "down"
      if m.helpers.focusedChild(m) = "Keyboard" then m.confirm_button.setFocus(true) : result = true
    else if key = "up"
      if m.helpers.focusedChild(m) = "ConfirmButton" then m.keyboard.setFocus(true) : result = true
    end if
  end if

  return result
end function

function onVisibleChange() as void
  if m.top.visible then m.keyboard.textEditBox.cursorPosition = len(m.top.value) : m.keyboard.setFocus(true)
end function

function onInputTypeChange() as void
  input_type = m.top.type

  if input_type = "Password" then m.keyboard.textEditBox.secureMode = true else m.keyboard.textEditBox.secureMode = false

  m.header.text = input_type
end function

function helpers() as object
  this = {}

  this.focusedChild = function(self) as string
    return self.top.focusedChild.id
  end function

  return this
end function

function initializers() as object
  this = {}

  this.initChildren = function(self) as void
    self.top.observeField("visible", "onVisibleChange")

    self.background = self.top.findNode("Background")
    self.background.color = self.global.theme.background_color

    self.header = self.top.findNode("Header")
    self.header.color = self.global.theme.primary_text_color

    self.keyboard = self.top.findNode("Keyboard")
    self.keyboard.keyColor = self.global.theme.primary_text_color
    self.keyboard.focusedKeyColor = self.global.brand_color
    self.keyboard.textEditBox.textColor = self.global.theme.primary_text_color

    self.confirm_button = self.top.findNode("ConfirmButton")
    self.confirm_button.color = self.global.theme.primary_text_color
    self.confirm_button.focusedColor = self.global.theme.background_color
    self.confirm_button.focusBitmapUri = self.global.theme.button_filledin_uri
    self.confirm_button.focusFootprintBitmapUri = self.global.theme.focus_grid_uri
    self.confirm_button.content = self.content_helpers.oneDimList2ContentNode([{title: "Continue"}], "ButtonNode")
  end function

  return this
end function
