sub init()
  m.top.id = "BaseTask"
  m.top.functionName = "execute"
end sub


sub epgRequest()
  channels = []
  if m.top.params.channels = invalid
    guides = GetProgramGuides({per_page: "500"})
  else
    guides = []
    for i = 0 to m.top.params.channels.count() - 1
      guides.push({"_id": m.top.params.channels[i].id, "name": m.top.params.channels[i].title})
    end for
  end if
  fullGuide = {}
  date = CreateObject("roDatetime")
  'date.toLocalTime()
  now = date.asSeconds()
  guideDate = convertTimestampToYyyyMmDd(m.top.params.timelineStartTime - 86400)
  guideEndDate = convertTimestampToYyyyMmDd(m.top.params.timelineStartTime + 86400)
  m.startTime = m.top.params.timelineStartTime - m.top.params.visibleHours * 2 * 3600
  m.endTime = m.top.params.timelineStartTime + m.top.params.visibleHours * 2 * 3600
  for each guide in guides
    events = []
    m.eventids = []
    resp = GetProgramGuide(guide._id, {per_page: "500", sort: "start_time", order: "asc", "start_time.gte": guideDate, "end_time.lte": guideEndDate})
    page = formatPrograms(resp.response)
    programs = page.events
    isPaginationExist = resp.pagination <> invalid and resp.pagination.pages <> invalid and resp.pagination.current <> invalid
    while isPaginationExist and resp.pagination.current < resp.pagination.pages and not page.isOutOfTimeline
      resp = GetProgramGuide(guide._id, {per_page: "500", sort: "start_time", order: "asc", "start_time.gte": guideDate, "end_time.lte": guideEndDate, page: resp.pagination["next"].toStr()})
      page = formatPrograms(resp.response)
      programs.Append(page.events)
      isPaginationExist = resp.pagination <> invalid and resp.pagination.pages <> invalid and resp.pagination.current <> invalid
    end while 
    if programs.count() > 0
      programs.SortBy("utcStart")
'      for i = 0 to programs.count() - 2
'        programs[i].duration = programs[i+1].utcStart - programs[i].utcStart
'      end for
      fullGuide[guide._id] = programs
      if m.top.params.channels = invalid then channels.push({id: guide._id, title: guide.name})
    end if
  end for
  m.top.responseAA = {channels: channels, programs: fullGuide, timelineStartTime: m.top.params.timelineStartTime, guideDate: guideDate}
  m.top.control = "DONE"
end sub


function formatPrograms(programs)
  date = CreateObject("roDatetime")
  'date.toLocalTime()
  now = date.asSeconds()
  events = []
  hasNow = false
  isOutOfTimeline = false
  if programs.count() > 0
    for each program in programs
      program.id = program["_id"]
      if not ArrayContains(m.eventids, program.id)
        program.delete("_id")
        'date.FromISO8601String(program.adjustedstarttime)
        'program.localstarttime = date.asSeconds()
        date.FromISO8601String(program.start_time)
        program.utcStart = date.asSeconds()
        if program.utcStart + program.duration >= now then hasNow = true
'        if program.utcStart + program.duration > m.endTime then isOutOfTimeline = true
        if program.utcStart + program.duration >= m.startTime and program.utcStart <= m.endTime
          program.delete("category")
          program.delete("created_at")
          program.delete("updated_at")
          if program.title = invalid or program.title = "" then program.title = "--"
          events.push(program)
          m.eventids.push(program.id)
        end if
      end if
    end for
  end if
  return {events: events, hasNow: hasNow, isOutOfTimeline: isOutOfTimeline}
end function


function convertTimestampToYyyyMmDd(timestamp)
  date = CreateObject("roDatetime")
  date.fromSeconds(timestamp)
  return date.ToISOString().split("T")[0]
end function


function ArrayContains(arr, value)
  for i=0 to arr.count() - 1
    if arr[i] = value then return true
  end for
  return false
end function


sub execute()
  m.top.control = "DONE"
end sub
