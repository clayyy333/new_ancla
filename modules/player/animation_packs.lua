-- Equipar paquetes completos o estados individuales del script Animate.
return function(context)
	setfenv(1, context)

	local states = {
		Idle={"idle"}, Walk={"walk"}, Run={"run"}, Jump={"jump"},
		Fall={"fall"}, Climb={"climb"}, Swim={"swim","swimidle"}
	}
	local stateOrder={"Idle","Walk","Run","Jump","Fall","Climb","Swim"}
	local selected={}
	local versions={}
	local originalAnimate=nil
	local originals={}
	local refreshVersion=0

	local function getAnimate()
		local character=player.Character
		return character and character:FindFirstChild("Animate")
	end

	local function captureOriginal(animate)
		if originalAnimate==animate then return end
		originalAnimate=animate
		originals={}
		for _,folders in pairs(states) do
			for _,folderName in ipairs(folders) do
				local folder=animate:FindFirstChild(folderName)
				if folder then
					local copies={}
					for _,child in ipairs(folder:GetChildren()) do
						if child:IsA("Animation") then copies[#copies+1]=child:Clone() end
					end
					originals[folderName]=copies
				end
			end
		end
	end

	local function replaceAnimations(animate, folderName, ids)
		local folder=animate:FindFirstChild(folderName)
		if not folder then return end
		for _,child in ipairs(folder:GetChildren()) do
			if child:IsA("Animation") then child:Destroy() end
		end
		for index,id in ipairs(ids) do
			local animation=Instance.new("Animation")
			animation.Name="Animation"..index
			animation.AnimationId=id
			animation.Parent=folder
		end
	end

	local function restoreOriginal(animate)
		if originalAnimate~=animate then return end
		for folderName,copies in pairs(originals) do
			local folder=animate:FindFirstChild(folderName)
			if folder then
				for _,child in ipairs(folder:GetChildren()) do
					if child:IsA("Animation") then child:Destroy() end
				end
				for _,copy in ipairs(copies) do copy:Clone().Parent=folder end
			end
		end
	end

	local function refreshAnimate(animate)
		refreshVersion=refreshVersion+1
		local version=refreshVersion
		task.defer(function()
			if version~=refreshVersion or not animate.Parent then return end
			animate.Enabled=false
			task.wait(0.05)
			if animate.Parent then animate.Enabled=true end
		end)
	end

	local function resolveIds(catalogId)
		local ids={}
		local ok,objects=pcall(function()
			return game:GetObjects("rbxassetid://"..tostring(catalogId))
		end)
		if ok and objects then
			local function scan(instance)
				if instance:IsA("Animation") and instance.AnimationId~="" then
					ids[#ids+1]=instance.AnimationId
				end
				for _,child in ipairs(instance:GetChildren()) do scan(child) end
			end
			for _,object in ipairs(objects) do scan(object);object:Destroy() end
		end
		if #ids==0 then ids[1]="rbxassetid://"..tostring(catalogId) end
		return ids
	end

	local function applyState(pack,state)
		local catalogId=pack and pack[state]
		if not catalogId or not states[state] then return false end
		local animate=getAnimate()
		if not animate then return false end
		captureOriginal(animate)
		versions[state]=(versions[state] or 0)+1
		local version=versions[state]
		selected[state]={id=catalogId,name=pack.name}
		task.spawn(function()
			local ids=resolveIds(catalogId)
			if versions[state]~=version or selected[state]==nil or getAnimate()~=animate then return end
			for _,folderName in ipairs(states[state]) do replaceAnimations(animate,folderName,ids) end
			refreshAnimate(animate)
		end)
		return true
	end

	function EquipAnimationPart(pack,state)
		local applied=applyState(pack,state)
		if applied then
			Notify(isES and "Animación equipada" or "Animation equipped",
				(pack.name or "").." - "..state)
		end
		return applied
	end

	function EquipAnimationPack(pack)
		local animate=getAnimate()
		if not animate then return false end
		captureOriginal(animate)
		restoreOriginal(animate)
		for _,state in ipairs(stateOrder) do
			versions[state]=(versions[state] or 0)+1
			selected[state]=nil
		end
		local count=0
		for _,state in ipairs(stateOrder) do
			if applyState(pack,state) then count=count+1 end
		end
		lastVexroAnimationPack=pack
		if count>0 then
			Notify(isES and "Paquete equipado" or "Pack equipped",pack.name or "")
		end
		return count>0
	end

	function RemoveAnimationPacks(silent)
		for _,state in ipairs(stateOrder) do
			versions[state]=(versions[state] or 0)+1
			selected[state]=nil
		end
		lastVexroAnimationPack=nil
		local animate=getAnimate()
		if animate then
			restoreOriginal(animate)
			refreshAnimate(animate)
		end
		if not silent then Notify(isES and "Animaciones restauradas" or "Animations restored",
			isES and "Se recuperaron las animaciones originales." or "Original animations restored.") end
	end

	function ReapplyAnimationSelection()
		local animate=getAnimate()
		if not animate then return end
		captureOriginal(animate)
		for _,state in ipairs(stateOrder) do
			local entry=selected[state]
			if entry then applyState({[state]=entry.id,name=entry.name},state) end
		end
	end

	return true
end