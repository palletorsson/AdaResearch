"""The inventory gate: commons/data/inventory/items.json against the code it names.

An item's token must be in a registry file with a scene on disk (unless the item is 'coming'),
and every knob must name an @export var of that scene's script (derive, never transcribe:
a knob the code does not have would be set in silence and change nothing). Exit = findings.
"""
import json, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ITEMS = os.path.join(ROOT, "commons", "data", "inventory", "items.json")
REG = os.path.join(ROOT, "commons", "artifacts", "registry")


def registry():
    out = {}
    for f in sorted(os.listdir(REG)):
        if f.endswith(".json"):
            try:
                d = json.load(open(os.path.join(REG, f), encoding="utf-8"))
            except Exception as e:  # a registry file that does not parse is a finding of its own
                print(f"registry {f}: {e}")
                continue
            # token-keyed at the top, or wrapped in "artifacts"
            for k, v in list(d.items()) + list((d.get("artifacts") or {}).items()):
                if isinstance(v, dict) and "scene" in v:
                    out[k] = v["scene"]
    return out


def root_script(scene_path, depth=0):
    """The script on a scene's root; a scene that instances another scene inherits that one's."""
    tscn = os.path.join(ROOT, scene_path.replace("res://", ""))
    if not os.path.exists(tscn):
        return None, f"scene missing on disk: {scene_path}"
    text = open(tscn, encoding="utf-8").read()
    res = {m.group(3): (m.group(1), m.group(2)) for m in re.finditer(r'\[ext_resource type="(\w+)"[^\]]*?path="(res://[^"]+)"[^\]]*?id="([^"]+)"', text)}
    root = re.search(r'\[node name="[^"]+"[^\]]*\]', text)
    if root:
        m = re.search(r'script = ExtResource\("([^"]+)"\)', text[root.end():].split("\n[node", 1)[0])
        if m and m.group(1) in res and res[m.group(1)][0] == "Script":
            return res[m.group(1)][1], None
        m = re.search(r'instance=ExtResource\("([^"]+)"\)', root.group(0))
        if m and m.group(1) in res and res[m.group(1)][0] == "PackedScene" and depth < 4:
            return root_script(res[m.group(1)][1], depth + 1)
    return None, f"{scene_path}: the root carries no script"


def exports(scene_path):
    script, why = root_script(scene_path)
    if script is None:
        return None, why
    gd = os.path.join(ROOT, script.replace("res://", ""))
    if not os.path.exists(gd):
        return None, f"script missing on disk: {script}"
    text = open(gd, encoding="utf-8").read()
    # a key the artifact takes: an @export it reads back by name, or a key its apply_grid_config reads itself
    names = set(re.findall(r"^\s*@export[^\n]*?\bvar\s+(\w+)", text, re.M))
    names |= set(re.findall(r'config(?:_data)?(?:\.get\(|\.has\(|\[)\s*"(\w+)"', text)) | set(re.findall(r'"config_(\w+)"', text))
    return names, script


def main():
    data = json.load(open(ITEMS, encoding="utf-8"))
    reg = registry()
    findings = 0
    seen = set()
    for it in data["items"]:
        iid = it.get("id", "?")
        if iid in seen:
            print(f"{iid}: id twice"); findings += 1
        seen.add(iid)
        if it.get("mount") not in ("wall", "floor", "hand", "any", "worn"):
            print(f"{iid}: mount is wall, floor, hand, any or worn"); findings += 1
        if it.get("coming"):
            if it.get("token"):
                print(f"{iid}: 'coming' with a token: drop one of them"); findings += 1
            continue
        tok = it.get("token", "")
        if tok not in reg:
            print(f"{iid}: token {tok!r} is in no registry file"); findings += 1
            continue
        names, where = exports(reg[tok])
        if names is None:
            print(f"{iid}: {where}"); findings += 1
            continue
        if "scale" in it and not (0 < float(it["scale"]) <= 4):
            print(f"{iid}: scale is a factor between 0 and 4"); findings += 1
        for key in list(it.get("defaults", {})) + [k["key"] for k in it.get("knobs", [])]:
            if key not in names:
                print(f"{iid}: '{key}' is not an @export of {where}"); findings += 1
        for k in it.get("knobs", []):
            kinds = sum(1 for x in ("choices", "range", "text") if x in k)
            if kinds != 1:
                print(f"{iid}.{k.get('key')}: one of choices, range or text"); findings += 1
            if "names" in k and len(k["names"]) != len(k.get("choices", [])):
                print(f"{iid}.{k.get('key')}: names and choices differ in length"); findings += 1
    print(f"{len(data['items'])} items, {findings} findings")
    return findings


if __name__ == "__main__":
    sys.exit(min(main(), 255))
