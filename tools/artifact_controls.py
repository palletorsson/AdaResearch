# -*- coding: utf-8 -*-
"""artifact_controls.py — which artifacts can be OPERATED, and with what.

The info board says what a map is ABOUT (the 29-term vocabulary) and what it is
MADE OF (the substrate row). Neither says whether you look at the thing or work
it. Palle: "there are substrates but there are also interactive machines —
shannon_workbench, pattern machine, wave examples."

That is a third category and it is large. This tool derives it, and derives it
from the SCENE rather than from adjectives, because the repo has a real widget
vocabulary and counting instances of it is a fact:

    commons/interactables/       slider_* · push_button* · lever_* · dial_* · knob_*
    commons/audio/rack_controls/ RackSlider* · RackKnob · RackButton · RackLever
    commons/interfaces/qfep/     lambda_slider · phi_slider
    addons/godot-xr-tools/       interactable_slider · interactable_area_button · handle

There are THREE ways an artifact gets a control, and a first cut that knew only
the first one found 33 widgets in 159 machines — an undercount so large it was
its own bug report. shannon_workbench, which Palle named as the example, has a
.tscn containing exactly one node and a script that builds everything:

  1. scene instance   `instance=ExtResource("id")` where id is a widget path.
                      Exact: a .tscn names a widget once and instances it N times.
  2. builder call     `panel.add_slider("P(1)")` against commons/ui/control_panel.gd.
                      One call is one control. 81 add_slider calls across 52 files —
                      this is the majority pattern and the first cut saw none of it.
  3. path constant    `const SLIDER_SCENE_PATH := "res://.../slider_horizontal.tscn"`
                      then load+instantiate. The KIND is known; the count is not,
                      so no count is invented.

A builder call inside a `for` gives a floor rather than a total, and says so
(`at_least`). 188 of the spine's 814 placed tokens resolve to no script or scene
on disk; they are `unknown`, never silently `exhibit`.

    python tools/artifact_controls.py
    python tools/artifact_controls.py --token=shannon_workbench
"""
import json, re, argparse, pathlib, sys
from collections import Counter

ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / "commons/data/artifact_controls.json"
sys.path.insert(0, str(ROOT / "tools"))
import walk_polish as wp                       # noqa: E402
import spine_typologies as sty                 # noqa: E402

# basename -> control kind. Ordered longest-first at match time so that
# "slider_horizontal" does not get read as a bare "slider".
WIDGETS = {
    "slider_horizontal": "slider", "slider_vertical": "slider", "slider_axis": "slider",
    "slider_plane": "slider", "slider_smooth": "slider", "slider_snap": "slider",
    "slider_time": "slider", "slider_zero": "slider", "axis_slider": "slider",
    "curvature_slider": "slider", "lambda_slider": "slider", "phi_slider": "slider",
    "xyz_slider_plate": "slider", "interactable_slider": "slider",
    "racksliderh": "slider", "racksliderv": "slider", "rackslidderbipolar": "slider",
    "rackslliderstepped": "slider", "rackslider": "slider",
    "vraudiocontrolslider": "slider", "vraudiocontrolslidervertical": "slider",
    "simple_mario_slider": "slider", "mariosliders": "slider",
    "push_button": "button", "push_button_front": "button", "push_button_2d3d": "button",
    "cube_button": "button", "emergency_button": "button", "hold_button": "button",
    "interactable_area_button": "button", "rackbutton": "button",
    "soundtriggerbutton": "button", "menubutton3d": "button", "button_closeup": "button",
    "knob_test": "knob", "rackknob": "knob", "dial_smooth": "knob",
    "vraudiocontroldial": "knob",
    "lever_smooth": "lever", "lever_snap": "lever", "lever_zero": "lever",
    "racklever": "lever", "interactable_handle": "handle",
}
KIND_ORDER = ["slider", "knob", "dial", "joystick", "wheel", "lever", "button",
              "handle", "crank", "grab"]

# pattern 2 — the ControlPanel builder API (commons/ui/control_panel.gd). One
# call is one control, which makes this the only countable code-side signal.
BUILDERS = {"add_slider": "slider", "add_dial": "dial", "add_joystick": "joystick",
            "add_button": "button", "add_knob": "knob"}

# pattern 3 — a widget path written as a string anywhere in the script
PATH_KIND = {"slider": "slider", "push_button": "button", "dial": "dial",
             "knob": "knob", "lever": "lever", "joystick": "joystick",
             "wheel": "wheel", "crank": "crank", "grab_cube": "grab",
             "handle": "handle"}

# signals a script listens to — proof the control is WIRED, not decoration
SIGNALS = {
    "slider": [r"slider_moved", r"\bon_slider", r"value_changed"],
    "button": [r"button_pressed", r"\bpressed\b\s*\.connect", r"on_button"],
    "knob":   [r"dial_(changed|moved)", r"knob_(changed|moved)"],
    "lever":  [r"lever_(moved|changed|pulled)"],
    "crank":  [r"\bcrank"],
}


def widget_kind(path: str):
    b = pathlib.Path(path).stem.lower()
    if b in WIDGETS:
        return WIDGETS[b]
    for key in sorted(WIDGETS, key=len, reverse=True):
        if key in b:
            return WIDGETS[key]
    return None


def scan_scene(p: pathlib.Path, depth=0, seen=None):
    """Count widget instances in a .tscn, following sub-scenes one level.

    A .tscn names each PackedScene once and then instances it, so the honest
    count is `instance=ExtResource("id")` occurrences per id — not the number of
    ext_resource lines, which is always 1 per distinct widget and would report a
    rack of eight knobs as one knob.
    """
    seen = seen if seen is not None else set()
    counts = Counter()
    if depth > 1 or not p.exists() or p in seen:
        return counts
    seen.add(p)
    try:
        t = p.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return counts
    res = dict(re.findall(r'\[ext_resource[^\]]*path="res://([^"]+\.tscn)"[^\]]*id="([^"]+)"', t))
    res = {v: k for k, v in res.items()}                    # id -> path
    for rid, path in res.items():
        n = len(re.findall(r'instance=ExtResource\("%s"\)' % re.escape(rid), t))
        if n == 0:
            continue
        k = widget_kind(path)
        if k:
            counts[k] += n
        else:
            sub = scan_scene(ROOT / path, depth + 1, seen)
            for kk, vv in sub.items():
                counts[kk] += vv * n                        # n copies of a sub-assembly
    return counts


def _in_loop(src, line):
    """Is this line inside a for/while? Then its count is a floor, not a total."""
    lines = src.splitlines()
    try:
        i = lines.index(line)
    except ValueError:
        return False
    ind = len(line) - len(line.lstrip())
    for j in range(i - 1, max(-1, i - 40), -1):
        s = lines[j]
        if not s.strip():
            continue
        k = len(s) - len(s.lstrip())
        if k < ind and re.match(r"\s*(for|while)", s):
            return True
        if k < ind and re.match(r"\s*func", s):
            return False
    return False


def script_of(entry):
    scene = str(entry.get("scene", "")).replace("res://", "")
    if not scene:
        return None, None
    p = ROOT / scene
    if p.suffix == ".gd":
        return (p if p.exists() else None), None
    if p.exists():
        try:
            m = re.search(r'path="res://([^"]+\.gd)"', p.read_text(encoding="utf-8", errors="replace"))
        except Exception:
            m = None
        if m and (ROOT / m.group(1)).exists():
            return ROOT / m.group(1), p
        q = p.with_suffix(".gd")
        return (q if q.exists() else None), p
    q = p.with_suffix(".gd")
    return (q if q.exists() else None), None


def registry():
    reg = {}
    for f in (ROOT / "commons/artifacts/registry").glob("*.json"):
        try:
            d = json.loads(f.read_text(encoding="utf-8"))
        except Exception:
            continue
        for k, v in (d.get("artifacts", d) or {}).items():
            if isinstance(v, dict):
                reg[k] = v
    return reg


def build():
    reg = registry()
    toks = set()
    placements = Counter()
    for _, nm in sty.spine_maps():
        md = wp.load(nm)
        if not md:
            continue
        for row in wp.grids(md)[2]:
            for c in row:
                s = str(c).strip()
                if s and not s.startswith(wp.PRE) and not s.startswith("hangar_"):
                    toks.add(s.split(":")[0])
                    placements[s.split(":")[0]] += 1

    out, unknown = {}, 0
    for t in sorted(toks):
        e = reg.get(t, {})
        gd, tscn = script_of(e)
        if gd is None and tscn is None:
            unknown += 1
            out[t] = {"state": "unknown", "why": "no scene or script on disk"}
            continue
        counts = scan_scene(tscn) if tscn else Counter()
        src = ""
        if gd is not None:
            try:
                src = gd.read_text(encoding="utf-8", errors="replace")
            except Exception:
                src = ""
        # pattern 2 — builder calls. Counted, with a floor flag when the call
        # sits inside a loop and the real number depends on runtime data.
        built, at_least = Counter(), False
        for line in src.splitlines():
            for b, k in BUILDERS.items():
                n = line.count("." + b + "(")
                if n:
                    built[k] += n
                    if _in_loop(src, line):
                        at_least = True
        # pattern 3 — a widget path written as a string. Kind only, no number.
        code_kinds = set()
        for m in re.finditer(r"res://[^\"']*?/([a-z_0-9]+)\.tscn", src):
            stem = m.group(1)
            for key, k in PATH_KIND.items():
                if key in stem:
                    code_kinds.add(k)
                    break
        wired = sorted({k for k, pats in SIGNALS.items()
                        if any(re.search(p, src) for p in pats)})
        for k, v in built.items():
            counts[k] += v
        kinds = sorted(set(counts) | code_kinds | set(wired),
                       key=lambda k: KIND_ORDER.index(k) if k in KIND_ORDER else 99)
        axes = (e.get("dna", {}) or {}).get("axes", {}) or {}
        out[t] = {
            "state": "machine" if kinds else "exhibit",
            "kinds": kinds,
            "counted": {k: int(v) for k, v in counts.items()},
            "at_least": at_least,
            "code_built": sorted(code_kinds - set(counts)),
            "wired": wired,
            "axes": {k: len(v) for k, v in axes.items() if isinstance(v, list)},
            "placements": placements[t],
            "scene": (str(tscn.relative_to(ROOT)).replace("\\", "/") if tscn else ""),
        }

    mach = {k: v for k, v in out.items() if v.get("state") == "machine"}
    OUT.write_text(json.dumps({
        "_readme": ("Which spine artifacts can be OPERATED. Derived from the scene: each .tscn "
                    "declares a control widget once and instances it N times, so `counted` is "
                    "real. `code_built` lists kinds the script preloads and builds at runtime — "
                    "the kind is known, the number is not, so no number is given. `wired` is the "
                    "signals the script listens to, which is the proof a control does something. "
                    "`axes` is the artifact's declared DNA: how many settings it HAS, whether or "
                    "not any map ever uses them."),
        "counts": {"placed_tokens": len(out), "machines": len(mach),
                   "exhibits": sum(1 for v in out.values() if v.get("state") == "exhibit"),
                   "unknown": unknown,
                   "widget_instances": sum(sum(v.get("counted", {}).values()) for v in mach.values()),
                   "by_kind": dict(Counter(k for v in mach.values() for k in v["kinds"]).most_common())},
        "artifacts": out}, indent=1), encoding="utf-8")

    print("%d placed spine tokens -> %d machines, %d exhibits, %d unknown"
          % (len(out), len(mach), sum(1 for v in out.values() if v.get("state") == "exhibit"), unknown))
    print("  widget instances counted in scenes: %d"
          % sum(sum(v.get("counted", {}).values()) for v in mach.values()))
    print("  by kind:", Counter(k for v in mach.values() for k in v["kinds"]).most_common())
    top = sorted(mach.items(), key=lambda kv: -sum(kv[1]["counted"].values()))[:10]
    print("\n  most controls:")
    for k, v in top:
        print("    %-34s %-28s wired:%s" % (k[:34], str(dict(v["counted"]))[:28],
                                            ",".join(v["wired"]) or "-"))
    return 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--token", default="")
    a = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    if a.token:
        if not OUT.exists():
            build()
        d = json.loads(OUT.read_text(encoding="utf-8"))
        print(json.dumps(d["artifacts"].get(a.token, {"error": "not placed in the spine"}), indent=1))
        return 0
    return build()


if __name__ == "__main__":
    raise SystemExit(main())
