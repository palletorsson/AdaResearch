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
        # Gate B checks registry -> scene. This is the mirror direction,
        # map -> registry, which nothing checked until 2026-08-23. See
        # gate G below for why the pipeline scorer is not a substitute.
        rc_tok, out_tok = run_cmd(
            [sys.executable, "tools/check_map_tokens.py", "--json"]
        )
        # ...and the detector's own negative half. A gate that reports a
        # clean corpus is making two claims -- that the corpus is clean,
        # and that it would have said so if it were not. Only the first is
        # tested by running it on the corpus, and a green row over a blind
        # detector is the exact failure this gate exists to prevent. 17
        # synthetic cases, no corpus, under a second.
        rc_tokneg, _ = run_cmd(
            [sys.executable, "tools/test_map_token_scan.py"]
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
            # A scene-less entry is excused only by a biome_token the engine can
            # parse. A malformed one names a kingdom or role that does not exist,
            # so it fails here rather than quietly buying the exemption.
            and int(art_summary.get("invalid_biome_token", 999999)) == 0
        )
        gates.append(
            {
                "id": "B",
                "name": "Artifact Registry Integrity",
                "pass": gate_b_pass,
                "metrics": {
                    "unresolved_scene_files": int(art_summary.get("unresolved_scene_files", -1)),
                    "missing_scene_path": int(art_summary.get("missing_scene_path", -1)),
                    "invalid_biome_token": int(art_summary.get("invalid_biome_token", -1)),
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

        # E: every museum tile individually sound (dims/vocab/hero/pockets/BFS)
        # and every ordered museum pair joinable through the vestibule model.
        rc_mus, out_mus = run_cmd([sys.executable, "tools/validate_museum_templates.py"])
        mus_failing = -1
        mus_chain_pass = -1
        mus_chain_total = -1
        m = re.search(r"(\d+) failing museum template", out_mus)
        if m:
            mus_failing = int(m.group(1))
        m = re.search(r"chain: (\d+)/(\d+)", out_mus)
        if m:
            mus_chain_pass, mus_chain_total = int(m.group(1)), int(m.group(2))
        gates.append(
            {
                "id": "E",
                "name": "Museum Template Integrity",
                "pass": rc_mus == 0 and mus_failing == 0,
                "metrics": {
                    "failing_templates": mus_failing,
                    "chain_pairs_pass": mus_chain_pass,
                    "chain_pairs_total": mus_chain_total,
                },
            }
        )

        # F: the walkthrough — a CharacterBody3D physically walks three museums
        # on a plan drawn from the stamped cells; a stall is a plan/physics
        # disagreement. Runs Godot headless under the watchdog (~60 s); the
        # wrapper judges by the verdict file, not the exit code. Serialize:
        # nothing else may hold the Godot user:// lock while gates run.
        #
        # "Serialize" was advice until 2026-08-28, and advice does not gate. That
        # morning this row read `no_route, frontier_z 7` against 21/37/44 in the
        # three breaths before it — measured while the editor had been open since
        # 07:44 and Point_One/map_data.json was saved at 09:08:43, mid-walk. The
        # autopilot now enumerates Godot processes bound to this repo and refuses,
        # so a contended run reports `reason: contended_builder` with every
        # corridor field at -1. A -1 row here is NOT a short walk; it is no walk.
        # Read `reason` before reading `frontier_z`.
        rc_walk, out_walk = run_cmd([sys.executable, "tools/em_autopilot.py"])
        walk_verdict: dict[str, Any] = {}
        walk_verdict_path = REPO / "ada_run" / "em_autopilot.json"
        if walk_verdict_path.exists():
            try:
                walk_verdict = json.loads(walk_verdict_path.read_text(encoding="utf-8"))
            except json.JSONDecodeError:
                walk_verdict = {}
        gates.append(
            {
                "id": "F",
                "name": "Museum Walkthrough (autopilot)",
                "pass": rc_walk == 0,
                "metrics": {
                    "museums": int(walk_verdict.get("museums_target", -1)),
                    "z_reached": round(float(walk_verdict.get("z", -1.0)), 1),
                    "goal_z": round(float(walk_verdict.get("goal_z", -1.0)), 1),
                    "walked_s": round(float(walk_verdict.get("elapsed_s", -1.0)), 1),
                    "cells_unlearned": int(walk_verdict.get("cells_unlearned", -1)),
                    # cells_unlearned counted stall events until 2026-08-15 and
                    # so read as a corridor 26 cells thick when it was 6 cells
                    # and a dead plan. These say which failure this is: a
                    # frontier short of goal with reason=no_route is a severed
                    # walk map, not an expensive one.
                    "stall_events": int(walk_verdict.get("stall_events", -1)),
                    "frontier_z": int(walk_verdict.get("frontier_z", -1)),
                    "reason": str(walk_verdict.get("reason", "")),
                },
            }
        )

        # Gate G: every interactable token in a spine map resolves to a
        # scene on disk. The pipeline scorer already had this information
        # and could not report it: it prints a ROUNDED percentage, so its
        # sensitivity scales inversely with the size of the sequence it is
        # judging. One dead token in primitives (1 of 144) dropped that
        # sequence's HEAD by three stages; one dead token in forces
        # (1 of 319) printed OK for 68 days. Same fault, opposite verdicts,
        # and the discriminator was the denominator. This gate counts
        # placements instead, so one is one wherever it lands.
        tok_summary = {}
        if out_tok.strip():
            try:
                tok_summary = json.loads(out_tok)
            except json.JSONDecodeError:
                tok_summary = {}
        gates.append(
            {
                "id": "G",
                "name": "Map Token Resolution",
                "pass": rc_tok == 0
                and int(tok_summary.get("unresolved_placements", 999999)) == 0
                # A scan of nothing prints identically to a clean corpus in
                # every summary form; this gate's own first run did exactly
                # that. An empty denominator is a broken gate, not a green one.
                and int(tok_summary.get("placements", 0)) > 0
                # ...and neither is a blind detector.
                and rc_tokneg == 0,
                "metrics": {
                    "detector_selftest": "PASS" if rc_tokneg == 0
                    else "FAIL rc=%d" % rc_tokneg,
                    "maps_scanned": int(tok_summary.get("maps_scanned", -1)),
                    "maps_named": int(tok_summary.get("maps_named", -1)),
                    "maps_without_data": ", ".join(
                        tok_summary.get("maps_without_data", []) or []) or "none",
                    "placements": int(tok_summary.get("placements", -1)),
                    "unresolved_placements": int(
                        tok_summary.get("unresolved_placements", -1)
                    ),
                    "unresolved_tokens": ", ".join(
                        sorted(tok_summary.get("unresolved_tokens", {}))
                    ),
                    "malformed_empty_cells": int(
                        tok_summary.get("malformed_empty_cells", -1)
                    ),
                },
            }
        )

        # Gate H: every tool this table's rows are produced by is in the
        # repository. On 2026-08-24 gate G had been printing PASS for a day
        # from an untracked file, and gate seal_clamp named a .gd in no
        # commit -- so a clone of HEAD ran six gates, printed six, and had
        # no row missing to notice. Six breaths found instances of that by
        # hand, one at a time, which is the signature of a class nothing
        # watches. This gate is the class.
        rc_chain, out_chain = run_cmd(
            [sys.executable, "tools/check_gate_chain.py", "--json"]
        )
        chain = {}
        if out_chain.strip():
            try:
                chain = json.loads(out_chain)
            except json.JSONDecodeError:
                chain = {}
        gates.append(
            {
                "id": "H",
                "name": "Gate Chain Integrity",
                "pass": rc_chain == 0
                and int(chain.get("unreachable_from_a_clone", 999999)) == 0
                # An empty scan is a broken check, not a green one.
                and int(chain.get("tools_referenced", 0)) > 0,
                "metrics": {
                    "tools_referenced": int(chain.get("tools_referenced", -1)),
                    "absent_on_disk": ", ".join(
                        chain.get("absent_on_disk", []) or []) or "none",
                    "present_but_untracked": ", ".join(
                        chain.get("present_but_untracked", []) or []) or "none",
                    "unreachable_from_a_clone": int(
                        chain.get("unreachable_from_a_clone", -1)
                    ),
                },
            }
        )

        # Gates I, J, K: the book's claims about the world, and whether they still
        # hold. Everything above this line checks that the game is BUILDABLE. These
        # check that what has been WRITTEN about it is still true — a different
        # failure, and until 2026-08-29 nothing watched it. edge_gate.py had been
        # sitting at 3 LOST with no row anywhere and nobody told.
        #
        # I and J share three underlying anchors today, so one repair clears both.
        # They are not redundant: I judges all 269 edge sentences including the 50
        # on pearls with no hero, J judges only the 219 that have a SUBJECT and can
        # therefore also ask whether that subject exists and stands where the book
        # says. Neither question contains the other.
        rc_edge, out_edge = run_cmd([sys.executable, "tools/edge_gate.py", "--json"])
        edge = {}
        if out_edge.strip():
            try:
                edge = json.loads(out_edge)
            except json.JSONDecodeError:
                edge = {}
        gates.append(
            {
                "id": "I",
                "name": "Edge Anchors",
                "pass": rc_edge == 0
                and int(edge.get("LOST", 999999)) == 0
                # A book that failed to parse tallies zero LOST, which is what a
                # clean book tallies. An empty denominator is a broken gate.
                and int(edge.get("edges", 0)) > 0,
                "metrics": {
                    "edges": int(edge.get("edges", -1)),
                    "held": int(edge.get("HELD", -1)),
                    "near": int(edge.get("NEAR", -1)),
                    "lost": int(edge.get("LOST", -1)),
                    "ungrounded": int(edge.get("UNGROUNDED", -1)),
                    "lost_rooms": ", ".join(
                        r.get("map", "") for r in (edge.get("lost") or [])) or "none",
                },
            }
        )

        rc_cite, out_cite = run_cmd([sys.executable, "tools/cite_gate.py", "--json"])
        cite = {}
        if out_cite.strip():
            try:
                cite = json.loads(out_cite).get("totals", {})
            except json.JSONDecodeError:
                cite = {}
        gates.append(
            {
                "id": "J",
                "name": "Artifact Citations",
                "pass": rc_cite == 0
                and int(cite.get("LOST", 999999)) == 0
                and int(cite.get("NO SUCH WORK", 999999)) == 0
                and int(cite.get("citations", 0)) > 0,
                "metrics": {
                    "citations": int(cite.get("citations", -1)),
                    "held": int(cite.get("HELD", -1)),
                    "near": int(cite.get("NEAR", -1)),
                    "lost": int(cite.get("LOST", -1)),
                    # ELSEWHERE passes on purpose: a work discussed where it does
                    # not stand is a finding, not a fault. All three today are the
                    # hall's own declared hero.
                    "elsewhere": int(cite.get("ELSEWHERE", -1)),
                    "no_such_work": int(cite.get("NO SUCH WORK", -1)),
                },
            }
        )

        rc_want, out_want = run_cmd([sys.executable, "tools/want_gate.py", "--json"])
        want: dict[str, Any] = {}
        if out_want.strip():
            try:
                want = json.loads(out_want)
            except json.JSONDecodeError:
                want = {}
        want_checked = want.get("checked", {}) if isinstance(want.get("checked"), dict) else {}
        want_v = want.get("verdicts", {}) if isinstance(want.get("verdicts"), dict) else {}
        rc_wantneg, _ = run_cmd([sys.executable, "tools/test_want_gate.py"])
        gates.append(
            {
                "id": "K",
                "name": "Wants Closed Honestly",
                # This gate does NOT count open wants. 1638 works with no words is
                # the shape of the project; counting it as debt builds a scoreboard
                # that rewards thin filling. It counts wants marked DONE that are
                # not: a line naming nothing, one sentence given to two different
                # works, a hall named for a work that does not exist.
                "pass": rc_want == 0
                and int(want.get("fails", 999999)) == 0
                and int(want_checked.get("token_lines", 0)) > 0
                # Three of this gate's failing verdicts are at zero on the real
                # corpus, and a rule at zero is indistinguishable from a rule that
                # never runs. The self-test trips each one deliberately.
                and rc_wantneg == 0,
                "metrics": {
                    "detector_selftest": "PASS" if rc_wantneg == 0 else "FAIL rc=%d" % rc_wantneg,
                    "token_lines": int(want_checked.get("token_lines", -1)),
                    "closed_dishonestly": int(want.get("fails", -1)),
                    "ghost": int(want_v.get("GHOST", 0)),
                    "echo": int(want_v.get("ECHO", 0)),
                    "no_registry": int(want_v.get("NO REGISTRY", 0)),
                    "broken_body": int(want_v.get("BROKEN BODY", 0)),
                    "hero_ghost": int(want_v.get("HERO GHOST", 0)),
                    "open_not_counted": "empty %d · stub %d · elsewhere %d · no_body %d · no_subject %d"
                    % (int(want_v.get("EMPTY", 0)), int(want_v.get("STUB", 0)),
                       int(want_v.get("ELSEWHERE", 0)), int(want_v.get("NO BODY", 0)),
                       int(want_v.get("NO SUBJECT", 0))),
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
                "validate_museum_templates": rc_mus,
                "em_autopilot": rc_walk,
                "check_map_tokens": rc_tok,
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
