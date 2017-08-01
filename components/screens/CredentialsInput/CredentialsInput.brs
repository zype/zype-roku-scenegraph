sub init()
  m.private = {}

  m.content_helpers = ContentHelpers()
  m.helpers = helpers()
  m.initializers = initializers()

  m.initializers.initChildren(m)
end sub

function initializers() as object
  this = {}

  this.initChildren = function(self) as void
    self.header_label = self.top.findNode("HeaderLabel")
    self.header_label.color = self.global.theme.primary_text_color

    inputs_content = [
      [ { title: "email", name: "email", value: "" } ],
      [ { title: "password", name: "password", value: "" } ]
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
