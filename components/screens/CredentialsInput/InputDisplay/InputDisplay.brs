' Input
sub init()
  m.private = {}

  m.content_helpers = ContentHelpers()
  m.text_helpers = TextHelpers()
  m.initializers = initializers()
  m.helpers = helpers()

  m.initializers.initChildren(m)
end sub

function onContentUpdate() as void
  input_data = m.top.itemContent

  m.input_box.hintText = input_data.title
  m.top.name = input_data.name
  m.top.value = input_data.value
end function

function onInputFocus() as void
  ? "InputDisplay >>> onInputFocus"
  ? "m.top.rowHasFocus: "; m.top.rowHasFocus
  ? "m.top.name: "; m.top.name
  ? "m.top.value: "; m.top.value

  if m.top.rowHasFocus
    m.input_box.text = m.top.value
    ' m.input_text.text = m.top.value

    m.input_box.cursorPosition = len(m.input_box.text)
    if len(m.input_box.text) > 0 then m.input_box.active = true else m.input_box.active = false

    ' m.input_text.visible = false
    m.input_box.setFocus(true)
  else

    if m.top.name = "password" and len(m.top.value) > 0
      m.input_box.text = m.text_helpers.securedPassword(m.top.value)
    else
      m.input_box.text = m.top.value
    end if

    m.input_text.visible = true
    m.input_box.active = false
    m.input_box.setFocus(false)
  end if
end function

function setInputRules() as void
  if m.top.name = "password" then m.input_box.secure = true
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
    self.input_text = self.top.findNode("Text")
    self.input_text.color = self.global.theme.primary_text_color

    self.input_box = self.top.findNode("InputBox")
    self.input_box.textColor = self.global.theme.primary_text_color
    self.input_box.hintTextColor = self.global.theme.secondary_text_color
  end function

  return this
end function
