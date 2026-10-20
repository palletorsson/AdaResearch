"""Update only the four Point Trace paint-box models in the existing web editor."""
from pathlib import Path
import hashlib
import json
import os
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
WEB = ROOT.parent / "ada_encyclopedia/public/void-models"
OUT = ROOT / "doc/book/iterations/2026-10-20-trace-paint-boxes/editor"
STAGE = Path((ROOT / "ada_run/void-game-test/latest.txt").read_text().strip()) / "source"
OUT.mkdir(parents=True, exist_ok=True)
for name in ("export_void_editor.gd", "export_trace_paint_boxes.gd"):
    shutil.copy2(ROOT / "tools/probes" / name, STAGE / "tools/probes" / name)
with (OUT / "export.log").open("w", encoding="utf-8") as stream:
    result = subprocess.run([
        os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"),
        "--headless", "--path", str(STAGE), "--script",
        "res://tools/probes/export_trace_paint_boxes.gd", "--", "--out=" + str(OUT)],
        stdout=stream, stderr=subprocess.STDOUT, timeout=90,
        creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0)
log = (OUT / "export.log").read_text(encoding="utf-8", errors="replace")
assert result.returncode == 0 and "SCRIPT ERROR" not in log and "\nERROR:" not in log, log[-5000:]
patch = json.loads((OUT / "trace-paint-boxes.json").read_text())
assert not patch["failures"] and len(patch["artifacts"]) == 4
manifest_path = WEB / "manifest.json"
manifest = json.loads(manifest_path.read_text())
assert manifest["floors"]["4"]["map"] == "Point_Trace"
shutil.copy2(manifest_path, OUT / "manifest-before.json")
records = manifest["floors"]["4"]["artifacts"]
records.pop("museum-point_line_grid-7-15", None)
records.update(patch["artifacts"])
for key, record in patch["artifacts"].items():
    assert record["model"]["meshes"] > 0 and record["model"]["labels"]
    filename = Path(record["model"]["url"]).name
    shutil.copy2(OUT / filename, WEB / filename)
for relative in ("commons/void/rooms.json", "commons/void/catalog.json",
                 "commons/artifacts/trace_paint_box/trace_paint_box.gd",
                 "commons/artifacts/trace_paint_box/trace_paint_box.tscn"):
    manifest.setdefault("source_files", {})[relative] = hashlib.sha256((ROOT / relative).read_bytes()).hexdigest()
manifest["revision"] = hashlib.sha256(json.dumps(manifest).encode()).hexdigest()[:12]
manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
(OUT / "checks.json").write_text(json.dumps({
    "passed": True, "models": list(patch["artifacts"]),
    "scope": "Only the four native paint-box models replace the original vitrine entry in the web editor manifest.",
    "revision": manifest["revision"]
}, indent=2), encoding="utf-8")
print("Four native paint-box models and their labels exported to the layout editor.")
