sub init()
  m.private = {

  }

  m.content_helpers = ContentHelpers()
  m.initializers = initializers()
  m.helpers = helpers()

  m.initializers.initChildren(m)
end sub

function OnKeyEvent(key as string, press as boolean) as boolean
    ? ">>> UniversalAuthSelection >>> OnKeyEvent"

    result = false

    return result
end function

function OnItemSelected() as void
  index = m.top.itemSelected
  m.top.itemSelectedRole = currentButtonRole(m, index)
  m.top.itemSelectedTarget = currentButtonTarget(m, index)
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
    self.u_auth_buttons.content.getChild(index).role
  end function

  this.currentButtonTarget = function(self, index) as string
    self.u_auth_buttons.content.getChild(index).target
  end function

  return this
end function

function initializers() as object
  this = {}

  this.initChildren = function(self) as void
    self.u_auth_buttons = self.top.findNode("UAuthMethods")
    btns = [
      { title: "Link Device", role: "transition", target: "DeviceLinking" },
      { title: "Sign in with email", role: "transition", target: "SignInScreen" }
    ]
    self.u_auth_buttons.content = m.content_helpers.oneDimList2ContentNode(btns, "ButtonNode")

    self.top.observeField("visible", "onVisibleChange")
  end function

  return this
end function
