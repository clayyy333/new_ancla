-- Flujo de regalos integrado. Conserva seleccion persistente por UserId,
-- autoseleccion, reconexiones, envio continuo y limpieza no bloqueante.
return function(context)
	setfenv(1,context)

	local Remotes=game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
	local EquipRF=Remotes:WaitForChild("EquipToolRF")
	local GiftRE=Remotes:WaitForChild("InteractGiftRE")
	local ClearRE=Remotes:FindFirstChild("ClearToolRE")
	local ITEMS={"Babycar_a","Whistle","FoolBall","LedText","Lightstick","SignText","Skates2"}
	local OWNER_RECIPIENT_IDS={
		[11739864999]=true,
		[11743514302]=true,
		[11747901934]=true,
		[11794166113]=true,
		[11797966007]=true,
		[11866242235]=true,
	}
	local BOX="GiftBox5"
	local EQUIP_TIMEOUT=4
	local MIN_REQUEST_GAP=.15
	local RECIPIENT_COOLDOWN=4.25
	local OBSERVE_TIMEOUT=5
	local RETRY_EQUIP_PENDING=.05
	local POLL=.02

	local Core={
		Items=ITEMS,Item=ITEMS[1],Running=false,State="DETENIDO",AutoSelect=false,
		Allowed=not(BackendAnchorGuard and BackendAnchorGuard.GiftDeliveryBlocked==true),
		Selected={},SelectedOrder={},Generation=0,Alive=true,AntiEnabled=false,
		AntiDetected=0,AntiRemoved=0,AntiFailures=0,_changed=Instance.new("BindableEvent")
	}
	local nextRecipientIndex=1
	local lastSendAt=-math.huge
	local lastRecipientId=nil
	local recipientReadyAt={}
	local equipBusy=false
	local monitors=0
	local MAX_MONITORS=8
	local connections={}
	local busyUiConnections={}
	local busyUiSeen=setmetatable({},{__mode="k"})
	local busyUiReported=setmetatable({},{__mode="k"})

	local function connect(signal,fn,bucket)
		local c=signal:Connect(fn);table.insert(bucket or connections,c);return c
	end
	local function disconnect(bucket)
		for _,c in pairs(bucket)do pcall(function()c:Disconnect()end)end
		table.clear(bucket)
	end
	local function changed() Core._changed:Fire() end
	local function valid(token)return Core.Alive and Core.Running and Core.Generation==token end
	local function containers(p)
		local result={};if not p then return result end
		local backpack=p:FindFirstChildOfClass("Backpack");if backpack then result[#result+1]=backpack end
		if p.Character then result[#result+1]=p.Character end
		return result
	end
	local function snapshot(p,itemName)
		local result={}
		for _,container in ipairs(containers(p))do
			for _,obj in ipairs(container:GetChildren())do
				if obj:IsA("Tool")and obj.Name==(itemName or Core.Item)then result[obj]=true end
			end
		end
		return result
	end
	local function countItems(p,itemName)local n=0;for _ in pairs(snapshot(p,itemName))do n+=1 end;return n end
	local function waitUntil(fn,timeout,token)
		local started=os.clock()
		while valid(token)do
			local ok,result=pcall(fn);if ok and result then return true end
			if os.clock()-started>=timeout then return false end
			task.wait(.05)
		end
		return false
	end
	local function waitControlled(seconds,token)
		local deadline=os.clock()+seconds
		while valid(token)and os.clock()<deadline do task.wait(math.min(.1,deadline-os.clock()))end
		return valid(token)
	end
	local function busyText(value)
		local text=string.lower(tostring(value or""))
		return string.find(text,"ocupado",1,true)~=nil or string.find(text,"busy",1,true)~=nil
	end
	local function visiblyDisplayed(obj)
		local current=obj
		while current and current~=playerGui do
			if current:IsA("GuiObject")and not current.Visible then return false end
			if current:IsA("ScreenGui")and not current.Enabled then return false end
			current=current.Parent
		end
		return current==playerGui
	end
	local function inspectBusy(obj)
		if not Core.Alive or not(obj:IsA("TextLabel")or obj:IsA("TextButton"))then return end
		if not obj:IsDescendantOf(playerGui)or(giftDeliveryPanel and obj:IsDescendantOf(giftDeliveryPanel))then return end
		local ok,text=pcall(function()return obj.Text end)
		if not ok or not busyText(text)or not visiblyDisplayed(obj)then return end
		local now=os.clock();if busyUiReported[obj]and now-busyUiReported[obj]<.35 then return end
		busyUiReported[obj]=now
		if lastRecipientId then recipientReadyAt[lastRecipientId]=math.max(recipientReadyAt[lastRecipientId]or 0,now+RECIPIENT_COOLDOWN)end
	end
	local function watchBusy(obj)
		if busyUiSeen[obj]or not(obj:IsA("TextLabel")or obj:IsA("TextButton"))then return end
		busyUiSeen[obj]=true
		connect(obj:GetPropertyChangedSignal("Text"),function()inspectBusy(obj)end,busyUiConnections)
		connect(obj:GetPropertyChangedSignal("Visible"),function()inspectBusy(obj)end,busyUiConnections)
		inspectBusy(obj)
	end
	for _,obj in ipairs(playerGui:GetDescendants())do watchBusy(obj)end
	connect(playerGui.DescendantAdded,watchBusy,busyUiConnections)

	function Core:OnChanged(fn)return self._changed.Event:Connect(fn)end
	function Core:GetSelectedCount()return #self.SelectedOrder end
	function Core:IsSelected(id)return self.Selected[id]~=nil end
	function Core:IsOwnerRecipient(id)return OWNER_RECIPIENT_IDS[tonumber(id)]==true end
	function Core:GetPlayers()
		local result={}
		for _,candidate in ipairs(Players:GetPlayers())do if candidate~=player and not self:IsOwnerRecipient(candidate.UserId)then result[#result+1]=candidate end end
		table.sort(result,function(a,b)return a.Name:lower()<b.Name:lower()end);return result
	end
	function Core:AddPlayer(candidate)
		if not candidate or candidate==player or self:IsOwnerRecipient(candidate.UserId)or self.Selected[candidate.UserId]then return false end
		self.Selected[candidate.UserId]=candidate.Name;self.SelectedOrder[#self.SelectedOrder+1]=candidate.UserId;changed();return true
	end
	function Core:RemovePlayer(candidate)
		if not candidate or not self.Selected[candidate.UserId]then return false end
		self.Selected[candidate.UserId]=nil
		for i,id in ipairs(self.SelectedOrder)do if id==candidate.UserId then table.remove(self.SelectedOrder,i)break end end
		if self.Running and #self.SelectedOrder==0 then self:Stop()end
		changed();return true
	end
	function Core:TogglePlayer(candidate)
		if self:IsSelected(candidate.UserId)then return self:RemovePlayer(candidate)end
		return self:AddPlayer(candidate)
	end
	function Core:SetSelectAll(enabled)
		self.AutoSelect=enabled==true
		if self.AutoSelect then for _,candidate in ipairs(self:GetPlayers())do self:AddPlayer(candidate)end
		else table.clear(self.Selected);table.clear(self.SelectedOrder);if self.Running then self:Stop()end end
		changed()
	end
	function Core:SetItem(name)
		for _,allowed in ipairs(ITEMS)do if allowed==name then self.Item=name;changed();return true end end
		return false
	end

	local function chooseRecipient()
		if #Core.SelectedOrder==0 then return nil end
		if nextRecipientIndex>#Core.SelectedOrder then nextRecipientIndex=1 end
		for _=1,#Core.SelectedOrder do
			local id=Core.SelectedOrder[nextRecipientIndex];nextRecipientIndex=(nextRecipientIndex%#Core.SelectedOrder)+1
			local candidate=Players:GetPlayerByUserId(id)
			if candidate and not Core:IsOwnerRecipient(id)and Core.Selected[id]and os.clock()>=(recipientReadyAt[id]or 0)then return{id=id,name=candidate.Name,player=candidate}end
		end
	end
	local function obtain(token,itemName)
		if countItems(player,itemName)>0 then return true end
		Core.State="OBTENIENDO";changed()
		local ok,result=pcall(function()return EquipRF:InvokeServer(itemName)end)
		if not valid(token)then return false,"cancelled"end
		if not ok then return false,"error"end
		if result==false then return false,"pending"end
		local appeared=waitUntil(function()return countItems(player,itemName)>0 end,EQUIP_TIMEOUT,token)
		return appeared,appeared and nil or "pending"
	end
	local function ensureStock(token,itemName)
		if countItems(player,itemName)>0 then return true end
		if equipBusy then return false,"pending"end
		equipBusy=true;local ok,reason=obtain(token,itemName);equipBusy=false;return ok,reason
	end
	local function observeAsync(token,recipient,sourceBefore,targetBefore,itemName)
		monitors+=1
		task.spawn(function()
			local deadline=os.clock()+OBSERVE_TIMEOUT
			while valid(token)and os.clock()<deadline do
				local targetObserved=false
				for obj in pairs(snapshot(recipient.player,itemName))do if not targetBefore[obj]then targetObserved=true break end end
				local sourceRemoved=false;local current=snapshot(player,itemName)
				for obj in pairs(sourceBefore)do if not current[obj]then sourceRemoved=true break end end
				if targetObserved and sourceRemoved then break end
				if Players:GetPlayerByUserId(recipient.id)~=recipient.player then break end
				task.wait(POLL)
			end
			monitors=math.max(0,monitors-1)
		end)
	end
	local function runRound(token)
		local itemName=Core.Item
		local recipient=chooseRecipient()
		if not recipient then Core.State="ESPERANDO JUGADORES";changed();return"waiting"end
		if monitors>=MAX_MONITORS then return"monitor_pending"end
		local obtained,reason=ensureStock(token,itemName)
		if not obtained then return reason=="pending"and"equip_pending"or"equip_failed"end
		local remaining=MIN_REQUEST_GAP-(os.clock()-lastSendAt)
		if remaining>0 and not waitControlled(remaining,token)then return"cancelled"end
		if not valid(token)then return"cancelled"end
		if Players:GetPlayerByUserId(recipient.id)~=recipient.player then return"waiting"end
		local sourceBefore=snapshot(player,itemName);local targetBefore=snapshot(recipient.player,itemName)
		Core.State="ENVIANDO CONTINUO";changed()
		local ok=pcall(function()GiftRE:FireServer({Action="GiveGift",TargetUserId=recipient.id,ToolId=itemName,GiftBox=BOX})end)
		lastSendAt=os.clock()
		lastRecipientId=recipient.id
		recipientReadyAt[recipient.id]=lastSendAt+RECIPIENT_COOLDOWN
		if not ok then return"unconfirmed"end
		observeAsync(token,recipient,sourceBefore,targetBefore,itemName)
		return"complete"
	end
	local function runLoop(token)
		while valid(token)do
			local result=runRound(token)
			if result=="cancelled"then break
			elseif result=="equip_failed"then break
			elseif result=="equip_pending"then Core.State="ESPERANDO SIGUIENTE OBJETO";changed();waitControlled(RETRY_EQUIP_PENDING,token)
			elseif result=="waiting"or result=="monitor_pending"then waitControlled(.1,token)
			elseif result=="unconfirmed"then waitControlled(.15,token)
			elseif result=="complete"then
				if countItems(player)==0 and not equipBusy then task.spawn(function()if valid(token)then ensureStock(token)end end)end
				task.wait()
			end
		end
		if Core.Generation==token then Core.Running=false;Core.State="DETENIDO";changed()end
	end
	function Core:Start()
		if not self.Allowed then return false,isES and"Regalos desactivado por el administrador."or"Gifts disabled by the administrator."end
		if self.Running then return true end
		if #self.SelectedOrder<1 then return false,isES and"Selecciona al menos un jugador."or"Select at least one player."end
		self.Generation+=1;local token=self.Generation;self.Running=true;self.State="INICIANDO";changed()
		task.spawn(function()local ok=xpcall(function()runLoop(token)end,debug.traceback);if not ok and self.Generation==token then self.Running=false;self.State="DETENIDO";changed()end end)
		return true
	end
	function Core:Stop()self.Running=false;self.Generation+=1;self.State="DETENIDO";changed()end
	function Core:SetAllowed(allowed)
		self.Allowed=allowed==true
		if not self.Allowed then self:Stop();if self.AntiEnabled then self:SetAntiEnabled(false)end end
		changed()
	end

	local antiEpoch=0;local antiExisting={};local antiSeen={};local antiPending={};local antiConnections={};local antiToolConnections={};local antiBusy=false;local antiOwner=nil
	local function antiProtected(tool)for _,name in ipairs(ITEMS)do if tool.Name==name then return true end end;return false end
	local function antiLocation(tool)local char=player.Character;local backpack=player:FindFirstChildOfClass("Backpack");return(char and tool.Parent==char)or(backpack and tool.Parent==backpack)end
	local function antiValid(epoch,tool)return Core.Alive and Core.AntiEnabled and antiEpoch==epoch and tool and antiLocation(tool)and not antiExisting[tool]and not antiProtected(tool)and tool:GetAttribute("IsGift")==true end
	local function antiIsEquipped(tool,char)
		if tool.Parent~=char then return false end
		for _,item in ipairs(char:GetChildren())do if item:IsA("Tool")and item~=tool then return false end end
		return true
	end
	local antiAttempt
	antiAttempt=function(tool,epoch)
		if antiBusy or not antiValid(epoch,tool)then return end
		ClearRE=ClearRE or Remotes:FindFirstChild("ClearToolRE");if not ClearRE then Core.AntiFailures+=1;changed();return end
		local gate=rawget(context,"CleanupToolGate");local gateToken
		if gate and type(gate.Acquire)=="function"then local ok,result=pcall(function()return gate:Acquire("GiftDeliveryCleanup")end);if not ok or not result then return end;gateToken=result elseif antiOwner then return end
		antiOwner=tool;antiBusy=true
		task.spawn(function()
			local removed=false
			pcall(function()
				local char=player.Character;local humanoid=char and char:FindFirstChildOfClass("Humanoid");if not humanoid or not antiValid(epoch,tool)then return end
				if tool.Parent~=char then humanoid:EquipTool(tool)end
				local deadline=os.clock()+1.5;while antiValid(epoch,tool)and tool.Parent~=char and os.clock()<deadline do RunService.Heartbeat:Wait()end
				if not antiValid(epoch,tool)or not antiIsEquipped(tool,char)then return end
				ClearRE:FireServer(true);local timeout=os.clock()+1.5;while Core.Alive and antiEpoch==epoch and tool.Parent~=nil and os.clock()<timeout do RunService.Heartbeat:Wait()end;removed=tool.Parent==nil
			end)
			if gate and gateToken then pcall(function()gate:Release(gateToken)end)end
			antiOwner=nil;antiBusy=false;antiPending[tool]=nil
			if removed then Core.AntiRemoved+=1 else Core.AntiFailures+=1 end;changed()
			for candidate in pairs(antiPending)do if antiValid(epoch,candidate)then task.defer(antiAttempt,candidate,epoch)break else antiPending[candidate]=nil end end
		end)
	end
	local function antiConsider(tool,epoch)
		if not antiValid(epoch,tool)or antiSeen[tool]then return end
		antiSeen[tool]=true;Core.AntiDetected+=1;antiPending[tool]=true;changed();if not antiBusy then task.defer(antiAttempt,tool,epoch)end
	end
	local function antiWatch(tool,epoch)
		if not tool:IsA("Tool")or antiExisting[tool]or antiProtected(tool)or antiToolConnections[tool]then return end
		antiToolConnections[tool]=tool:GetAttributeChangedSignal("IsGift"):Connect(function()antiConsider(tool,epoch)end);antiConsider(tool,epoch)
	end
	local function antiStop()
		Core.AntiEnabled=false;antiEpoch+=1;disconnect(antiConnections);for _,c in pairs(antiToolConnections)do pcall(function()c:Disconnect()end)end;table.clear(antiToolConnections);table.clear(antiPending);changed()
	end
	local function antiStart()
		antiStop();Core.AntiEnabled=true;local epoch=antiEpoch;table.clear(antiExisting);table.clear(antiSeen)
		for _,container in ipairs(containers(player))do for _,item in ipairs(container:GetChildren())do if item:IsA("Tool")then antiExisting[item]=true end end end
		local watched={};local function watchContainer(container)if not container or watched[container]then return end;watched[container]=true;connect(container.ChildAdded,function(item)if Core.AntiEnabled and antiEpoch==epoch then antiWatch(item,epoch)end end,antiConnections)end
		for _,container in ipairs(containers(player))do watchContainer(container)end
		connect(player.CharacterAdded,function(char)if Core.AntiEnabled and antiEpoch==epoch then watchContainer(char)end end,antiConnections)
		connect(player.ChildAdded,function(child)if Core.AntiEnabled and antiEpoch==epoch and child:IsA("Backpack")then watchContainer(child)end end,antiConnections);changed()
	end
	function Core:SetAntiEnabled(enabled)if enabled then antiStart()else antiStop()end end
	function Core:Destroy()
		if not self.Alive then return end
		self:Stop();antiStop();self.Alive=false;disconnect(busyUiConnections);disconnect(connections);self._changed:Destroy()
	end

	connect(Players.PlayerAdded,function(candidate)
		if candidate==player then return end
		if Core:IsOwnerRecipient(candidate.UserId)then
			Core.Selected[candidate.UserId]=nil
			for i,id in ipairs(Core.SelectedOrder)do if id==candidate.UserId then table.remove(Core.SelectedOrder,i)break end end
		elseif Core.Selected[candidate.UserId]then Core.Selected[candidate.UserId]=candidate.Name elseif Core.AutoSelect then Core:AddPlayer(candidate)end;changed()
	end)
	connect(Players.PlayerRemoving,function()changed()end)
	GiftDeliveryCore=Core
	return true
end
