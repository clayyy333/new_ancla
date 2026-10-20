-- Feature availability, not remote character control. No messages or dialogs.
return function(context)
	setfenv(1,context)
	local blocked=false
	local buttons={}
	local cores={}
	if DeploymentSafetyCore then
		cores[#cores+1]=DeploymentSafetyCore
		local original=DeploymentSafetyCore.Start
		DeploymentSafetyCore.Start=function(self,...)if blocked then return false end;return original(self,...)end
		local mobile=DeploymentSafetyCore.SetMobileEnabled
		DeploymentSafetyCore.SetMobileEnabled=function(self,value)if blocked and value then return false end;return mobile(self,value)end
	end
	if ExperimentalFlingCore then
		local start=ExperimentalFlingCore.Start
		ExperimentalFlingCore.Start=function(self,...)if blocked then return false end;return start(self,...)end
		cores[#cores+1]=ExperimentalFlingCore
	end
	for _,name in ipairs({"AnchorCore","AutoAnchorCore","StaticPassThroughAnchorCore","MobileAnchorCore","MobileAnchorV11Core","EmergencyAnchorController","Fling2AutoController","Fling2Core","Fling2EfficientCore","CustomFlingCore","ContactFlingController","MotoFlingCore","MotoFlingXenoCore","CarFling","CarFlingXeno","CarFling2Delta","CarFling2Xeno","ObjectFling2Delta","ObjectFling2Xeno"}) do
		local core=context[name]
		if core then
			cores[#cores+1]=core
			for _,method in ipairs({"Start","SetAncla","SetAntiSeat","SetHeartbeat","SetTest","SetEnabled","SetPhase"}) do
				local original=core[method]
				if type(original)=="function" then
					core[method]=function(self,...)
						local value=select(1,...)
						if blocked and (method=="Start" or value==true) then return false end
						return original(self,...)
					end
				end
			end
		end
	end
	local function protect(button)
		-- Cleanup is local opt-in only; the backend observes but never controls it.
		if button.Name=="FoldingTableCleanupToggle" then return end
		if not button:IsA("GuiButton") or buttons[button] or button.Name=="FeatureBlockShade" then return end
		local shade=Instance.new("TextButton")
		shade.Name="FeatureBlockShade";shade.Size=UDim2.fromScale(1,1);shade.Text=""
		shade.BackgroundColor3=Color3.new(0,0,0);shade.BackgroundTransparency=.45
		shade.BorderSizePixel=0;shade.AutoButtonColor=false;shade.Active=true
		shade.ZIndex=button.ZIndex+50;shade.Visible=blocked
		local corner=button:FindFirstChildOfClass("UICorner")
		if corner then corner:Clone().Parent=shade end
		buttons[button]={shade=shade,active=button.Active}
		shade.Parent=button;shade.Activated:Connect(function() end)
	end
	if experimentalFlingPanel then
		for _,b in ipairs(experimentalFlingPanel:GetDescendants())do protect(b)end
		experimentalFlingPanel.DescendantAdded:Connect(protect)
	end
	for _,name in ipairs({"anchorPanel","moveAnchoredPanel","autoAnchorPanel","fling2Panel","customFlingPanel","contactFlingPanel","carFlingPanel","carFling2Panel","objectFlingPanel","motoFlingPanel","motoFlingXenoPanel"}) do
		local panel=context[name]
		if panel then
			for _,b in ipairs(panel:GetDescendants()) do protect(b) end
			panel.DescendantAdded:Connect(protect)
		end
	end
	ApplyFeatureBlock=function(value)
		value=value==true
		if value==blocked then return end
		blocked=value
		if blocked then
			for _,core in ipairs(cores) do
				if type(core.Stop)=="function" then pcall(core.Stop,core) end
				for _,method in ipairs({"SetPhase","SetTest","SetHeartbeat","SetAntiSeat","SetAncla","SetEnabled"}) do
					if type(core[method])=="function" then pcall(core[method],core,false) end
				end
			end
		end
		for button,state in pairs(buttons) do
			if button.Parent then
				state.shade.Visible=blocked
				if blocked then button.Active=false else button.Active=state.active end
			else buttons[button]=nil end
		end
	end
	if BackendAnchorGuard then ApplyFeatureBlock(BackendAnchorGuard.FeaturesBlocked) end
	return true
end
