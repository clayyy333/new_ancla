"""Ejecuta regresiones con Luau CLI y compila todos los archivos."""
import argparse
import json
import re
import shutil
import subprocess
import tempfile
from pathlib import Path
from build import ROOT, build

parser = argparse.ArgumentParser()
parser.add_argument("--luau", default=shutil.which("luau"), help="Ruta al ejecutable luau")
parser.add_argument("--compiler", default=shutil.which("luau-compile"), help="Ruta a luau-compile")
args = parser.parse_args()
if not args.luau or not args.compiler:
    parser.error("Indica --luau y --compiler (herramientas oficiales de Luau).")
bundle = build()
modules = sorted((ROOT / "modules").rglob("*.lua"))
subprocess.run([args.compiler, "--null", str(ROOT / "main.lua"), str(bundle), *map(str, modules)], check=True)
parts = ["local factories = {}\n"]
for path in modules:
    name = path.relative_to(ROOT / "modules").with_suffix("").as_posix()
    source = path.read_text(encoding="utf-8-sig")
    if name.startswith("data/"):
        payload = source.split("[====[", 1)[1].split("]====]", 1)[0]
        catalog = json.loads(payload)
        assert len(catalog["data"]) == catalog["totalItems"]
        assert all("id" in entry and "name" in entry for entry in catalog["data"])
        print(f"Catalogo {name}: {len(catalog['data'])} entradas validas")
    else:
        assert not re.search(r"vexroscripts|BASE_URL|ApiRequest|HttpGet\(", source, re.I), path
    parts.append("factories[" + json.dumps(name) + "] = function()\n" + source + "\nend\n")
parts.append("local function loadModule(name) assert(factories[name], name); return factories[name]() end\n")
parts.append((ROOT / "tests/regression.luau").read_text(encoding="utf-8-sig"))
parts.append((ROOT / "tests/friend_follow.luau").read_text(encoding="utf-8-sig"))
with tempfile.TemporaryDirectory(prefix="emotes-tests-") as directory:
    test = Path(directory) / "regression.luau"
    test.write_text("".join(parts), encoding="utf-8")
    subprocess.run([args.luau, str(test)], check=True)
