-- Construye una instancia aislada. Los modulos comparten estado, no el entorno global.
return function(loadModule, hostEnvironment, moduleRoot)
	local manifest = loadModule("manifest")
	local initializers = {}
	local declared = {}
	for _, name in ipairs(manifest.sharedNames) do declared[name] = true end

	-- Validar todos los archivos antes de desmontar una instancia anterior.
	loadModule("data/emotes")
	loadModule("data/animations")
	for _, name in ipairs(manifest.order) do
		local initialize = loadModule(name)
		assert(type(initialize) == "function", "Modulo invalido: " .. name)
		initializers[#initializers + 1] = initialize
	end

	local function start()
		local context = setmetatable({
			loadModule = loadModule,
			moduleRoot = moduleRoot or "",
			reloadApp = start,
		}, {
			__index = function(_, key)
				if declared[key] then return nil end
				return hostEnvironment[key]
			end,
		})
		for index, initialize in ipairs(initializers) do
			if initialize(context) ~= true then
				return context, false
			end
		end
		return context, true
	end

	return start()
end
