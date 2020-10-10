' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********
function Init()
    m.Scene = m.top.getScene()
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
      if key = "options" then
          result = true
      else if key = "back"
        if m.global.auth.isLoggedIn = true and m.confirm_plan_group.visible = true Then
          resetScreen()
          return true
        end if
        if m.thank_you_group.visible = true Then
           m.thank_you_group.visible = false
           resetScreen()
           return true
        end if
      else if key = "down"
        if m.helpers.focusedChild(m) = "Plans" and m.global.auth.isLoggedIn = false and m.global.device_linking = true then m.oauth_button.setFocus(true)
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
    selectedPlan = m.helpers.planSelected(m)
    print " onPlanSelection "
    m.confirm_plan_group.visible = true
    'm.subscription_group.visible = false
    m.confirm_plan_button.translation = [490,330]
    m.confirm_plan_header.text = ""
    m.confirm_plan_description.text = ""
    btn = []
    if isSubscribed() then
        purchasePlan = m.top.purchasePlans[0]
        if selectedPlan.zypePlanId = purchasePlan.zypePlanId
          m.confirm_plan_description.text = "It appears you have already purchased this plan before." '' + chr(10) + "If you cancelled your subscription, please renew your subscription on the Roku website. " + chr(10) + "Then you can sign in with your account."
          btn = [{ title: m.global.labels.ok_button, role: "Cancel", target: "" }]
          m.confirm_plan_button.translation = [490,450]
        else
          m.confirm_plan_header.text = m.global.labels.change_plan_confirm_header_label
          m.confirm_plan_description.text = Substitute(m.global.labels.change_plan_confirm_cost_detail, selectedPlan.cost, GetPlanDurationText(selectedPlan.productType), purchasePlan.cost, GetPlanDurationText(purchasePlan.productType))
          btn = [ { title: m.global.labels.change_plan_button, role: "ChangePlan", target: "" }, { title: m.global.labels.no_back_button, role: "Cancel", target: "" }]
        end if

    else
        m.confirm_plan_header.text = m.global.labels.subscribe_confirm_header_label
        m.confirm_plan_description.text = Substitute(m.global.labels.subscribe_confirm_cost_detail, selectedPlan.cost, GetPlanDurationText(selectedPlan.productType))
        btn = [ { title: m.global.labels.subscribe_now_button, role: "Subscribe", target: "" }, { title: m.global.labels.no_back_button, role: "Cancel", target: "" }]
    end if

    m.confirm_plan_button.content = m.content_helpers.oneDimList2ContentNode(btn, "ButtonNode")
    m.confirm_plan_button.jumpToItem = 0
    m.confirm_plan_button.setFocus(true)
end function

function OnPlanSubscribeSuccess() as void
  print " >>>>>>>> OnPlanSubscribeSuccess "m.top.planSubscribeDetail
    m.thank_you_group.visible = true
    m.confirm_plan_group.visible = false

    'btn = [ { title: m.global.labels.return_to_home_button, role: "transition", target: "DetailsScreen" } ]
    btn = [{ title: m.global.labels.close_button, role: "Cancel", target: "" }]

    m.thank_you_header.text = Substitute(m.global.labels.thank_you_message, m.top.planSubscribeDetail)
    m.thank_you_button.content = m.content_helpers.oneDimList2ContentNode(btn, "ButtonNode")
    m.thank_you_button.jumpToItem = 0
    m.thank_you_button.setFocus(true)
end function

function GetPlanDurationText(productType as string) as string
    if(productType = "MonthlySub") then
        return "per month"
    else
        return "per year"
    end if

end function

function onVisibleChange() as void

    if m.top.visible = true
        resetScreen()
    end if
end function

function isSubscribed() as boolean
  return (m.global.auth.nativeSubCount > 0 or m.global.auth.universalSubCount > 0 and m.top.purchasePlan <> invalid and  m.top.purchasePlan.count() > 0)
end function

function resetScreen() as void
      ' if only one plan center plan
      'if m.top.plans.count() = 1 then m.plan_buttons.translation = [450,350] else m.plan_buttons.translation = [220,350]
    m.confirm_plan_group.visible = false
    if m.thank_you_group.visible = true then
      return
    end if
    m.subscription_group.visible = true
      if m.top.plans.count() > 2 then
        m.plan_buttons.translation = [160,350]
      else if m.top.plans.count() > 1 then
        m.plan_buttons.translation = [330,350]
      else if m.top.plans.count() > 0
        m.plan_buttons.translation = [500,350]
      end if

      if m.global.device_linking = true
          if m.global.auth.isLoggedIn = false then
            m.oauth_button.content = m.content_helpers.oneDimList2ContentNode([{title: m.global.labels.sign_in_button}], "ButtonNode")

            m.oauth_label.translation = [135,0]
            m.oauth_label.text = m.global.labels.already_have_account_label
            m.oauth_label.visible = true
          else
            m.oauth_button.content = invalid

            m.oauth_label.translation = [135,0]
            m.oauth_label.text = m.global.labels.logged_in_header_label + m.global.auth.email
            m.oauth_label.visible = true
          end if
      end if

      m.plan_buttons.jumpToRowItem = [0,0]
      m.plan_buttons.setFocus(true)
    m.plan_buttons.setFocus(false)
    m.plan_buttons.setFocus(true)
end function

function onConfirmOptionSelected() as void
    m.top.itemSelectedRole = ""
    m.top.itemSelectedTarget = ""
    index = m.top.confirmOptionSelected
    confirmRole = m.helpers.currentConfirmPopupButtonRole(m, index)
    if confirmRole = "Cancel" then
        m.confirm_plan_group.visible = false
        resetScreen()
    else
        m.top.currentPlanSelected = m.helpers.planSelected(m)
    end if
end function

Function onThankYouOptionSelected() as void
    m.top.itemSelectedRole = ""
    m.top.itemSelectedTarget = ""
    index = m.top.thankYouOptionSelected
    thankYouBtnRole = m.helpers.currentThankYouButtonRole(m, index)
    print " onThankYouOptionSelected "
    if thankYouBtnRole = "Cancel" then
        resetScreen()
        m.top.itemSelectedRole = "backScreen"
        m.top.itemSelectedTarget = "AuthSelection"
        m.top.thankYouCloseSelected = true   
    end if
End Function

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

function SetNativePurchasePlans() as void
    internal = m.plan_buttons.content.getChild(0)
    for i=0 to  m.plan_buttons.content.getChildCount() -1
        for j=0 to  m.plan_buttons.content.getChild(i).getChildCount() - 1
            planItem = m.plan_buttons.content.getChild(i).getChild(j)
            for each purchasePlan in m.top.purchasePlans
                if planItem.code = purchasePlan.code Then
                    planItem.isPlanSubscribed = true
                end if
            end for
        end for
    end for

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
    return self.top.focusedChild.focusedChild.id
  end function

  this.planSelected = function(self) as object
    row = self.plan_buttons.rowItemSelected[0]
    col = self.plan_buttons.rowItemSelected[1]
    return self.plan_buttons.content.getChild(row).getChild(col)
  end function

  this.currentConfirmPopupButtonRole = function(self, index) as string
    return self.confirm_plan_button.content.getChild(index).role
  end function

  this.currentThankYouButtonRole = function(self, index) as string
    return self.thank_you_button.content.getChild(index).role
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

    self.subscription_group = self.top.findNode("subscriptionGroup")

    self.background = self.top.findNode("Background")
    self.background.color = self.global.theme.background_color

    self.header = self.top.findNode("Header")
    self.header.color = self.global.theme.primary_text_color

    self.description = self.top.findNode("Description")

    ' You can add your own custom
    if Len(self.global.labels.custom_plan_purchase_message) <> 0
        self.description.text = self.global.labels.custom_plan_purchase_message
    else
        self.description.text = "You need to be a " + app_info.GetTitle() + " subscriber to watch this content. Get unlimited access on all your devices by subscribing now."
    end if

    self.description.color = self.global.theme.primary_text_color

    self.plan_buttons = self.top.findNode("Plans")
    self.plan_buttons.focusBitmapUri = self.global.theme.focus_grid_uri

    self.oauth_button = self.top.findNode("OAuthButton")
    self.oauth_button.color = self.global.theme.primary_text_color
    self.oauth_button.focusedColor = self.global.theme.background_color
    self.oauth_button.focusBitmapUri = self.global.theme.button_filledin_uri
    self.oauth_button.focusFootprintBitmapUri = self.global.theme.focus_grid_uri

    self.oauth_label = self.top.findNode("OAuthLabel")
    self.oauth_label.color = self.global.theme.primary_text_color


    ' Confirm plan group for confirm plan for purchase/upgrade/downgrade '

    self.confirm_plan_group = self.top.findNode("confirmPlanGroup")

    self.confirm_plan_background = self.top.findNode("confirmPlanBackground")
    self.confirm_plan_background.color = self.global.theme.background_color

    self.confirm_plan_header = self.top.findNode("confirmPlanHeader")
    self.confirm_plan_header.color = self.global.theme.primary_text_color

    self.confirm_plan_description = self.top.findNode("confirmPlanDescription")
    self.confirm_plan_description.color = self.global.theme.primary_text_color

    self.confirm_plan_button = self.top.findNode("confirmPlanButton")
    self.confirm_plan_button.color = self.global.theme.primary_text_color
    self.confirm_plan_button.focusedColor = self.global.theme.background_color
    self.confirm_plan_button.focusBitmapUri = self.global.theme.button_filledin_uri
    self.confirm_plan_button.focusFootprintBitmapUri = self.global.theme.focus_grid_uri



    ' Thank you for subscription group '

    self.thank_you_group = self.top.findNode("thankYouGroup")

    self.thank_you_background = self.top.findNode("thankYouBackground")
    self.thank_you_background.color = self.global.theme.background_color

    self.thank_you_header = self.top.findNode("thankYouHeader")
    self.thank_you_header.color = self.global.theme.primary_text_color

    self.thank_you_description = self.top.findNode("thankYouDescription")
    self.thank_you_description.color = self.global.theme.primary_text_color

    self.thank_you_button = self.top.findNode("thankYouButton")
    self.thank_you_button.color = self.global.theme.primary_text_color
    self.thank_you_button.focusedColor = self.global.theme.background_color
    self.thank_you_button.focusBitmapUri = self.global.theme.button_filledin_uri
    self.thank_you_button.focusFootprintBitmapUri = self.global.theme.focus_grid_uri

    self.top.observeField("itemSelected", "onItemSelected")
  end function

  this.setUpPlanButtons = function(self, plans) as void
    self.plan_buttons.content = plans
  end function


  return this
end function
