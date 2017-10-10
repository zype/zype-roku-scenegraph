' **************************************************
' Text Helpers
'   - Contains generic function for text
'
' Functions in service
'     securedPassword
'
' Usage
'     text_helpers = TextHelpers()
'     text_helpers.securedPassword("myPassword") => *********d
' **************************************************
function TextHelpers() as object
  this = {}

  ' Accepts a password and returns password secured
  '   Example:  myPassword => *********d
  this.securedPassword = function(password as string) as string
    secured_password = box("")

    for n = 1 to len(password) - 1
      secured_password.AppendString("*", 1)
    end for

    secured_password.AppendString(password.right(1), 1)

    return secured_password
  end function

  return this
end function
