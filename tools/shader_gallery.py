"""A shader floor's gallery, written from its own console (Palle, 2026-11-09: "the playground's own panels wear the
shaders as a gallery; there should be a syntax for this ... mixed with the existing shader setup in a very nice way").

    python tools/shader_gallery.py contents <console script>          the chapter's screens, as board contents
    python tools/shader_gallery.py place <Map> <console id> <console script> [--size=2] [--out=<pass.json>] [--id=]

`contents` reads the console's own shader definitions (each {"shader", "title", "sliders" [name, min, max, default,
step], "uniforms" [...] / "extra_uniforms" {...}}) and writes one display-plate content per shader: the same shader,
the console's default settings, its title "NN  Title". `place` adds a playground_spec_hall on that floor whose board
of floor screens `wear`s the console: each screen wears the console's live material with its shader (by shader - a
console builds only its current mode's materials, the screen follows), so the console's sliders change the gallery.
It stands on the nearest free strip to the console, measured from the last size survey (on the slab or a side slab,
off the shafts and columns, clear of every work). The row is a decisions file for tools/void_fit.py apply."""
import json, math, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def _blocks(text):
    """Every {...} literal that names a .gdshader, parsed (GDScript dict literals are JSON but for trailing commas)."""
    out = []
    for m in re.finditer(r'"shader"\s*:\s*"(res://[^"]+\.gdshader)"', text):
        i = text.rfind("{", 0, m.start())
        depth = 0; j = i; ins = False
        while j < len(text):
            c = text[j]
            if c == '"' and text[j - 1] != "\\": ins = not ins
            elif not ins and c == "{": depth += 1
            elif not ins and c == "}":
                depth -= 1
                if depth == 0: break
            j += 1
        raw = re.sub(r",(\s*[}\]])", r"\1", text[i:j + 1])
        raw = re.sub(r"#[^\n\"]*\n", "\n", raw)
        try:
            out.append(json.loads(raw))
        except json.JSONDecodeError:
            out.append({"shader": m.group(1)})
    return out


def contents(script):
    text = (ROOT / script.replace("res://", "")).read_text(encoding="utf-8")
    seen, out = set(), []
    for d in _blocks(text):
        params = {}
        for k, v in (d.get("extra_uniforms") or {}).items(): params[k] = float(v) if isinstance(v, (int, float)) else v
        sliders, names = d.get("sliders") or [], d.get("uniforms") or []
        for s, u in zip(sliders, names):
            if isinstance(s, list) and len(s) >= 4 and isinstance(s[3], (int, float)): params.setdefault(u, float(s[3]))
        key = d["shader"] + json.dumps(params, sort_keys=True)
        if key in seen: continue
        seen.add(key)
        out.append({"content": "shader", "shader": d["shader"], "params": params,
                    "title": "%02d  %s" % (len(out) + 1, d.get("title", Path(d["shader"]).stem))})
    return out


def place(map_name, console, script, size=2, out=None, gid="shader-gallery"):
    sys.path.insert(0, str(ROOT / "tools"))
    import void_size_survey as S
    building, floors = S.load()
    rooms = json.loads((ROOT / "commons/void/rooms.json").read_text(encoding="utf-8"))
    index = next(i for i, f in enumerate(rooms["floors"]) if f["map"] == map_name)
    f = floors[str(index)]
    items = contents(script)
    n = len(items)
    hw, hd = building["width"] / 2, building["depth"] / 2
    shafts = [(float(s["x"]) - 3.5, -3.5, float(s["x"]) + 3.5, 3.5) for s in building["shafts"]]
    cols = [(x - .6, z - .6, x + .6, z + .6) for x in building["column_x"] for z in building["column_z"]]
    boxes = [(w["box"][0], w["box"][2], w["box"][3], w["box"][5]) for w in f["works"] if w.get("box") and None not in w["box"]
             and w.get("token") != "void_slab_extension" and (w["box"][3] - w["box"][0]) < 40]
    slabs = S.slab_grounds(rooms["floors"][index], .3)
    me = next(w for w in f["works"] if w["id"] == console)
    cx, cz = (me["box"][0] + me["box"][3]) / 2, (me["box"][2] + me["box"][5]) / 2
    def on_ground(r):
        def inside(x, z):
            return (-hw + .3 <= x <= hw - .3 and -hd + .3 <= z <= hd - .3) or any(s[0] <= x <= s[2] and s[1] <= z <= s[3] for s in slabs)
        return all(inside(r[0] + (r[2] - r[0]) * i / 4, r[1] + (r[3] - r[1]) * j / 2) for i in range(5) for j in range(3))
    clash = lambda r, b, m=.3: r[0] - m < b[2] and b[0] < r[2] + m and r[1] - m < b[3] and b[1] < r[3] + m
    best = None
    length = n * size
    for x2 in range(-46, 47):
        for z2 in range(-36, 37):
            x0, z0 = x2 * .5, z2 * .5
            for along_x in (True, False):
                r = (x0, z0, x0 + length, z0 + size) if along_x else (x0, z0, x0 + size, z0 + length)
                if not on_ground(r) or any(clash(r, s, 0) for s in shafts) or any(clash(r, c, 0) for c in cols) or any(clash(r, b) for b in boxes): continue
                d = math.hypot((r[0] + r[2]) / 2 - cx, (r[1] + r[3]) / 2 - cz)
                if best is None or d < best[0]: best = (d, r, along_x)
    if best is None:
        print("no free strip of %d x %d m on %s" % (length, size, map_name)); return None
    _, r, along_x = best
    # board centres in whole metres (the board vocabulary's rule): round the first centre, step by `size`
    first = [round(r[0] + size / 2), 0, round(r[1] + size / 2)]
    step = [size, 0, 0] if along_x else [0, 0, size]
    spec = {"version": 1, "units": "metres", "places": [],
            "title": "%s / the chapter's shaders as walkable screens, wearing %s's live materials" % (map_name, console),
            "boards": [{"id": "chapter", "at": first, "size": [size, size], "orient": "floor", "repeat": {"count": n, "step": step},
                        "wear": console, "contents": items, "label": True}]}
    row = {"map": map_name, "add": {"id": gid, "artifact": "playground_spec_hall", "station": "NW", "position": [0, 0], "height": 0,
                                    "scale": 1, "facing": 0, "config": {"place_spec": spec,
                                    "editor_label": "Shader gallery / the playground's screens wear %s's live shaders (2026-11-09)" % console,
                                    "fit": {"strategies": ["playground_setup"]}}},
           "strategies": ["playground_setup"], "note": "%d screens %s from %s, %.1f m from the console" % (n, "along x" if along_x else "along z", first, best[0])}
    print(json.dumps(row["note"]))
    if out:
        rows = json.loads(Path(out).read_text(encoding="utf-8")) if Path(out).exists() else []
        rows.append(row); Path(out).write_text(json.dumps(rows, indent=1, ensure_ascii=False), encoding="utf-8")
    return row


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf8")
    if sys.argv[1] == "contents":
        print(json.dumps(contents(sys.argv[2]), indent=1, ensure_ascii=False))
    elif sys.argv[1] == "place":
        size = int(next((a.split("=")[1] for a in sys.argv if a.startswith("--size=")), 2))
        out = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--out=")), None)
        gid = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--id=")), "shader-gallery")
        place(sys.argv[2], sys.argv[3], sys.argv[4], size, out, gid)
