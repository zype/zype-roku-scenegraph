' **************************************************
' Deep Linking Helpers
'   - Contains helper methods for deep linking
'
' Functions in service
'     parseContentId
'
' Usage
'     deep_linking_helpers = DeepLinkingHelpers()
'     deep_linking_helpers.parseContentId(""VIDEO_ID-PLAYLIST_ID"")
' **************************************************
function DeepLinkingHelpers() as object
  this = {}

  ' ********************************************
  ' parseContentId()
  '
  ' Parameters:
  '     contentID - contentID string included in the deep linking request
  '     separator - string of separator (default is "-")
  '
  ' Return: an array of the strings split by the separator
  '
  ' Usage
  '   myContentId = "VIDEO_ID-PLAYLIST_ID"
  '   parsedContentId = DeepLinkingHelpers().parseContentId(myContentId)
  '   // parseContentId should be equal to ["VIDEO_ID", "PLAYLIST_ID"]
  ' ********************************************
  this.parseContentId = function(contentID as string, separator = "-" as string) as object
    return contentID.Split(separator)
  end function

  return this
end function
