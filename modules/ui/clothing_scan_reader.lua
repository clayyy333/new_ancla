-- Read-only, on-demand character inspection. Never reads the profile outfit.
return function(context)
	setfenv(1,context)
	local function read(object,key)
		local ok,value=pcall(function() return object[key] end)
		return ok and value or nil
	end
	local function assetId(value)
		local number=tonumber(value)
		if not number then
			local s=tostring(value or "")
			number=tonumber(s:match("[?&]id=(%d+)") or s:match("rbxassetid://(%d+)") or s:match("/asset/(%d+)"))
		end
		return number and number==number and number>0 and number<math.huge and math.floor(number)==number and number or nil
	end
	local classic={Shirt={"Camisa clásica","Classic shirt","ShirtTemplate"},Pants={"Pantalón clásico","Classic pants","PantsTemplate"},ShirtGraphic={"Camiseta clásica","Classic T-shirt","Graphic"}}
	local function tr(es,en) return isES and es or en end
	local function belongs(object,character)
		local ancestor=object.Parent
		while ancestor and ancestor~=character do
			if ancestor:IsA("Tool") then return false end
			if ancestor:IsA("Model") and ancestor:FindFirstChildOfClass("Humanoid") then return false end
			ancestor=ancestor.Parent
		end
		return ancestor==character
	end
	local Reader={}
	function Reader:Snapshot(character)
		local items={}
		for _,object in ipairs(character:GetDescendants()) do
			local entry=classic[object.ClassName]
			if (entry or object:IsA("Accessory")) and belongs(object,character) then
				local kind=entry and tr(entry[1],entry[2]) or tr("Accesorio","Accessory")
				if not entry then
					local category=tostring(read(object,"AccessoryType") or ""):match("%.([^%.]+)$")
					if category=="Hair" then kind=tr("Cabello","Hair")
					elseif category and category~="Unknown" then kind=kind.." ("..category..")" end
				end
				local id=assetId(read(object,"SourceAssetId"))
				-- Some games name inserted accessories with their catalog ID but expose
				-- no SourceAssetId. Keep it as a candidate until metadata is validated.
				local candidate=not entry and tostring(object.Name):match("^%d+$") and assetId(object.Name) or nil
				items[#items+1]={id=id,candidate=candidate,kind=kind,name=object.Name,source=id and "origin" or "unknown",instance=object}
				if entry then
					local texture=assetId(read(object,entry[3]))
					if texture then items[#items+1]={id=texture,kind=kind,name=object.Name,source="texture",instance=object} end
				end
			end
		end
		return items
	end
	function Reader:ValidateAccessoryCandidate(item,info)
		local accessoryTypes={[8]=true,[41]=true,[42]=true,[43]=true,[44]=true,[45]=true,[46]=true,[47]=true,[64]=true,[65]=true,[66]=true,[67]=true,[68]=true,[69]=true,[70]=true,[71]=true,[72]=true,[76]=true,[77]=true}
		local id=item.candidate
		if not id or type(info)~="table" or not accessoryTypes[tonumber(info.AssetTypeId)] then return false end
		if info.AssetId and tonumber(info.AssetId)~=id then return false end
		if type(info.Name)~="string" or info.Name=="" then return false end
		item.id=id;item.source="validated_name";item.name=info.Name
		if tonumber(info.AssetTypeId)==41 then item.kind=tr("Cabello","Hair") end
		return true
	end
	function Reader:Description(humanoid)
		local ok,description=pcall(function() return humanoid:GetAppliedDescription() end)
		if not ok or not description then return {} end
		local items,seen={},{}
		local function add(value,kind)
			local id=assetId(value)
			if id and not seen[id] then seen[id]=true;items[#items+1]={id=id,kind=kind,name=tr("Nombre no disponible","Name unavailable"),source="description"} end
		end
		for _,entry in ipairs({{"Shirt","Camisa clásica","Classic shirt"},{"Pants","Pantalón clásico","Classic pants"},{"GraphicTShirt","Camiseta clásica","Classic T-shirt"}}) do
			add(read(description,entry[1]),tr(entry[2],entry[3]))
		end
		local success,accessories=pcall(function() return description:GetAccessories(true) end)
		if success and type(accessories)=="table" then
			for _,a in ipairs(accessories) do add(a.AssetId,tostring(a.AccessoryType or tr("Accesorio","Accessory")):gsub("Enum.AccessoryType%.","")) end
		end
		-- Older executors can expose these properties even when GetAccessories fails.
		for _,property in ipairs({"HairAccessory","HatAccessory","FaceAccessory","NeckAccessory","ShouldersAccessory","FrontAccessory","BackAccessory","WaistAccessory"}) do
			for id in tostring(read(description,property) or ""):gmatch("%d+") do add(id,property=="HairAccessory" and tr("Cabello","Hair") or tr("Accesorio","Accessory")) end
		end
		pcall(function() description:Destroy() end)
		return items
	end
	ClothingScanReader=Reader
	return true
end
