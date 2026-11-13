-- Detection only: never moves parts, removes clothing, or calls remotes.
return function(context)
 setfenv(1,context)
 local Detector={}
 local function inside(item,container)
  return item and container and (item==container or item:IsDescendantOf(container))
 end
 function Detector:IsAttached(object,character)
  if not object or not object.Parent or not character or not character.Parent then return false end
  -- Scan only this placed object, not Workspace or other players' rigs.
  for _,link in ipairs(object:GetDescendants())do
   if link.Name=="AttachParentObject"and link:IsA("ObjectValue")then
    -- A reference may identify a body part, layered clothing, or classic clothing.
    if inside(link.Value,character)then return true end
   elseif link:IsA("JointInstance")or link:IsA("WeldConstraint")then
    -- Accept actual endpoint relationships regardless of the joint's name.
    local a,b=link.Part0,link.Part1
    if (inside(a,character)and inside(b,object))or(inside(b,character)and inside(a,object))then return true end
   end
  end
  return false
 end
 CleanupAttachmentDetector=Detector
 return true
end
