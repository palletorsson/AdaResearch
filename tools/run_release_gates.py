#!/usr/bin/env python3
"""
Run release gates for AdaResearch and print a pass/fail scoreboard.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
from collections import Counter
from pathlib import Path
from typing import Any


REPO = Path(__file__).resolve().parent.parent
DEFAULT_GATE_TOGGLES_PATH = REPO / "doc/reports/RELEASE_GATES_TOGGLES.json"


def run_cmd(cmd: list[str], env: dict[str, str] | None = None) -> tuple[int, str]:
    proc = subprocess.run(
        cmd,
        cwd=REPO,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        env=env,
    )
    out = (proc.stdout or "") + (proc.stderr or "")
    return proc.returncode, out


def parse_lab_audit_output(text: str) -> dict[str, Any]:
    total_issues = 0
    m = re.search(r"TOTAL ISSUES:\s*(\d+)", text)
    if m:
        total_issues = int(m.group(1))

    lost_lines = [line for line in text.splitlines() if " LOST " in line]
    changed_lines = [line for line in text.splitlines() if " CHANGED " in line]
    ok_links = [line for line in text.splitlines() if "OK (superset)" in line]

    return {
        "total_issues": total_issues,
        "lost_count": len(lost_lines),
        "changed_count": len(changed_lines),
        "ok_superset_pairs": len(ok_links),
        "lost_examples": lost_lines[:10],
        "changed_examples": changed_lines[:10],
    }


def load_gate_toggles(path: Path) -> dict[str, bool]:
    if not path.exists():
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8-sig"))
    except (json.JSONDecodeError, OSError):
        return {}
    if not isinstance(data, dict):
        return {}
    enabled_raw = data.get("enabled", {})
    if not isinstance(enabled_raw, dict):
        return {}
    enabled: dict[str, bool] = {}
    for key, value in enabled_raw.items():
        gate_id = str(key).strip()
        if not gate_id:
            continue
        enabled[gate_id] = bool(value)
    return enabled


def apply_gate_toggles(
    gates: list[dict[str, Any]], gate_enabled: dict[str, bool]
) -> tuple[int, int, bool, str]:
    enabled_count = 0
    pass_count = 0
    for gate in gates:
        gate_id = str(gate.get("id", "")).strip()
        enabled = bool(gate_enabled.get(gate_id, True))
        gate["enabled"] = enabled
        if not enabled:
            continue
        enabled_count += 1
        if bool(gate.get("pass", False)):
            pass_count += 1

    if enabled_count == 0:
        return pass_count, enabled_count, True, "N/A"

    overall_pass = pass_count == enabled_count
    return pass_count, enabled_count, overall_pass, ("PASS" if overall_pass else "FAIL")


def build_report(
    max_grade_f: int,
    max_grade_c: int | None,
    gate_enabled: dict[str, bool] | None = None,
) -> dict[str, Any]:
    if gate_enabled is None:
        gate_enabled = {}
    with tempfile.TemporaryDirectory() as td:
        td_path = Path(td)

        seq_json = td_path / "sequence_contract.json"
        art_json = td_path / "artifact_audit.json"
        map_json = td_path / "map_validate.json"

        rc_seq, out_seq = run_cmd(
            [sys.executable, "tools/spine_map_workbench.py", "sequence-contract", "--json", str(seq_json)]
        )
        rc_art, out_art = run_cmd(
            [sys.executable, "tools/spine_map_workbench.py", "audit-artifacts", "--json", str(art_json)]
        )
        rc_map, out_map = run_cmd(
            [sys.executable, "scripts/validate_map.py", "--all", "--json"]
        )

        # Force UTF-8 console encoding for audit_lab_chain (contains Unicode separators).
        lab_env = os.environ.copy()
        lab_env["PYTHONIOENCODING"] = "utf-8"
        rc_lab, out_lab = run_cmd([sys.executable, "scripts/audit_lab_chain.py"], env=lab_env)

        if rc_map == 0:
            map_json.write_text(out_map, encoding="utf-8")

        sequence_data: dict[str, Any] = {}
        artifact_data: dict[str, Any] = {}
        map_data: list[dict[str, Any]] = []

        if seq_json.exists():
            sequence_data = json.loads(seq_json.read_text(encoding="utf-8"))
        if art_json.exists():
            artifact_data = json.loads(art_json.read_text(encoding="utf-8"))
        if map_json.exists():
            map_data = json.loads(map_json.read_text(encoding="utf-8"))

        seq_summary = sequence_data.get("summary", {})
        art_summary = artifact_data.get("summary", {})

        grade_counts = Counter()
        for row in map_data:
            grade = str(row.get("score", {}).get("grade", "UNKNOWN"))
            grade_counts[grade] += 1

        lab_metrics = parse_lab_audit_output(out_lab)

        gates = []

        gate_a_pass = (
            rc_seq == 0
            and int(seq_summary.get("missing_declared_maps", 999999)) == 0
            and int(seq_summary.get("duplicate_entries_within_sequence", 999999)) == 0
        )
        gates.append(
            {
                "id": "A",
                "name": "Sequence Contract",
                "pass": gate_a_pass,
                "metrics": {
                    "missing_declared_maps": int(seq_summary.get("missing_declared_maps", -1)),
                    "duplicate_entries_within_sequence": int(
                        seq_summary.get("duplicate_entries_within_sequence", -1)
                    ),
                    "undeclared_map_folders": int(seq_summary.get("undeclared_map_folders", -1)),
                },
            }
        )

        gate_b_pass = (
            rc_art == 0
            and int(art_summary.get("unresolved_scene_files", 999999)) == 0
            and int(art_summary.get("missing_scene_path", 999999)) == 0
            and int(art_summary.get("unsupported_scene_path", 999999)) == 0
        )
        gates.append(
            {
                "id": "B",
                "name": "Artifact Registry Integrity",
                "pass": gate_b_pass,
                "metrics": {
                    "unresolved_scene_files": int(art_summary.get("unresolved_scene_files", -1)),
                    "missing_scene_path": int(art_summary.get("missing_scene_path", -1)),
                    "unsupported_scene_path": int(art_summary.get("unsupported_scene_path", -1)),
                    "missing_map_ready": int(art_summary.get("missing_map_ready", -1)),
                    "missing_include_in_map_data": int(
                        art_summary.get("missing_include_in_map_data", -1)
                    ),
                },
            }
        )

        f_count = int(grade_counts.get("F", 0))
        c_count = int(grade_counts.get("C", 0))
        grade_c_blocking = max_grade_c is not None
        gate_c_pass = rc_map == 0 and f_count <= max_grade_f and (
            (not grade_c_blocking) or c_count <= max_grade_c
        )
        gates.append(
            {
                "id": "C",
                "name": "Map Validation",
                "pass": gate_c_pass,
                "metrics": {
                    "grade_A": int(grade_counts.get("A", 0)),
                    "grade_B": int(grade_counts.get("B", 0)),
                    "grade_C": c_count,
                    "grade_F": f_count,
                    "max_grade_c": max_grade_c,
                    "grade_c_blocking": grade_c_blocking,
                    "max_grade_f": max_grade_f,
                },
            }
        )

        gate_d_pass = rc_lab == 0 and int(lab_metrics.get("lost_count", 999999)) == 0
        gates.append(
            {
                "id": "D",
                "name": "Lab Progression Continuity",
                "pass": gate_d_pass,
                "metrics": {
                    "lost_count": int(lab_metrics.get("lost_count", -1)),
                    "changed_count": int(lab_metrics.get("changed_count", -1)),
                    "total_issues": int(lab_metrics.get("total_issues", -1)),
                    "ok_superset_pairs": int(lab_metrics.get("ok_superset_pairs", -1)),
                },
                "examples": {
                    "lost": lab_metrics.get("lost_examples", []),
                    "changed": lab_metrics.get("changed_examples", []),
                },
            }
        )

        pass_count, enabled_count, overall_pass, overall_status = apply_gate_toggles(
            gates, gate_enabled
        )

        return {
            "overall_pass": overall_pass,
            "overall_status": overall_status,
            "enabled_gate_count": enabled_count,
            "passing_enabled_gate_count": pass_count,
            "total_gate_count": len(gates),
            "command_exit_codes": {
                "sequence_contract": rc_seq,
                "artifact_audit": rc_art,
                "validate_map_all": rc_map,
                "audit_lab_chain": rc_lab,
            },
            "gates": gates,
            "raw": {
                "sequence_contract_summary": seq_summary,
                "artifact_audit_summary": art_summary,
                "grade_counts": dict(grade_counts),
                "lab_metrics": lab_metrics,
                "stderr_samples": {
                    "sequence_contract": out_seq.splitlines()[:20],
                    "artifact_audit": out_art.splitlines()[:20],
                    "validate_map_all": out_map.splitlines()[:20],
                    "audit_lab_chain": out_lab.splitlines()[:40],
                },
            },
        }


def to_markdown(report: dict[str, Any]) -> str:
    lines: list[str] = []
    lines.append("# Release Gates Report")
    lines.append("")
    overall_status = str(report.get("overall_status", "PASS" if report.get("overall_pass") else "FAIL"))
    lines.append(f"- Overall: {overall_status}")
    lines.append(
        "- Enabled gates: {}/{} passing".format(
            int(report.get("passing_enabled_gate_count", 0)),
            int(report.get("enabled_gate_count", 0)),
        )
    )
    gate_policy = report.get("gate_policy", {})
    if isinstance(gate_policy, dict) and bool(gate_policy.get("require_all_gates_enabled", False)):
        lines.append("- Strict policy: all gates must be enabled")
        disabled_ids = gate_policy.get("disabled_gate_ids", [])
        if isinstance(disabled_ids, list) and disabled_ids:
            lines.append(f"- Disabled gate IDs: {', '.join(str(x) for x in disabled_ids)}")
    lines.append("")
    lines.append("| Gate | Status | Key Metrics |")
    lines.append("|---|---|---|")
    for gate in report.get("gates", []):
        status = "OFF"
        if bool(gate.get("enabled", True)):
            status = "PASS" if gate.get("pass") else "FAIL"
        metrics = gate.get("metrics", {})
        metric_text = ", ".join(f"{k}={v}" for k, v in metrics.items())
        lines.append(f"| {gate.get('id')}: {gate.get('name')} | {status} | {metric_text} |")
    lines.append("")
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Run AdaResearch release gates")
    parser.add_argument(
        "--max-grade-f",
        type=int,
        default=0,
        help="Maximum allowed count of grade-F maps (default: 0)",
    )
    parser.add_argument(
        "--max-grade-c",
        type=int,
        default=-1,
        help="Maximum allowed count of grade-C maps (-1 disables C as a blocking gate; default: -1)",
    )
    parser.add_argument(
        "--gate-toggles",
        default=str(DEFAULT_GATE_TOGGLES_PATH),
        help="Path to gate-toggle JSON with {'enabled': {'A': true, ...}} (default: doc/reports/RELEASE_GATES_TOGGLES.json)",
    )
    parser.add_argument(
        "--ignore-gate-toggles",
        action="store_true",
        help="Ignore gate toggle file and evaluate all gates",
    )
    parser.add_argument(
        "--require-all-gates-enabled",
        action="store_true",
        help="Fail if any gate is disabled (strict policy for main/release)",
    )
    parser.add_argument("--json-out", default="", help="Optional JSON report path")
    parser.add_argument("--md-out", default="", help="Optional markdown report path")
    args = parser.parse_args()

    max_grade_c: int | None = None if args.max_grade_c < 0 else max(0, args.max_grade_c)
    gate_toggle_path = Path(args.gate_toggles)
    gate_enabled: dict[str, bool] = {}
    gate_toggle_source = ""
    if not args.ignore_gate_toggles:
        gate_enabled = load_gate_toggles(gate_toggle_path)
        if gate_toggle_path.exists():
            gate_toggle_source = str(gate_toggle_path)

    report = build_report(
        max_grade_f=max(0, args.max_grade_f),
        max_grade_c=max_grade_c,
        gate_enabled=gate_enabled,
    )
    disabled_gate_ids = [
        str(gate.get("id", ""))
        for gate in report.get("gates", [])
        if not bool(gate.get("enabled", True))
    ]
    disabled_gate_ids = [gate_id for gate_id in disabled_gate_ids if gate_id != ""]
    all_gates_enabled = int(report.get("enabled_gate_count", 0)) == int(report.get("total_gate_count", 0))

    if args.require_all_gates_enabled and not all_gates_enabled:
        report["overall_pass"] = False
        report["overall_status"] = "FAIL"

    report["gate_policy"] = {
        "toggle_source": gate_toggle_source,
        "ignore_gate_toggles": bool(args.ignore_gate_toggles),
        "require_all_gates_enabled": bool(args.require_all_gates_enabled),
        "all_gates_enabled": all_gates_enabled,
        "disabled_gate_ids": disabled_gate_ids,
    }

    print("")
    print("=== RELEASE GATES ===")
    print("")
    print(f"Overall: {report.get('overall_status', 'PASS' if report['overall_pass'] else 'FAIL')}")
    print(
        "Enabled gates: {}/{} passing ({} total)".format(
            int(report.get("passing_enabled_gate_count", 0)),
            int(report.get("enabled_gate_count", 0)),
            int(report.get("total_gate_count", 0)),
        )
    )
    if gate_toggle_source:
        print(f"Gate toggles: {gate_toggle_source}")
    if args.require_all_gates_enabled:
        print("Strict policy: all gates must be enabled")
        if disabled_gate_ids:
            print(f"Disabled gate IDs: {', '.join(disabled_gate_ids)}")
    print("")
    for gate in report.get("gates", []):
        status = "OFF"
        if bool(gate.get("enabled", True)):
            status = "PASS" if gate.get("pass") else "FAIL"
        print(f"[{status}] {gate.get('id')}: {gate.get('name')}")
        for key, value in gate.get("metrics", {}).items():
            print(f"  - {key}: {value}")
    print("")

    if args.json_out:
        out_path = Path(args.json_out)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"JSON report: {out_path}")

    if args.md_out:
        out_path = Path(args.md_out)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(to_markdown(report), encoding="utf-8")
        print(f"Markdown report: {out_path}")

    return 0 if report["overall_pass"] else 2


if __name__ == "__main__":
    raise SystemExit(main())
