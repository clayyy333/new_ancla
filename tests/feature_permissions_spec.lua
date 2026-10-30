local source=...
local function signal()return {Connect=function()return {Disconnect=function()end}end}end
local function control(kind,name)
 local b={Name=name or kind,Active=true,TextEditable=true,ZIndex=8,Parent=true}
 function b:IsA(c)return c==kind end
 function b:FindFirstChildOfClass()end
 return b
end
local toggle=control('GuiButton','ContactToggle')
local input=control('TextBox','AxisY')
local cleanup=control('GuiButton','FoldingTableCleanupToggle')
local panel={DescendantAdded=signal(),GetDescendants=function()return {toggle,input,cleanup}end}
local calls={start=0,stop=0,axis=0,intensity=0}
local core={
 Start=function()calls.start=calls.start+1;return true end,
 Stop=function()calls.stop=calls.stop+1 end,
 SetAxis=function()calls.axis=calls.axis+1;return true end,
 SetIntensity=function()calls.intensity=calls.intensity+1;return true end,
}
local env=setmetatable({AdjustableContactFlingController=core,contactFlingPanel=panel,BackendAnchorGuard={FeaturesBlocked=true},
 Instance={new=function()return {Activated=signal()}end},
 UDim2={fromScale=function()return {}end},Color3={new=function()return {}end}}, {__index=_G})
env.setfenv=function(_,e)debug.setupvalue(debug.getinfo(2,'f').func,1,e)end
assert(load(source,nil,'t',env))()(env)
assert(calls.stop==1 and not toggle.Active and not input.Active and not input.TextEditable,'cached block applied at GUI startup')
assert(not core:Start()and not core:SetAxis('Y',1)and not core:SetIntensity(1))
assert(calls.start==0 and calls.axis==0 and calls.intensity==0,'activation and settings blocked internally')
assert(cleanup.Active,'cleanup exemption preserved')
env.ApplyFeatureBlock(false)
assert(toggle.Active and input.Active and input.TextEditable,'controls restore after unlock')
assert(core:Start()and core:SetAxis('Y',1)and core:SetIntensity(1))
assert(calls.start==1 and calls.axis==1 and calls.intensity==1)
env.ApplyFeatureBlock(true)
assert(calls.stop==2,'locking active mode stops it')
print('Feature permissions OK: startup block, silent rejection, inputs, adjustable settings, cleanup exemption and unlock')
