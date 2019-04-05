'****************************************************
' Helper functions for CurrentUser model
'   - shortcuts for gathering info on current user
'
' Dependencies
'     source/oauth.brs
'     source/zype_api.brs
'****************************************************
function CurrentUserHelpers() as object
  this = {}

  this.consumerIdFromAccessToken = function(access_token) as dynamic
    token_status = RetrieveTokenStatus({ access_token: access_token })

    if token_status <> invalid then return token_status.resource_owner_id else return invalid
  end function

  this.consumerFromAccessToken = function(access_token) as object
    consumer_id = m.consumerIdFromAccessToken(access_token)

    if consumer_id <> invalid then return GetConsumer(consumer_id, access_token) else LogOut() : return invalid
  end function

  this.LinkedUser = function() as object
    linked_user = IsLinked({"linked_device_id": GetUdidFromReg(), "type": "roku"})

    if linked_user.linked then return linked_user else return invalid
  end function

  return this
end function
