' Input
sub init()
  m.private = {}

  m.content_helpers = ContentHelpers()
  m.helpers = helpers()
  m.initializers = initializers()

  m.initializers.initChildren(m)
end sub

function initializers() as object
  this = {}

  this.initChildren = function(self) as void

  end function

  return this
end function
