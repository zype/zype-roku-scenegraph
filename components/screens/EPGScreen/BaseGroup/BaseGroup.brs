Sub Init()
  if not m.global.hasField("timeShift") then m.global.addFields({ timeShift: getTimeshift() })
'  baseGroupInit()
'  m.top.observeField("focusedChild","onFocusedChildChange")
End Sub


Sub onFocusedChildChange()
  if m.top.hasFocus() and not m.top.visible then m.top.visible = true
End Sub


Function showBackNode()
  Dbg("showBackNode", m.top.backNavigation)
  if isnonemptystr(m.top.backNavigation)
    m.global.navigate = m.top.backNavigation
    return true
  end if
  if m.top.backNode <> invalid
    if m.top.backNode.hasField("show")
      m.top.backNode.show = true
    else
      m.top.backNode.setfocus(true)
    end if
    return true
  end if
  return false
end Function


Sub Dbg(pre As Dynamic, o=invalid As Dynamic)
    if m.top <> invalid and o <> invalid
        ? " [ " m.top.id " ] " pre, o
    else if m.top <> invalid
        ? " [ " m.top.id " ] " pre
    else if o <> invalid
        ? pre, o
    else
        ? pre
    end if
End Sub


'******************************************************
'Get remaining hours from a total seconds
'******************************************************
Function hoursLeft(seconds As Integer) As Integer
  hours% = seconds / 3600
  return hours%
End Function


function utcToLocal(utcStart)
  return utcStart + m.global.timeShift
end function


function getTimeshift()
  date = CreateObject("roDatetime")
  utc = date.asSeconds()
  date.toLocalTime()
  return date.asSeconds() - utc
end function


Function getHourStart(secs = 0)
  date = CreateObject("roDateTime")
  if evalBoolean(secs)
    date.fromSeconds(secs)
  else
    secs = date.asSeconds()
  end if
  hourStart = secs - date.GetSeconds() - date.GetMinutes() * 60
  return hourStart
end function


function getCurrentTimeOffset(hourwidth, timeShift=0)
  date = CreateObject("roDatetime")
  sec = date.asSeconds() + timeShift
  date.fromSeconds(sec)
  return (hourwidth/60)*date.getMinutes()
end function


function secondsToTime(secs, usTimeFormat=true)
  date = CreateObject("roDatetime")
  if isInteger(secs) then date.fromSeconds(secs)

  hour            = date.GetHours()
  minutes         = Num2ZeroLeadingStr(date.GetMinutes())

  if usTimeFormat then
    periodIndicator = "AM"

    if (hour > 12 and hour <= 23)
      hour = hour - 12
      periodIndicator = "PM"
    else if (hour = 12)
      periodIndicator = "PM"
    else if (hour = 0)
      hour = 12       
    end if
  end if
  hour = hour.ToStr()
  formattedTime = hour + ":" + minutes
  if usTimeFormat then formattedTime += " " + periodIndicator
  return formattedTime
end function


function isString(value) as boolean
  if isInvalid(obj) then return false
  if GetInterface(obj, "ifString") = invalid return false
  return true
end function

function isInteger(value) as boolean
    return not isInvalid(value) and type(value) = "Integer" or type(value) = "roInt" or type(value) = "roInteger"
end function

function isFloat(value) as boolean
    return not isInvalid(value) and type(value) = "Float" or type(value) = "roFloat"
end function

function isDouble(value) as boolean
    return not isInvalid(value) and type(value) = "Double"
end function

function isNumber(value) as boolean
    return isInteger(value) or isFloat(value) or isDouble(value)
end function

function isBoolean(value) as boolean
    return not isInvalid(value) and (type(value) = "Boolean" or type(value) = "roBoolean")
end function

function isDateTime(value) as boolean
    return not isInvalid(value) and type(value) = "roDateTime"
end function

function isArray(value) as boolean
    return not isInvalid(value) and type(value) = "roArray"
end function

function isAA(value) as boolean
    return not isInvalid(value) and type(value) = "roAssociativeArray"
end function

function isNode(value) as boolean
    return not isInvalid(value) and type(value) = "roSGNode"
end function


function isNonEmptyArray(value) as boolean
  return (isArray(value) and value.count() > 0)
end function


function isEmptyAA(value) as boolean
  if isAA(value) then return value.items().count() = 0
  return true
end function


function isNonEmptyAA(value) as boolean
  return isAA(value) and value.items().count() > 0
end function


Function isEmpty(value)
  if isInvalid(value) then return true
  if isString(value) then return value = ""
  if isArray(value) then return value.Count() = 0
  if isNumber(value) then return value = 0
  if isAA(value) then return value.items().count() = 0
  if isBoolean(value) then return not value
  return false
End Function

function isFunction(value) as boolean
    if isInvalid(value) return false
    return type(value) = "roFunction" or type(value) = "Function"
end function

function isObject(value) as boolean
    return not (isString(value) or isInteger(value) or isFloat(value) or isBoolean(value) or isDouble(value) or isFunction(value))
end function

function isInvalid(value) as Boolean
    return lcase(type(value)) = "roinvalid" or lcase(type(value)) = "invalid" or type(value) = "<uninitialized>"
end function

function isException(value) as boolean
    if isAA(value) and value.classname = "Exception" return true
    return false
end function

function evalString(value) as string
    if (isString(value)) return value
    if isNumber(value) or isBoolean(value) then return value.toStr()
    return ""
end function

function evalInteger(value)
    if (isString(value)) return value.toInt()
    if (isInteger(value)) return value
    if (isNumber(value)) return int(value)
    return 0
end function

function evalFloat(value)
    if (isString(value)) return value.toFloat()
    if (isInteger(value)) return (str(value)).toFloat()
    if (isFloat(value)) return value
    return 0
end function

function evalBoolean(value) as boolean
    if isInvalid(value) then return false
    if isBoolean(value) then return value
    if isString(value) then return UCase(value) = "TRUE"
    if isNumber(value) then return value > 0
    return true
end function

function evalBooleanAsString(value) as string
    if (evalBoolean(value)) return "true"
    return "false"
end function


Function Num2ZeroLeadingStr(enumb)
    enumb = evalInteger(enumb)
    if enumb < 10 then
        return "0" + enumb.tostr()
    else
        return enumb.tostr()
    end if
End Function


function getCurrentTime(withsec=true)
  currentTime = CreateObject("roDatetime")
  currentTime.toLocalTime()
  secs = currentTime.GetSeconds()
  seconds = currentTime.asSeconds()
  formattedTime = secondsToTime(seconds)
  if withsec then formattedTime = formattedTime+" | "+secs.ToStr()+"s"
  return formattedTime
end function


function ArrayContains(arr, value)
  if (not isArray(arr)) return false
  for i=0 to arr.count() - 1
    if arr[i] = value then return true
  end for
  return false
end function


Function runTask(taskFunc, params=invalid, observersAA=invalid)
  taskNode = CreateObject("roSGNode", "BaseTask")
  if taskNode <> invalid
    taskNode.id = taskFunc
    taskNode.functionName = taskFunc
    if isNonEmptyAA(observersAA)
      for each key in observersAA.keys()
        taskNode.observeField(key, observersAA[key])
      end for
    end if
    if isNonEmptyAA(params) then taskNode.params = params
    taskNode.control = "RUN"
  end if
  return taskNode
end Function
