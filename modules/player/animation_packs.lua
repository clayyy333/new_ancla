-- Estado compartido mediante el contexto privado de la aplicacion.
return function(context)
	setfenv(1, context)

function EquipAnimationPack(pack)
	local char = player.Character
	if not char then return end
	local animate = char:FindFirstChild("Animate")
	if not animate then return end
	
	local ids = {
		pack.Idle,
		pack.Walk,
		pack.Run,
		pack.Jump,
		pack.Fall,
		pack.Climb,
		pack.Swim
	}
	
	local activeThreads = 0
	for _, catalogId in ipairs(ids) do
		if catalogId then
			activeThreads = activeThreads + 1
			task.spawn(function()
				local resolvedIds = {}
				local success, objs = pcall(function()
					return game:GetObjects("rbxassetid://" .. tostring(catalogId))
				end)
				
				local animName = nil
				if success and objs and #objs > 0 then
					local function scan(inst)
						if inst:IsA("Animation") then
							table.insert(resolvedIds, inst.AnimationId)
							local name = inst.Name:lower()
							if name:find("climb") then
								animName = "climb"
							elseif name:find("fall") then
								animName = "fall"
							elseif name:find("walk") then
								animName = "walk"
							elseif name:find("swim") then
								animName = "swim"
							elseif name:find("run") then
								animName = "run"
							elseif name:find("jump") then
								animName = "jump"
							elseif name:find("idle") or name:find("pose") or name:find("animation") then
								animName = "idle"
							end
						end
						for _, kid in ipairs(inst:GetChildren()) do
							scan(kid)
						end
					end
					for _, obj in ipairs(objs) do
						scan(obj)
					end
				end
				
				if #resolvedIds == 0 then
					table.insert(resolvedIds, "rbxassetid://" .. tostring(catalogId))
				end
				
				if animName then
					local val = animate:FindFirstChild(animName)
					if val then
						for _, child in ipairs(val:GetChildren()) do
							if child:IsA("Animation") then
								child:Destroy()
							end
						end
						for i, animId in ipairs(resolvedIds) do
							local anim = Instance.new("Animation")
							anim.Name = "Animation" .. i
							anim.AnimationId = animId
							anim.Parent = val
						end
					end
				end
				activeThreads = activeThreads - 1
			end)
		end
	end
	
	task.spawn(function()
		while activeThreads > 0 do
			task.wait(0.05)
		end
		pcall(function()
			animate.Enabled = false
			task.wait(0.05)
			animate.Enabled = true
		end)
	end)
	
	lastVexroAnimationPack = pack
	Notify("🎨 " .. (isTR and "Animasyon Kuşanıldı" or "Animation Equipped"), pack.name)
end

	return true
end
