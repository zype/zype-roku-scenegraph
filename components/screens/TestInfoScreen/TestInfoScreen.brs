sub init()
  m.initializers = initializers()
  m.helpers = helpers()

  m.initializers.initChildren(m)
end sub

function onInfoChange() as void
  m.info_display.text = m.top.info
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
    self.background = self.top.findNode("Background")
    self.background.color = self.global.theme.background_color

    self.header = self.top.findNode("Header")
    self.header.color = self.global.theme.primary_text_color

    self.info_display = self.top.findNode("InfoDisplay")
    self.info_display.color = self.global.theme.primary_text_color
  end function

  return this
end function
