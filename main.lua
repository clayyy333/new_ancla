-- Entrada modular local. Mantener modules/ junto a este archivo.
-- Para otra carpeta: getgenv().EmotesRootPath = "mi_carpeta"
local hostEnvironment = getfenv()
local shared = type(getgenv) == "function" and getgenv() or hostEnvironment
local moduleRoot = tostring(shared.EmotesRootPath or ""):gsub("\\", "/")
if moduleRoot ~= "" and moduleRoot:sub(-1) ~= "/" then moduleRoot = moduleRoot .. "/" end
assert(type(readfile) == "function", "Se necesita readfile o la version dist/emotes.lua")
assert(type(loadstring) == "function", "Se necesita loadstring para cargar los modulos locales")

local cache = {}
local function loadModule(name)
	assert(type(name) == "string" and name:match("^[%w_/-]+$"), "Nombre de modulo invalido")
	if cache[name] ~= nil then return cache[name] end
	local path = moduleRoot .. "modules/" .. name .. ".lua"
	local ok, source = pcall(readfile, path)
	assert(ok and type(source) == "string", "No se pudo leer el modulo: " .. path)
	local chunk, err = loadstring(source, "@" .. path)
	assert(chunk, err)
	setfenv(chunk, hostEnvironment)
	local result = chunk()
	assert(result ~= nil, "El modulo no devolvio un valor: " .. name)
	cache[name] = result
	return result
end

return loadModule("app")(loadModule, hostEnvironment, moduleRoot)
