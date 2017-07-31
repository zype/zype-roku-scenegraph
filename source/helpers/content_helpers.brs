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

  return this
end function
