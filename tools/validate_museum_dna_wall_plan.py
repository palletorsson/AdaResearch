#!/usr/bin/env python3
"""Validate measured DNA wall envelopes against the executable museum plan."""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

REPO = Path(__file__).resolve().parents[1]
PLAN = REPO / "ada_run" / "em_plan.json"
ENVELOPES = REPO / "commons" / "data" / "museum_dna_wall_envelopes.json"
OUT = REPO / "ada_run" / "museum_dna_wall_validation.json"
TOLERANCE_M = 0.051


def read(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def check() -> dict[str, Any]:
    plan = read(PLAN)
    envelopes = read(ENVELOPES).get("families", {})
    rows: list[dict[str, Any]] = []
    errors: list[str] = []
    counts = {"measured_housed": 0, "variants_housed": 0,
              "spatial_demand": 0, "contract_repairs": 0}

    for museum in plan.get("plans", []):
        museum_key = f"{museum.get('museum')}|{museum.get('sequence')}"
        demands = {d.get("id"): d for d in museum.get("dna_spatial_demand", [])}
        for run in museum.get("wall_runs", []):
            anchor, axis = str(run.get("anchor", "")), str(run.get("axis", ""))
            key = f"{anchor}|{axis}"
            measured = envelopes.get(key)
            if measured is None:
                continue
            demand_id = f"dna:{anchor}:{axis}"
            if not measured.get("complete"):
                counts["contract_repairs"] += 1
                ok = (not run.get("housed") and not run.get("assemble")
                      and bool(run.get("contract_repair")))
                if not ok:
                    errors.append(f"{museum_key} {key}: incomplete family may assemble")
                rows.append({"museum": museum_key, "family": key,
                             "verdict": "contract_repair" if ok else "fail"})
                continue

            if run.get("housed"):
                counts["measured_housed"] += 1
                values = list(run.get("values") or [])
                rects = list(run.get("rects_uv") or [])
                if len(values) != len(rects):
                    errors.append(f"{museum_key} {key}: {len(values)} values but "
                                  f"{len(rects)} rectangles")
                    continue
                family_ok = bool(run.get("reserved")) and bool(run.get("assemble"))
                for value, rect in zip(values, rects):
                    # JSON object keys are strings even where a numeric DNA
                    # ladder (0.1, 0.25, ...) remains numeric in the plan row.
                    size = (measured.get("values") or {}).get(str(value))
                    if not size or len(rect) < 4:
                        family_ok = False
                        errors.append(f"{museum_key} {key}={value}: evidence missing")
                        continue
                    rect_w = float(rect[2]) - float(rect[0])
                    rect_h = float(rect[3]) - float(rect[1])
                    if float(size[0]) > rect_w + TOLERANCE_M or \
                            float(size[2]) > rect_h + TOLERANCE_M or \
                            float(size[1]) > 0.7:
                        family_ok = False
                        errors.append(f"{museum_key} {key}={value}: measured "
                                      f"{size} exceeds rect {rect_w:.3f}x{rect_h:.3f}")
                    counts["variants_housed"] += 1
                rows.append({"museum": museum_key, "family": key,
                             "verdict": "fit" if family_ok else "fail",
                             "variants": len(values)})
            else:
                demand = demands.get(demand_id)
                ok = demand is not None and demand.get("space") in {
                    "side_gallery", "courtyard", "dedicated_room"}
                if not ok:
                    errors.append(f"{museum_key} {key}: measured refusal has no "
                                  "named spatial demand")
                else:
                    counts["spatial_demand"] += 1
                rows.append({"museum": museum_key, "family": key,
                             "verdict": "spatial_demand" if ok else "fail",
                             **({"space": demand.get("space")} if demand else {})})

    return {
        "schema": "adaresearch.museum_dna_wall_validation.v1",
        "generated": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "inputs": [str(PLAN.relative_to(REPO)), str(ENVELOPES.relative_to(REPO))],
        "verdict": "PASS" if not errors else "FAIL",
        "counts": counts,
        "errors": errors,
        "rows": rows,
    }


def main() -> int:
    report = check()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(report, indent=1) + "\n", encoding="utf-8")
    print(f"{report['verdict']}: {report['counts']} -> {OUT}")
    for error in report["errors"][:20]:
        print(f"  {error}")
    return 0 if report["verdict"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
