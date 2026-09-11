-- Coordinador de Ancla automatica.
return function(context)
	setfenv(1,context)
	local Core={Mode=nil,Busy=false,Status=isES and "Ancla automática detenida." or "Automatic Anchor stopped."}
	local function update(text)
		Core.Status=text or Core.Status
		if UpdateAutoAnchorPanel then UpdateAutoAnchorPanel() end
	end
	local function enableAnchorSuite()
		local ok,err=AnchorCore:SetAncla(true)
		if not ok then return false,err end
		AnchorCore:SetAntiSeat(true)
		AnchorCore:SetHeartbeat(true)
		return true
	end
	local function disableAnchorSuite()
		AnchorCore:SetHeartbeat(false)
		AnchorCore:SetAntiSeat(false)
		AnchorCore:SetAncla(false)
	end
	function Core:Start(mode)
		if self.Busy then return false,isES and "Hay una operación en curso." or "An operation is in progress." end
		if self.Mode then return self.Mode==mode,self.Mode==mode and nil or (isES and "Desactiva primero el otro modo." or "Disable the other mode first.") end
		local engine=mode=="delta" and AutoSkateDelta or mode=="xeno" and AutoSkateXeno or nil
		if not engine then return false,"Modo inválido" end
		self.Busy=true
		update(isES and "Retirando el vehículo actual..." or "Removing current vehicle...")
		local removed,removeErr=engine:RemoveOwnedVehicle()
		if not removed then self.Busy=false; update(removeErr); return false,removeErr end
		update(isES and "Activando Ancla, AntiSeat y Heartbeat..." or "Enabling Anchor, AntiSeat and Heartbeat...")
		local ok,err=enableAnchorSuite()
		if not ok then self.Busy=false; update(err); return false,err end
		ok,err=engine:Start()
		if not ok then disableAnchorSuite(); self.Busy=false; update(err); return false,err end
		self.Mode=mode
		self.Busy=false
		update(mode=="delta" and (isES and "Ancla con asiento Delta activa." or "Delta Seat Anchor active.") or (isES and "Ancla con asiento Xeno activa." or "Xeno Seat Anchor active."))
		return true
	end
	function Core:PrepareForFling()
		if self.Busy then return false,isES and "Ancla automática está procesando una operación." or "Automatic Anchor is processing an operation." end
		local mode=self.Mode
		if not mode then return true end
		self.Busy=true
		update(isES and "Retirando el patín y conservando Ancla..." or "Removing skateboard and keeping Anchor...")
		local engine=mode=="delta" and AutoSkateDelta or AutoSkateXeno
		local removed,warning=engine:StopAndRemove()
		self.Mode=nil
		self.Busy=false
		if UpdateAnchorPanel then UpdateAnchorPanel() end
		local readyMessage=isES and "Ancla normal activa. Presiona nuevamente para iniciar el fling." or "Normal Anchor active. Press again to start the fling."
		update(readyMessage)
		if not removed then return false,warning or readyMessage end
		return false,readyMessage
	end
	function Core:PrepareForMotoFling()
		if self.Busy then return false,isES and "Ancla automática está procesando una operación." or "Automatic Anchor is processing an operation." end
		local mode=self.Mode
		local removed,warning=true,nil
		if mode then
			self.Busy=true
			update(isES and "Retirando el patín antes del fling con moto..." or "Removing skateboard before motorcycle fling...")
			local engine=mode=="delta" and AutoSkateDelta or AutoSkateXeno
			removed,warning=engine:StopAndRemove()
			self.Mode=nil
			self.Busy=false
		end
		disableAnchorSuite()
		if UpdateAnchorPanel then UpdateAnchorPanel() end
		update(isES and "Ancla desactivada; iniciando fling con moto." or "Anchor disabled; starting motorcycle fling.")
		return removed,warning
	end
	function Core:Stop()
		if self.Busy then return false,isES and "Hay una operación en curso." or "An operation is in progress." end
		local mode=self.Mode
		if not mode then disableAnchorSuite(); return true end
		self.Busy=true
		update(isES and "Retirando el patín..." or "Removing skateboard...")
		local engine=mode=="delta" and AutoSkateDelta or AutoSkateXeno
		local removed,warning=engine:StopAndRemove()
		update(isES and "Desactivando las protecciones de Ancla..." or "Disabling Anchor protections...")
		disableAnchorSuite()
		self.Mode=nil
		self.Busy=false
		update(removed and (isES and "Ancla automática detenida." or "Automatic Anchor stopped.") or (warning or (isES and "Patín retirado localmente; Ancla desactivada." or "Skateboard removed locally; Anchor disabled.")))
		return removed,warning
	end
	function Core:Toggle(mode)
		if self.Mode==mode then return self:Stop() end
		return self:Start(mode)
	end
	function Core:Destroy()
		if self.Mode or AutoSkateDelta.Enabled or AutoSkateXeno.Enabled then self:Stop() else disableAnchorSuite() end
		AutoSkateDelta:Destroy()
		AutoSkateXeno:Destroy()
	end
	AutoAnchorCore=Core
	return true
end
