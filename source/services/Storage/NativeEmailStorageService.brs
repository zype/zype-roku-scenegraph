'****************************************************
' NativeEmailStorageService
'    - used to handle storage of orignal email associated with native subscription purchase
'
' Dependencies
'     source/utils.brs
'****************************************************
function NativeEmailStorageService() as object
  this = {}

  this.ReadEmail = function() as string
    email = RegRead("Email", "NativeSubscription")
    if email = invalid then return "" else return email
  end function

  this.WriteEmail = function(email) as void
    RegWrite("Email", email, "NativeSubscription")
  end function

  this.DeleteEmail = function() as void
    RegDelete("Email", "NativeSubscription")
  end function

  return this
end function
