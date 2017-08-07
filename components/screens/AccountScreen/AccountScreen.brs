sub init()
  m.private = {}

  m.content_helpers = ContentHelpers()
  m.helpers = helpers()
  m.initializers = initializers()

  m.initializers.initChildren(m)
end sub

function onVisibleChange() as void
  if m.top.visible
    if m.global.auth.isLoggedIn
      m.header.text = "Signed in as: " + m.global.auth.userEmail

      btn = [ { title: "Sign out", role: "signout", target: "" } ]
      m.button.content = m.content_helpers.oneDimList2ContentNode(btn, "ButtonNode")
      m.button.setFocus(true)
    else
      m.header.text = "Sign In To Your Account"

      btn = [ { title: "Sign in", role: "transition", target: "UniversalAuthSelection" } ]
      m.button.content = m.content_helpers.oneDimList2ContentNode(btn, "ButtonNode")
      m.button.setFocus(true)
    end if
  end if
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

    self.button = self.top.findNode("Button")
    self.button.color = self.global.theme.primary_text_color
    self.button.focusedColor = self.global.theme.background_color
    self.button.focusBitmapUri = self.global.theme.button_filledin_uri
    self.button.focusFootprintBitmapUri = self.global.theme.focus_grid_uri

    self.header = self.top.findNode("Header")
    self.header.color = self.global.theme.primary_text_color
  end function

  return this
end function
