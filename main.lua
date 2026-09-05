-- Entrada remota: descarga los modulos del mismo repositorio.
local REPOSITORY_ROOT = "https://raw.githubusercontent.com/clayyy333/new_ancla/main/"

local host = getfenv()
local shared = type(getgenv) == "function" and getgenv() or host
local compile = loadstring or shared.loadstring
assert(type(compile) == "function", "Este entorno no permite cargar modulos Lua (loadstring).")

local cache = {}
local function loadModule(name)
    assert(type(name) == "string" and name:match("^[%w_/-]+$"), "Nombre de modulo invalido")
    if cache[name] ~= nil then return cache[name] end
    local path = "modules/" .. name .. ".lua"
    local ok, source = pcall(function()
        return game:HttpGet(REPOSITORY_ROOT .. path)
    end)
    if not ok or type(source) ~= "string" then
        error("No se pudo descargar " .. path .. ". Comprueba que el archivo este publicado en la rama main del repositorio. Detalle: " .. tostring(source), 0)
    end
    local chunk, compileError = compile(source, "@" .. path)
    if not chunk then error("Error de sintaxis en " .. path .. ": " .. tostring(compileError), 0) end
    setfenv(chunk, host)
    local loaded, result = pcall(chunk)
    if not loaded then error("Error al cargar " .. path .. ": " .. tostring(result), 0) end
    assert(result ~= nil, "El modulo no devolvio un valor: " .. path)
    cache[name] = result
    return result
end

local manifest = loadModule("manifest")
local initializers, declared = {}, {}
for _, name in ipairs(manifest.sharedNames) do declared[name] = true end
-- Descargar todos los modulos antes de cerrar la GUI que pudiera estar abierta.
loadModule("data/emotes")
loadModule("data/animations")
for _, name in ipairs(manifest.order) do
    local initialize = loadModule(name)
    assert(type(initialize) == "function", "Modulo invalido: " .. name)
    initializers[#initializers + 1] = {name = name, run = initialize}
end

local function start()
    local context = setmetatable({loadModule = loadModule, reloadApp = start}, {
        __index = function(_, key)
            if declared[key] then return nil end
            local value = host[key]
            if value ~= nil then return value end
            return shared[key]
        end,
    })
    for _, module in ipairs(initializers) do
        local ok, result = pcall(module.run, context)
        if not ok then
            if context.gui then pcall(function() context.gui:Destroy() end) end
            error("Fallo al iniciar modules/" .. module.name .. ".lua: " .. tostring(result), 0)
        end
        if result ~= true then return context, false end
    end
    return context, true
end

return start()
