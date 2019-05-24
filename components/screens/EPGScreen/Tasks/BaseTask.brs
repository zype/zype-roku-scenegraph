sub init()
  m.top.id = "BaseTask"
  m.top.functionName = "execute"
end sub


sub epgProgramInfo()
  responseAA = invalid
  if m.top.params <> invalid and m.top.params.program_guide_id <> invalid
    response = ViewProgramGuide(m.top.params.program_guide_id).response
    if response.video_ids <> invalid and response.video_ids[0] <> invalid
      responseAA = { id: response.video_ids[0], start: m.top.params.start_time, end: m.top.params.end_time }
    end if
  end if
  m.top.responseAA = responseAA
end sub


function localToUtc(start)
  return start - m.global.timeShift
end function


Function getHourStart(secs = 0)
  date = CreateObject("roDateTime")
  date.fromSeconds(secs)
  hourStart = secs - date.GetSeconds() - date.GetMinutes() * 60
  return hourStart
end function


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
'  date = CreateObject("roDatetime")
'  utcNow = date.asSeconds()
'  date.toLocalTime()
'  now = date.asSeconds()
'  timeShift = utcNow - now
  
  utcTimelineStartTime = localToUtc(m.top.params.timelineStartTime)
  guideDate = convertTimestampToYyyyMmDd(utcTimelineStartTime - 43200)
  guideEndDate = convertTimestampToYyyyMmDd(utcTimelineStartTime + 43200)
  m.startTime = utcTimelineStartTime - m.top.params.visibleHours * 2 * 3600
  m.endTime = utcTimelineStartTime + m.top.params.visibleHours * 2 * 3600
  for each guide in guides
    events = []
    m.eventids = []
    resp = GetProgramGuide(guide._id, getProgramGuideParams(guideDate, guideEndDate))
    page = formatPrograms(resp.response)
    programs = page.events
    isPaginationExist = resp.pagination <> invalid and resp.pagination.pages <> invalid and resp.pagination.current <> invalid
    while isPaginationExist and resp.pagination.current < resp.pagination.pages and not page.isOutOfTimeline
      resp = GetProgramGuide(guide._id, getProgramGuideParams(guideDate, guideEndDate, resp.pagination["next"].toStr()))
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
  if channels.count() = 0 and m.top.params.channels = invalid
    m.startTime = 0
    m.endTime = utcTimelineStartTime + 30 * 86400
    for each guide in guides
      events = []
      m.eventids = []
      resp = GetProgramGuide(guide._id, getProgramGuideParams())
      page = formatPrograms(resp.response)
      programs = page.events
      if programs.count() > 0
        programs.SortBy("utcStart")
        p = programs[programs.count() - 1]
        programs = []
        if p.utcStart + p.duration < utcTimelineStartTime
          programs.Push(p)
          programs.push(createFakeProgram(guide._id))
        else
          programs.push(createFakeProgram(guide._id))
          programs.Push(p)
        end if
        fullGuide[guide._id] = programs
        channels.push({id: guide._id, title: guide.name})
      end if
    end for
  end if
  if channels.count() = 0 and m.top.params.channels = invalid
    for each guide in guides
      fullGuide[guide._id] = [createFakeProgram(guide._id)]
      channels.push({id: guide._id, title: guide.name})
    end for
  end if
  m.top.responseAA = {channels: channels, programs: fullGuide, timelineStartTime: m.top.params.timelineStartTime}  ', guideDate: guideDate}
  m.top.control = "DONE"
end sub


function getProgramGuideParams(guideDate=invalid, guideEndDate=invalid, page=invalid)
  params = {per_page: "500", order: "asc"}
  if guideDate <> invalid and guideEndDate <> invalid
    params["sort"] = "start_time"
    params["start_time.gte"] = guideDate
    params["end_time.lte"] = guideEndDate
  end if
  if page <> invalid then params.page = page
  return params
end function


function createFakeProgram(program_guide_id, utcStart=getHourStart(localToUtc(m.top.params.timelineStartTime)), duration=m.top.params.visibleHours * 3600)
  return {id: (rnd(1000)*rnd(1000)).toStr(), title: m.global.labels.program_is_not_available, utcStart: utcStart, duration: duration, program_guide_id: program_guide_id}
end function


function formatPrograms(programs)
  date = CreateObject("roDatetime")
  'date.toLocalTime()
  now = date.asSeconds()
  events = []
'  hasNow = false
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
'        if program.utcStart + program.duration >= now then hasNow = true
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
  return {events: events, isOutOfTimeline: isOutOfTimeline}  ', hasNow: hasNow}
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
