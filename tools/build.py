"""Genera dist/emotes.lua sin dependencias externas (Python 3)."""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]

def build():
    parts = ["-- Generado por tools/build.py. Editar modules/, no este archivo.\nlocal factories = {}\n"]
    for path in sorted((ROOT / "modules").rglob("*.lua")):
        name = path.relative_to(ROOT / "modules").with_suffix("").as_posix()
        parts.append("factories[" + json.dumps(name) + "] = function()\n")
        parts.append(path.read_text(encoding="utf-8"))
        parts.append("\nend\n")
    parts.append('''local cache = {}
local function loadModule(name)
    if cache[name] ~= nil then return cache[name] end
    assert(factories[name], "Modulo ausente: " .. tostring(name))
    local result = factories[name]()
    assert(result ~= nil, "Modulo sin resultado: " .. name)
    cache[name] = result
    return result
end
return loadModule("app")(loadModule, getfenv(), "")
''')
    destination = ROOT / "dist" / "emotes.lua"
    destination.parent.mkdir(exist_ok=True)
    destination.write_text("".join(parts), encoding="utf-8", newline="\n")
    print(f"Generado: {destination} ({destination.stat().st_size:,} bytes)")
    return destination

if __name__ == "__main__":
    build()
