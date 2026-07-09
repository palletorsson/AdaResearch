"""prop_isolation.py — one small map per exhibit prop, to inspect it alone.

Palle: "for each prop or principal create a specific scene for that object
so you can look at it in isolation." Each Prop_<name> map is a tiny lit room
with a single object centred on a dais of context, spawn a few steps back, a
name label, and (for the wedge) a real 2->1 step so its ramp is visible. Walk
or capture any one without the noise of a full gallery.

Usage: python tools/prop_isolation.py            # writes all Prop_* maps
       python tools/prop_isolation.py --capture   # + headless captures
"""
import json
import re
import subprocess
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8", errors="replace")
ROOT = Path(__file__).resolve().parent.parent

# (map_suffix, interactable token, needs_step)
PROPS = [
    ("podium_m", "exhibit_podium#kind:podium#size:m", False),
    ("podium_s", "exhibit_podium#size:s", False),
    ("podium_l", "exhibit_podium#size:l", False),
    ("dais", "exhibit_podium#kind:dais", False),
    ("vitrine", "exhibit_vitrine", False),
    ("floating_wall", "exhibit_furniture#kind:floating_wall#w:4", False),
    ("plinth_s", "exhibit_furniture#kind:plinth#size:s", False),
    ("plinth_m", "exhibit_furniture#kind:plinth#size:m", False),
    ("plinth_l", "exhibit_furniture#kind:plinth#size:l", False),
    ("hollow_plinth", "exhibit_furniture#kind:hollow_plinth", False),
    ("platform", "exhibit_furniture#kind:platform#size:l", False),
    ("table_2m", "exhibit_furniture#kind:table_2m", False),
    ("vitrine_tall", "exhibit_furniture#kind:vitrine_tall", False),
    ("cabinet", "exhibit_furniture#kind:cabinet", False),
    ("infoboard", "exhibit_furniture#kind:infoboard", False),
    ("sign_exit", "exhibit_furniture#kind:sign_exit", False),
    ("sign_fire", "exhibit_furniture#kind:sign_fire", False),
    ("wedge", "", True),        # the walkable prism on a real step
]

W, D = 9, 9


def compact(data):
    text = json.dumps(data, indent=1)
    return re.sub(r'\[\s+((?:"[^"]*",?\s+)+)\]',
                  lambda m: '[' + ', '.join(x.strip().rstrip(',')
                                            for x in m.group(1).split('\n') if x.strip()) + ']', text)


def build(suffix, token, needs_step):
    structure = [["1"] * W for _ in range(D)]
    utilities = [[" "] * W for _ in range(D)]
    inter = [[" "] * W for _ in range(D)]

    cx, cz = W // 2, D // 2
    utilities[cz][1] = "s"                     # spawn a few steps west
    utilities[cz][W - 1] = "t"
    structure[cz][W - 1] = "0"

    if needs_step:
        # a west-high 2->1 step with the wedge, so the ramp is legible
        for r in range(cz - 1, cz + 2):
            structure[r][cx - 1] = "2"          # high plateau (west)
            structure[r][cx] = "1"              # low cell with wedge
        utilities[cz][cx] = "wp:90"            # ramp rises WEST (verified)
        inter[cz + 2][cx] = "exhibit_furniture#kind:infoboard"
    else:
        inter[cz][cx] = token

    title = f"Prop_{suffix}"
    data = {
        "map_info": {
            "name": f"Prop: {suffix.replace('_', ' ')}", "title": title, "lookup_name": title,
            "description": f"Isolation scene for {token or 'the walkable-prism wedge (wp:90 on a west-high step)'} "
                           f"- one object, lit, alone, to inspect in the tester or a capture.",
            "version": "0.1", "format": "json",
            "dimensions": {"width": W, "depth": D, "max_height": 2},
            "metadata": {"difficulty": "beginner", "category": "test",
                         "estimated_time": "1 min", "learning_objectives": [f"inspect {suffix}"]},
        },
        "utility_definitions": {"s": {"type": "spawn", "description": "step back and look"},
                                "t": {"type": "teleporter", "description": "exit"}},
        "settings": {"cube_size": 1.0, "gutter": 0.02, "show_grid": True, "enable_physics": True,
                     "auto_reveal_on_entry": False, "initial_tile_visibility": "all", "background": "dark"},
        "lighting": {"ambient_color": [0.55, 0.55, 0.6], "ambient_energy": 0.75,
                     "directional_light": {"enabled": True, "direction": [-0.3, -0.8, -0.35],
                                           "color": [1.0, 0.99, 0.95], "energy": 1.0}},
        "layers": {"structure": structure, "utilities": utilities, "interactables": inter},
    }
    out = ROOT / "commons" / "maps" / title
    out.mkdir(parents=True, exist_ok=True)
    (out / "map_data.json").write_text(compact(data), encoding="utf-8")
    return title


def main():
    do_capture = "--capture" in sys.argv
    titles = [build(s, t, step) for (s, t, step) in PROPS]
    print(f"wrote {len(titles)} isolation maps: {', '.join(titles)}")
    if do_capture:
        exe = "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"
        base = Path(r"C:/Users/palle/AppData/Roaming/Godot/app_userdata/Ada Research Zero One/multi_shots")
        for t in titles:
            (base / t).exists() and __import__("shutil").rmtree(base / t, ignore_errors=True)
            subprocess.run(["python", "tools/godot_watchdog.py",
                            f"--expect={base / t}", "--", exe, "--path", ".",
                            "--xr-mode", "off", "--no-window", "--script",
                            "res://commons/testing/capture_multi_angle.gd", "--",
                            "--mode=map", f"--target={t}"], cwd=ROOT)


if __name__ == "__main__":
    main()
