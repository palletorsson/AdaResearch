"""Render the authored Boolean egg preview with the project's portable Godot."""
from pathlib import Path
import hashlib
import json
import os
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "doc/book/iterations/2026-10-01-kapoor-surface-and-depth/figures"
SOURCES = [
    "commons/artifacts/kapoor_void_studies/boolean_eggs.gd",
    "commons/artifacts/kapoor_void_studies/boolean_eggs.tscn",
    "commons/artifacts/kapoor_void_studies/boolean_eggs_preview.gd",
    "commons/artifacts/kapoor_void_studies/boolean_eggs_preview.tscn",
    "tools/captures/boolean_eggs.gd",
]


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    workspace = Path(tempfile.mkdtemp(prefix="ada-boolean-eggs-"))
    hashes = {}
    for name in SOURCES:
        target = workspace / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / name, target)
        hashes[name] = hashlib.sha256(target.read_bytes()).hexdigest()
    (workspace / "project.godot").write_text(
        'config_version=5\n[application]\nconfig/name="Boolean eggs capture"\n'
        '[rendering]\nrenderer/rendering_method="gl_compatibility"\n',
        encoding="utf-8",
    )
    godot = Path(os.environ.get("GODOT_EXE", str(Path.home() / "Desktop/Godot_v4.6-stable_win64.exe")))
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 0
    common = dict(cwd=workspace, capture_output=True, text=True, encoding="utf-8", errors="replace", startupinfo=startup)
    commands = [
        ("eggs-import.log", [str(godot), "--headless", "--path", str(workspace), "--editor", "--import"]),
        ("eggs-capture.log", [str(godot), "--path", str(workspace), "--rendering-method", "gl_compatibility",
                              "--resolution", "128x128", "--position", "-10000,-10000", "--script",
                              "res://tools/captures/boolean_eggs.gd", "--", OUT.as_posix()]),
    ]
    for log_name, command in commands:
        result = subprocess.run(command, timeout=60, **common)
        log = result.stdout + result.stderr
        (OUT / log_name).write_text(log, encoding="utf-8")
        print(log[-4500:])
        if result.returncode or "SCRIPT ERROR" in log or "ERROR:" in log:
            return result.returncode or 1
    (OUT / "eggs-provenance.json").write_text(json.dumps({
        "godot": str(godot), "source_files": hashes, "isolated_project": str(workspace),
        "size": [2000, 1400], "renderer": "gl_compatibility", "scene_lighting_unchanged": True,
        "closeup_labels_hidden": True,
        "scope": "Actual authored companion scene, not the assembled museum or a headset capture",
    }, indent=2) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
