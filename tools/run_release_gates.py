#!/usr/bin/env python3
"""
Run release gates for AdaResearch and print a pass/fail scoreboard.
"""

from __future__ import annotations

import argparse
import datetime
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

# The report is written by DEFAULT, and these are where. Until 2026-08-30 it was
# written only when a caller passed --json-out, which nobody in the ledger ever
# did: doc/reports/RELEASE_GATES.json sat at 2026-06-10 for 81 days saying
# `overall_pass: true` over four gates, while the live run failed four of eleven.
# The in-game dashboard (ProjectDashboardOverlay.gd, KEY_P) reads that file as
# res://doc/reports/RELEASE_GATES.json, so the headset was being shown a green
# verdict from June. A verdict file nobody rewrites is not a cache, it is a lie
# with a filename.
DEFAULT_JSON_REPORT_PATH = REPO / "doc/reports/RELEASE_GATES.json"
DEFAULT_MD_REPORT_PATH = REPO / "doc/reports/RELEASE_GATES.md"


def measurement_stamp() -> dict[str, Any]:
    """Who measured, when, and against which tree.

    prop-024/prop-025: a verdict is a fact about a TREE at a MOMENT. Without
    these three fields a reader cannot tell an 81-day-old PASS from a fresh one,
    which is exactly how doc/reports/RELEASE_GATES.json went stale unnoticed.
    """
    def git(*args: str) -> str:
        try:
            # encoding is not optional here. Without it Python decodes git's
            # output with the locale codec, which on this machine is cp1252, and
            # a commit subject containing an em dash lands in the report as
            # "â€”". The first run of this stamp did exactly that.
            proc = subprocess.run(
                ["git", *args],
                cwd=REPO,
                capture_output=True,
                text=True,
                encoding="utf-8",
                errors="replace",
                timeout=30,
            )
            return proc.stdout.strip() if proc.returncode == 0 else ""
        except Exception:
            return ""

    status = git("status", "--porcelain")
    lines = status.splitlines() if status else []
    return {
        "measured_at": datetime.datetime.now().astimezone().isoformat(timespec="seconds"),
        "measured_by": "tools/run_release_gates.py",
        "head": git("rev-parse", "HEAD") or "unknown",
        "head_subject": git("log", "-1", "--format=%s") or "unknown",
        "tree_dirty": len([ln for ln in lines if not ln.startswith("??")]),
        "tree_untracked": len([ln for ln in lines if ln.startswith("??")]),
    }


def _git_lines(*args: str) -> list[str]:
    try:
        proc = subprocess.run(
            ["git", *args],
            cwd=REPO,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=60,
        )
    except Exception:
        return []
    return proc.stdout.splitlines() if proc.returncode == 0 else []


def _tree_index() -> tuple[set[str], dict[str, str]]:
    """Every tracked path, and the porcelain code for every changed one.

    One pair of git calls for the whole run. Paths are normalised to forward
    slashes so a metric string lifted from a gate's output compares directly.
    """
    tracked = {ln.strip().strip('"').replace("\\", "/") for ln in _git_lines("ls-files")}
    changed: dict[str, str] = {}
    for ln in _git_lines("status", "--porcelain"):
        if len(ln) < 4:
            continue
        code, rest = ln[:2], ln[3:].strip().strip('"')
        # a rename reads "old -> new"; the new path is the one on disk
        if " -> " in rest:
            rest = rest.split(" -> ", 1)[1].strip().strip('"')
        changed[rest.replace("\\", "/").rstrip("/")] = code
    return tracked, changed


# A failing gate names its rows in prose: "a/b.md, c/d.md" or "Room_Name,
# Other_Room" or "some/tool.py (262h)". These strip the decoration back to a
# subject the tree can be asked about.
_SUBJECT_TRAILER = re.compile(r"\s*\((?:[^()]*)\)\s*$")
_NOT_A_SUBJECT = {"none", "PASS", "FAIL", "unknown", ""}


def _metric_subjects(metrics: dict[str, Any]) -> list[str]:
    subjects: list[str] = []
    for key, value in metrics.items():
        if not isinstance(value, str) or value in _NOT_A_SUBJECT:
            continue
        # counters rendered as prose ("empty 118 · stub 32") name no file
        if key in {"detector_selftest", "reason", "open_not_counted", "age_reading"}:
            continue
        for raw in value.split(","):
            token = _SUBJECT_TRAILER.sub("", raw.strip()).strip()
            if not token or token in _NOT_A_SUBJECT or " " in token:
                continue
            subjects.append(token)
    return subjects


def classify_subjects(subjects: list[str], tracked: set[str], changed: dict[str, str]) -> dict[str, Any]:
    """prop-025 clause 2: what is the git state of the thing this row convicts?

    Three states, and they demand different actions. tracked-and-clean is a
    finding about the release. tracked-and-modified is a prediction about
    somebody's unsaved work and un-fires if they revert. untracked is content
    that has not landed yet. The gate output could not tell them apart, which
    is what cost four evenings of manual forensics between 2026-08-10 and
    2026-09-08.
    """
    counts = {"tracked_clean": 0, "tracked_modified": 0, "untracked": 0, "not_resolved": 0}
    examples: dict[str, list[str]] = {k: [] for k in counts}

    for subject in subjects:
        path = subject
        if "/" not in path:
            # a bare room name is a directory of prose and map data
            candidate = f"commons/maps/{path}"
            if (REPO / candidate).is_dir():
                path = candidate
            else:
                counts["not_resolved"] += 1
                if len(examples["not_resolved"]) < 4:
                    examples["not_resolved"].append(subject)
                continue

        if (REPO / path).is_dir():
            prefix = path.rstrip("/") + "/"
            under = [p for p in changed if p.startswith(prefix)]
            dirty = [p for p in under if not changed[p].startswith("??")]
            if dirty:
                state = "tracked_modified"
            elif under:
                state = "untracked"
            elif any(p.startswith(prefix) for p in tracked):
                state = "tracked_clean"
            else:
                state = "untracked"
        else:
            code = changed.get(path)
            if path in tracked:
                state = "tracked_modified" if code else "tracked_clean"
            elif code and code.startswith("??"):
                state = "untracked"
            elif code:
                state = "tracked_modified"
            else:
                state = "untracked" if (REPO / path).exists() else "not_resolved"

        counts[state] += 1
        if len(examples[state]) < 4:
            examples[state].append(subject)

    total = sum(counts.values())
    if total == 0:
        return {"subjects": 0}
    out: dict[str, Any] = {"subjects": total}
    for state, n in counts.items():
        if n:
            out[state] = n
            out[state + "_eg"] = ", ".join(examples[state])
    return out


def annotate_tree_state(report: dict[str, Any]) -> None:
    """Add a tree_state line to every failing gate. Never changes a verdict.

    A gate that names no rows gets `named_subjects: 0` rather than silence --
    the honest reading is that the gate cannot be attributed to a tree, not
    that its subjects are clean.
    """
    failing = [
        g for g in report.get("gates", [])
        if bool(g.get("enabled", True)) and not g.get("pass")
    ]
    stamp = report.get("measurement")
    if isinstance(stamp, dict):
        # The annotator's own negative half. A classifier that answered
        # "modified" to every subject would read plausibly on this tree and
        # be worthless; 12 synthetic cases, no corpus, well under a second.
        rc_self, _ = run_cmd([sys.executable, "tools/test_gate_tree_state.py"])
        stamp["tree_state_detector"] = "PASS" if rc_self == 0 else f"FAIL(rc={rc_self})"
    if not failing:
        return
    tracked, changed = _tree_index()
    for gate in failing:
        metrics = gate.get("metrics", {})
        if not isinstance(metrics, dict):
            continue
        verdict = classify_subjects(_metric_subjects(metrics), tracked, changed)
        if verdict.get("subjects"):
            parts = []
            for state in ("tracked_clean", "tracked_modified", "untracked", "not_resolved"):
                if verdict.get(state):
                    parts.append(f"{state.replace('_', '-')} {verdict[state]}")
            summary = " | ".join(parts)
            for state in ("tracked_modified", "untracked"):
                eg = verdict.get(state + "_eg")
                if eg:
                    summary += f"  [{state.replace('_', '-')}: {eg}]"
            metrics["tree_state"] = summary
        else:
            metrics["tree_state"] = "named_subjects 0 - this row cannot be attributed to a tree"


def write_json_report(path: Path, report: dict[str, Any]) -> None:
    """Write, then read back and parse. prop-042.

    The dashboard overlay in the headset reads this file. A half-written one
    renders as no gates at all, which the overlay cannot distinguish from a
    clean project, so the write is atomic and the result is parsed before the
    old file is replaced.
    """
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(report, indent=2, ensure_ascii=False) + "\n"
    if len(payload) < 200:
        raise ValueError(
            f"refusing to write a {len(payload)}-byte gate report to {path}"
        )
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(payload, encoding="utf-8")
    json.loads(tmp.read_text(encoding="utf-8"))
    os.replace(tmp, path)


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
        # ...and this gate's own negative half. On 2026-08-30 the matcher was
        # loosened — a transliteration table for the mathematics in the source
        # files, and ellipsis quotes matched fragment by fragment — and LOST fell
        # 3 -> 0 in a single pass. A gate reading zero right after its comparison
        # was widened is exactly the shape of one that stopped checking, so
        # test_edge_gate.py feeds it anchors that ARE broken and the gate does not
        # pass unless they are still convicted.
        rc_edgeneg, _ = run_cmd([sys.executable, "tools/test_edge_gate.py"])
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
                and int(edge.get("edges", 0)) > 0
                # ...and a matcher that has stopped convicting tallies zero too.
                and rc_edgeneg == 0,
                "metrics": {
                    "detector_selftest": "PASS" if rc_edgeneg == 0 else "FAIL",
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

        # Gate L: the writing a reachable room ships is in the repository.
        # Gates A-K all read the WORKING TREE, and gate H is the only one in
        # the battery that ever asks git a question -- about tools. On
        # 2026-09-05 seven finished essays, 9,567 words and the whole of
        # foundationscrisis but its centrepiece, had been untracked for two
        # days while four instruments called the tree clean: the pipeline
        # scorer asks blurb.exists() OR intent.exists(), the coverage hook
        # reported 179/179 doc 100.0%, and final_tags.py read all 49 final.md
        # INCLUDING the seven and found 0 stale tags, because to a check that
        # calls os.path.exists() an untracked file is simply present. Three
        # consecutive breaths found instances of that one at a time. This
        # gate is the class, on the other side of gate H's line: H asks
        # whether the code that produces a verdict is in the repository, L
        # asks whether the writing that ships is.
        rc_prose, out_prose = run_cmd(
            [sys.executable, "tools/check_prose_reachable.py", "--json"]
        )
        # ...and its negative half. This gate reads zero on a good day, which
        # is indistinguishable from one that stopped checking -- and it has
        # already been wrong twice in its first hour, once on Windows case
        # folding and once on working-tree-versus-HEAD. The selftest plants
        # both.
        rc_prose_neg, _ = run_cmd(
            [sys.executable, "tools/check_prose_reachable.py", "--selftest"]
        )
        prose = {}
        if out_prose.strip():
            try:
                prose = json.loads(out_prose)
            except json.JSONDecodeError:
                prose = {}
        casemiss = prose.get("declared_case_mismatch") or {}
        gates.append(
            {
                "id": "L",
                "name": "Prose Reachable From A Clone",
                "pass": rc_prose == 0
                and int(prose.get("unreachable_from_a_clone", 999999)) == 0
                # An empty scan is a broken check, not a green one.
                and int(prose.get("prose_files", 0)) > 0
                and rc_prose_neg == 0,
                "metrics": {
                    "detector_selftest": "PASS" if rc_prose_neg == 0 else "FAIL",
                    "rooms_declared": int(prose.get("rooms_declared", -1)),
                    "rooms_resolved": int(prose.get("rooms_resolved", -1)),
                    "prose_files": int(prose.get("prose_files", -1)),
                    "prose_tracked": int(prose.get("prose_tracked", -1)),
                    "unreachable_from_a_clone": int(
                        prose.get("unreachable_from_a_clone", -1)
                    ),
                    "stranded_words": int(prose.get("stranded_words", -1)),
                    # How old the stranded writing is. A red row where every
                    # file was touched an hour ago is a session mid-sentence;
                    # the same count at 133h is finished work left outside the
                    # repository. Four consecutive mornings the breather did
                    # this arithmetic by hand and deferred.
                    "age_reading": str(prose.get("age_reading", "")) or "none",
                    "unreachable": ", ".join(
                        u.get("path", "") for u in (prose.get("unreachable") or [])
                    ) or "none",
                    # Not this gate's verdict -- a declared name that differs
                    # from the disk only in case is gate A's business -- but
                    # nothing else in the battery prints it, and Windows is
                    # the only place it looks fine.
                    "declared_case_mismatch": ", ".join(sorted(casemiss)) or "none",
                },
            }
        )

        # Gate M: the artifacts a reachable room places are in the repository.
        # The third surface of gate H's class. On 2026-09-06 five tracked maps
        # placed artifacts a clone cannot load, and gate B called it
        # unresolved_scene_files: 0 -- because gate B asks os.path.exists().
        # The root cause was one unanchored glob, `data_*/` in the Mono block,
        # which matched three artifact FOLDERS; git will not descend into an
        # excluded directory, so the !*.gd / !*.tscn re-includes could not
        # reach inside one. H asks whether the code that produces a verdict is
        # in the repository, L whether the writing that ships is, M whether
        # the objects a room stands up are.
        rc_art_reach, out_art_reach = run_cmd(
            [sys.executable, "tools/check_artifacts_reachable.py", "--json"]
        )
        # Its negative half. This gate's own first run convicted 143 addon
        # files that are absent from the repository on purpose, which is the
        # same false positive gate L made against ten facade files an hour
        # after it was written. The selftest fixtures that, the Windows case
        # fold, and the difference between absent and unreachable.
        rc_art_reach_neg, _ = run_cmd(
            [sys.executable, "tools/check_artifacts_reachable.py", "--selftest"]
        )
        reach = {}
        if out_art_reach.strip():
            try:
                reach = json.loads(out_art_reach)
            except json.JSONDecodeError:
                reach = {}
        gates.append(
            {
                "id": "M",
                "name": "Artifacts Reachable From A Clone",
                "pass": int(reach.get("unreachable_from_a_clone", 999999)) == 0
                # An empty scan is a broken check, not a green one.
                and int(reach.get("artifacts_declared", 0)) > 0
                and rc_art_reach_neg == 0,
                "metrics": {
                    "detector_selftest": "PASS" if rc_art_reach_neg == 0 else "FAIL",
                    "artifacts_declared": int(reach.get("artifacts_declared", -1)),
                    "files_checked": int(reach.get("files_checked", -1)),
                    "unreachable_from_a_clone": int(
                        reach.get("unreachable_from_a_clone", -1)
                    ),
                    "rooms_affected": int(reach.get("rooms_affected", -1)),
                    # Not this gate's verdict. A file no tree has is gate B's
                    # unresolved_scene_files, and a vendored addon is absent by
                    # decision -- both printed so the numbers stay visible.
                    "absent_from_every_tree": int(reach.get("absent_from_every_tree", -1)),
                    "vendored_not_in_repo": int(reach.get("vendored_not_in_repo", -1)),
                },
            }
        )

        # Gate N: every tool on this disk is in the repository. The fourth
        # surface, and the one gate H cannot reach. H walks: it collects what a
        # runner INVOKES and what a gate tool NAMES, then asks git about those.
        # A walk cannot see an orphan. tools/pull_vr_feedback.py was written on
        # 2026-09-07, tested on a real Quest, recorded as LANDED and left
        # untracked; H read 53 referenced / 0 unreachable every day it sat
        # there, and widening H from INVOKED to NAMED would not have found it
        # either -- the only files naming it were its own uncommitted hunks, so
        # HEAD grepped 0. When a tool and its callers land or fail to land as
        # one commit, the naming set is empty exactly when the file is absent.
        # The population a tools gate must ask about is the DIRECTORY.
        rc_tools_reach, out_tools_reach = run_cmd(
            [sys.executable, "tools/check_tools_reachable.py", "--json"]
        )
        # Its negative half. Every gate in this table convicted something
        # innocent on its first run; this one's exposure is a concurrent
        # session's open buffers, so the selftest fixtures the 24-hour hold at
        # its boundary, the ignored file, and the nested .gd.
        rc_tools_reach_neg, _ = run_cmd(
            [sys.executable, "tools/check_tools_reachable.py", "--selftest"]
        )
        treach = {}
        if out_tools_reach.strip():
            try:
                treach = json.loads(out_tools_reach)
            except json.JSONDecodeError:
                treach = {}
        gates.append(
            {
                "id": "N",
                "name": "Tools Reachable From A Clone",
                "pass": int(treach.get("unreachable_from_a_clone", 999999)) == 0
                # An empty scan is a broken check, not a green one.
                and int(treach.get("tools_on_disk", 0)) > 0
                and rc_tools_reach_neg == 0,
                "metrics": {
                    "detector_selftest": "PASS" if rc_tools_reach_neg == 0 else "FAIL",
                    "tools_on_disk": int(treach.get("tools_on_disk", -1)),
                    "tools_tracked": int(treach.get("tools_tracked", -1)),
                    "unreachable_from_a_clone": int(
                        treach.get("unreachable_from_a_clone", -1)
                    ),
                    # Not this gate's verdict, printed so the census stays whole:
                    # a file written in the last 24h is somebody's open buffer,
                    # and one that is gitignored is absent by decision.
                    "live_uncommitted": int(treach.get("live_uncommitted", -1)),
                    "ignored_on_purpose": int(treach.get("ignored_on_purpose", -1)),
                    "stranded": ", ".join(
                        "%s (%.0fh)" % (r["path"], r["age_hours"])
                        for r in treach.get("stranded", [])) or "none",
                },
            }
        )

        # Gate O: every cell in every map layer is a string. The convention is
        # as old as the maps and until today nothing in either language checked
        # it, which is why the same eleven maps crashed a live museum walk in
        # GDScript on 2026-08-24 and the encyclopedia's strip in TypeScript on
        # 2026-09-10. Both times the READER was swept and the data was left as
        # it was, so the third reader inherits the trap -- and the trap is not
        # always a crash. `cell == "1"` is False against the integer 1, so a
        # floor reads as void with nothing printed anywhere.
        rc_cells, out_cells = run_cmd(
            [sys.executable, "tools/check_cell_types.py", "--json"]
        )
        rc_cells_neg, _ = run_cmd(
            [sys.executable, "tools/check_cell_types.py", "--selftest"]
        )
        cells = {}
        if out_cells.strip():
            try:
                cells = json.loads(out_cells)
            except json.JSONDecodeError:
                cells = {}
        gates.append(
            {
                "id": "O",
                "name": "Cells Are Strings",
                "pass": int(cells.get("non_string_cells", 999999)) == 0
                # An empty scan is a broken check, not a green one.
                and int(cells.get("cells_scanned", 0)) > 0
                and not cells.get("unreadable")
                and rc_cells_neg == 0,
                "metrics": {
                    "detector_selftest": "PASS" if rc_cells_neg == 0 else "FAIL",
                    "maps_scanned": int(cells.get("maps_scanned", -1)),
                    "cells_scanned": int(cells.get("cells_scanned", -1)),
                    "non_string_cells": int(cells.get("non_string_cells", -1)),
                    "maps_affected": int(cells.get("maps_with_non_string_cells", -1)),
                    # Not a defence, printed so the reader can tell a stale
                    # corpus fault from a live session's open buffer.
                    "in_working_tree": int(cells.get("in_working_tree", -1)),
                    "unreadable": ", ".join(cells.get("unreadable", [])) or "none",
                    "offenders": ", ".join(
                        "%s (%d %s%s)"
                        % (
                            o["map"],
                            o["count"],
                            "/".join(o["kinds"]),
                            ", open in working tree" if o["in_working_tree"] else "",
                        )
                        for o in cells.get("offenders", [])
                    )
                    or "none",
                },
            }
        )

        pass_count, enabled_count, overall_pass, overall_status = apply_gate_toggles(
            gates, gate_enabled
        )

        return {
            "measurement": measurement_stamp(),
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
                "check_prose_reachable": rc_prose,
                "check_artifacts_reachable": rc_art_reach,
                "check_tools_reachable": rc_tools_reach,
                "check_cell_types": rc_cells,
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
    stamp = report.get("measurement", {})
    if isinstance(stamp, dict) and stamp:
        lines.append(
            "- Measured: {} by {} at {} ({} dirty / {} untracked)".format(
                stamp.get("measured_at", "?"),
                stamp.get("measured_by", "?"),
                (str(stamp.get("head", "?")))[:9],
                stamp.get("tree_dirty", "?"),
                stamp.get("tree_untracked", "?"),
            )
        )
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
    parser.add_argument(
        "--json-out",
        default=str(DEFAULT_JSON_REPORT_PATH),
        help="JSON report path (default: doc/reports/RELEASE_GATES.json)",
    )
    parser.add_argument(
        "--md-out",
        default=str(DEFAULT_MD_REPORT_PATH),
        help="Markdown report path (default: doc/reports/RELEASE_GATES.md)",
    )
    parser.add_argument(
        "--no-report",
        action="store_true",
        help="Do not write the report files (measure only, print to stdout)",
    )
    args = parser.parse_args()
    if args.no_report:
        args.json_out = ""
        args.md_out = ""

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

    # prop-025 clause 2. Additive: reads git, writes one metric, touches no
    # pass/fail. Runs after the policy verdicts so a strict-policy failure
    # does not get a tree it has no rows in.
    annotate_tree_state(report)

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
    stamp = report.get("measurement", {})
    if stamp:
        print(
            "Measured: {} at {} ({} dirty / {} untracked)".format(
                stamp.get("measured_at", "?"),
                (stamp.get("head", "?") or "?")[:9],
                stamp.get("tree_dirty", "?"),
                stamp.get("tree_untracked", "?"),
            )
        )
        if stamp.get("tree_state_detector"):
            print(f"Tree-state detector: {stamp['tree_state_detector']}")
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
        write_json_report(out_path, report)
        print(f"JSON report: {out_path}")

    if args.md_out:
        out_path = Path(args.md_out)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(to_markdown(report), encoding="utf-8")
        print(f"Markdown report: {out_path}")

    return 0 if report["overall_pass"] else 2


if __name__ == "__main__":
    raise SystemExit(main())
