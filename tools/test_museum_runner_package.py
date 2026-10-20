"""Export the runner and Shadow Game encounter without access to doc/.

Uses the Android preset's include/exclude filters and compiled-script mode in a
small Windows PCK. This checks packaging and staging's scene type, not Android
rendering, a full museum export, or physical headset input.
"""
import configparser
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "doc/book/iterations/2026-10-18-runner-levels"
GODOT = os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe")
WORK = ROOT / "ada_run/museum-runner-package-test"
OUT.mkdir(parents=True, exist_ok=True)
WORK.mkdir(parents=True, exist_ok=True)
(WORK / ".gdignore").touch()
sys.stdout.reconfigure(encoding="utf-8")
checks = []


def check(name, passed):
    checks.append({"name": name, "passed": bool(passed)})
    if not passed:
        raise AssertionError(name)


def invoke(label, args, cwd, timeout=100):
    log_path = OUT / f"package-{label}.log"
    with log_path.open("w", encoding="utf-8") as log:
        process = subprocess.Popen([GODOT, *args], cwd=cwd, stdout=log,
                                   stderr=subprocess.STDOUT,
                                   creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0)
        try:
            code = process.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
            code = 124
    text = log_path.read_text(encoding="utf-8", errors="replace")
    print(f"{label}: exit {code}; {log_path.name}", flush=True)
    if code != 0 or "SCRIPT ERROR:" in text or "Parse Error:" in text:
        print(text[-6000:], flush=True)
        raise RuntimeError(f"{label} failed (exit {code}); see {log_path}")


def run():
    provenance = json.loads((ROOT / "commons/museum_runner/forms/provenance.json").read_text())
    for name, item in provenance.items():
        data = (ROOT / "commons/museum_runner/forms" / name).read_bytes()
        check(f"{name}: exact recorded lesson source", data == (ROOT / item["source"]).read_bytes()
              and hashlib.sha256(data).hexdigest() == item["sha256"])
    for name in ["game.gd", "chunk.gd"]:
        check(f"{name}: no documentation preload", "res://doc/" not in (ROOT / "commons/museum_runner" / name).read_text(encoding="utf-8"))
    for name in ["world.gd", "encounter.gd", "point.gd", "piece.gd"]:
        check(f"Shadow Game {name}: no documentation dependency", "res://doc/" not in (ROOT / "commons/shadow_game" / name).read_text(encoding="utf-8"))

    presets = configparser.ConfigParser(interpolation=None)
    presets.read(ROOT / "export_presets.cfg", encoding="utf-8")
    android = next(presets[s] for s in presets.sections() if presets[s].get("platform") == '"Android"')
    check("shipping export excludes documentation", "doc/" in android["exclude_filter"])
    # Fresh source staging and a separate empty runtime folder. The latter has
    # only the PCK: a missing resource cannot fall back to this working checkout.
    stage = Path(tempfile.mkdtemp(prefix="run-", dir=WORK))
    project = stage / "source"
    runtime = stage / "runtime"
    project.mkdir()
    runtime.mkdir()

    def copy(relative):
        destination = project / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / relative, destination)

    # Keep the real XRTools scripts/assets, but only the scenes in this mode's
    # dependency chain. Exporting unrelated addon demos would test their editor
    # tool lifecycle as well (e.g. FallDamage's Node/Node3D mismatch).
    xr_scenes = {"staging/scene_base.tscn", "player/player_body.tscn", "objects/hand_pose_area.tscn"}
    xr_root = ROOT / "addons/godot-xr-tools"
    for path in xr_root.rglob("*"):
        if not path.is_file() or path.suffix == ".import" or ".git" in path.parts:
            continue
        if path.suffix == ".tscn" and path.relative_to(xr_root).as_posix() not in xr_scenes:
            continue
        copy(path.relative_to(ROOT))
    for path in (ROOT / "commons/museum_runner").rglob("*"):
        if path.is_file() and path.suffix in {".gd", ".tscn", ".json"} and path.name != "verify.gd":
            copy(path.relative_to(ROOT))
    for relative in ["commons/artifacts/resolution_colonnade/resolution_totem.gd",
                     "commons/hazards/biome_ladder/route.gd", "doc/.gdignore",
                     "commons/shadow_game/encounter.gd", "commons/shadow_game/point.gd",
                     "commons/shadow_game/socket_frame.gd",
                     "commons/shadow_game/piece.gd", "commons/interactables/cube_button.gd",
                     "commons/interactables/cube_button.tscn", "commons/interactables/push_button.gd",
                     "commons/interactables/push_button.tscn",
                     "commons/interactables/interactable_area_button_pointer.gd",
                     "commons/font/Roboto-VariableFont_wdth,wght.ttf"]:
        copy(relative)
    # Include originals in the ignored source tree, just as in the real project.
    for item in provenance.values():
        copy(item["source"])
    (project / "doc/package-sentinel.txt").write_text("This must not reach the package.")
    shutil.copy2(ROOT / "tools/probes/museum_runner_package_probe.gd", project / "package_probe.gd")
    # tools/ is intentionally excluded from shipping; package this test-only
    # harness at the isolated project's root, beside package_probe.gd.
    shutil.copy2(ROOT / "tools/probes/museum_runner_xr_input.gd", project / "runner_xr_input_probe.gd")
    shutil.copy2(ROOT / "tools/probes/museum_runner_levels.gd", project / "runner_levels_probe.gd")
    (project / "staging_type_probe.gd").write_text('''extends RefCounted
static func assign_scene(scene: XRToolsSceneBase) -> XRToolsSceneBase:
    return scene
''', encoding="utf-8")
    (project / "project.godot").write_text('''config_version=5
[application]
config/name="Museum Runner package regression"
[autoload]
XRToolsUserSettings="*res://addons/godot-xr-tools/user_settings/user_settings.gd"
XRToolsRumbleManager="*res://addons/godot-xr-tools/rumble/rumble_manager.gd"
[filesystem]
import/blender/enabled=false
[rendering]
renderer/rendering_method="gl_compatibility"
''', encoding="utf-8")
    (project / "export_presets.cfg").write_text(f'''[preset.0]
name="Runner package regression"
platform="Windows Desktop"
runnable=true
export_filter="all_resources"
include_filter={android['include_filter']}
exclude_filter={android['exclude_filter']}
script_export_mode={android['script_export_mode']}
[preset.0.options]
binary_format/architecture="x86_64"
''', encoding="utf-8")
    invoke("import", ["--headless", "--path", str(project), "--editor", "--import"], project, 180)
    package = runtime / "runner.pck"
    invoke("export", ["--headless", "--path", str(project), "--export-pack",
                       "Runner package regression", str(package)], project, 180)
    report = OUT / "package-checks.json"
    if report.exists():
        report.unlink()
    invoke("run", ["--headless", "--path", str(runtime), "--main-pack", str(package),
                   "--xr-mode", "off", "--script", "res://package_probe.gd",
                   "--", "--report=" + str(report)], runtime)
    result = json.loads(report.read_text(encoding="utf-8"))
    check("exported package assertions pass", result["passed"])
    check("runtime folder contains no loose source project", not (runtime / "project.godot").exists()
          and not (runtime / "doc").exists() and not (runtime / "commons").exists())
    return {"passed": True, "checks": checks, "native": result,
            "package_sha256": hashlib.sha256(package.read_bytes()).hexdigest(),
            "package": str(package), "shipping_filters": dict(android),
            "scope": "Windows PCK using Android export exclusions and script mode; real runner, Shadow Game encounter and XRTools, documentation absent. Shadow Game's full world is checked separately by test_shadow_game.py. Not an APK or headset test."}


try:
    receipt = run()
except Exception as exc:
    receipt = {"passed": False, "checks": checks, "error": str(exc)}
(OUT / "package-receipt.json").write_text(json.dumps(receipt, indent=2), encoding="utf-8")
print(json.dumps({"passed": receipt["passed"], "checks": len(checks), "error": receipt.get("error")}), flush=True)
raise SystemExit(0 if receipt["passed"] else 1)
