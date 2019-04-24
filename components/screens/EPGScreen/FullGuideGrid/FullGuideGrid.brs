Function Init()
  m.top.focusable = true
  m.top.observeField("focusedChild", "onFocusChanged")
  m.showList = m.top.findNode("showList")
  m.showListArea = m.top.findNode("showListArea")
  m.channelList = m.top.findNode("channelList")
  m.startRow = 0
  m.focusedGridCell = 0
End Function


sub onSizeChanged()
  m.top.clippingRect = [0, 0, m.top.width, m.top.height]
  m.showListArea.clippingRect = [0, 0, m.top.width - m.top.leftOffset, m.top.height]
'  m.top.rowHeight = m.top.height / m.top.numRows - m.channelList.itemSpacings[0]
end sub


sub onGridFocusChanged()
  Dbg("get/lost focus:",m.top.gridHasFocus)
  if m.top.gridHasFocus then m.top.setFocus(true)
  Dbg("has focus:",m.top.hasFocus())
end sub


sub fillGrid()
  if isNonEmptyArray(m.top.channels)
  '  m.channelList.removeChildren(m.channelList.getChildren(m.channelList.getChildCount(), 0))
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
      fillShowRow(i)
    end for
  end if
end sub


sub fillShowRow(i)
  row = m.showList.getChild(i - m.startRow)
  if row = invalid
    row = m.showList.createChild("LayoutGroup")
    row.layoutDirection = "horiz"
'    row.itemSpacings = [0]
  end if
  ci = 0
  if utcToLocal(m.top.programs[i][0].utcStart) > m.timelineStart
    item = getOrCreateRowItem(row, ci)
    item.width = m.top.hourWidth * (utcToLocal(m.top.programs[i][0].utcStart) - m.timelineStart) / 3600
    item.rowHasFocus = false
    item.cellHasFocus = false
    item.itemContent = {id: "fake", title: ""}
    if m.top.focusedRow = i and m.focusedGridCell = 0 then m.focusedGridCell = 1
    ci++
  end if
  for j = 0 to m.top.programs[i].count() - 1
    p = m.top.programs[i][j]
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
  if m.top.focusedRow = i then setInrowFocus()
end sub


function getOrCreateRowItem(row, ci)
  item = row.getChild(ci)
  if item = invalid then item = row.createChild("EPGGridCell")
  item.height = m.top.rowHeight
  item.gridHasFocus = true
  return item
end function


sub setupTimelineStartTime()
  m.timelineStart = getHourStart(m.top.timelineStartTime)
  m.timelineEnd = getHourStart(m.top.timelineStartTime) + m.top.visibleHours * 3600
  fillGrid()
end sub


sub onFocusChanged()
  Dbg("get/lost hasFocus", m.top.hasFocus())
  if m.top.hasFocus() then fillGrid()
end sub


function isTimelineUpdateRequired()
  p = m.top.programs[m.top.focusedRow][m.top.focusedCell]
  isOutOfTimeline = utcToLocal(p.utcStart + p.duration) > m.timelineEnd
  return isOutOfTimeline or utcToLocal(p.utcStart) < m.timelineStart
end function


function moveCellFocus(stepValue)
  Dbg("MoveCellFocus", stepValue)
  if m.top.focusedCell + stepValue >= 0 and m.top.focusedCell + stepValue < m.top.programs[m.top.focusedRow].count()
    m.top.focusedCell += stepValue
    if not moveCellInnerFocus(stepValue) or isTimelineUpdateRequired()
      m.focusedGridCell = 0
      p = m.top.programs[m.top.focusedRow][m.top.focusedCell]
      m.top.timelineStartTime = getHourStart(utcToLocal(p.utcStart))  ' + p.duration)
    end if
'    if m.showList.getChild(m.top.focusedRow - m.startRow).getChild(m.focusedGridCell).title = "" then moveCellFocus(stepValue)
    return true
  end if
  return false
end function


function moveCellInnerFocus(stepValue)
  Dbg("moveCellInnerFocus", stepValue)
  if m.focusedGridCell + stepValue >= 0 and m.focusedGridCell + stepValue < m.showList.getChild(m.top.focusedRow - m.startRow).getChildCount()
    m.focusedGridCell += stepValue
    setInrowFocus()
    return true
  end if
  return false
end function


sub setInrowFocus()
  if m.showList.getChild(m.top.focusedRow - m.startRow) <> invalid and m.showList.getChild(m.top.focusedRow - m.startRow).getChildCount() > 0
    p = m.top.programs[m.top.focusedRow][m.top.focusedCell]
    for i = 0 to m.showList.getChild(m.top.focusedRow - m.startRow).getChildCount() - 1
      c = m.showList.getChild(m.top.focusedRow - m.startRow).getChild(i)
      c.cellHasFocus = c.itemContent.id = p.id  'm.focusedGridCell = i
      if c.itemContent.id = p.id then m.focusedGridCell = i 
    end for
  end if
end sub


function findFocusedCellOnRowChange(prevFocusedRow, nextFocusedRow)
  utcStart = m.top.programs[prevFocusedRow][m.top.focusedCell].utcStart
  newRow = m.top.programs[nextFocusedRow]
  for i = 0 to newRow.count() - 1
    if newRow[i].utcStart <= utcStart and utcStart < newRow[i].utcStart + newRow[i].duration then return i
  end for
  return 0
end function


function moveRowFocus(stepValue)
  Dbg("moveRowFocus", stepValue)
  if m.top.focusedRow + stepValue >= 0 and m.top.focusedRow + stepValue < m.top.channels.count()
    prevFocusedRow = m.top.focusedRow
    m.top.focusedRow += stepValue
    m.top.focusedCell = findFocusedCellOnRowChange(prevFocusedRow, m.top.focusedRow)
    fillGrid()
    if m.focusedGridCell > m.showList.getChild(m.top.focusedRow - m.startRow).getChildCount() - 1
      m.focusedGridCell = m.showList.getChild(m.top.focusedRow - m.startRow).getChildCount() - 1
      setInrowFocus()
    end if
    return true
  end if
  return false
end function


function isSlideUpDown(stepValue)
  rows = m.channelList.getChildCount() - 1
  if stepValue > 0
    return m.top.focusedRow > m.top.focusRow and m.top.focusedRow <= rows - (m.top.numRows - m.top.focusRow - 1)
  else
    return m.top.focusedRow >= m.top.focusRow and m.top.focusedRow < rows - (m.top.numRows - m.top.focusRow - 1)
  end if
end function


function slideLeftRight()
  bRect = m.showList.getChild(m.top.focusedRow).getChild(m.top.focusedCell).ancestorBoundingRect(m.showListArea)
  if bRect.x < 0
    m.showList.translation = [m.showList.translation[0] - bRect.x, m.showList.translation[1]]
    return true
  else if bRect.x + bRect.width > m.top.width - m.top.leftOffset
    shiftValue = bRect.x + bRect.width - (m.top.width - m.top.leftOffset)
    m.showList.translation = [m.showList.translation[0] - shiftValue, m.showList.translation[1]]
    return true
  end if
  return false
end function


Function OnKeyEvent(key, press) as Boolean
  result = false
  if press
      Dbg(">>> FullGuideGrid >> OnkeyEvent key: "+key+" >> grid id: ", m.top.id)
      if key = "options"
      else if key = "back"
        if result
          result = true
        end if
      else if key = "OK"
          result = true
'      else if key = "play"
'        if result
'          result = true
'        else
'          result = true
'        end if
      else if key = "left"
          if not result then result = MoveCellFocus(-1)
      else if key = "right"
          if not result then result = MoveCellFocus(1)
      else if key = "up"
        result = moveRowFocus(-1)
      else if key = "down"
        result = moveRowFocus(1)
      else if key = "fastforward"
          'if not result then result = MoveRowFocus(5)
      else if key = "rewind"
          'if not result then result = MoveRowFocus(-5)
      end if
  end if
  return result
End Function
