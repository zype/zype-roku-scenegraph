'******************************************************
'Try to convert anything to a string. Only works on simple items.
'
'Test with this script...
'
'    s$ = "yo1"
'    ss = "yo2"
'    i% = 111
'    ii = 222
'    f! = 333.333
'    ff = 444.444
'    d# = 555.555
'    dd = 555.555
'    bb = true
'
'    so = CreateObject("roString")
'    so.SetString("strobj")
'    io = CreateObject("roInt")
'    io.SetInt(666)
'    tm = CreateObject("roTimespan")
'
'    Dbg("", s$ ) 'call the Dbg() function which calls AkaMA_AnyToString()
'    Dbg("", ss )
'    Dbg("", "yo3")
'    Dbg("", i% )
'    Dbg("", ii )
'    Dbg("", 2222 )
'    Dbg("", f! )
'    Dbg("", ff )
'    Dbg("", 3333.3333 )
'    Dbg("", d# )
'    Dbg("", dd )
'    Dbg("", so )
'    Dbg("", io )
'    Dbg("", bb )
'    Dbg("", true )
'    Dbg("", tm )
'
'try to convert an object to a string. return invalid if can't
'******************************************************
Function AkaMA_AnyToString(any As Dynamic) As dynamic
    if any = invalid return "invalid"
    if AkaMA_isstr(any) return any
    if AkaMA_isint(any) return AkaMA_itostr(any)
    if AkaMA_isbool(any)
        if any = true return "true"
        return "false"
    endif
    if AkaMA_isfloat(any) return Str(any)
    if type(any) = "roTimespan" return AkaMA_itostr(any.TotalMilliseconds()) + "ms"
    return invalid
End Function

'******************************************************
'Tokenize a string. Return roList of strings
'******************************************************
Function AkaMA_strTokenize(str As String, delim As String) As Object
    if str <> invalid and delim <> invalid
        st=CreateObject("roString")
        st.SetString(str)
        return st.Tokenize(delim)
    endif
End Function

'******************************************************
'Replace substrings in a string. Return new string
'******************************************************
' Function AkaMA_strReplace(basestr As String, oldsub As String, newsub As String) As String
Function AkaMA_strReplace(basestr, oldsub As String, newsub As String) As String
    newstr = ""
    ' basestr1 = Str(basestr)
    ' print "Type of basestr: ";type(basestr)

    if(type(basestr) = "roFloat")
        basestr = Str(basestr)
    end if

    i = 1
    while i <= Len(basestr)
        x = Instr(i, basestr, oldsub)
        if x = 0 then
            newstr = newstr + Mid(basestr, i)
            exit while
        endif

        if x > i then
            newstr = newstr + Mid(basestr, i, x-i)
            i = x
        endif

        newstr = newstr + newsub
        i = i + Len(oldsub)
    end while

    return newstr
End Function

Function AkaMA_str8859toutf8(obj as dynamic) As String
    r = ""
    if AkaMA_isnonemptystr(obj)
        l = len(obj)
        for i=1 to l
            c = mid(obj,i,1)
            a = asc(c)
            if a<0 then a = a + 256
            if a<160
                s = c
            else if a<192
                s = chr(194) + chr(a)
            else
                s = chr(195) + chr(a-64)
            end if
            r = r + s
        end for
    end if
    'print "converted string = "; r
    return r
End Function

function AkaMA_doubleToString(originalVal as double) as string
    modVal% = originalVal mod 10
    print "mod value  = "; modVal%; "original value = "; originalVal
    retStr = box("")
    if originalVal <> 0
        originalVal = originalVal - modVal%
        originalVal = originalVal / 10
        result = AkaMA_doubleToString(originalVal)
        modString = modVal%.tostr()
        print "original value  = "; originalVal; " and return result = "; result
        retStr.ifstringops.AppendString(result, result.len())
        retStr.ifstringops.AppendString(modString, modString.len())
    else
        print "return str = "; retStr
       return retStr
    endif    
    return retStr
end function

function AkaMA_doubleToStr(originalVal) as string
    modVal = originalVal mod 10
    if originalVal <> 0
        tempVal% = originalVal - modVal
        tempVal% = originalVal / 10
        result = AkaMA_doubleToStr(tempVal%)
        modString = Str(modVal).Trim()
        result = result + modString
        'print "original value  = "; originalVal; " and return result = "; result
        'retStr.ifstringops.AppendString(result, result.len())
        'retStr.ifstringops.AppendString(modString, modString.len())
        'result = invalid
    else
        'print "return str = "; retStr
        retStr = box("")
        return retStr
    endif    
    return result
end function


