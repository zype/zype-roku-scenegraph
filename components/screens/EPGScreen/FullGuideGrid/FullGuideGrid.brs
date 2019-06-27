Function Init()
  m.top.focusable = true
  m.top.observeField("focusedChild", "onFocusChanged")
  m.showList = m.top.findNode("showList")
  m.showListArea = m.top.findNode("showListArea")
  m.channelList = m.top.findNode("channelList")
  m.borderBottom = m.top.findNode("borderBottom")
  m.startRow = 0
End Function


sub onSizeChanged()
  m.top.clippingRect = [0, 0, m.top.width, m.top.height]
  m.showListArea.clippingRect = [0, 0, m.top.width - m.top.leftOffset, m.top.height]
  m.borderBottom.width = m.top.width
  m.borderBottom.translation = [0, m.top.height - 1]
end sub


sub onGridFocusChanged()
  Dbg("get/lost focus:",m.top.gridHasFocus)
  if m.top.gridHasFocus then m.top.setFocus(true)
  Dbg("has focus:",m.top.hasFocus())
end sub


sub fillGrid()
  if isNonEmptyArray(m.top.channels)
  '  m.channelList.removeChildren(m.channelList.getChildren(m.channelList.getChildCount(), 0))
'    m.showList.removeChildren(m.showList.getChildren(m.showList.getChildCount(), 0))
    m.startRow = m.top.focusedRow - m.top.focusRow
    if m.startRow < 0 then m.startRow = 0
    if m.startRow > m.top.channels.count() - m.top.numRows - 1 then m.startRow = m.top.channels.count() - m.top.numRows - 1
    for i = m.startRow to m.startRow + m.top.numRows
      if m.channelList.getchildCount() > i - m.startRow
        item = m.channelList.getChild(i - m.startRow)
      else
        item = m.channelList.createChild("EPGGridChannelCell")
      end if
      item.width = m.top.leftOffset
      item.height = m.top.rowHeight
      item.gridHasFocus = true
      item.rowHasFocus = m.top.focusedRow = i
      item.itemContent = {title: m.top.channels[i].title}
      fillGuideRow(i)
    end for
    m.top.getScene().loadingIndicator.control = "stop"
  end if
  setInrowFocus()
end sub


sub fillGuideRow(i)
  row = m.showList.getChild(i - m.startRow)
  if row = invalid
    row = m.showList.createChild("LayoutGroup")
    row.layoutDirection = "horiz"
'    row.itemSpacings = [0]
  end if
  ci = 0
  n = getFirstItemIndex(i)
  p = getProgramsArray(i)[n]
  if p <> invalid and utcToLocal(p.utcStart) > m.timelineStart
    item = getOrCreateRowItem(row, ci)
    item.width = m.top.hourWidth * (utcToLocal(p.utcStart) - m.timelineStart) / 3600
    item.rowHasFocus = false
    item.cellHasFocus = false
    item.itemContent = {id: "fake", title: ""}
    ci++
  end if
  for j = n to getProgramsArray(i).count() - 1
    p = getProgramsArray(i)[j]
    if utcToLocal(p.utcStart) > m.timelineEnd then exit for
    if utcToLocal(p.utcStart + p.duration) > m.timelineStart
      item = getOrCreateRowItem(row, ci)
      item.width = m.top.hourWidth * p.duration / 3600
      if utcToLocal(p.utcStart) < m.timelineStart
        removeHours = (m.timelineStart - utcToLocal(p.utcStart)) / 3600
        item.width -= m.top.hourWidth * removeHours
      end if
      item.rowHasFocus = m.top.focusedRow = i
      item.cellHasFocus = false
      item.itemContent = {id: p.id, title: p.title, utcStart: p.utcStart, duration: p.duration}
      ci++
    end if
  end for
  if ci < row.getChildCount() then row.removeChildrenIndex(row.getChildCount() - ci, ci)
end sub


function getOrCreateRowItem(row, ci)
  item = row.getChild(ci)
  if item = invalid then item = row.createChild("EPGGridCell")
  item.height = m.top.rowHeight
  item.gridHasFocus = true
  return item
end function


function getFirstItemIndex(i, alignEnd = true)
  programs = getProgramsArray(i)
  infinityCounter% = programs.count() / 2
  iStart = 0
  iEnd = programs.count() - 1
  while (iEnd - iStart) > 10
    iMiddle% = iStart + (iEnd - iStart) / 2
    p = programs[iMiddle%]
    if utcToLocal(p.utcStart + p.duration) <= m.timelineStart
      iEnd = iMiddle%
    else if utcToLocal(p.utcStart) >= m.timelineStart
      iStart = iMiddle%
    end if
    infinityCounter% -= 1
    if infinityCounter% < 0
      iStart = 0
      iEnd = programs.count() - 1
      exit while
    end if
  end while
  for j = iStart to iEnd
    p = programs[j]
    if alignEnd
      if utcToLocal(p.utcStart + p.duration) > m.timelineStart then return j
    else
      if utcToLocal(p.utcStart) >= m.timelineStart then return j
    end if
  end for
  return 0
end function


sub setupTimelineStartTime()
  m.timelineStart = getHourStart(m.top.timelineStartTime)
  m.timelineEnd = m.timelineStart + m.top.visibleHours * 3600
  fillGrid()
end sub


sub onReset()
  if m.top.reset
    m.top.reset = false
    date = CreateObject("roDatetime")
    date.toLocalTime()
    m.timelineStart = getHourStart(date.asSeconds())
    m.timelineEnd = m.timelineStart + m.top.visibleHours * 3600
    m.top.focusedCell = getFirstItemIndex(m.top.focusedRow, false)
    m.top.timelineStartTime = m.timelineStart
  end if
end sub


sub onProgramsUpdate()
  if isNonEmptyAA(m.top.program)
    programs = getProgramsArray(m.top.focusedRow)
    for i = 0 to programs.count() - 1
      if programs[i].id = m.top.program.id
        m.top.focusedCell = i
        exit for
      end if
    end for
  else
    m.top.focusedCell = getFirstItemIndex(m.top.focusedRow, false)
  end if
end sub


sub onFocusChanged()
  Dbg("get/lost hasFocus", m.top.hasFocus())
  if m.top.hasFocus() then fillGrid()
end sub


function getProgramsArray(i)
  if m.top.programs <> invalid and m.top.channels <> invalid and m.top.channels[i] <> invalid and m.top.programs[m.top.channels[i].id] <> invalid
    return m.top.programs[m.top.channels[i].id]
  else
    return []
  end if
end function


function isTimelineUpdateRequired()
  isOutOfTimeline = utcToLocal(m.top.program.utcStart + m.top.program.duration) > m.timelineEnd
  isOutOfTimeline = isOutOfTimeline or utcToLocal(m.top.program.utcStart) < m.timelineStart
  return isOutOfTimeline
end function


function moveCellFocus(stepValue)
  Dbg("MoveCellFocus", stepValue)
  if m.top.focusedCell + stepValue >= 0 and m.top.focusedCell + stepValue < getProgramsArray(m.top.focusedRow).count()
    m.top.focusedCell += stepValue
    return true
  end if
  return false
end function


sub setInrowFocus()
  if m.showList.getChild(m.top.focusedRow - m.startRow) <> invalid and m.showList.getChild(m.top.focusedRow - m.startRow).getChildCount() > 0 and m.top.program <> invalid
    for i = 0 to m.showList.getChild(m.top.focusedRow - m.startRow).getChildCount() - 1
      cell = m.showList.getChild(m.top.focusedRow - m.startRow).getChild(i)
      cell.cellHasFocus = cell.itemContent.id = m.top.program.id  'm.focusedGridCell = i
    end for
  end if
end sub


function findFocusedCellOnRowChange()
  if m.top.program <> invalid
    utcStart = m.top.program.utcStart + m.top.program.duration / 2
    newRow = getProgramsArray(m.top.focusedRow)
    for i = 0 to newRow.count() - 1
      if newRow[i].utcStart <= utcStart and utcStart <= newRow[i].utcStart + newRow[i].duration then return i
    end for
  end if
  return 0
end function


function moveRowFocus(stepValue)
  Dbg("moveRowFocus", stepValue)
  if m.top.focusedRow + stepValue >= 0 and m.top.focusedRow + stepValue < m.top.channels.count()
    m.top.focusedRow += stepValue
    focusedCell = findFocusedCellOnRowChange()
    if m.top.focusedCell = focusedCell
      onProgramFocusMove()
    else
      m.top.focusedCell = focusedCell
    end if
    fillGrid()
    return true
  end if
  return false
end function


sub onProgramFocusMove()
  m.top.program = getProgramsArray(m.top.focusedRow)[m.top.focusedCell]
  if m.top.program <> invalid and isTimelineUpdateRequired()
    m.top.getScene().loadingIndicator.control = "start"
    m.top.timelineStartTime = getHourStart(utcToLocal(m.top.program.utcStart))  ' + p.duration)
  else
    setInrowFocus()
  end if
end sub


'function isSlideUpDown(stepValue)
'  rows = m.channelList.getChildCount() - 1
'  if stepValue > 0
'    return m.top.focusedRow > m.top.focusRow and m.top.focusedRow <= rows - (m.top.numRows - m.top.focusRow - 1)
'  else
'    return m.top.focusedRow >= m.top.focusRow and m.top.focusedRow < rows - (m.top.numRows - m.top.focusRow - 1)
'  end if
'end function


'function slideLeftRight()
'  bRect = m.showList.getChild(m.top.focusedRow).getChild(m.top.focusedCell).ancestorBoundingRect(m.showListArea)
'  if bRect.x < 0
'    m.showList.translation = [m.showList.translation[0] - bRect.x, m.showList.translation[1]]
'    return true
'  else if bRect.x + bRect.width > m.top.width - m.top.leftOffset
'    shiftValue = bRect.x + bRect.width - (m.top.width - m.top.leftOffset)
'    m.showList.translation = [m.showList.translation[0] - shiftValue, m.showList.translation[1]]
'    return true
'  end if
'  return false
'end function


Function OnKeyEvent(key, press) as Boolean
  result = false
  if press
      Dbg(">>> FullGuideGrid >> OnkeyEvent key: "+key+" >> grid id: ", m.top.id)
      if key = "options"
      else if key = "back"
        if result
          result = true
        end if
      else if key = "OK" or key = "play"
          m.top.itemSelected = true
          result = true
      else if key = "left"
          if not result then result = MoveCellFocus(-1)
      else if key = "right"
          if not result then result = MoveCellFocus(1)
      else if key = "up"
        result = moveRowFocus(-1)
      else if key = "down"
        result = moveRowFocus(1)
      end if
  end if
  return result
End Function
