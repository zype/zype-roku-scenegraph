' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********

function Init()
  m.private = {
    plan_attibutes: [ "code", "cost", "freeTrialQuantity", "freeTrialType", "name", "productType" ],
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

' ***********************
'   Public Functions
' ***********************
function GetPlanInfo(data = invalid) as object
  return m.private.plan
end function


function initializers() as object
  this = {}

  this.initChildren = function(self) as void
    self.plan_display = self.top.findNode("PlanDisplay")
    self.plan_display.color = self.global.theme.plan_button_color

    self.plan_name = self.top.findNode("PlanName")
    self.plan_name.color = self.global.theme.primary_text_color

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
  end function

  return this
end function

function helpers() as object
  this = {}

  this.focusedChild = function() as string
    return m.top.focusedChild
  end function

  return this
end function
