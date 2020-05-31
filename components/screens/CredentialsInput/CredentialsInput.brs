sub init()
  m.private = {
    email: "",
    password: ""
  }

  m.content_helpers = ContentHelpers()
  m.initializers = initializers()
  m.helpers = helpers()

  m.initializers.initChildren(m)
end sub

' Key pressed
function onKeyEvent(key as string, press as boolean) as boolean
  result = false

  if press
    ? ">>> " + m.helpers.id(m) + " >>> onKeyEvent"
    if key = "down"
      if m.helpers.focusedChild(m) = "Inputs"
        m.submit_button.setFocus(true)
        result = true
      else if m.helpers.focusedChild(m) = "SubmitButton"
        if m.global.confirm_signup and m.top.isSignup = true
          m.confirm_signup.setFocus(true)
          result = true
        else if m.top.isRegister
          m.signin_button.setFocus(true)
          result = true
        end if
      end if
    else if key = "up"
      if m.helpers.focusedChild(m) = "SubmitButton" AND m.inputs <> invalid
        m.inputs.setFocus(true)
        result = true
      else if m.helpers.focusedChild(m) = "ConfirmSignup"
        m.submit_button.setFocus(true)
        result = true
      else if m.helpers.focusedChild(m) = "signinButton"
        m.submit_button.setFocus(true)
        result = true
      end if
    else if key = "back"
      if m.helpers.focusedChild(m) = "InputKeyboard" AND m.inputs <> invalid then
        m.inputs.setFocus(true)
        m.helpers.hideKeyboard(m)
        result = true
      else if not m.top.isSignup and m.top.isRegister and m.top.isSignin AND m.inputs <> invalid
        m.top.isSignin = false
        m.top.isRegister = true
        m.inputs.setFocus(true)
        m.inputs.jumpToRowItem = [0,0]
        result = true
      end if
    end if

  end if ' press = true

  return result
end function

' reset field set. Reset everything
function resetCallback() as void
  if m.top.reset = true
    m.top.email = ""
    m.top.password = ""
    m.input_keyboard.value = ""

    m.helpers.reassignInputs(m, {
      email: m.top.email,
      password: m.top.password
    })
    m.inputs.setFocus(true)
    m.inputs.jumpToRowItem = [1,0]
    m.inputs.jumpToRowItem = [0,0]
  end if
end function

' User clicked "OK" on email/password input field
function onInputSelect() as void
  m.input_keyboard.type = m.helpers.currentFocusedInput(m)

  if m.input_keyboard.type = "Email"
    m.input_keyboard.value = m.private.email
  else if m.input_keyboard.type = "Password"
    m.input_keyboard.value = m.private.password
  end if

  m.input_keyboard.visible = true
  m.input_keyboard.setFocus(true)
end function

function onItemSelected() as void
  if m.helpers.focusedChild(m) = "SubmitButton"
    m.top.itemSelectedRole = "submitCredentials"
    m.top.email = m.private.email
    m.top.password = m.private.password
    ? "You are submitting these credentials: "; m.top.email tab(4); m.top.password
  end if
end function

function onSigninSelected() as void
  m.top.isSignin = true
  m.top.isSignup = false
  m.top.header = m.global.labels.sign_in_screen_header
  m.top.helperMessage = m.global.labels.sign_in_helper_message
  m.top.submitButtonText = m.global.labels.sign_in_submit_button
  m.inputs.jumpToRowItem = [0,0]
  m.inputs.setFocus(true)
end function

function onVisibleChange() as void
  if m.top.visible = true then m.input_keyboard.visible = false : m.inputs.setFocus(true)
end function

function setHeader() as void
  m.header_label.text = m.top.header
end function


function setSubmitButtonText() as void
  m.submit_button.content = m.content_helpers.oneDimList2ContentNode([{title: m.top.submitButtonText}], "ButtonNode")
end function


function setSigninButtonText() as void
  m.signin_button.content = m.content_helpers.oneDimList2ContentNode([{title: m.top.signinButtonText}], "ButtonNode")
end function


function updateCheckbox() as void
  if m.global.confirm_signup and m.top.isSignup = true
    m.confirm_signup.visible = true
    m.helper_message.translation = [0,620]
  else
    m.confirm_signup.visible = false
    m.helper_message.translation = [0,520]
  end if
  m.top.findNode("Inputs").translation = [400,200]
  m.top.findNode("SubmitButton").translation = [500,400]
  m.top.findNode("ConfirmSignup").translation = [425,500]
  m.top.findNode("signinHintMessage").visible = false
  m.top.findNode("signinButton").visible = false
end function


sub updateScreen()
  if m.top.isRegister
    m.confirm_signup.visible = false
    m.helper_message.translation = [0,180]
    m.top.findNode("Inputs").translation = [400,280]
    m.top.findNode("SubmitButton").translation = [500,460]
    m.top.findNode("ConfirmSignup").translation = [425,560]
    m.top.findNode("signinHintMessage").visible = true
    m.top.findNode("signinButton").visible = true
    m.top.header = m.global.labels.registration_screen_header
    m.top.helperMessage = m.global.labels.registration_helper_message.replace("{{chr(10)}}", chr(10))
    m.top.signinHintMessage = m.global.labels.already_have_account_label.replace("{{chr(10)}}", chr(10))
    m.top.submitButtonText = m.global.labels.create_account_submit_button
  else
    updateCheckbox()
  end if
end sub


function isSignupChecked() as boolean
  signupChecked = m.confirm_signup.checkedState[0] = true
  if m.global.confirm_signup and m.top.isSignup = true and signupChecked
    return true
  end if
  return signupChecked
end function


function handleInput() as void
  m.input_keyboard.setFocus(false)
  m.input_keyboard.visible = false

  input_type = m.input_keyboard.type
  input_value = m.input_keyboard.value

  if input_type = "Email"
    data = {
      email: input_value,
      password: m.private.password
    }
  else if input_type = "Password"
    data = {
      email: m.private.email,
      password: input_value
    }
  end if

  m.helpers.reassignInputs(m, data)
  m.inputs.setFocus(true)

  if input_type = "Email"
    m.inputs.jumpToRowItem = [0,0]
  else if input_type = "Password"
    m.inputs.jumpToRowItem = [1,0]
  end if
end function

function helpers() as object
  this = {}

  this.id = function(self) as string
    return self.top.id
  end function

  this.focusedChild = function(self) as string
    return self.top.focusedChild.id
  end function

  this.currentFocusedInput = function(self) as string
    index = self.inputs.itemFocused
    return self.inputs.content.getChild(index).getChild(0).title
  end function

  this.emailInputNode = function(self) as object
    return self.inputs.content.getChild(0).getChild(0)
  end function

  this.passwordInputNode = function(self) as object
    return self.inputs.content.getChild(1).getChild(0)
  end function

  this.keyboardValue = function(self) as string
    return self.input_keyboard.value
  end function

  this.hideKeyboard = function(self) as void
    self.input_keyboard.visible = false
    self.input_keyboard.setFocus(false)
  end function

  this.reassignInputs = function(self, data) as void
    self.private.email = data.email
    self.private.password = data.password

    inputs_content = [
      [ { title: "Email", name: "email", value: self.private.email } ],
      [ { title: "Password", name: "password", value: self.private.password } ]
    ]

    self.inputs.content = self.content_helpers.twoDimList2ContentNode(inputs_content, "InputNode")
  end function

  return this
end function

function initializers() as object
  this = {}

  this.initChildren = function(self) as void
    self.top.observeField("visible", "onVisibleChange")

    self.background = self.top.findNode("Background")
    self.background.color = self.global.theme.background_color

    self.header_label = self.top.findNode("HeaderLabel")
    self.header_label.color = self.global.theme.primary_text_color

    inputs_content = [
      [ { title: "Email", name: "email", value: "" } ],
      [ { title: "Password", name: "password", value: "" } ]
    ]

    self.inputs = self.top.findNode("Inputs")
    self.inputs.focusBitmapUri = self.global.theme.focus_grid_uri
    self.inputs.content = self.content_helpers.twoDimList2ContentNode(inputs_content, "InputNode")

    self.signin_button = self.top.findNode("signinButton")
    self.signin_button.focusBitmapUri = self.global.theme.button_focus_uri
    self.signin_button.color = self.global.theme.primary_text_color
    self.signin_button.focusedColor = self.global.theme.primary_text_color
    self.signin_button.content = self.content_helpers.oneDimList2ContentNode([{title: self.global.labels.sign_in_submit_button, role: "transition", target: "SignInScreen"}], "ButtonNode")
'    self.signin_button.observeField("visible", "onVisibleChange")

    self.submit_button = self.top.findNode("SubmitButton")
    self.submit_button.focusBitmapUri = self.global.theme.button_focus_uri
    self.submit_button.color = self.global.theme.primary_text_color
    self.submit_button.focusedColor = self.global.theme.primary_text_color
    self.submit_button.content = self.content_helpers.oneDimList2ContentNode([{title: self.global.labels.user_credential_submit_button}], "ButtonNode")

    self.helper_message = self.top.findNode("HelperMessage")
    self.helper_message.color = self.global.theme.primary_text_color

    self.input_keyboard = self.top.findNode("InputKeyboard")

    self.confirm_signup = self.top.findNode("ConfirmSignup")
  end function

  return this
end function
