local source=...
setfenv=function()end
local function item(kind,parent)
 local o={Parent=parent,ClassName=kind,Name=kind,Children={}}
 if parent then parent.Children[#parent.Children+1]=o end
 function o:IsA(k)return self.ClassName==k or(k=="JointInstance"and self.ClassName=="Weld")end
 function o:IsDescendantOf(p)local n=self.Parent;while n do if n==p then return true end;n=n.Parent end;return false end
 function o:GetDescendants()local out={};local function walk(n)for _,c in ipairs(n.Children)do out[#out+1]=c;walk(c)end end;walk(self);return out end
 return o
end
assert(load(source))()(_G)
local world=item("Folder")
local character=item("Model",world)
local body=item("Part",character)
local layered=item("Accessory",character)
local handle=item("Part",layered)
local shirt=item("Shirt",character)
local other=item("Model",world)
local otherBody=item("Part",other)
local object=item("Model",world)
local part=item("Part",object)
local weld=item("WeldConstraint",object);weld.Name="BodyClothingJoint"
local detector=CleanupAttachmentDetector
for _,target in ipairs({body,handle})do
 weld.Part0=target;weld.Part1=part
 assert(detector:IsAttached(object,character))
 weld.Part0=part;weld.Part1=target
 assert(detector:IsAttached(object,character),'both endpoint directions')
end
weld.Part0=otherBody;weld.Part1=part
assert(not detector:IsAttached(object,character),'another player is not local clothing')
weld.Part0=body;weld.Part1=otherBody
assert(not detector:IsAttached(object,character),'must connect to the placed object')
weld.Part0=nil;weld.Part1=nil
local reference=item("ObjectValue",object);reference.Name="AttachParentObject"
for _,target in ipairs({body,layered,shirt})do
 reference.Value=target;assert(detector:IsAttached(object,character))
end
reference.Value=otherBody;assert(not detector:IsAttached(object,character))
reference.Value=nil;assert(not detector:IsAttached(object,character),'nearby objects alone do not qualify')
object.Parent=nil;assert(not detector:IsAttached(object,character))
print('cleanup_attachment_detector_spec OK: body, layered/classic clothing references, reversed joints, other players and unattached objects')
