-- Shared only by cleanup tool operations; never waits when uncontended.
return function(context)
 setfenv(1,context)
 local Gate={Owner=nil}
 function Gate:TrackPickup(object)
  return not CleanupBacklogCore or CleanupBacklogCore:RegisterPrimary(object)
 end
 function Gate:IsReservedObject(object)
  return CleanupBacklogCore and CleanupBacklogCore:IsReserved(object)or false
 end
 function Gate:IsSupplementTool(tool)
  return CleanupBacklogCore and CleanupBacklogCore:OwnsTool(tool)or false
 end
 function Gate:Acquire(owner)
  if self.Owner then return nil end
  local token={Owner=owner};self.Owner=token;return token
 end
 function Gate:Release(token)
  if self.Owner==token then
   self.Owner=nil
   if CleanupBacklogCore then CleanupBacklogCore:Wake()end
  end
 end
 function Gate:IsEquipped(tool,character)
  if not tool or tool.Parent~=character then return false end
  for _,item in ipairs(character:GetChildren())do
   if item:IsA("Tool") and item~=tool then return false end
  end
  return true
 end
 CleanupToolGate=Gate
 return true
end
