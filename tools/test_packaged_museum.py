#!/usr/bin/env python3
"""Run hall/ghost probes against resources extracted from the actual Quest APK.

Only the test harness and an isolated user-data setting are injected. Museum and
artifact scripts come from the APK's bytecode, never the working-tree source.
"""
from pathlib import Path
import argparse
import hashlib
import json
import re
import subprocess
import zipfile
from verify_museum_apk import apk_name

ROOT = Path(__file__).resolve().parents[1]
GODOT = Path("C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe")


def digest(path):
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def run(apk, out):
    sha = digest(apk)
    runtime = out / ("runtime-" + sha[:12])
    runtime.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(apk) as package:
        for info in package.infolist():
            if not info.filename.startswith("assets/") or info.is_dir():
                continue
            target = runtime / apk_name(info).removeprefix("assets/")
            if not target.resolve().is_relative_to(runtime.resolve()):
                raise ValueError("Unsafe package path")
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(package.read(info))
    # The production binary settings remain. Godot reads this documented local
    # override after them; the probes also assert the resulting user-data path.
    (runtime / "override.cfg").write_text(
        '[application]\nconfig/use_custom_user_dir=true\n'
        'config/custom_user_dir="AdaResearch_Lean_APK_Verification"\n', encoding="utf-8")

    # Reuse the established ghost tests without replacing their historical output.
    cases = []
    ghost_dir = out / "prefab-reconstruction"
    ghost_dir.mkdir(exist_ok=True)
    source = (ROOT / "doc/book/iterations/2026-10-16-ghost-prefab-playtest/verify.gd").read_text(encoding="utf-8")
    source = source.replace('const DIR="res://doc/book/iterations/2026-10-16-ghost-prefab-playtest/"',
                            'const DIR="' + ghost_dir.as_posix() + '/"')
    source = source.replace('AudioServer.set_bus_mute(0,true);',
        'if not OS.get_user_data_dir().contains("AdaResearch_Lean_APK_Verification"): quit(2);return\n\tcheck("isolated test user-data directory",true)\n\tAudioServer.set_bus_mute(0,true);')
    script = ghost_dir / "verify.gd"
    script.write_text(source, encoding="utf-8")
    cases.append(("prefab-reconstruction", script, [], ghost_dir / "verification.json"))

    base = (ROOT / "tools/probes/transformation_encounters.gd").read_text(encoding="utf-8")
    base = base.replace('func run() -> void:', 'func run() -> void:\n\tif not OS.get_user_data_dir().contains("AdaResearch_Lean_APK_Verification"): quit(2);return')
    base = base.replace('museum = load(folder + "museum_snapshot.tscn").instantiate()',
                        'museum = load("res://commons/scenes/endless_museum.tscn").instantiate()')
    base = base.replace('museum.set("plan_file",folder+"plan.json")',
                        'museum.set("plan_file","res://commons/data/museum/em_plan.json")')
    base = base.replace('museum.set("plan_file", folder+"plan.json")',
                        'museum.set("plan_file", "res://commons/data/museum/em_plan.json")')
    base_path = out / "hall-base.gd"
    base_path.write_text(base, encoding="utf-8")
    for room, sequence in [("Random_Entropy", "randomness"), ("Random_Definition", "randomness"),
                           ("Noise_Columns", "noise"), ("Point_Animatedcube", "primitives")]:
        folder = out / room
        folder.mkdir(exist_ok=True)
        control = json.loads((runtime / "ada_run/em_control.json").read_text(encoding="utf-8-sig"))
        control.update(first_chapter=sequence, first_map=room, dollhouse=0)
        for key in ("resume_eye", "resume_hall", "resume_yaw", "resume_pitch"):
            control.pop(key, None)
        (folder / "control.json").write_text(json.dumps(control), encoding="utf-8")
        for name, production in [("necklace_hand.json", "ada_run/necklace_hand.json"),
                                 ("em_overrides.json", "commons/data/museum/em_overrides.json")]:
            src = runtime / production
            (folder / name).write_bytes(src.read_bytes() if src.exists() else b"{}")
        spec = folder / "spec.json"
        spec.write_text(json.dumps({"run": folder.as_posix() + "/", "room": room, "sequence": sequence}), encoding="utf-8")
        if room == "Random_Entropy":
            test = (ROOT / "doc/book/iterations/2026-10-16-ghost-prefab-playtest/museum_probe.gd").read_text(encoding="utf-8")
            test = test.replace('extends "res://tools/probes/transformation_encounters.gd"', 'extends "' + base_path.as_posix() + '"')
        else:
            test = 'extends "' + base_path.as_posix() + '"\n' + '''func landing_checks() -> void:
	AudioServer.set_bus_mute(0,true)
	check("isolated test user-data directory",OS.get_user_data_dir().contains("AdaResearch_Lean_APK_Verification"))
	museum.call("flush_stamps");await create_timer(0.5).timeout
	var count:=0
	var placeholders:=0
	for row in museum.get("_edit_records"):
		if row.get("seg")!=hall:continue
		var node: Node3D=row.get("node")
		check("placed artifact exists: "+str(row.get("token")),is_instance_valid(node))
		if is_instance_valid(node):
			count+=1
			if node.get_meta("is_placeholder_artifact",false):placeholders+=1
	check("hall contains artifact instances",count>0)
	check("no missing-artifact placeholders",placeholders==0)
	check("hall contains physical floor",not hall.find_children("*","CollisionShape3D",true,false).is_empty())
	var view: Camera3D=museum.get("_cam")
	if view!=null:
		camera.global_transform=view.global_transform;camera.current=true
		await create_timer(0.3).timeout;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(folder+"hall.png")
	observations={"artifact_count":count,"placeholders":placeholders,"source":"Actual APK bytecode/resources"}
'''
        script = folder / "verify.gd"
        script.write_text(test, encoding="utf-8")
        cases.append((room, script, [str(spec)], folder / "report.json"))

    results = []
    for name, script, user_args, report in cases:
        print("Running packaged resources:", name, flush=True)
        cmd = [str(GODOT), "--path", str(runtime), "--xr-mode", "off", "--rendering-method", "gl_compatibility",
               "--no-window", "--log-file", str(script.parent / "engine.log"), "--script", str(script),
               "--", *user_args, "--no-bridges"]
        log_path = script.parent / "stdout.log"
        try:
            with log_path.open("wb") as log:
                process = subprocess.run(cmd, stdout=log, stderr=subprocess.STDOUT, timeout=180,
                                         creationflags=subprocess.CREATE_NO_WINDOW)
            code = process.returncode
        except subprocess.TimeoutExpired:
            code = "timeout"
        text = log_path.read_text(encoding="utf-8", errors="replace")
        script_errors = [line for line in text.splitlines() if "SCRIPT ERROR" in line or "Parse Error" in line]
        data = json.loads(report.read_text(encoding="utf-8")) if report.exists() else {}
        checks = data.get("checks", [])
        passed = code == 0 and bool(checks) and all(c.get("passed") for c in checks) and not script_errors
        row = {"case": name, "exit_code": code, "passed": passed, "checks": len(checks),
               "script_errors": script_errors, "report": str(report), "log": str(log_path)}
        results.append(row)
        (out / "native-results.json").write_text(json.dumps({"apk_sha256": sha, "runtime": str(runtime),
            "passed": all(r["passed"] for r in results), "results": results}, indent=2), encoding="utf-8")
        print(json.dumps(row), flush=True)
        if not passed:
            print(text[-5000:], flush=True)
            return 1
    return 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("apk", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    raise SystemExit(run(args.apk.resolve(), args.output.resolve()))
