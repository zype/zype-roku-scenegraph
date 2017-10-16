function ContentHelpers() as object
  this = {}

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

  this.twoDimList2ContentNode = function(two_d_arr as object, node_type as string)
    content_container = CreateObject("roSGNode", "ContentNode")

    for each row in two_d_arr
      row_content = m.oneDimList2ContentNode(row, node_type)
      content_container.appendChild(row_content)
    end for

    return content_container
  end function

  this.CountOneDimContentNode = function(content_node as object) as integer
      if content_node = invalid then return 0
      return content_node.GetChildCount()
  end function

  this.CountTwoDimContentNodeAtIndex = function(content_node as object, row_index as integer) as integer
      if content_node = invalid then return 0
      return content_node.GetChild(row_index).GetChildCount()
  end function

  this.AppendToOneDimContentNode = function(content_node as object, arr as object, node_type as string) as object
      if content_node <> invalid and arr <> invalid
          if arr.count() = 0 then return content_node

          for each item in arr
              content = CreateObject("roSGNode", node_type)

              for each key in item
                  content[key] = item[key]
              end for

              content_node.appendChild(content)
          end for

          return content_node
      end if
  end function

  this.AppendToTwoDimContentNodeAtIndex = function(content_node as object, arr as object, row_index as integer, node_type as string) as object
      if content_node <> invalid and arr <> invalid
          if arr.count() = 0 then return content_node

          for each item in arr
              content = CreateObject("roSGNode", node_type)

              for each key in item
                  content[key] = item[key]
              end for

              content_node.GetChild(row_index).appendChild(content)
          end for

          return content_node
      end if
  end function

  this.PopOneDimContentNode = function(content_node as object) as object
      if content_node <> invalid and content_node.GetChildCount() > 0
          content_node.removeChildIndex(content_node.GetChildCount() - 1)
          return content_node
      else
          return CreateObject("roSGNode", "ContentNode")
      end if
  end function

  this.PopTwoDimContentNodeAtIndex = function(content_node as object, row_index as integer) as object
      if content_node <> invalid and content_node.GetChildCount() > 0
          content_node.GetChild(row_index).removeChildIndex(content_node.GetChild(row_index).GetChildCount() - 1)
          return content_node
      else
          return CreateObject("roSGNode", "ContentNode")
      end if
  end function

  return this
end function
