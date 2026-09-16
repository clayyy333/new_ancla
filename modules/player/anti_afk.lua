-- Anti-AFK sin interfaz independiente; compatible con Xeno y Delta.
return function(context)
	setfenv(1, context)
	local VirtualUser = game:GetService("VirtualUser")
	local INTERACTION_INTERVAL = 600
	AntiAFKController = {Enabled=false, _session=0, _idledConnection=nil, _destroyed=false}
	function AntiAFKController:_Interact()
		if not self.Enabled or self._destroyed then return false end
		return pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new(0,0))
		end)
	end
	function AntiAFKController:_Schedule(session)
		task.delay(INTERACTION_INTERVAL,function()
			if self._destroyed or not self.Enabled or session~=self._session then return end
			self:_Interact()
			self:_Schedule(session)
		end)
	end
	function AntiAFKController:SetEnabled(enabled)
		if self._destroyed then return false end
		enabled=enabled==true
		self._session=self._session+1
		if self._idledConnection then self._idledConnection:Disconnect();self._idledConnection=nil end
		self.Enabled=enabled
		if not enabled then return true end
		local session=self._session
		self._idledConnection=player.Idled:Connect(function()
			if self.Enabled and session==self._session then self:_Interact() end
		end)
		self:_Schedule(session)
		return true
	end
	function AntiAFKController:Destroy()
		if self._destroyed then return end
		self:SetEnabled(false)
		self._destroyed=true
	end
	AntiAFKController:SetEnabled(Settings.antiAFK==true)
	return true
end