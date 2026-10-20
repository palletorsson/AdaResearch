"""Run the native cycle, cross-process replay, and exact printed-code reconstruction."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[5]
COMPANION = ROOT / "doc/book/experiments/random-definition/seed-bench-001"
GODOT = Path("C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe")


def run(name, base, output, replay=False, expected_failure=False):
    report = output / (name + ".json")
    args = [str(GODOT), "--headless", "--path", str(ROOT), "--xr-mode", "off",
            "--script", "res://" + (HERE / "probe.gd").relative_to(ROOT).as_posix(), "--", "--no-bridges",
            "--base=res://" + base.relative_to(ROOT).as_posix() + "/",
            "--report=" + report.as_posix(), "--record=" + (output / "kept.json").as_posix()]
    if replay:
        args.append("--replay-only")
    try:
        result = subprocess.run(args, capture_output=True, encoding="utf-8", errors="replace",
                                timeout=60, creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
    except subprocess.TimeoutExpired as exc:
        (output / (name + ".timeout.txt")).write_text(str(exc), encoding="utf-8")
        raise
    log = result.stdout + result.stderr
    (output / (name + ".log")).write_text(log, encoding="utf-8")
    data = json.loads(report.read_text(encoding="utf-8")) if report.exists() else {}
    ok = result.returncode == 0 and data.get("passed") and "SCRIPT ERROR" not in log
    print(f"{name}: {'PASS' if ok else 'FAIL'} ({len(data.get('checks', []))} checks)")
    if not ok and not expected_failure:
        print(log[-6000:])
    return bool(ok)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--tag", required=True, help="New evidence directory; existing runs are never overwritten")
    parser.add_argument("--printed", action="store_true")
    parser.add_argument("--faults", action="store_true")
    args = parser.parse_args()
    if not re.fullmatch(r"[a-z0-9-]+", args.tag):
        raise SystemExit("Invalid tag")
    output = HERE / "runs" / args.tag
    output.mkdir(parents=True, exist_ok=False)
    runtime = COMPANION / "runtime"
    hashes = {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
              for p in list(runtime.glob("*")) + [HERE / "probe.gd", Path(__file__)] if p.is_file() and not p.name.endswith(".uid")}
    (output / "sources.json").write_text(json.dumps(hashes, indent=2) + "\n", encoding="utf-8")
    ok = run("native", runtime, output)
    ok = run("fresh-process", runtime, output, True) and ok
    if args.printed:
        text = (COMPANION / "tutorial.md").read_text(encoding="utf-8")
        blocks = dict(re.findall(r"<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)```", text, re.S))
        assert set(blocks) == {"seed_record.gd", "seed_study.gd", "seed_board.gd"}
        extracted = output / "extracted"
        extracted.mkdir()
        for name, code in blocks.items():
            (extracted / name).write_text(code, encoding="utf-8")
            assert code == (runtime / name).read_text(encoding="utf-8"), name
        ok = run("printed-reconstruction", extracted, output) and ok
        hashes[(COMPANION / "tutorial.md").relative_to(ROOT).as_posix()] = hashlib.sha256((COMPANION / "tutorial.md").read_bytes()).hexdigest()
    if args.faults:
        source = (runtime / "seed_record.gd").read_text(encoding="utf-8")
        faults = {
            "alias": ("kept = current.duplicate(true)", "kept = current"),
            "draw-on-switch": ("\treturn true\n\nfunc cells", "\tcurrent.raw_values[0] = 0.0\n\treturn true\n\nfunc cells"),
            "drifting-bottom": ("y = p.bottom_m + size.y / 2.0", "y = p.bottom_m + p.cube_side_m / 2.0"),
            "wrong-mean": ("(a + b + c) / 3.0", "a"),
            "bad-import-mutation": ("error = validate(parser.data)", "current.clear()\n\terror = validate(parser.data)")
        }
        for name, (old, new) in faults.items():
            assert source.count(old) == 1
            folder = output / name
            folder.mkdir()
            (folder / "seed_record.gd").write_text(source.replace(old, new), encoding="utf-8")
            detected = not run("fault", folder, folder, expected_failure=True)
            report = json.loads((folder / "fault.json").read_text(encoding="utf-8"))
            ok = detected and bool(report.get("failures")) and ok
    (output / "sources.json").write_text(json.dumps(hashes, indent=2) + "\n", encoding="utf-8")
    (output / "summary.json").write_text(json.dumps({"passed": ok, "printed": args.printed, "faults": args.faults,
        "physical_VR": "not_tested", "independent_learner": "not_tested"}, indent=2) + "\n", encoding="utf-8")
    raise SystemExit(0 if ok else 1)


if __name__ == "__main__":
    main()
