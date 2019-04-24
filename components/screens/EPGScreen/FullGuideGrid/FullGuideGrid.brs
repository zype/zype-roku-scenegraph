Function Init()
  m.top.focusable = true
  m.top.observeField("focusedChild", "onFocusChanged")
  m.showList = m.top.findNode("showList")
  m.showListArea = m.top.findNode("showListArea")
  m.channelList = m.top.findNode("channelList")
  m.startRow = 0
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


sub fillChannels()
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
  '    setShowsRowFocus(i - m.startRow, false)
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
  if m.top.programs[i][0].utcStart + m.global.timeShift > m.timelineStart
    item = getOrCreateRowItem(row, ci)
    item.width = m.top.hourWidth * (m.top.programs[i][0].utcStart + m.global.timeShift - m.timelineStart) / 3600
    item.rowHasFocus = false'm.top.focusedRow = i'!!!!!!!!
    item.itemContent = {title: ""}
    ci++
  end if
  for j = 0 to m.top.programs[i].count() - 1
    p = m.top.programs[i][j]
    if p.utcStart + m.global.timeShift > m.timelineEnd then exit for
    if p.utcStart + p.duration + m.global.timeShift > m.timelineStart
      item = getOrCreateRowItem(row, ci)
      item.width = m.top.hourWidth * p.duration / 3600
      if p.utcStart + m.global.timeShift < m.timelineStart
        removeHours = (m.timelineStart - (p.utcStart + m.global.timeShift)) / 3600
        item.width -= m.top.hourWidth * removeHours
      end if
      item.rowHasFocus = m.top.focusedRow = i
      item.itemContent = {title: p.title}
      ci++
    end if
  end for
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
  fillChannels()
end sub


sub onFocusChanged()
  Dbg("get/lost hasFocus", m.top.hasFocus())
  if m.top.hasFocus()
    fillChannels()
    m.showList.getChild(0).getChild(0).cellHasFocus = true
    m.focusedGridCell = 0
  
'    m.top.gridHasFocus = true
'  else if not m.top.isinfocuschain()
'    m.top.gridHasFocus = false
  end if
end sub


function moveCellFocus(stepValue)
  Dbg("MoveCellFocus", stepValue)
  if m.top.focusedCell + stepValue >= 0 and m.top.focusedCell + stepValue < m.top.programs[m.top.focusedRow].count()
    m.showList.getChild(m.top.focusedRow - m.startRow).getChild(m.focusedGridCell).cellHasFocus = false
    m.top.focusedCell += stepValue
    if m.focusedGridCell + stepValue >= 0 and m.focusedGridCell + stepValue < m.showList.getChild(m.top.focusedRow - m.startRow).getChildCount()
      m.focusedGridCell += stepValue
      m.showList.getChild(m.top.focusedRow - m.startRow).getChild(m.focusedGridCell).cellHasFocus = true
    else
      moveCellFocus(1)
    end if
    p = m.top.programs[m.top.focusedRow][m.top.focusedCell]
'      timelineEnd = getHourStart(m.top.timelineStartTime) + m.top.visibleHours * 3600
    if p.utcStart + p.duration - m.global.timeShift > m.timelineEnd
      m.showList.getChild(m.top.focusedRow - m.startRow).getChild(m.focusedGridCell).cellHasFocus = false
      m.focusedGridCell = 0
      m.showList.getChild(m.top.focusedRow - m.startRow).getChild(m.focusedGridCell).cellHasFocus = true
      m.top.timelineStartTime = getHourStart(p.utcStart - m.global.timeShift)  ' + p.duration)
    else if p.utcStart - m.global.timeShift < m.timelineStart
      m.showList.getChild(m.top.focusedRow - m.startRow).getChild(m.focusedGridCell).cellHasFocus = false
      m.focusedGridCell = 0
      m.showList.getChild(m.top.focusedRow - m.startRow).getChild(m.focusedGridCell).cellHasFocus = true
      m.top.timelineStartTime = getHourStart(p.utcStart - m.global.timeShift)  ' + p.duration)
    end if
'    slideLeftRight()
    if m.showList.getChild(m.top.focusedRow - m.startRow).getChild(m.focusedGridCell).title = "" then moveCellFocus(1)
    return true
  end if
  return false
end function


function moveRowFocus(stepValue)
  Dbg("moveRowFocus", stepValue)
  if m.top.focusedRow + stepValue >= 0 and m.top.focusedRow + stepValue < m.top.channels.count()  'm.channelList.getChildCount()
'    grid = m.top.findNode("grid")
'    m.channelList.getChild(m.top.focusedRow).rowHasFocus = false
'    m.showList.getChild(m.top.focusedRow).getChild(m.top.focusedCell).cellHasFocus = false
'    setShowsRowFocus(m.top.focusedRow - m.startRow, false)
    m.top.focusedRow += stepValue
'    m.channelList.getChild(m.top.focusedRow).rowHasFocus = true
'    setShowsRowFocus(m.top.focusedRow, true)
'    m.showList.getChild(m.top.focusedRow).getChild(m.top.focusedCell).cellHasFocus = true
'    if isSlideUpDown(stepValue) then grid.translation = [grid.translation[0], grid.translation[1] - stepValue * (m.top.rowHeight + m.channelList.itemSpacings[0] + 1)]
    fillChannels()
    if m.focusedGridCell > m.showList.getChild(m.top.focusedRow - m.startRow).getChildCount() - 1
      m.focusedGridCell = m.showList.getChild(m.top.focusedRow - m.startRow).getChildCount() - 1
    end if
    moveCellFocus(0)
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


sub setShowsRowFocus(index, rowHasFocus)
  if m.showList.getChild(index) <> invalid
    for i = 0 to m.showList.getChild(index).getChildCount() - 1
      m.showList.getChild(index).getChild(i).rowHasFocus = rowHasFocus
    end for
  end if
end sub


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
          if not result
'            onChannelListItemSelected()
          else
'                m.infoPanel.show = not m.infoPanel.show
          end if
          result = true
'      else if key = "play"
'        if result
'          getScene().videoscreen.fullScreen = false
'          result = true
'        else
'          getScene().videoscreen.fullScreen = true
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
