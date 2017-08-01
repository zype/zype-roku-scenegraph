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
