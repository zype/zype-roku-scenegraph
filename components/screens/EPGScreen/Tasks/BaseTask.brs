sub init()
  m.top.id = "BaseTask"
  m.top.functionName = "execute"
end sub


sub epgRequest()
  guides = GetProgramGuides({per_page: "500"})
  channels = []
  eventids = []
  fullGuide = []
  date = CreateObject("roDatetime")
  'date.toLocalTime()
  now = date.asSeconds()
  for each guide in guides
    events = []
    programs = GetProgramGuide(guide._id, {per_page: "500"})
    if programs.count() > 0
      for each program in programs
        program.id = program["_id"]
        if not ArrayContains(eventids, program.id)
          program.delete("_id")
          'date.FromISO8601String(program.adjustedstarttime)
          'program.localstarttime = date.asSeconds()
          date.FromISO8601String(program.start_time)
          program.utcStart = date.asSeconds()
          if program.utcStart + program.duration >= now
            program.delete("category")
            program.delete("created_at")
            program.delete("updated_at")
            if program.title = invalid or program.title = "" then program.title = "--"
            events.push(program)
            eventids.push(program.id)
          end if
        end if
      end for
      if events.count() > 0
        events.SortBy("utcStart")
        for i = 0 to events.count() - 2
          events[i].duration = events[i+1].utcStart - events[i].utcStart
        end for
        fullGuide.Push(events)
        channels.push({title: guide.name})
      end if
    end if
  end for
  m.top.responseAA = {channels: channels, programs: fullGuide}
  m.top.control = "DONE"
end sub


function ArrayContains(arr, value)
  for i=0 to arr.count() - 1
    if arr[i] = value then return true
  end for
  return false
end function


sub execute()
  m.top.control = "DONE"
end sub
