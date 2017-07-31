' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********
function Init()
    m.private = {
      plans: []
    }

    m.content_helpers = ContentHelpers()
    m.initializers = initializers()
    m.helpers = helpers()

    m.initializers.initChildren(m)
end function

' ************************************************************************
'   Listeners - Callback functions that respond to field changes or input
' ************************************************************************
function OnKeyEvent(key as string, press as boolean) as boolean
    ? ">>> AuthSelection >>> OnKeyEvent"

    result = false

    if press
      if key = "down"
        if m.helpers.focusedChild(m) = "Plans" then m.oauth_button.setFocus(true)
      else if key = "up"
        if m.helpers.focusedChild(m) = "OAuthTransition" then m.plan_buttons.setFocus(true)
      end if
    end if

    return result
end function

function onItemSelected() as void
    if m.helpers.focusedChild(m) = "OAuthTransition" then m.top.itemSelectedRole = "transition" : m.top.itemSelectedTarget = "UniversalAuthSelection"
end function

function onPlanSelection() as void
    selected_plan = m.helpers.planSelected(m)
    stop

    ' Need code to trigger transition to Sign Up
end function

function onVisibleChange() as void
    if m.top.visible = true
      m.plan_buttons.setFocus(true)
    end if
end function

' ***********************
'   Public Functions
'
'   Callable from main thread or parent component with .callFunc("function name", param)
'     - object can only be the value itself or an associative array of parameters
' ***********************
function SetNativePlans() as void
    content = m.content_helpers.twoDimList2ContentNode([m.top.plans], "PlanNode")
    m.initializers.setUpPlanButtons(m, content)
end function

function GetNativePlans(data = invalid) as object
    return m.top.plans
end function

' ************************************************************************
' Component helpers - internal / private functions only
'   - Not callable from outside component
' ************************************************************************
function helpers() as object
  this = {}

  this.focusedChild = function(self) as string
    return self.top.focusedChild.id
  end function

  this.planSelected = function(self) as object
    row = self.plan_buttons.rowItemSelected[0]
    col = self.plan_buttons.rowItemSelected[1]

    return self.plan_buttons.content.getChild(row).getChild(col)
  end function

  return this
end function

' *********************************************************************
'   Initializer Functions - Called when initializing component
' *********************************************************************
function initializers() as object
  this = {}

  ' Accepts m (self) and initializes children
  '   - Does not work without passing m
  this.initChildren = function(self) as void
    app_info = CreateObject("roAppInfo")

    self.top.observeField("visible", "onVisibleChange")

    self.header = self.top.findNode("Header")
    self.header.color = self.global.theme.primary_text_color

    self.description = self.top.findNode("Description")
    self.description.text = "You need to be a " + app_info.GetTitle() + " subscriber to watch this content. Get unlimited access on all your devices by subscribing now."
    self.description.color = self.global.theme.primary_text_color

    self.plan_buttons = self.top.findNode("Plans")

    self.oauth_button = self.top.findNode("OAuthButton")
    self.oauth_button.color = self.global.theme.primary_text_color
    self.oauth_button.focusedColor = self.global.theme.background_color
    self.oauth_button.focusBitmapUri = self.global.theme.auth_button_uri
    self.oauth_button.content = self.content_helpers.oneDimList2ContentNode([{title: "Sign In"}], "ButtonNode")
  end function

  this.setUpPlanButtons = function(self, plans) as void
    self.plan_buttons.content = plans
  end function

  return this
end function
