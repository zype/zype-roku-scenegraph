function currentConsumer() as object
  return IsLinked({"linked_device_id": GetUdidFromReg(), "type": "roku"})
end function
