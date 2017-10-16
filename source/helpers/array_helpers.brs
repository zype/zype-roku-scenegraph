function ArrayHelpers() as object
    this = {}

    ' Accept array of associative arrays and key to filter by
    '   - does not return item if duplicate
    this.RemoveDuplicatesBy = function(arr as object, key as string) as object
        keys = {}
        no_duplicates_arr = []

        for each item in arr
            key_value = item[key]

            ' unique item
            if keys.DoesExist(key_value) = false
                keys[key_value] = key_value
                no_duplicates_arr.push(item)
            end if
        end for

        return no_duplicates_arr
    end function

    return this
end function
