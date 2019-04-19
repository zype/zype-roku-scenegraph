sub init()
  m.private = {

  }

  m.content_helpers = ContentHelpers()
  m.initializers = initializers()
  m.helpers = helpers()

  m.initializers.initChildren(m)
end sub

function onItemSelected() as void
  index = m.top.itemSelected
  m.top.itemSelectedRole = m.helpers.currentButtonRole(m, index)
  m.top.itemSelectedTarget = m.helpers.currentButtonTarget(m, index)
end function

function onVisibleChange() as void
    if m.top.visible = true
      m.u_auth_buttons.setFocus(true)
    end if
end function

function helpers() as object
  this = {}

  this.focusedChild = function(self) as string
    return self.top.focusedChild.id
  end function

  this.currentButtonRole = function(self, index) as string
    return self.u_auth_buttons.content.getChild(index).role
  end function

  this.currentButtonTarget = function(self, index) as string
    return self.u_auth_buttons.content.getChild(index).target
  end function

  return this
end function

function initializers() as object
  this = {}

  this.initChildren = function(self) as void
    self.background = self.top.findNode("Background")
    self.background.color = self.global.theme.background_color

    self.header = self.top.findNode("Header")
    self.header.color = self.global.theme.primary_text_color

    self.u_auth_buttons = self.top.findNode("UAuthMethods")
    self.u_auth_buttons.color = self.global.theme.primary_text_color
    self.u_auth_buttons.focusedColor = self.global.theme.primary_text_color
    self.u_auth_buttons.focusBitmapUri = self.global.theme.focus_grid_uri
    btns = [
      { title: self.global.labels.sign_in_transition_button, role: "transition", target: "SignInScreen" },
      { title: self.global.labels.link_device_transition_button, role: "transition", target: "DeviceLinking" }
    ]
    self.u_auth_buttons.content = self.content_helpers.oneDimList2ContentNode(btns, "ButtonNode")

    self.top.observeField("visible", "onVisibleChange")
  end function

  return this
end function
