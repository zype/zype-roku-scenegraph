function init()
  m.private = {}

  m.contentHelpers = ContentHelpers()
  m.initializers = initializers()
  m.helpers = helpers()

  m.initializers.initChildren(m)
end function

' ***********
'
' Assignment - onVisibleChange(), onPurchaseItemChanged(), onItemNameChanged()
' Actions - onKeyEvent(), onOauthSelected(), onPurchaseButtonSelected()
' ***********
function onKeyEvent(key as string, press as boolean) as boolean
  result = false

  if key = "down"
    if m.global.auth.isLoggedIn = false then m.OauthButton.setFocus(true)
  else if key = "up"
    m.PurchaseButtons.setFocus(true)
  else if key = "back"
  end if

  return result
end function

function onVisibleChange() as void
  if m.top.visible = true
      m.PurchaseButtons.setFocus(true)

    if m.global.device_linking = true
      if m.global.auth.isLoggedIn = false then
        btn = [{title: m.global.labels.sign_in_button, role: "transition", target: "UniversalAuthSelection"}]
        m.OauthButton.content = m.contentHelpers.oneDimList2ContentNode(btn, "ButtonNode")

        m.OauthLabel.translation = [135,0]
        m.OauthLabel.text = m.global.labels.already_have_account_label
        m.OauthLabel.visible = true
      else
        m.OauthButton.content = invalid

        m.OauthLabel.translation = [135,0]
        m.OauthLabel.text = m.global.labels.logged_in_header_label + m.global.auth.email
        m.OauthLabel.visible = true
      end if

    end if
  end if
end function

function onPurchaseItemChanged() as void
  if m.top.isPlayList=false
    btns = [
      { title: "Purchase Video - " + m.top.purchaseItem.cost, role: "confirm_purchase" },
      { title: "Cancel", role: "cancel" }
    ]
  else
    m.top.isPlayList=false
    btns = [
      { title: "Buy all "+m.top.playListVideoCount.toStr()+" Videos - " + m.top.purchaseItem.cost, role: "confirm_purchase" },
      { title: "Cancel", role: "cancel" }
    ]
  end if
  m.purchaseButtons.content = m.contentHelpers.oneDimList2ContentNode(btns, "ButtonNode")
end function

function onItemNameChanged() as void
  m.ItemLabel.text = m.top.itemName
end function

function onOauthSelected() as void
  m.top.itemSelectedRole = m.OauthButton.content.getChild(0).role
  m.top.itemSelectedTarget = m.oauthButton.content.getChild(0).target
end function

function onPurchaseButtonSelected() as void
  index = m.purchaseButtons.itemSelected
  m.top.itemSelectedRole = m.purchaseButtons.content.getChild(index).role
  m.top.itemSelectedTarget = m.purchaseButtons.content.getChild(index).target
end function

' *****************************************************
' Component helpers - internal / private functions only
' *****************************************************
function helpers() as object
  this = {}

  return this
end function

' ***************
' Initialization
' ***************
function initializers() as object
  this = {}

  this.initChildren = function(self) as void
    self.top.observeField("visible", "onVisibleChange")

    self.Background = self.top.findNode("Background")
    self.Background.color = self.global.theme.background_color

    self.Header = self.top.findNode("Header")
    self.Header.text = "Confirm purchase"
    self.Header.color = self.global.theme.primary_text_color

    self.ItemLabel = self.top.findNode("ItemNameLabel")
    self.ItemLabel.text = "Product"
    self.ItemLabel.color = self.global.theme.primary_text_color

    self.PurchaseButtons = self.top.findNode("PurchaseButtons")
    self.PurchaseButtons.color = self.global.theme.primary_text_color
    self.PurchaseButtons.focusedColor = self.global.theme.primary_text_color
    self.PurchaseButtons.focusBitmapUri = self.global.theme.focus_grid_uri
    self.PurchaseButtons.focusedFootprintBitmapUri = self.global.theme.focus_grid_uri

    btns = [
      { title: "Purchase product - $X.XX", role: "confirm_purchase" },
      { title: "Cancel", role: "cancel" }
    ]
    self.PurchaseButtons.content = self.contentHelpers.oneDimList2ContentNode(btns, "ButtonNode")

    self.OauthButton = self.top.findNode("OAuthButton")
    self.OauthButton.color = self.global.theme.primary_text_color
    self.OauthButton.focusedColor = self.global.theme.background_color
    self.OauthButton.focusBitmapUri = self.global.theme.button_filledin_uri
    self.OauthButton.focusFootprintBitmapUri = self.global.theme.focus_grid_uri

    oauthBtn = [{ title: self.global.labels.sign_in_button, role: "transition", target: "UniversalAuthSelection" }]
    self.OauthButton.content = self.contentHelpers.oneDimList2ContentNode(oauthBtn, "ButtonNode")

    self.OauthLabel = self.top.findNode("OAuthLabel")
    self.OauthLabel.color = self.global.theme.primary_text_color
  end function

  this.setupPurchaseButtons = function(self, btnContent) as void
    self.PurchaseButtons.content = btnContent
  end function

  return this
end function