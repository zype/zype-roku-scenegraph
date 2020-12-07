sub init()
  m.private = {}

  m.content_helpers = ContentHelpers()
  m.helpers = helpers()
  m.initializers = initializers()

  m.initializers.initChildren(m)
end sub

function onItemSelected() as void
  index = m.top.itemSelected
  m.top.itemSelectedRole = m.helpers.currentButtonRole(m, index)
  m.top.itemSelectedTarget = m.helpers.currentButtonTarget(m, index)
end function

function onVisibleChange() as void
  if m.top.visible
    resetTextCallback()
    m.button.setFocus(true)
  end if
end function

sub OnFocusedChild()
    if (m.top.IsInFocusChain() and m.top.hasFocus()) then
        m.button.setFocus(true)
    else
        ' Unfocused'
    end if
end sub

function resetTextCallback() as void
  if m.global.auth.isLoggedIn
    m.header.text = m.global.labels.logged_in_header_label + m.global.auth.email

    btn = [ { title: m.global.labels.sign_out_button, role: "signout", target: "" } ]

    if m.global.auth.universalSubCount = 0 and m.global.nsvod.currentPlan.count() > 0 then btn.push({ title: m.global.labels.sync_native_button, role: "syncNative", target: "" })
  else
    m.header.text = m.global.labels.account_screen_header

    btn = [ { title: m.global.labels.sign_in_button, role: "transition", target: "UniversalAuthSelection" } ]
  end if

  m.button.content = m.content_helpers.oneDimList2ContentNode(btn, "ButtonNode")
end function

function onKeyEvent(key as String, press as Boolean) as Boolean
  result = false
  if press
    ? ">>> AccountScreen >> onKeyEvent >> key " key
    if key = "options"
      result = true
    end if
  end if
  return result
end function

function helpers() as object
  this = {}

  this.focusedChild = function(self) as string
    return self.top.focusedChild.id
  end function

  this.currentButtonRole = function(self, index) as string
    return self.button.content.getChild(index).role
  end function

  this.currentButtonTarget = function(self, index) as string
    return self.button.content.getChild(index).target
  end function

  return this
end function

sub OnFocusedChild()
    if (m.top.IsInFocusChain() and m.top.hasFocus()) then
      m.button.setFocus(true)
    else
    end if
end sub

function initializers() as object
  this = {}

  this.initChildren = function(self) as void
    self.top.observeField("visible", "onVisibleChange")
    self.top.observeField("focusedChild", "OnFocusedChild")

    self.background = self.top.findNode("Background")
    self.background.color = self.global.theme.background_color

    self.button = self.top.findNode("Button")
    self.button.color = self.global.theme.primary_text_color
    self.button.focusedColor = self.global.theme.primary_text_color
    self.button.focusBitmapUri = self.global.theme.focus_grid_uri
    self.button.focusFootprintBitmapUri = self.global.theme.focus_grid_uri

    if self.global.enable_top_navigation = true then
      self.top.observeField("focusedChild", "OnFocusedChild")
    end if

    self.header = self.top.findNode("Header")
    self.header.color = self.global.theme.primary_text_color
  end function

  return this
end function
