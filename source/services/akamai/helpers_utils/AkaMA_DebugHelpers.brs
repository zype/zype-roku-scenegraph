' this file contians all the functions related to debug messages
' and other supporting functions for debugging

'Function       :   AkaMA_logger
'Params         :   None
'Return         :   set of functions to switch logging / trace on/off 
'Description    :   Set enableLogging to true if logging needs to be printed on the console
'                   set enableTracing to true if trace nees to be printed on the console

function AkaMA_logger()
return {
    isLoggingEnabled    :   false           'Represents logging state
    isTraceEnabled      :   false           'Represents trace state
    
    
    'turns logging on/off
    enableLogging : function(loggingEnabled)
        m.isLoggingEnabled = loggingEnabled
    end function
    ' prints log if isLoggingEnabled is true   
    AkaMA_print : function(debugLog)
        if m.isLoggingEnabled <> false
            print debugLog
        endif
    end function
    
    'turns tracing on/off
    eanbelTrace : function(traceEnabled)
        m.isTraceEnabled = traceEnabled
    end function
    'prings trace if isTraceEnabled is true
    AkaMA_Trace : function(traceLog)
        if m.isTraceEnabled <> false
            print debugLog
        endif
    end function
}
end function

'******************************************************
'Walk an AA and print it
'******************************************************
Sub AkaMA_PrintAA(aa as Object)
    print "---- AA ----"
    if aa = invalid
        print "invalid"
        return
    else
        cnt = 0
        for each e in aa
            x = aa[e]
            AkaMA_PrintAny(0, e + ": ", aa[e])
            cnt = cnt + 1
        next
        if cnt = 0
            AkaMA_PrintAny(0, "Nothing from for each. Looks like :", aa)
        endif
    endif
    print "------------"
End Sub


''******************************************************
''Walk a list and print it
''******************************************************
'Sub PrintList(list as Object)
'    print "---- list ----"
'    AkaMA_PrintAnyList(0, list)
'    print "--------------"
'End Sub


'******************************************************
'Print an associativearray
'******************************************************
Sub AkaMA_PrintAnyAA(depth As Integer, aa as Object)
 if type(aa) = "roAssociativeArray" then
    for each e in aa
        x = aa[e]
        AkaMA_PrintAny(depth, e + ": ", aa[e])
    next
 endif   
End Sub


'******************************************************
'Print a list with indent depth
'******************************************************
Sub AkaMA_PrintAnyList(depth As Integer, list as Object)
    i = 0
    for each e in list
        AkaMA_PrintAny(depth, "List(" + AkaMA_itostr(i) + ")= ", e)
        i = i + 1
    next
End Sub

Sub AkaMA_tooDeep(depth As Integer) As Boolean
    hitLimit = (depth >= 10)
    if hitLimit then  print "**** TOO DEEP "; depth
    return hitLimit
End Sub

'******************************************************
'Print anything
'******************************************************
Sub AkaMA_PrintAny(depth As Integer, prefix As String, any As Dynamic)
    if AkaMA_tooDeep(depth) then return
    prefix = string(depth*2," ") + prefix
    depth = depth + 1
    str = AkaMA_AnyToString(any)
    if str <> invalid
        print prefix + str
        return
    endif
    if type(any) = "roAssociativeArray"
        print prefix + "(assocarr)..."
        AkaMA_PrintAnyAA(depth, any)
        return
    endif
    if AkaMA_islist(any) = true
        print prefix + "(list of " + AkaMA_itostr(any.Count()) + ")..."
        AkaMA_PrintAnyList(depth, any)
        return
    endif

    print prefix + "?" + type(any) + "?"
End Sub

'******************************************************
'Print an object as a string for debugging. If it is
'very long print the first 500 chars.
'******************************************************
Sub AkaMA_Dbg(pre As Dynamic, o=invalid As Dynamic)
    p = AkaMA_AnyToString(pre)
    if p = invalid p = ""
    if o = invalid o = ""
    s = AkaMA_AnyToString(o)
    if s = invalid s = "???: " + type(o)
    if Len(s) > 4000
        s = Left(s, 4000)
    endif
    print p + s
End Sub

'******************************************************
'Walk an XML tree and print it
'******************************************************
Sub AkaMA_PrintXML(element As Object, depth As Integer)
    print tab(depth*3);"Name: [" + element.GetName() + "]"
    if invalid <> element.GetAttributes() then
        print tab(depth*3);"Attributes: ";
        for each a in element.GetAttributes()
            print a;"=";left(element.GetAttributes()[a], 4000);
            if element.GetAttributes().IsNext() then print ", ";
        next
        print
    endif

    if element.GetBody()=invalid then
        ' print tab(depth*3);"No Body"
    else if type(element.GetBody())="roString" then
        print tab(depth*3);"Contains string: [" + left(element.GetBody(), 4000) + "]"
    else
        print tab(depth*3);"Contains list:"
        for each e in element.GetBody()
            AkaMA_PrintXML(e, depth+1)
        next
    endif
    print
end sub


'******************************************************
'islist
'
'Determine if the given object supports the ifList interface
'******************************************************
Function AkaMA_islist(obj as dynamic) As Boolean
    if obj = invalid return false
    if GetInterface(obj, "ifArray") = invalid return false
    return true
End Function


'******************************************************
'AkaMA_isint
'
'Determine if the given object supports the ifInt interface
'******************************************************
Function AkaMA_isint(obj as dynamic) As Boolean
    if obj = invalid return false
    if GetInterface(obj, "ifInt") = invalid return false
    return true
End Function

'******************************************************
' AkaMA_validstr
'
' always return a valid string. if the argument is
' invalid or not a string, return an empty string
'******************************************************
Function AkaMA_validstr(obj As Dynamic) As String
    if AkaMA_isnonemptystr(obj) return obj
    return ""
End Function


'******************************************************
'AkaMA_isstr
'
'Determine if the given object supports the ifString interface
'******************************************************
Function AkaMA_isstr(obj as dynamic) As Boolean
    if obj = invalid return false
    if GetInterface(obj, "ifString") = invalid return false
    return true
End Function


'******************************************************
'AkaMA_isnonemptystr
'
'Determine if the given object supports the ifString interface
'and returns a string of non zero length
'******************************************************
Function AkaMA_isnonemptystr(obj)
    if AkaMA_isnullorempty(obj) return false
    return true
End Function


'******************************************************
'AkaMA_isnullorempty
'
'Determine if the given object is invalid or supports
'the ifString interface and returns a string of non zero length
'******************************************************
Function AkaMA_isnullorempty(obj)
    if obj = invalid return true
    if not AkaMA_isstr(obj) return true
    if Len(obj) = 0 return true
    return false
End Function


'******************************************************
'AkaMA_isbool
'
'Determine if the given object supports the ifBoolean interface
'******************************************************
Function AkaMA_isbool(obj as dynamic) As Boolean
    if obj = invalid return false
    if GetInterface(obj, "ifBoolean") = invalid return false
    return true
End Function


'******************************************************
'AkaMA_isfloat
'
'Determine if the given object supports the ifFloat interface
'******************************************************
Function AkaMA_isfloat(obj as dynamic) As Boolean
    if obj = invalid return false
    if GetInterface(obj, "ifFloat") = invalid return false
    return true
End Function




'******************************************************
'AkaMA_itostr
'
'Convert int to string. This is necessary because
'the builtin Stri(x) prepends whitespace
'******************************************************
Function AkaMA_itostr(i As Integer) As String
    str = Stri(i)
    return AkaMA_strTrim(str)
End Function

'******************************************************
'Trim a string
'******************************************************
Function AkaMA_strTrim(str As String) As String
    st=CreateObject("roString")
    st.SetString(str)
    return st.Trim()
End Function
