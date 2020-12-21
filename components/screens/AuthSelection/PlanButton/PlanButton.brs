' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********

function Init()
  m.private = {
    plan_attibutes: [ "code", "cost", "costValue", "freeTrialQuantity", "freeTrialType", "name", "productType", "isPlanSubscribed", "planStatus", "activateDate" ],
    plan: {}
  }

  m.initializers = initializers()
  m.helpers = helpers()

  m.initializers.initChildren(m)
end function

' ***********************
'   Listener Functions
' ***********************
function PlanChanged() as void
  plan = m.top.itemContent

  for each attr in m.private.plan_attibutes
    m.private.plan[attr] = plan[attr]
  end for

  m.initializers.setButtonText(m)
end function


sub ItemHasFocus_Changed(event as dynamic)
    if event.GetData() = true
        setFocusButton()
    else
        setUnFocusButton()
    end if
end sub


' ***********************
'   Public Functions
' ***********************
function GetPlanInfo(data = invalid) as object
  return m.private.plan
end function


function setFocusButton() as void
    m.plan_display.color = m.global.theme.focus_plan_button_color

    m.plan_name.color = m.global.theme.focus_primary_text_color
    m.trial_period.color = m.global.theme.focus_primary_text_color
    m.cost.color = m.global.theme.focus_primary_text_color
end function

function setUnFocusButton() as void
    m.plan_display.color = m.global.theme.plan_button_color

    m.plan_name.color = m.global.theme.primary_text_color
    m.trial_period.color = m.global.theme.primary_text_color
    m.cost.color = m.global.theme.primary_text_color
end function


function initializers() as object
  this = {}

  this.initChildren = function(self) as void
    self.plan_display = self.top.findNode("PlanDisplay")
    self.plan_display.color = self.global.theme.plan_button_color

    self.plan_name = self.top.findNode("PlanName")
    self.plan_name.color = self.global.theme.primary_text_color

    self.selectedPlanText = self.top.findNode("selectedPlanText")
    self.selectedPlanText.color = self.global.theme.primary_text_color


    self.selectedPlanActivateDate = self.top.findNode("selectedPlanActivateDate")
    self.selectedPlanActivateDate.color = self.global.theme.primary_text_color

    self.trial_period = self.top.findNode("TrialPeriod")
    self.trial_period.color = self.global.theme.primary_text_color

    self.cost = self.top.findNode("Cost")
    self.cost.color = self.global.theme.primary_text_color
  end function

  this.setButtonText = function(self) as void
    qty = self.private.plan.freeTrialQuantity
    time_period = LCase(self.private.plan.freeTrialType).replace("s", "")

    self.plan_name.text = self.private.plan.name

    if self.private.plan.freeTrialType = "None"
      self.trial_period.text = "No Free Trial"
    else
      self.trial_period.text = str(qty) + "-" + time_period + " Free Trial"
    end if

    if self.private.plan.productType = "MonthlySub"
      self.cost.text = self.private.plan.cost + " per month"
    else if self.private.plan.productType = "YearlySub"
      self.cost.text = self.private.plan.cost + " per year"
    end if

    self.selectedPlanText.visible = self.private.plan.isPlanSubscribed
    self.selectedPlanActivateDate.visible = false

    if self.private.plan.isPlanSubscribed then
      self.selectedPlanText.text = self.private.plan.planStatus
    else if self.private.plan.activateDate <> "" and self.private.plan.planStatus <> ""
      self.selectedPlanText.text = self.private.plan.planStatus
      self.selectedPlanText.visible = true
      activateDateTime = CreateObject("roDateTime")
      activateDateTime.FromISO8601String(self.private.plan.activateDate)
      year = activateDateTime.GetYear()
      month = activateDateTime.GetMonth()
      date =  activateDateTime.GetDayOfMonth()
      activateDateText = self.helpers.GetFormattedDate(year,month,date)
      self.selectedPlanActivateDate.text =activateDateText
      self.selectedPlanActivateDate.visible = true
    end if

  end function

  return this
end function

function helpers() as object
  this = {}

  this.focusedChild = function() as string
    return m.top.focusedChild
  end function

  this.GetFormattedDate = function(year as integer, month as integer, date as integer) as string
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

    return yearText + "-" + monthText + "-" + dateText
  end function

  return this
end function
