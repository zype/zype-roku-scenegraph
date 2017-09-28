' **************************************************
' Content Helpers
'   - Contains helper methods for creating content nodes
'   - Useful in components which use list + grid nodes: LabelList, RowList, etc.
'       If using in components, include file in component XML before including component Brightscript file
'
' Functions in service
'     oneDimList2ContentNode
'     twoDimList2ContentNode
'
' Usage
'     content_helpers = ContentHelpers()
'     content_helpers.oneDimList2ContentNode(my_one_d_array, "ButtonNode")
' **************************************************
function ContentHelpers() as object
  this = {}

  ' ********************************************
  ' ContentHelpers.oneDimList2ContentNode()
  '
  ' Parameters:
  '     arr       - one dimensional array of associative arrays with key/values to place into ContentNode
  '     node_type - string of the type of content node to be made
  '
  ' Usage
  '   one_dimensional_array = [
  '     {title: "My First Button"},
  '     {title: "My Second Button"}
  '   ]
  '   my_labellist.content = m.content_helpers.oneDimList2ContentNode(one_dimensional_array, "ButtonNode")
  ' ********************************************
  this.oneDimList2ContentNode = function(arr as object, node_type as string)
    row = CreateObject("roSGNode", "ContentNode")

    for each item in arr
      content = CreateObject("roSGNode", node_type)

      for each key in item
        content[key] = item[key]
      end for

      row.appendChild(content)
    end for

    return row
  end function

  ' ********************************************
  ' ContentHelpers.twoDimList2ContentNode()
  '   - Dependent on ContentHelpers.oneDimList2ContentNode()
  '
  ' Parameters:
  '     arr       - two dimensional array of associative arrays with key/values to place into ContentNode
  '     node_type - string of the type of content node to be made
  '
  ' Usage:
  '   two_dimensional_array = [
  '     [ {title: "My First Video", duration: 5}, {title: "My Second Video", duration: 10} ],
  '     [ {title: "My Third Video", duration: 20} ]
  '   ]
  '   my_rowlist.content = m.content_helpers.twoDimList2ContentNode(two_dimensional_array, "VideoNode")
  ' ********************************************
  this.twoDimList2ContentNode = function(two_d_arr as object, node_type as string)
    content_container = CreateObject("roSGNode", "ContentNode")

    for each row in two_d_arr
      row_content = m.oneDimList2ContentNode(row, node_type)
      content_container.appendChild(row_content)
    end for

    return content_container
  end function

  return this
end function
