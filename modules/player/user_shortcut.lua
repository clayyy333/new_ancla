-- Estado y ciclo de vida del atajo de selección de usuarios.
return function(context)
	setfenv(1,context)
	local Core={Enabled=Settings.userShortcut==true,InputConnection=nil,Modal=nil,Destroyed=false}
	function Core:SetEnabled(enabled)
		self.Enabled=enabled==true
		Settings.userShortcut=self.Enabled
		if not self.Enabled and self.Modal then self.Modal.Visible=false end
		return self.Enabled
	end
	function Core:IsEnabled() return self.Enabled end
	function Core:Destroy()
		self.Destroyed=true
		if self.InputConnection then self.InputConnection:Disconnect();self.InputConnection=nil end
		if self.Modal then self.Modal:Destroy();self.Modal=nil end
	end
	UserShortcutController=Core
	return true
end