local source=...
table.clear=function(t)for key in pairs(t)do t[key]=nil end end
local function signal()
 local items={};local event={}
 function event:Connect(fn)local c={Active=true};function c:Disconnect()self.Active=false end;items[#items+1]={c,fn};return c end
 function event:Fire(value)for _,item in ipairs(items)do if item[1].Active then item[2](value)end end end
 function event:Count()local count=0;for _,item in ipairs(items)do if item[1].Active then count=count+1 end end;return count end
 return event
end
local function control(kind,name)
 local b={Name=name or kind,Active=true,TextEditable=true,ZIndex=8,Parent=true}
 function b:IsA(c)return c==kind or(kind=='TextButton'and c=='GuiButton')end
 function b:FindFirstChildOfClass()end
 return b
end
local nodes={}
for _,name in ipairs({'ContactToggle','EmoteCard','AnimationPack','FlightToggle','SettingsTheme','Couples','HUDPause','UserShortcut','AdminDestination','FoldingTableCleanupToggle'})do nodes[#nodes+1]=control('GuiButton',name)end
local input=control('TextBox','AxisY');nodes[#nodes+1]=input
local readonly=control('TextBox','Readonly');readonly.Active=false;readonly.TextEditable=false;nodes[#nodes+1]=readonly
local minimize=control('GuiButton','Minimize');nodes[#nodes+1]=minimize
local close=control('GuiButton','Close');nodes[#nodes+1]=close
local launcher=control('GuiButton','WindowLauncher');nodes[#nodes+1]=launcher
local gui={DescendantAdded=signal(),Destroying=signal(),GetDescendants=function()return nodes end}
local calls={start=0,stop=0,axis=0,intensity=0,emote=0,pack=0,suspend=0,cleanup=0,restore=0}
local core={
 Start=function()calls.start=calls.start+1;return true end,
 Stop=function()calls.stop=calls.stop+1 end,
 SetAxis=function()calls.axis=calls.axis+1;return true end,
 SetIntensity=function()calls.intensity=calls.intensity+1;return true end,
}
local clean={Enabled=true,SetEnabled=function(self,v)self.Enabled=v;calls.cleanup=calls.cleanup+1;return true end}
local movement={SetWalkSpeed=function()return true end,RestoreWalkSpeed=function()calls.restore=calls.restore+1 end}
local inherited={FlightController={Start=function()return true end,Stop=function()end}}
local env=setmetatable({AdjustableContactFlingController=core,FutureController=core,FoldingCleanupCore=clean,MovementControlController=movement,
 gui=gui,minBtn=minimize,closeBtn=close,BackendAnchorGuard={FeaturesBlocked=true},
 PlayEmote=function()calls.emote=calls.emote+1;return true end,
 EquipAnimationPack=function()calls.pack=calls.pack+1;return true end,
 StopEmote=function()end,SuspendAnimationSelection=function()calls.suspend=calls.suspend+1 end,
 Instance={new=function()return {Activated=signal()}end},table=table,
 UDim2={fromScale=function()return {}end},Color3={new=function()return {}end}}, {__index=function(_,key)return inherited[key]or _G[key]end})
env.setfenv=function(_,e)debug.setupvalue(debug.getinfo(2,'f').func,1,e)end
assert(load(source,nil,'t',env))()(env)
assert(calls.stop==1,'controller aliases are stopped only once')
assert(env.AreFeaturesBlocked()and not input.Active and not input.TextEditable,'cached block applies immediately')
for _,button in ipairs(nodes)do
 if button~=minimize and button~=close and button~=launcher then assert(not button.Active,'every GUI section is blocked: '..button.Name)end
end
assert(minimize.Active and close.Active and launcher.Active,'window controls remain usable')
assert(not env.FlightController:Start(),'controllers exposed by the loader metatable are also blocked')
assert(not core:Start()and not core:SetAxis('Y',1)and not core:SetIntensity(1))
assert(not env.PlayEmote(1)and not env.EquipAnimationPack({})and not movement:SetWalkSpeed(100),'keyboard/automatic entry points cannot bypass the UI block')
assert(calls.start==0 and calls.axis==0 and calls.intensity==0 and calls.emote==0 and calls.pack==0)
assert(not clean.Enabled and not clean:SetEnabled(true),'cleanup now participates in the whole GUI block')
assert(calls.restore==1 and calls.suspend==1,'active movement and animation selection are suspended')
local late=control('TextBox','LateInput');gui.DescendantAdded:Fire(late)
assert(not late.Active and not late.TextEditable,'new controls inherit an active block immediately')
local lateLauncher=control('TextButton','WindowLauncher');gui.DescendantAdded:Fire(lateLauncher)
assert(lateLauncher.Active,'launcher created after initialization remains draggable')
env.ApplyFeatureBlock(false)
assert(not env.AreFeaturesBlocked()and input.Active and input.TextEditable and late.Active and late.TextEditable,'unlock restores existing and newly created controls')
assert(not readonly.Active and not readonly.TextEditable,'unlock preserves initially disabled/readonly inputs')
assert(calls.start==0,'unlock never starts stopped functions automatically')
assert(core:Start()and core:SetAxis('Y',1)and core:SetIntensity(1)and env.PlayEmote(1)and env.EquipAnimationPack({})and clean:SetEnabled(true))
assert(calls.start==1 and calls.axis==1 and calls.intensity==1 and calls.emote==1 and calls.pack==1)
env.ApplyFeatureBlock(true);assert(calls.stop==2,'locking active functions stops them again')
env.ApplyFeatureBlock(true);assert(calls.stop==2,'unchanged backend heartbeats do not repeat cleanup')
gui.Destroying:Fire();assert(gui.DescendantAdded:Count()==0 and gui.Destroying:Count()==0,'GUI close disconnects availability listeners')
print('Feature permissions OK: whole GUI, cleanup, future controls, internal guards, startup block, restoration, deduplication and listener cleanup')
