sub init()
  m.private = {}

  m.content_helpers = ContentHelpers()
  m.initializers = initializers()
  m.helpers = helpers()

  m.initializers.initChildren(m)
end sub

function onKeyEvent(key as string, press as boolean) as boolean
  ? ">>> " + m.helpers.id(m) + " >>> onKeyEvent"
  result = false

  if press
    if key = "down"
      if m.helpers.focusedChild(m) = "Inputs" then m.submit_button.setFocus(true) : result = true
    else if key = "up"
      if m.helpers.focusedChild(m) = "SubmitButton" then m.inputs.setFocus(true) : result = true
    end if
  end if

  return result
end function

function onVisibleChange() as void
  if m.top.visible = true then m.inputs.setFocus(true)
end function

function setHeader() as void
  m.header_label.text = m.top.header
end function

function helpers() as object
  this = {}

  this.id = function(self) as string
    return self.top.id
  end function

  this.focusedChild = function(self) as string
    return self.top.focusedChild.id
  end function

  return this
end function

function initializers() as object
  this = {}

  this.initChildren = function(self) as void
    self.top.observeField("visible", "onVisibleChange")

    self.header_label = self.top.findNode("HeaderLabel")
    self.header_label.color = self.global.theme.primary_text_color

    inputs_content = [
      [ { title: "Email", name: "email", value: "" } ],
      [ { title: "Password", name: "password", value: "" } ]
    ]

    self.inputs = self.top.findNode("Inputs")
    self.inputs.focusBitmapUri = self.global.theme.focus_grid_uri
    self.inputs.content = self.content_helpers.twoDimList2ContentNode(inputs_content, "InputNode")

    self.submit_button = self.top.findNode("SubmitButton")
    self.submit_button.focusBitmapUri = self.global.theme.button_focus_uri
    self.submit_button.color = self.global.theme.primary_text_color
    self.submit_button.content = self.content_helpers.oneDimList2ContentNode([{title: "Continue"}], "ButtonNode")
  end function

  return this
end function
