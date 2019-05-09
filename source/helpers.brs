' Get limit-livesream

function LoadLimitStream()
    rawData = GetZObjects({"zobject_type": "limit_livestream"})
    print rawData.count()
    if rawData <> invalid and rawData.count() > 0
        data = rawData[0]
        SetLimitStreamObject(data)
    end if
end function

<<<<<<< HEAD
=======
function LoadHeroCarousels()
    rawData = GetZObjects({"zobject_type": "top_playlists"})
    if rawData <> invalid AND rawData.Count()>0
      return rawData
    end if
    return invalid
end function

>>>>>>> 084d74cfdab6cc622ee30032a1b4120be0e74bab
function GetLimitStreamObject() as Object
    if m.limitStream <> invalid then
        return m.limitStream
    end if

    return invalid
end function

function SetLimitStreamObject(data as Object)
    m.limitStream = invalid

    m.limitStream = {
        "limit": data.limit,
        "message": data.message,
        "refresh_rate": data.refresh_rate,
        "played": 0
    }
end function

function IsPassedLimit(position as Integer, limit as Integer) as Boolean
    return position >= limit
end function

function readManifest()
  result = {}
  
  raw = ReadASCIIFile("pkg:/manifest")
  lines = raw.Tokenize(Chr(10))
  for each line in lines
    bits = line.Tokenize("=")
    if bits.Count() > 1
      result.AddReplace(bits[0], bits[1])
    end if
  next
  
  return result
end function