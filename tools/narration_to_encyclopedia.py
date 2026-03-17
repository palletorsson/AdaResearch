#!/usr/bin/env python3
"""
narration_to_encyclopedia.py

Reads a narration report JSON (from Godot's narrate_all.gd) and:
  - Prints a human-readable summary table to stdout
  - Generates improvement proposals for maps with issues
  - Optionally POSTs proposals to the Ada Encyclopedia API
  - Otherwise writes proposals to improvement_proposals.json

Usage:
    python tools/narration_to_encyclopedia.py --report ada_run/narrations/narration_report.json
    python tools/narration_to_encyclopedia.py --report ada_run/narrations/narration_report.json --encyclopedia http://localhost:3003
    python tools/narration_to_encyclopedia.py --report ada_run/narrations/narration_report.json --encyclopedia http://localhost:3003 --dry-run
"""

import argparse
import json
import os
import sys
import urllib.request
import urllib.error

SUGGESTED_ACTIONS = {
    "unreachable_teleporter": "Check teleporter placement and adjacent walkable tiles",
    "unreachable_artifact": "Verify artifact tile has walkable floor (h=1) or is adjacent to walkable",
    "no_spawn": "Add MovePlayer utility to the map",
    "high_dead_ends": "Consider adding connecting corridors to reduce dead ends",
    "sparse_pacing": "Add more artifacts or reduce map size for better density",
    "dense_pacing": "Spread artifacts further apart or add corridors between them",
}


def load_report(path):
    """Load and return the narration report JSON."""
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def print_summary_table(report):
    """Print a human-readable summary table to stdout."""
    col_seq = 22
    col_map = 20
    col_art = 10
    col_issues = 8
    col_status = 10

    header = (
        f"{'Sequence':<{col_seq}} "
        f"{'Map':<{col_map}} "
        f"{'Artifacts':>{col_art}} "
        f"{'Issues':>{col_issues}} "
        f"{'Status':<{col_status}}"
    )
    separator = "-" * len(header)

    print()
    print("=== Narration Report Summary ===")
    print()
    print(header)
    print(separator)

    total_maps = 0
    total_issues = 0

    for seq in report.get("sequences", []):
        seq_name = seq.get("name", "unknown")
        for map_entry in seq.get("maps", []):
            map_name = map_entry.get("map_name", "?")
            artifacts = map_entry.get("artifacts", 0)
            issues = map_entry.get("issues", [])
            issue_count = len(issues)
            status = map_entry.get("status", "unknown")

            total_maps += 1
            total_issues += issue_count

            print(
                f"{seq_name:<{col_seq}} "
                f"{map_name:<{col_map}} "
                f"{artifacts:>{col_art}} "
                f"{issue_count:>{col_issues}} "
                f"{status:<{col_status}}"
            )

    print(separator)

    stats = report.get("statistics", {})
    maps_with_issues = stats.get("maps_with_issues", total_issues > 0)
    global_issues = report.get("global_issues", [])

    print(f"Total maps: {total_maps}")
    print(f"Maps with issues: {maps_with_issues}")
    print(f"Total issues: {total_issues}")

    if global_issues:
        print()
        print("Global issues:")
        for gi in global_issues:
            desc = gi if isinstance(gi, str) else gi.get("description", str(gi))
            print(f"  - {desc}")

    print()


def build_proposals(report):
    """Generate improvement proposals for maps that have issues."""
    proposals = []

    for seq in report.get("sequences", []):
        seq_name = seq.get("name", "unknown")
        for map_entry in seq.get("maps", []):
            issues = map_entry.get("issues", [])
            if not issues:
                continue

            suggested_actions = []
            for issue in issues:
                issue_type = issue.get("type", "")
                action = SUGGESTED_ACTIONS.get(issue_type)
                if action and action not in suggested_actions:
                    suggested_actions.append(action)

            if not suggested_actions:
                suggested_actions.append(
                    "Review map layout and fix reported issues"
                )

            proposal = {
                "map_name": map_entry.get("map_name", "?"),
                "sequence": seq_name,
                "issues": issues,
                "suggested_actions": suggested_actions,
            }
            proposals.append(proposal)

    return proposals


def post_proposal(base_url, proposal):
    """POST a single improvement proposal to the encyclopedia API."""
    url = base_url.rstrip("/") + "/api/game/improve"
    data = json.dumps(proposal).encode("utf-8")

    req = urllib.request.Request(
        url,
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            body = resp.read().decode("utf-8")
            return resp.status, body
    except urllib.error.HTTPError as e:
        body = ""
        try:
            body = e.read().decode("utf-8")
        except Exception:
            pass
        return e.code, body
    except urllib.error.URLError as e:
        return None, str(e.reason)


def main():
    parser = argparse.ArgumentParser(
        description="Parse narration report and generate improvement proposals"
    )
    parser.add_argument(
        "--report",
        required=True,
        help="Path to the narration_report.json file",
    )
    parser.add_argument(
        "--encyclopedia",
        default=None,
        help="Base URL of the Ada Encyclopedia (e.g. http://localhost:3003). "
        "If provided, proposals are POSTed to /api/game/improve.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be sent without actually POSTing",
    )
    args = parser.parse_args()

    # Load report
    if not os.path.isfile(args.report):
        print(f"Error: report file not found: {args.report}", file=sys.stderr)
        sys.exit(1)

    try:
        report = load_report(args.report)
    except json.JSONDecodeError as e:
        print(f"Error: invalid JSON in report: {e}", file=sys.stderr)
        sys.exit(1)
    except OSError as e:
        print(f"Error: could not read report: {e}", file=sys.stderr)
        sys.exit(1)

    # Print summary
    print_summary_table(report)

    # Build proposals
    proposals = build_proposals(report)

    if not proposals:
        print("No issues found — no improvement proposals generated.")
        return

    print(f"Generated {len(proposals)} improvement proposal(s).")
    print()

    # Dispatch proposals
    if args.encyclopedia:
        # POST to encyclopedia API
        for i, proposal in enumerate(proposals, 1):
            map_name = proposal["map_name"]
            if args.dry_run:
                print(f"[dry-run] Would POST proposal {i}/{len(proposals)} "
                      f"for {map_name}:")
                print(json.dumps(proposal, indent=2))
                print()
            else:
                print(f"POSTing proposal {i}/{len(proposals)} for {map_name}...", end=" ")
                status, body = post_proposal(args.encyclopedia, proposal)
                if status is None:
                    print(f"FAILED (connection error: {body})")
                elif 200 <= status < 300:
                    print(f"OK ({status})")
                else:
                    print(f"ERROR ({status}): {body[:200]}")
    else:
        # Write proposals to file next to the report
        report_dir = os.path.dirname(os.path.abspath(args.report))
        out_path = os.path.join(report_dir, "improvement_proposals.json")
        try:
            with open(out_path, "w", encoding="utf-8") as f:
                json.dump(proposals, f, indent=2)
            print(f"Wrote proposals to: {out_path}")
        except OSError as e:
            print(f"Error: could not write proposals: {e}", file=sys.stderr)
            sys.exit(1)


if __name__ == "__main__":
    main()
