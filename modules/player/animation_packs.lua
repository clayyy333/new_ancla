-- Paquetes completos y mezcla de estados de Animate, sin tocar emotes externos.
return function(context)
	setfenv(1, context)

	local states={
		Idle={"idle"},Walk={"walk"},Run={"run"},Jump={"jump"},
		Fall={"fall"},Climb={"climb"},Swim={"swim","swimidle"}
	}
	local stateOrder={"Idle","Walk","Run","Jump","Fall","Climb","Swim"}
	local selected={}
	local originals={}
	local originalAnimate=nil
	local request=0
	local resolvedCache={}
	local bundleCache={}
	local ownershipConnections={}
	local animationIdConnections={}
	local desiredFolders={}
	local reconcileQueued={}
	local reconciling={}
	local ownershipAnimate=nil
	local function persistSelection()
		local saved={}
		for _,state in ipairs(stateOrder) do
			local entry=selected[state]
			if entry and tonumber(entry.id) then saved[state]={id=tonumber(entry.id),name=tostring(entry.name or "")} end
		end
		Settings.animationPackSelection=saved
		SaveLocalData()
	end
	-- Este paquete llega con un orden distinto en bundledItems; IDs comprobados por tipo.
	local verifiedPacks={
		[226897222628299]={
			Idle=79638430446468,Walk=125935884379030,Run=140668178711040,
			Jump=121044668035612,Fall=90121153486837,
			Climb=107026478538282,Swim=74464049474878
		}
	}
	local assetTypes={
		IdleAnimation="Idle",WalkAnimation="Walk",RunAnimation="Run",
		JumpAnimation="Jump",FallAnimation="Fall",ClimbAnimation="Climb",SwimAnimation="Swim",
		["51"]="Idle",["55"]="Walk",["53"]="Run",["52"]="Jump",
		["50"]="Fall",["48"]="Climb",["54"]="Swim"
	}

	local function getPackStates(pack)
		if not pack.bundleId then return pack end -- Paquetes de respaldo con IDs ya clasificados.
		if verifiedPacks[pack.bundleId] then return verifiedPacks[pack.bundleId] end
		if bundleCache[pack.bundleId] then return bundleCache[pack.bundleId] end
		local mapped={}
		local ok,details=pcall(function()
			return game:GetService("AssetService"):GetBundleDetailsAsync(pack.bundleId)
		end)
		if ok and type(details)=="table" and type(details.Items)=="table" then
			for _,item in ipairs(details.Items) do
				local state=assetTypes[tostring(item.AssetType)]
				if state and tonumber(item.Id) then mapped[state]=tonumber(item.Id) end
			end
		end
		-- Si el ejecutor bloquea AssetService, validar cada ID guardado por su tipo real.
		if not mapped.Idle and not mapped.Walk then
			local marketplace=game:GetService("MarketplaceService")
			for _,items in pairs(pack.bundledItems or {}) do
				local id=type(items)=="table" and tonumber(items[1]) or tonumber(items)
				if id then
					local success,info=pcall(function()
						return marketplace:GetProductInfoAsync(id,Enum.InfoType.Asset)
					end)
					if success and type(info)=="table" then
						local state=assetTypes[tostring(info.AssetTypeId)]
						if state then mapped[state]=id end
					end
				end
			end
		end
		if not mapped.Idle and not mapped.Walk then
			warn("[Animations] Could not identify bundle items: "..tostring(pack.bundleId))
			return nil
		end
		bundleCache[pack.bundleId]=mapped
		return mapped
	end

	local function getAnimate()
		local character=player.Character
		return character and character:FindFirstChild("Animate")
	end

	local function captureOriginal(animate)
		if originalAnimate==animate then return end
		originalAnimate=animate
		originals={}
		for _,folders in pairs(states) do
			for _,name in ipairs(folders) do
				local folder=animate:FindFirstChild(name)
				if folder then
					local copies={}
					for _,child in ipairs(folder:GetChildren()) do
						if child:IsA("Animation") then copies[#copies+1]=child:Clone() end
					end
					originals[name]=copies
				end
			end
		end
	end

	local function restoreOriginal(animate)
		if originalAnimate~=animate then return end
		for name,copies in pairs(originals) do
			local folder=animate:FindFirstChild(name)
			if folder then
				for _,child in ipairs(folder:GetChildren()) do
					if child:IsA("Animation") then child:Destroy() end
				end
				for _,copy in ipairs(copies) do copy:Clone().Parent=folder end
			end
		end
	end

	local function resolveIds(catalogId,state)
		local key=state..":"..tostring(catalogId)
		if resolvedCache[key] then return resolvedCache[key] end
		local ids={}
		local matchingIds={}
		local swimIdleIds={}
		local ok,objects=pcall(function()
			return game:GetObjects("rbxassetid://"..tostring(catalogId))
		end)
		if ok and objects then
			local function scan(instance)
				if instance:IsA("Animation") and instance.AnimationId~="" then
					ids[#ids+1]=instance.AnimationId
					local parentName=instance.Parent and instance.Parent.Name or ''
					local clipName=(instance.Name..' '..parentName):lower()
					local wanted=state:lower()
					if (state=='Swim' and clipName:find('swim') and not clipName:find('idle')) or (state~='Swim' and (clipName:find(wanted) or (state=='Idle' and clipName:find('pose')))) then
						matchingIds[#matchingIds+1]=instance.AnimationId
					end
					if state=='Swim' and clipName:find('swim') and clipName:find('idle') then
						swimIdleIds[#swimIdleIds+1]=instance.AnimationId
					end
				end
				for _,child in ipairs(instance:GetChildren()) do scan(child) end
			end
			for _,object in ipairs(objects) do scan(object);object:Destroy() end
		end
		if #matchingIds>0 then ids=matchingIds end
		if #ids==0 then ids[1]="rbxassetid://"..tostring(catalogId) end
		-- Animate solo debe recibir un clip por estado; Idle admite dos variantes.
		if state == 'Idle' then
			while #ids > 2 do table.remove(ids) end
		elseif state == 'Swim' then
			local moving=ids[1]
			ids={moving}
			if swimIdleIds[1] then ids[2]=swimIdleIds[1] end
		else
			while #ids > 1 do table.remove(ids) end
		end
		resolvedCache[key]=ids
		return ids
	end

	local function stopOutgoingTracks(animate)
		local character=animate.Parent
		local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		local animator=humanoid and humanoid:FindFirstChildOfClass("Animator")
		if not animator then return end
		local instances={}
		local ids={}
		for _,folders in pairs(states) do
			for _,name in ipairs(folders) do
				local folder=animate:FindFirstChild(name)
				if folder then
					for _,child in ipairs(folder:GetChildren()) do
						if child:IsA("Animation") then
							instances[child]=true
							local id=child.AnimationId:match("%d+")
							if id then ids[id]=true end
						end
					end
				end
			end
		end
		for _,track in ipairs(animator:GetPlayingAnimationTracks()) do
			local animation=track.Animation
			local id=animation and animation.AnimationId:match("%d+")
			local lowPriority=track.Priority.Value<=Enum.AnimationPriority.Movement.Value
			if animation and (instances[animation] or (id and ids[id] and lowPriority)) then
				track:Stop(0)
			end
		end
	end

	local function disconnectList(list)
		for _,connection in ipairs(list) do
			pcall(function() connection:Disconnect() end)
		end
		table.clear(list)
	end

	local function disconnectOwnership()
		disconnectList(ownershipConnections)
		for name,list in pairs(animationIdConnections) do
			disconnectList(list)
			animationIdConnections[name]=nil
		end
		table.clear(desiredFolders)
		table.clear(reconcileQueued)
		table.clear(reconciling)
		ownershipAnimate=nil
	end

	local function normalizedId(value)
		local id=tostring(value or ""):match("%d+")
		return id and ("rbxassetid://"..id) or ""
	end

	local function targetIdsForFolder(state,name,ids)
		if state~="Swim" then return ids end
		if name=="swimidle" then
			return ids[2] and {ids[2]} or nil
		end
		return ids[1] and {ids[1]} or nil
	end

	local reconcileFolder
	local queueReconcile

	local function refreshAnimationIdConnections(name,folder)
		local previous=animationIdConnections[name]
		if previous then disconnectList(previous) end
		local list={}
		animationIdConnections[name]=list
		for _,child in ipairs(folder:GetChildren()) do
			if child:IsA("Animation") then
				list[#list+1]=child:GetPropertyChangedSignal("AnimationId"):Connect(function()
					queueReconcile(name)
				end)
			end
		end
	end

	local function stopTracksFromRemovedAnimations(animate,removed)
		if not next(removed) then return end
		local character=animate and animate.Parent
		local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		local animator=humanoid and humanoid:FindFirstChildOfClass("Animator")
		if not animator then return end
		for _,track in ipairs(animator:GetPlayingAnimationTracks()) do
			if track.Animation and removed[track.Animation] then
				pcall(function() track:Stop(0.08) end)
			end
		end
	end

	reconcileFolder=function(name)
		local animate=ownershipAnimate
		local desired=desiredFolders[name]
		if not animate or animate~=getAnimate() or not desired or reconciling[name] then return end
		local folder=animate:FindFirstChild(name)
		if not folder then return end
		reconciling[name]=true
		local ok,err=pcall(function()
			local available={}
			for _,child in ipairs(folder:GetChildren()) do
				if child:IsA("Animation") then
					local id=normalizedId(child.AnimationId)
					available[id]=available[id] or {}
					table.insert(available[id],child)
				end
			end
			local keep={}
			local missing={}
			for index,id in ipairs(desired) do
				local normalized=normalizedId(id)
				local candidates=available[normalized]
				local existing=candidates and table.remove(candidates,1)
				if existing then
					keep[existing]=true
				else
					missing[#missing+1]={index=index,id=normalized}
				end
			end
			local removed={}
			for _,child in ipairs(folder:GetChildren()) do
				if child:IsA("Animation") and not keep[child] then
					removed[child]=true
				end
			end
			stopTracksFromRemovedAnimations(animate,removed)
			for child in pairs(removed) do child:Destroy() end
			local templates=originals[name] or {}
			for _,entry in ipairs(missing) do
				local template=templates[entry.index] or templates[1]
				local animation=template and template:Clone() or Instance.new("Animation")
				if not template then animation.Name="Animation"..entry.index end
				animation.AnimationId=entry.id
				animation.Parent=folder
			end
		end)
		reconciling[name]=nil
		if not ok then warn("[Animations] Could not reconcile "..name..": "..tostring(err)) end
		if ownershipAnimate==animate and desiredFolders[name] then
			refreshAnimationIdConnections(name,folder)
		end
	end

	queueReconcile=function(name)
		if reconcileQueued[name] or reconciling[name] or not desiredFolders[name] then return end
		reconcileQueued[name]=true
		task.defer(function()
			reconcileQueued[name]=nil
			reconcileFolder(name)
		end)
	end

	local function folderNameFromAnimation(instance)
		if not instance or not instance:IsA("Animation") then return nil end
		local parent=instance.Parent
		return parent and parent.Parent==ownershipAnimate and parent.Name or nil
	end

	local function bindOwnership(animate,resolved)
		disconnectOwnership()
		ownershipAnimate=animate
		for _,state in ipairs(stateOrder) do
			local ids=resolved[state]
			if ids then
				for _,name in ipairs(states[state]) do
					local targetIds=targetIdsForFolder(state,name,ids)
					local folder=animate:FindFirstChild(name)
					if folder and targetIds then
						desiredFolders[name]={}
						for index,id in ipairs(targetIds) do desiredFolders[name][index]=normalizedId(id) end
						reconcileFolder(name)
					end
				end
			end
		end
		ownershipConnections[#ownershipConnections+1]=animate.DescendantAdded:Connect(function(instance)
			local name=folderNameFromAnimation(instance)
			if name and desiredFolders[name] then queueReconcile(name) end
		end)
		ownershipConnections[#ownershipConnections+1]=animate.DescendantRemoving:Connect(function(instance)
			local name=folderNameFromAnimation(instance)
			if name and desiredFolders[name] then queueReconcile(name) end
		end)
		ownershipConnections[#ownershipConnections+1]=animate.ChildAdded:Connect(function(folder)
			if desiredFolders[folder.Name] then queueReconcile(folder.Name) end
		end)
	end
	local function replaceState(animate,state,ids)
		for _,name in ipairs(states[state]) do
			local targetIds=targetIdsForFolder(state,name,ids)
			local folder=animate:FindFirstChild(name)
			if folder and targetIds then
				local templates=originals[name] or {}
				for _,child in ipairs(folder:GetChildren()) do
					if child:IsA("Animation") then child:Destroy() end
				end
				for index,id in ipairs(targetIds) do
					local template=templates[index] or templates[1]
					local animation=template and template:Clone() or Instance.new("Animation")
					if not template then animation.Name="Animation"..index end
					animation.AnimationId=normalizedId(id)
					animation.Parent=folder
				end
			end
		end
	end
	local function applySelection()
		request=request+1
		local thisRequest=request
		local animate=getAnimate()
		if not animate then return end
		captureOriginal(animate)
		disconnectOwnership()
		task.spawn(function()
			local resolved={}
			for _,state in ipairs(stateOrder) do
				local entry=selected[state]
				if entry then resolved[state]=resolveIds(entry.id,state) end
				if request~=thisRequest or getAnimate()~=animate then return end
			end
			if request~=thisRequest or getAnimate()~=animate then return end
			-- Una sola transición evita que siete estados reinicien Animate a destiempo.
			local ok,err=pcall(function()
				animate.Enabled=false
				stopOutgoingTracks(animate)
				restoreOriginal(animate)
				for _,state in ipairs(stateOrder) do
					if resolved[state] then replaceState(animate,state,resolved[state]) end
				end
				bindOwnership(animate,resolved)
			end)
			task.wait(0.05)
			pcall(function() if animate.Parent then animate.Enabled=true end end)
			if not ok then warn('[Animations] Could not change animation tracks: '..tostring(err)) end
		end)
	end

	function EquipAnimationPart(pack,state)
		if not states[state] or not pack or (not pack.bundleId and not pack[state]) then return false end
		if not getAnimate() then return false end
		local mapped=getPackStates(pack)
		if not mapped or not mapped[state] then
			Notify(isES and "Animación no disponible" or "Animation unavailable",
				isES and "No se pudo identificar esta parte del paquete." or "Could not identify this pack part.")
			return false
		end
		selected[state]={id=mapped[state],name=pack.name}
		lastVexroAnimationPack=nil
		Settings.animationPackBundleId=nil
		persistSelection()
		applySelection()
		Notify(isES and "Animación equipada" or "Animation equipped",
			(pack.name or "").." - "..state)
		return true
	end

	function EquipAnimationPack(pack,silent)
		if not pack or not getAnimate() then return false end
		local mapped=getPackStates(pack)
		if not mapped then
			Notify(isES and "Paquete no disponible" or "Pack unavailable",
				isES and "No se pudieron identificar sus animaciones." or "Could not identify its animations.")
			return false
		end
		local count=0
		for _,state in ipairs(stateOrder) do
			if mapped[state] then
				selected[state]={id=mapped[state],name=pack.name}
				count=count+1
			else
				selected[state]=nil
			end
		end
		if count==0 then return false end
		lastVexroAnimationPack=pack
		Settings.animationPackBundleId=tonumber(pack.bundleId)
		persistSelection()
		applySelection()
		if not silent then Notify(isES and "Paquete equipado" or "Pack equipped",pack.name or "") end
		return true
	end

	function RemoveAnimationPacks(silent)
		for _,state in ipairs(stateOrder) do selected[state]=nil end
		lastVexroAnimationPack=nil
		if not silent then
			Settings.animationPackBundleId=nil
			Settings.animationPackSelection={}
			SaveLocalData()
		end
		applySelection()
		if not silent then
			Notify(isES and "Animaciones restauradas" or "Animations restored",
				isES and "Se recuperaron las animaciones originales." or "Original animations restored.")
		end
	end

	function ReapplyAnimationSelection()
		for _,state in ipairs(stateOrder) do
			if selected[state] then applySelection();return end
		end
	end

	-- El nuevo personaje recibe otro script Animate; reaplicar la selección
	-- existente cuando ese script ya esté disponible.
	player.CharacterAdded:Connect(function(character)
		disconnectOwnership()
		task.spawn(function()
			local animate=character:WaitForChild("Animate",8)
			if not animate or player.Character~=character then return end
			task.wait(0.15)
			if player.Character==character then ReapplyAnimationSelection() end
		end)
	end)
	local restoredSelection=false
	for _,state in ipairs(stateOrder) do
		local entry=type(Settings.animationPackSelection)=="table" and Settings.animationPackSelection[state]
		local id=type(entry)=="table" and tonumber(entry.id)
		if id then
			selected[state]={id=id,name=tostring(entry.name or "")}
			restoredSelection=true
		end
	end
	local savedBundleId=tonumber(Settings.animationPackBundleId)
	if restoredSelection then
		task.defer(function()
			local character=player.Character or player.CharacterAdded:Wait()
			if character and character:WaitForChild("Animate",5) then applySelection() end
		end)
	elseif savedBundleId then
		task.defer(function()
			local savedPack=nil
			for _,pack in ipairs(AnimationPacks or {}) do
				if tonumber(pack.bundleId)==savedBundleId then savedPack=pack;break end
			end
			if not savedPack then return end
			local character=player.Character or player.CharacterAdded:Wait()
			if character and character:WaitForChild("Animate",5) then
				EquipAnimationPack(savedPack,true)
			end
		end)
	end
	return true
end