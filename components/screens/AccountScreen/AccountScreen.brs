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
    ? ">>> AccountScreen >>> OnKeyEvent " key " press " press

    result = false
    ' ? " Focus " m.helpers.focusedChild(m)
    if m.global.auth.isLoggedIn = false Then
    ? "Return false"
        return false
    end if

    if press
      if key = "back"
        if m.global.auth.isLoggedIn = true and m.confirm_plan_group.visible = true Then
          resetScreen()
          return true
        end if
        if m.thank_you_group.visible = true Then
           m.thank_you_group.visible = false
           resetScreen()
           return true
        end if
      else if key = "up"
        if m.plan_buttons.hasFocus() and m.global.auth.isLoggedIn = true then
          ? " Focus change to oauth button "
          m.oauth_button.setFocus(true)
          result = true
        end if
      else if key = "down"
        ? " Focus change to plan_buttons "
        if m.oauth_button.hasFocus() then
          m.plan_buttons.setFocus(true)
          result = true
        end if
      end if
    end if

    return result
end function

function onItemSelected() as void
    m.top.itemSelectedRole = ""
    m.top.itemSelectedTarget = ""
    if m.global.auth.isLoggedIn = true Then
        if m.helpers.focusedChild(m) = "SubscripitionContainer" then
          m.top.itemSelectedRole = "transition"
        else
          index = m.top.oAuthItemSelected
          m.top.itemSelectedRole = m.helpers.currentLoggedInSignInButtonRole(m, index)
        end if
    else
        print " ------------ onItemSelected "
        index = m.top.signInItemSelected
        m.top.itemSelectedRole = m.helpers.currentSignInButtonRole(m, index)
        m.top.itemSelectedTarget = m.helpers.currentSignInButtonTarget(m, index)
    end if
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
        m.thank_you_group.visible = false
        resetScreen()
        ' m.Scene.callFunc("OpenPreviousScreen")
    end if
End Function

function onPlanSelection() as void
    print " >>>>>>>>>>>>>> Confirm plan" m.top.allowedUpgrade
    selectedPlan = m.helpers.planSelected(m)
    if m.top.allowedUpgrade = false then
      m.Scene.callFunc("CreateDialog",m.Scene, "Error", "You are not allowed to change plan in free trial.", ["Close"])
      return
    end if
    m.confirm_plan_group.visible = true
    m.signin_group.visible = false
    m.loggedin_group.visible = false
    m.confirm_plan_button.translation = [490,330]
    m.confirm_plan_header.text = ""
    m.confirm_plan_description.text = ""
    btn = []
    if isSubscribed() then
        purchasePlan = m.top.purchasePlans[0]
        if purchasePlan <> invalid and selectedPlan.zypePlanId = purchasePlan.zypePlanId
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


function onVisibleChange() as void
    if m.top.visible = true
      resetScreen()
    end if
end function

sub OnFocusedChild()
    print "[Account] OnFocusedChild " m.top.IsInFocusChain() " "m.top.hasFocus()
    if (m.top.IsInFocusChain() and m.top.hasFocus()) then
      if m.thank_you_group.visible = false then
          if m.global.auth.isLoggedIn
              m.oauth_button.setFocus(true)
          else
            m.signin_button.setFocus(true)
          end if
      end if
    else
        ' Unfocused'
    end if
end sub

function OnPlanSubscribeSuccess() as void
  print " >>>>>>>> OnPlanSubscribeSuccess "m.top.planSubscribeDetail
    m.thank_you_group.visible = true
    m.confirm_plan_group.visible = false
    m.signin_group.visible = false
    m.loggedin_group.visible = false

    'btn = [ { title: m.global.labels.return_to_home_button, role: "transition", target: "DetailsScreen" } ]
    btn = [{ title: m.global.labels.close_button, role: "Cancel", target: "" }]
    if m.isUpcommingPlanAvailble then
        m.thank_you_header.text = m.thankYouUpcomingPlanText
    else if m.isCurrentPlanFree
        m.thank_you_header.text = Substitute(m.global.labels.thank_you_message, m.top.planSubscribeDetail)
    else
        m.thank_you_header.text = Substitute(m.global.labels.thank_you_message, m.top.planSubscribeDetail)
    end if
    thankYouRect = m.thank_you_header.boundingRect()
    thankyouXPos = (1280 - thankYouRect.width) / 2
    m.thank_you_header.translation = [thankyouXPos,150]
    m.thank_you_button.content = m.content_helpers.oneDimList2ContentNode(btn, "ButtonNode")
    m.thank_you_button.jumpToItem = 0
    m.thank_you_button.setFocus(true)
end function

function resetScreen() as void
    m.confirm_plan_group.visible = false
    if m.thank_you_group.visible = true then
      return
    end if
    if m.global.auth.isLoggedIn
        m.signin_group.visible = false
        m.loggedin_group.visible = true
        m.top.setFocus(true)
        ' if only one plan center plan
        if m.top.plans.count() > 2 then
          m.plan_buttons.translation = [10,100]
        else if m.top.plans.count() > 1 then
          m.plan_buttons.translation = [180,100]
        else if m.top.plans.count() > 0
          m.plan_buttons.translation = [350,100]
        end if

        if m.global.device_linking = true
          btn = [ { title: m.global.labels.sign_out_button, role: "signout", target: "" } ]
          if m.global.auth.universalSubCount = 0 and m.global.nsvod.currentPlan.count() > 0 then  btn.push({ title: m.global.labels.sync_native_button, role: "syncNative", target: "" })
          m.oauth_button.content = m.content_helpers.oneDimList2ContentNode(btn, "ButtonNode")
          m.oauth_label.text = m.global.auth.email
        end if

        if isSubscribed() then
          m.subscription_header.text = m.global.labels.manage_subscription_header_label
        else
          m.subscription_header.text = m.global.labels.subscribe_header_label
        end if

        if m.isUpcommingPlanAvailble then
          m.upcomming_subscription_detail.text = m.upCommingPlanText
          m.upcomming_subscription_detail.visible = true
        else if m.isCurrentPlanFree then
          m.upcomming_subscription_detail.text = m.currentFreePlanText
          m.upcomming_subscription_detail.visible = true
        else
          m.upcomming_subscription_detail.text = ""
          m.upcomming_subscription_detail.visible = false
        end if

        m.plan_buttons.jumpToRowItem = [0,0]
        ' m.plan_buttons.setFocus(true)
        ' m.plan_buttons.setFocus(false)
        m.oauth_button.setFocus(true)
    else
      m.loggedin_group.visible = false
      m.signin_group.visible = true
      m.signin_header.text = m.global.labels.account_screen_header

      btn = [ { title: m.global.labels.sign_in_button, role: "transition", target: "UniversalAuthSelection" } ]
      m.signin_button.content = m.content_helpers.oneDimList2ContentNode(btn, "ButtonNode")

      m.signin_button.setFocus(true)
    end if

end function

function GetPlanDurationText(productType as string) as string
    if(productType = "MonthlySub") then
        return "per month"
    else
        return "per year"
    end if

end function
function isSubscribed() as boolean
  return ((m.global.auth.nativeSubCount > 0 or m.global.auth.universalSubCount > 0) and m.top.purchasePlans <> invalid and  m.top.purchasePlans.count() > 0)
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

function SetNativePurchasePlans() as void
    for i=0 to  m.plan_buttons.content.getChildCount() -1
        for j=0 to  m.plan_buttons.content.getChild(i).getChildCount() - 1
            planItem = m.plan_buttons.content.getChild(i).getChild(j)
            for each purchasePlan in m.top.purchasePlans
                if planItem.code = purchasePlan.code Then
                    if purchasePlan.freeTrialQuantity > 0
                        m.top.allowedUpgrade = false
                    end if
                    m.plan_buttons.content.getChild(i).getChild(j).isPlanSubscribed = true
                    m.SubscribedPlan = m.plan_buttons.content.getChild(i).getChild(j)
                    return
                end if
            end for
        end for
    end for

    if m.top.allowedUpgrade = true
      for each purchasePlan in m.top.purchasePlans
        for each planItem in m.top.allPlans
            if planItem.code = purchasePlan.code and purchasePlan.freeTrialQuantity > 0
                m.top.allowedUpgrade = false
                exit for
            end if
        end for
      end for
    end if
end function


function SetPurchasePlansDetails() as void
    m.isUpcommingPlanAvailble = false
    m.upCommingPlanText = invalid
    m.isCurrentPlanFree = false
    m.currentFreePlanText = invalid
    m.isCurrentPurchasePlanAvailable = false
    m.thankYouUpcomingPlanText = invalid
    for i=0 to  m.plan_buttons.content.getChildCount() -1
        for j=0 to  m.plan_buttons.content.getChild(i).getChildCount() - 1
            planItem = m.plan_buttons.content.getChild(i).getChild(j)
            for each purchasePlan in m.top.allPurchasePlans
                if planItem.code = purchasePlan.code Then
                    if m.plan_buttons.content.getChild(i).getChild(j).isPlanSubscribed = false Then
                      if purchasePlan.renewalDate <> invalid and purchasePlan.renewalDate <> ""
                        m.isUpcommingPlanAvailble = true
                        m.upCommingPlanText = Substitute(m.global.labels.upcoming_subscription_detail_label, m.plan_buttons.content.getChild(i).getChild(j).name)
                        renewalDate = m.helpers.getDateTextFromISODate(m,purchasePlan.renewalDate)
                        m.thankYouUpcomingPlanText = Substitute(m.global.labels.thank_you_message_upcommingplan, m.plan_buttons.content.getChild(i).getChild(j).name, renewalDate)
                      end if
                    else
                        m.plan_buttons.content.getChild(i).getChild(j).planStatus = "Current Plan"
                        m.plan_buttons.content.getChild(i).getChild(j).expiredDate = purchasePlan.expirationDate
                        m.isCurrentPurchasePlanAvailable = true
                    end if

                end if
            end for
        end for
    end for

    if m.isCurrentPurchasePlanAvailable = false
      for each purchasePlan in m.top.purchasePlans
          for each planItem in m.top.allPlans
                if planItem.code = purchasePlan.code Then
                    m.isCurrentPlanFree = true
                    m.currentFreePlanText = "Your current plan is " +planItem.name + "."
                    exit for
                end if
            end for
        end for
    end if
    if m.isUpcommingPlanAvailble = false and m.SubscribedPlan <> invalid then
      m.SubscribedPlan.expiredDate = ""
    end if
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

  this.currentLoggedInSignInButtonRole = function(self, index) as string
    return self.oauth_button.content.getChild(index).role
  end function


  this.currentSignInButtonRole = function(self, index) as string
    return self.signin_button.content.getChild(index).role
  end function

  this.currentSignInButtonTarget = function(self, index) as string
    return self.signin_button.content.getChild(index).target
  end function

  this.currentConfirmPopupButtonRole = function(self, index) as string
    return self.confirm_plan_button.content.getChild(index).role
  end function

  this.currentThankYouButtonRole = function(self, index) as string
    return self.thank_you_button.content.getChild(index).role
  end function

  this.currentThankYouButtonTarget = function(self, index) as string
    return self.thank_you_button.content.getChild(index).target
  end function

  this.getDateTextFromISODate = function(self, date as object) as string
      dateTime = CreateObject("roDateTime")
      dateTime.FromISO8601String(date)
      year = dateTime.GetYear()
      month = dateTime.GetMonth()
      date =  dateTime.GetDayOfMonth()
      dateText = self.helpers.GetFormattedDate(date,month,year)
      return dateText
  end function

  this.GetFormattedDate = function(date as integer, month as integer, year as integer) as string
    dateText = ""
    monthText = ""
    yearText = year.ToStr()
    if date > 9
        dateText = date.ToStr()
    else
        dateText = "0"+date.ToStr()
    end if

    if month > 9
        monthText = month.ToStr()
    else
        monthText = "0"+month.ToStr()
    end if

    return dateText + "-" + monthText + "-" + yearText
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
    self.isUpcommingPlanAvailble = false
    self.upCommingPlanText = invalid
	self.isCurrentPlanFree = false
    self.currentFreePlanText = invalid
    self.thankYouUpcomingPlanText = invalid
    ' SignIn Group for loggin '
    self.signin_group = self.top.findNode("signInGroup")

    self.signin_background = self.top.findNode("signInBackground")
    self.signin_background.color = self.global.theme.background_color

    self.signin_header = self.top.findNode("signInHeader")
    self.signin_header.color = self.global.theme.primary_text_color

    self.signin_button = self.top.findNode("signInButton")
    self.signin_button.color = self.global.theme.button_unfocus_color
    self.signin_button.focusedColor = self.global.theme.button_focus_color
    self.signin_button.focusBitmapUri = self.global.theme.button_focus_uri
    self.signin_button.focusFootprintBitmapUri = self.global.theme.button_unfocus_uri


    ' Loggin Group for manage subscription '
    self.loggedin_group = self.top.findNode("loggedInGroup")

    self.loggedin_background = self.top.findNode("loggedInBackground")
    self.loggedin_background.color = self.global.theme.background_color

    self.loggedin_header = self.top.findNode("loggedInHeader")
    self.loggedin_header.color = self.global.theme.primary_text_color


    self.oauth_email_label = self.top.findNode("OAuthEmailLabel")
    self.oauth_email_label.color = self.global.theme.primary_text_color

    self.oauth_label = self.top.findNode("OAuthLabel")
    self.oauth_label.color = self.global.theme.primary_text_color

    self.subscription_header = self.top.findNode("SubscriptionHeader")
    self.subscription_header.color = self.global.theme.primary_text_color

    self.upcomming_subscription_detail = self.top.findNode("UpcommingSubscriptionDetail")
    self.upcomming_subscription_detail.color = self.global.theme.primary_text_color

    self.plan_buttons = self.top.findNode("Plans")
    self.plan_buttons.focusBitmapUri = self.global.theme.focus_grid_uri

    self.oauth_button = self.top.findNode("OAuthButton")
    self.oauth_button.color = self.global.theme.primary_text_color
    self.oauth_button.focusedColor = self.global.theme.background_color
    self.oauth_button.focusBitmapUri = self.global.theme.button_filledin_uri
    self.oauth_button.focusFootprintBitmapUri = self.global.theme.focus_grid_uri

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

    if self.global.enable_top_navigation = true then
      self.top.observeField("focusedChild", "OnFocusedChild")
    end if


  end function

  this.setUpPlanButtons = function(self, plans) as void
    self.plan_buttons.content = plans
  end function


  return this
end function
