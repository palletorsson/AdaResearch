"""interaction_dna.py — DNA-style auto-research for interaction primitives.

The fifth pillar after substrates / primitives-dna / chamber / promotions-dna.
Where those substrate-ify the *artifact-as-noun* (its visual surface, mesh
shape, description, origin), this substrate-ifies the *artifact-as-verb*:
how the player encounters it.

The project already has a real interaction taxonomy:
  slider × {horizontal, axis, plane, smooth, snap, time, zero}
  lever  × {smooth, snap, zero}
  joystick × {smooth, snap, zero}
  dial × {smooth}
  wheel × {smooth}
  knob × {test}
  button × {push, push_2d3d, push_2d3d_content, push_front}

Each variant in a family shares the same interactable_*.gd script and
differs in scene config — exactly the substrate-DNA pattern. This tool
inventories them, captures multi-angle stills, and generates a manifest
the /interactions-dna page reads.

Usage:
    python tools/interaction_dna.py sweep      # capture all known
    python tools/interaction_dna.py sweep slider  # only one family
    python tools/interaction_dna.py list       # what's on disk

Storage convention: research material in encyclopedia/public/interaction-runs/.
"""

from __future__ import annotations

import argparse
import datetime
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
ENCY = REPO.parent / "ada_encyclopedia"
INTERACTABLES_DIR = REPO / "commons" / "interactables"
INTERACTION_RUNS = ENCY / "public" / "interaction-runs"
GODOT_EXE = "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"
CAPTURE_SCRIPT = "res://commons/testing/capture_scene_path.gd"

# ── Family taxonomy ─────────────────────────────────────────────────
# Each family collects scenes by filename prefix. A scene is in a family
# if its filename starts with the family name (slider_*.tscn → slider).
# Variants are everything-after-the-prefix.

FAMILIES: dict[str, dict[str, str]] = {
    "slider": {
        "essence": "linear continuous control — a knob constrained to one axis",
        "behavior_dimension": "smooth (continuous) / snap (discrete steps) / zero (returns to zero)",
    },
    "lever": {
        "essence": "rotational control around a fixed pivot — pull to actuate",
        "behavior_dimension": "smooth / snap / zero (springs back)",
    },
    "joystick": {
        "essence": "two-axis directional control — push toward direction",
        "behavior_dimension": "smooth / snap / zero (springs to center)",
    },
    "dial": {
        "essence": "rotational continuous control — spin to set value",
        "behavior_dimension": "smooth (continuous angle)",
    },
    "wheel": {
        "essence": "free-spinning rotational control — flick to set angular velocity",
        "behavior_dimension": "smooth (free rotation)",
    },
    "knob": {
        "essence": "small rotational control — variant of dial for fine tuning",
        "behavior_dimension": "(test artifact)",
    },
    "push_button": {
        "essence": "momentary press — depress to trigger, releases automatically",
        "behavior_dimension": "different visual styles (3d depth, 2d face, frontal panel)",
    },
}


def _short(p: Path) -> str:
    try:
        return str(p.relative_to(REPO))
    except ValueError:
        return str(p)


def _discover_interactions() -> dict[str, list[dict]]:
    """Scan commons/interactables/*.tscn and group by family."""
    families: dict[str, list[dict]] = {f: [] for f in FAMILIES}
    if not INTERACTABLES_DIR.exists():
        return families

    for tscn in sorted(INTERACTABLES_DIR.glob("*.tscn")):
        name = tscn.stem  # e.g. "slider_smooth"
        # Match against family prefixes.
        matched_family: str | None = None
        variant: str = name
        for fam in FAMILIES:
            if name == fam:
                matched_family = fam
                variant = "default"
                break
            if name.startswith(fam + "_"):
                matched_family = fam
                variant = name[len(fam) + 1:]
                break

        # Special-case push_button (not push_button_smooth etc).
        if matched_family is None and name.startswith("push_button"):
            matched_family = "push_button"
            variant = name[len("push_button"):].lstrip("_") or "default"

        if matched_family:
            families[matched_family].append({
                "token": name,
                "variant": variant,
                "scene_path": f"res://commons/interactables/{name}.tscn",
            })

    return families


def cmd_sweep(args) -> int:
    if not Path(GODOT_EXE).exists():
        print(f"  !! Godot exe not found: {GODOT_EXE}", file=sys.stderr)
        return 1
    if not ENCY.exists():
        print(f"  !! encyclopedia not found at {ENCY}", file=sys.stderr)
        return 1

    INTERACTION_RUNS.mkdir(parents=True, exist_ok=True)

    families = _discover_interactions()
    family_filter = args.family

    total_scenes = sum(len(v) for v in families.values())
    print(f"interaction_dna sweep: {total_scenes} scenes across {len(families)} families")

    user_data = (
        Path(os.environ.get("APPDATA", ""))
        / "Godot/app_userdata/Ada Research Zero One"
        / "interaction_dna_out"
    )
    user_data.mkdir(parents=True, exist_ok=True)

    captured: list[str] = []
    failed: list[str] = []

    for family, scenes in families.items():
        if family_filter and family != family_filter:
            continue
        if not scenes:
            continue
        print(f"  {family}: {len(scenes)} variants")
        for scene_info in scenes:
            token = scene_info["token"]
            scene_path = scene_info["scene_path"]
            out_dir = user_data / token
            if out_dir.exists():
                shutil.rmtree(out_dir)
            out_dir.mkdir(parents=True, exist_ok=True)

            cmd = [
                GODOT_EXE,
                "--path", str(REPO),
                "--xr-mode", "off",
                "--no-window",
                "--script", CAPTURE_SCRIPT, "--",
                f"--scene={scene_path}",
                f"--out=user://interaction_dna_out/{token}",
            ]
            try:
                result = subprocess.run(
                    cmd, check=False, capture_output=True, text=True, timeout=60
                )
                # Copy results to encyclopedia public.
                target_dir = INTERACTION_RUNS / token
                target_dir.mkdir(parents=True, exist_ok=True)
                n = 0
                for angle in ("front", "left", "right", "top"):
                    src = out_dir / f"{angle}.png"
                    if src.exists():
                        shutil.copy(str(src), str(target_dir / f"{angle}.png"))
                        n += 1
                if n > 0:
                    captured.append(token)
                    print(f"    OK {token} ({n} angles)")
                else:
                    failed.append(token)
                    print(f"    XX {token} (no captures)")
            except subprocess.TimeoutExpired:
                failed.append(token)
                print(f"    XX {token} (timeout)")
            except Exception as e:
                failed.append(token)
                print(f"    XX {token} ({e})")

    # Write manifest.
    manifest_artifacts = []
    for family, scenes in families.items():
        for scene_info in scenes:
            token = scene_info["token"]
            artifact_dir = INTERACTION_RUNS / token
            angles = []
            for angle in ("front", "left", "right", "top"):
                if (artifact_dir / f"{angle}.png").exists():
                    angles.append(angle)
            manifest_artifacts.append({
                "token": token,
                "family": family,
                "variant": scene_info["variant"],
                "scene_path": scene_info["scene_path"],
                "captures": angles,
            })

    manifest = {
        "generated_at": datetime.datetime.now().isoformat(timespec="seconds"),
        "total": len(manifest_artifacts),
        "families": {f: FAMILIES[f] for f in FAMILIES},
        "artifacts": manifest_artifacts,
    }
    manifest_path = INTERACTION_RUNS / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(f"  manifest: {_short(manifest_path)}")
    print(f"  captured: {len(captured)} / failed: {len(failed)}")
    print(f"  view: http://localhost:3003/interactions-dna")
    return 0


def cmd_list(args) -> int:
    families = _discover_interactions()
    print(f"  {'family':12s}  {'variants':>10s}  {'sample tokens'}")
    for family, scenes in families.items():
        if not scenes:
            continue
        names = ", ".join(s["variant"] for s in scenes[:5])
        if len(scenes) > 5:
            names += ", ..."
        print(f"  {family:12s}  {len(scenes):>4d}        {names}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(prog="interaction_dna")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_sweep = sub.add_parser("sweep", help="capture all interactables (or one family)")
    p_sweep.add_argument("family", nargs="?", default=None,
                         help=f"optional family filter ({', '.join(FAMILIES.keys())})")
    p_sweep.set_defaults(func=cmd_sweep)

    p_list = sub.add_parser("list", help="list discovered interactables grouped by family")
    p_list.set_defaults(func=cmd_list)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
