local seatSource,numericSource=...
setfenv=function()end
local signals={}
local function signal()
 local callbacks={}
 local s={}
 function s:Connect(fn)
  local token={};callbacks[token]=fn
  return {Disconnect=function()callbacks[token]=nil end}
 end
 function s:Fire(...)local copy={};for token,fn in pairs(callbacks)do copy[token]=fn end;for token,fn in pairs(copy)do if callbacks[token]then fn(...)end end end
 function s:Count()local n=0;for _ in pairs(callbacks)do n=n+1 end;return n end
 signals[#signals+1]=s
 return s
end
local function instance(class,name,parent)
 local o={ClassName=class,Name=name,Parent=parent,Children={},Attributes={},Properties={},ChildAdded=signal(),ChildRemoved=signal(),DescendantAdded=signal(),DescendantRemoving=signal()}
 if parent then parent.Children[#parent.Children+1]=o end
 function o:IsA(c)return self.ClassName==c or (c=='JointInstance'and self.ClassName=='Weld')end
 function o:GetChildren()return self.Children end
 function o:GetDescendants()
  local result={}
  local function walk(item)for _,child in ipairs(item.Children)do result[#result+1]=child;walk(child)end end
  walk(self);return result
 end
 function o:FindFirstChild(n)for _,child in ipairs(self.Children)do if child.Name==n then return child end end end
 function o:FindFirstChildOfClass(c)for _,child in ipairs(self.Children)do if child:IsA(c)then return child end end end
 function o:GetFullName()return self.Parent and self.Parent:GetFullName()..'.'..self.Name or self.Name end
 function o:GetAttribute(k)return self.Attributes[k]end
 function o:GetPropertyChangedSignal(k)if not self.Properties[k]then self.Properties[k]=signal()end;return self.Properties[k]end
 return o
end
local function rig(name)
 local char=instance('Model',name)
 local h=instance('Humanoid','Humanoid',char)
 h.Health=100;h.Sit=false;h.Seated=signal();h.HealthChanged=signal();h.Died=signal()
 function h:GetState()return {Name='Running'}end
 local root=instance('Part','HumanoidRootPart',char)
 root.Position={X=0,Y=0,Z=0};root.AssemblyLinearVelocity={X=900000000,Y=0,Z=0};root.AssemblyAngularVelocity={X=0,Y=0,Z=0}
 root.CFrame={GetComponents=function()return 0,0,0,1,0,0,0,1,0,0,0,1 end}
 return char,h,root
end
workspace=instance('Workspace','Workspace')
local cars=instance('Folder','Cars',workspace)
local localChar,localH,localRoot=rig('local')
local targetChar,targetH=rig('dayzero777')
player={Name='local',UserId=1,Character=localChar}
local target={Name='dayzero777',UserId=11773278300,Character=targetChar}
Players={GetPlayerByUserId=function(_,id)if id==target.UserId then return target end end,
 GetPlayerFromCharacter=function(_,c)if c==localChar then return player elseif c==targetChar then return target end end}
target.Parent=Players
local vehicle=instance('Part','reused_car_name',cars);vehicle.Attributes.VehicleOwner=1
local seat=instance('Seat','Seat',vehicle)
local foreign=instance('Part','same_name',cars);foreign.Attributes.VehicleOwner=999
local foreignSeat=instance('Seat','Seat',foreign)
RunService={Heartbeat=signal()}
ExperimentalFlingCore={IsAuthorized=function()return true end}
assert(load(seatSource))()(_G)
assert(load(numericSource))()(_G)
local seats,numbers=SeatDiagnosticCore,NumericDiagnosticCore
assert(not seats.Running and not numbers.Running,'observers start disabled')
assert(seats:Start());assert(numbers:Start())
assert(seats:GetReport():find('VEHICLE_FOUND',1,true))
assert(not seats:GetReport():find('Workspace.Cars.same_name',1,true),'do not observe foreign owner vehicles')
assert(numbers:GetReport():find('ALL_SAMPLED_VALUES_FINITE',1,true),'900 million must not be labeled NaN')
seat.Occupant=targetH;targetH.Sit=true;targetH.SeatPart=seat
seat:GetPropertyChangedSignal('Occupant'):Fire()
local weld=instance('Weld','SeatWeld',seat);weld.Part0=seat;weld.Part1=targetChar:FindFirstChild('HumanoidRootPart')
seat.ChildAdded:Fire(weld)
targetH.Seated:Fire(true,seat)
targetH.HealthChanged:Fire(0);targetH.Died:Fire()
local report=seats:GetReport()
for _,label in ipairs({'OCCUPANT_CHANGED','SEATWELD_ADDED','HUMANOID_SEATED','HEALTH dayzero777=0','DIED dayzero777'})do assert(report:find(label,1,true),label)end
assert(seat.Occupant==targetH and weld.Part0==seat,'observation never changes seating or joints')
seat.ChildRemoved:Fire(weld)
assert(weld:GetPropertyChangedSignal('Part0'):Count()==0 and weld:GetPropertyChangedSignal('Part1'):Count()==0,'removed weld endpoint watchers must be released')
local ok,selftest=numbers:RunLocalTest()
assert(ok and selftest:find('finite=FINITE',1,true)and selftest:find('nan=NaN',1,true)and selftest:find('positiveInfinity=INFINITY',1,true))
assert(localRoot.AssemblyLinearVelocity.X==900000000 and localRoot.Position.X==0,'synthetic test does not touch physical objects')
localRoot.Position.X=0/0
numbers:Sample()
assert(numbers:GetReport():find('Position.X=NaN',1,true))
local count=#numbers.Lines;numbers:Sample();assert(#numbers.Lines==count,'unchanged invalid sample is not spammed')
localRoot.Position.X=0;numbers:Sample();assert(#numbers.Lines==count+1,'finite recovery is recorded')
for i=1,200 do targetH.HealthChanged:Fire(i)end
assert(#seats.Lines==160,'bounded observer log')
seats:Stop();numbers:Stop()
local seatCount=#seats.Lines
seat:GetPropertyChangedSignal('Occupant'):Fire();targetH.Died:Fire();RunService.Heartbeat:Fire(1)
assert(#seats.Lines==seatCount and RunService.Heartbeat:Count()==0,'stop disconnects all callbacks')
for _,s in ipairs(signals)do assert(s:Count()==0,'observer connection leaked')end
ExperimentalFlingCore.IsAuthorized=function()return false end
assert(not seats:Start()and not numbers:Start()and not numbers:RunLocalTest())
print('diagnostic_observers_spec OK: read-only seating, NaN self-test, bounded logs, owner scope and cleanup')
