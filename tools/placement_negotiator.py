#!/usr/bin/env python3
"""Explain artifact-room placement decisions for the endless museum.

Negotiation v1 is deliberately conservative: it reads canonical artifact
requirements from dressing-room JSON and compares them with explicit floorplan
offers. It never rewrites the dressing room or a map. Its outputs are review
records and three-zone overlays that show occupied body, hard clearance, and
preferred space.

Usage:
    python tools/placement_negotiator.py
    python tools/placement_negotiator.py --check
"""
from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any


REPO = Path(__file__).resolve().parent.parent
ROOMS_DIR = REPO / "commons" / "artifacts" / "dressing_rooms"
DEFAULT_RULES = REPO / "commons" / "data" / "placement_rules_v1.json"
DEFAULT_OFFERS = REPO / "ada_run" / "museum_aaa_pass" / "negotiation_offers.json"
DEFAULT_RELEASE_REPORT = REPO / "ada_run" / "museum_aaa_pass" / "report.json"
DEFAULT_OUT = REPO / "ada_run" / "museum_aaa_pass" / "negotiation_report.json"
DEFAULT_OVERLAYS = REPO / "ada_run" / "museum_aaa_pass" / "negotiation"


def load_json(path: Path) -> dict[str, Any]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError(f"expected JSON object: {path}")
    return data


def room_for(lookup: str) -> dict[str, Any]:
    path = ROOMS_DIR / f"{lookup}.json"
    if not path.exists():
        raise FileNotFoundError(f"missing dressing room: {path}")
    return load_json(path)


def vec3(value: Any, label: str) -> list[float]:
    if not isinstance(value, list) or len(value) != 3:
        raise ValueError(f"{label} must be [width, depth, height]")
    return [float(value[0]), float(value[1]), float(value[2])]


def fits(inner: list[float], outer: list[float], epsilon: float = 1e-6) -> bool:
    return all(a <= b + epsilon for a, b in zip(inner, outer))


def rounded(values: list[float]) -> list[int | float]:
    out: list[int | float] = []
    for value in values:
        out.append(int(value) if float(value).is_integer() else round(value, 3))
    return out


def axis_can_expand(axis: int, directions: list[str]) -> bool:
    if axis == 0:
        return "east" in directions or "west" in directions
    if axis == 1:
        return "north" in directions or "south" in directions
    return "up" in directions


def rotate_side(side: str, rotation: int) -> str:
    sides = ["north", "east", "south", "west"]
    if side not in sides:
        return side
    return sides[(sides.index(side) + (rotation // 90)) % 4]


@dataclass
class RuleTrace:
    rule: str
    outcome: str
    reason: str

    def as_dict(self) -> dict[str, str]:
        return {"rule": self.rule, "outcome": self.outcome, "reason": self.reason}


def negotiate(
    offer: dict[str, Any],
    room: dict[str, Any],
    artifact_report: dict[str, Any],
) -> dict[str, Any]:
    lookup = str(offer.get("artifact", ""))
    contract_raw = room.get("placement_contract", {})
    if not isinstance(contract_raw, dict) or not contract_raw:
        raise ValueError(f"{lookup}: placement_contract is required")
    contract: dict[str, Any] = contract_raw

    body = vec3(artifact_report.get("measured_body_m"), f"{lookup}.measured_body_m")
    hard = vec3(contract.get("hard_zone_m"), f"{lookup}.hard_zone_m")
    preferred = vec3(contract.get("preferred_zone_m"), f"{lookup}.preferred_zone_m")
    offered = vec3(offer.get("room_m"), f"{lookup}.offer.room_m")
    final_room = offered[:]
    actions: list[dict[str, Any]] = []
    traces: list[RuleTrace] = []
    failures: list[str] = []

    body_ok = fits(body, hard)
    traces.append(RuleTrace(
        "body_inside_hard_zone",
        "pass" if body_ok else "fail",
        f"Measured body {rounded(body)} {'fits' if body_ok else 'does not fit'} hard zone {rounded(hard)}.",
    ))
    if not body_ok:
        failures.append("measured body exceeds hard zone")

    zones_nested = fits(hard, preferred)
    if not zones_nested:
        failures.append("hard zone exceeds preferred zone")

    allowed_modes = [str(x) for x in contract.get("allowed_modes", [])]
    preferred_mode = str(contract.get("preferred_mode", allowed_modes[0] if allowed_modes else ""))
    final_mode = str(offer.get("mode", ""))
    if final_mode not in allowed_modes:
        if preferred_mode in allowed_modes:
            actions.append({"action": "move", "from": final_mode, "to": preferred_mode})
            traces.append(RuleTrace(
                "mode_is_allowed", "applied",
                f"Moved from unsupported mode {final_mode!r} to {preferred_mode!r}.",
            ))
            final_mode = preferred_mode
        else:
            traces.append(RuleTrace("mode_is_allowed", "fail", f"Mode {final_mode!r} is not allowed."))
            failures.append("placement mode is not allowed")
    else:
        traces.append(RuleTrace("mode_is_allowed", "pass", f"Mode {final_mode!r} is allowed."))

    allowed_rotations = [int(str(x)) for x in room.get("rotations", ["0"])]
    offered_rotation = int(offer.get("rotation", 0)) % 360
    final_rotation = offered_rotation
    if offered_rotation not in allowed_rotations:
        final_rotation = allowed_rotations[0]
        actions.append({"action": "rotate", "from": offered_rotation, "to": final_rotation})
        traces.append(RuleTrace(
            "rotation_is_allowed", "applied",
            f"Rotated from {offered_rotation}° to allowed rotation {final_rotation}°.",
        ))
    else:
        traces.append(RuleTrace(
            "rotation_is_allowed", "pass", f"Rotation {offered_rotation}° is allowed."
        ))

    required_support = str(contract.get("required_support", room.get("posture", "")))
    offered_support = str(offer.get("support", ""))
    support_ok = required_support == offered_support
    traces.append(RuleTrace(
        "support_matches_contract",
        "pass" if support_ok else "fail",
        f"Offered support {offered_support!r} {'matches' if support_ok else 'does not match'} required {required_support!r}.",
    ))
    if not support_ok:
        failures.append("required support is unavailable")

    support_height_range = contract.get("support_surface_height_m")
    if isinstance(support_height_range, list) and len(support_height_range) == 2:
        support_min = float(support_height_range[0])
        support_max = float(support_height_range[1])
        offered_support_height = offer.get("support_surface_height_m")
        support_height_ok = (
            offered_support_height is not None
            and support_min <= float(offered_support_height) <= support_max
        )
        offered_label = (
            "missing" if offered_support_height is None
            else f"{float(offered_support_height):g} m"
        )
        traces.append(RuleTrace(
            "support_surface_height_is_usable",
            "pass" if support_height_ok else "fail",
            f"Offered surface height {offered_label} "
            f"{'is inside' if support_height_ok else 'is outside'} "
            f"the usable {support_min:g}-{support_max:g} m range.",
        ))
        if not support_height_ok:
            failures.append("support surface height is unusable")

    wall_side = rotate_side(str(contract.get("wall_side", "")), final_rotation)
    wall_sides = [str(x) for x in offer.get("wall_sides", [])]
    if final_mode == "against_wall":
        wall_ok = wall_side in wall_sides
        traces.append(RuleTrace(
            "wall_side_is_available",
            "pass" if wall_ok else "fail",
            f"Required {wall_side or 'contracted'} wall {'is' if wall_ok else 'is not'} available.",
        ))
        if not wall_ok:
            failures.append("required wall side is unavailable")
        rear = float(contract.get("rear_clearance_m", 0.0))
        circulation_behind = bool(contract.get("circulation_behind", True))
        if rear == 0.0 and not circulation_behind:
            actions.append({
                "action": "apply_wall_exception",
                "rear_clearance_m": 0.0,
                "reason": "the artifact has no rear interaction or circulation claim",
            })
            traces.append(RuleTrace(
                "rear_clearance_exception_is_explicit", "applied",
                "Zero rear clearance accepted because circulation_behind is false.",
            ))
        else:
            traces.append(RuleTrace(
                "rear_clearance_exception_is_explicit", "pass",
                f"Rear clearance remains {rear:g} m.",
            ))

    neighbors = [str(x) for x in offer.get("neighbor_artifacts", [])]
    neighbor_policy = str(contract.get("neighbor_policy", "outside_preferred_zone"))
    neighbors_ok = not neighbors or neighbor_policy == "allow_inside_preferred_zone"
    traces.append(RuleTrace(
        "neighbor_policy_is_respected",
        "pass" if neighbors_ok else "fail",
        "No artifact enters the reserved zone." if neighbors_ok else
        f"Neighbors {neighbors} violate policy {neighbor_policy!r}.",
    ))
    if not neighbors_ok:
        failures.append("neighbor artifact enters reserved space")

    min_route = float(contract.get("minimum_route_width_m", 0.0))
    offered_route = float(offer.get("route_width_m", 0.0))
    circulation = str(contract.get("circulation", "frontal"))
    orbit_ok = circulation != "full_orbit" or offered_route >= min_route
    if circulation == "full_orbit":
        traces.append(RuleTrace(
            "complete_orbit_is_preserved",
            "pass" if orbit_ok else "fail",
            f"Offered route width {offered_route:g} m {'meets' if orbit_ok else 'is below'} the {min_route:g} m minimum.",
        ))
        if not orbit_ok:
            failures.append("complete orbit route is too narrow")

    expansion_directions = [str(x) for x in offer.get("expansion_directions", [])]
    hard_short_axes = [i for i in range(3) if offered[i] < hard[i]]
    hard_can_grow = all(axis_can_expand(i, expansion_directions) for i in hard_short_axes)
    if hard_short_axes and not hard_can_grow:
        traces.append(RuleTrace(
            "hard_zone_inside_offer", "fail",
            f"Offer {rounded(offered)} is smaller than hard zone {rounded(hard)} and cannot expand on every required axis.",
        ))
        failures.append("floorplan cannot supply hard zone")
    elif hard_short_axes:
        previous = final_room[:]
        final_room = [max(a, b) for a, b in zip(final_room, hard)]
        actions.append({"action": "grow", "from_m": rounded(previous), "to_m": rounded(final_room)})
        traces.append(RuleTrace(
            "hard_zone_inside_offer", "applied",
            f"Offer can expand from {rounded(offered)} to contain hard zone {rounded(hard)}.",
        ))
    else:
        traces.append(RuleTrace(
            "hard_zone_inside_offer", "pass",
            f"Offer {rounded(offered)} already contains hard zone {rounded(hard)}.",
        ))

    if not failures:
        preferred_short_axes = [i for i in range(3) if final_room[i] < preferred[i]]
        can_reach_preferred = all(axis_can_expand(i, expansion_directions) for i in preferred_short_axes)
        if preferred_short_axes and can_reach_preferred:
            previous = final_room[:]
            final_room = [max(a, b) for a, b in zip(final_room, preferred)]
            actions.append({"action": "grow", "from_m": rounded(previous), "to_m": rounded(final_room)})
            traces.append(RuleTrace(
                "preferred_zone_is_offered", "applied",
                f"Expanded to preferred zone {rounded(preferred)}.",
            ))
        elif preferred_short_axes:
            traces.append(RuleTrace(
                "preferred_zone_is_offered", "compromised",
                f"Retained valid room {rounded(final_room)}; preferred zone {rounded(preferred)} cannot be fully offered.",
            ))
        elif any(final_room[i] > preferred[i] for i in range(3)) and bool(offer.get("allow_shrink", False)):
            previous = final_room[:]
            final_room = preferred[:]
            actions.insert(0, {"action": "shrink", "from_m": rounded(previous), "to_m": rounded(final_room)})
            traces.append(RuleTrace(
                "preferred_zone_is_offered", "applied",
                f"Released surplus space and retained preferred zone {rounded(preferred)}.",
            ))
        else:
            traces.append(RuleTrace(
                "preferred_zone_is_offered", "pass",
                f"Offer supplies preferred zone {rounded(preferred)}.",
            ))

    if failures:
        decision = "reject"
        status = "rejected"
        actions = [{"action": "reject", "reasons": failures}]
        final_room = offered[:]
    else:
        priority = ["move", "rotate", "grow", "shrink", "apply_wall_exception"]
        action_names = [str(a.get("action", "")) for a in actions]
        decision = next((name for name in priority if name in action_names), "accept")
        status = "accepted" if decision == "accept" else "accepted_with_changes"

    return {
        "artifact": lookup,
        "display_name": artifact_report.get("display_name", lookup),
        "status": status,
        "decision": decision,
        "offer": {
            "room_m": rounded(offered),
            "mode": offer.get("mode"),
            "rotation": offered_rotation,
            "support": offered_support,
            "support_surface_height_m": offer.get("support_surface_height_m"),
            "wall_sides": wall_sides,
            "neighbor_artifacts": neighbors,
            "expansion_directions": expansion_directions,
        },
        "zones": {
            "occupied_body_m": rounded(body),
            "hard_zone_m": rounded(hard),
            "preferred_zone_m": rounded(preferred),
        },
        "result": {
            "room_m": rounded(final_room),
            "mode": final_mode,
            "rotation": final_rotation,
            "support": required_support,
            "circulation": circulation,
            "wall_side": wall_side or None,
        },
        "actions": actions,
        "rules_used": [trace.as_dict() for trace in traces],
    }


def render_overlay(decision: dict[str, Any], path: Path) -> None:
    try:
        from PIL import Image, ImageDraw, ImageFont
    except ImportError as exc:
        raise RuntimeError("Pillow is required for negotiation overlays") from exc

    width_px, height_px = 760, 560
    image = Image.new("RGBA", (width_px, height_px), "#101820")
    draw = ImageDraw.Draw(image, "RGBA")
    def load_font(size: int, bold: bool = False):
        names = ["DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"]
        names.extend([
            "C:/Windows/Fonts/segoeuib.ttf" if bold else "C:/Windows/Fonts/segoeui.ttf",
            "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else
            "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        ])
        for name in names:
            try:
                return ImageFont.truetype(name, size)
            except OSError:
                continue
        return ImageFont.load_default()

    title_font = load_font(28, bold=True)
    label_font = load_font(16, bold=True)
    small_font = load_font(13)

    zones = decision["zones"]
    result = decision["result"]
    offer = decision["offer"]
    preferred = [float(x) for x in zones["preferred_zone_m"]]
    hard = [float(x) for x in zones["hard_zone_m"]]
    body = [float(x) for x in zones["occupied_body_m"]]
    final_room = [float(x) for x in result["room_m"]]
    offered_room = [float(x) for x in offer["room_m"]]
    plot_max_w = max(preferred[0], final_room[0], offered_room[0]) + 2.0
    plot_max_d = max(preferred[1], final_room[1], offered_room[1]) + 2.0
    plot = (60, 105, 700, 475)
    scale = min((plot[2] - plot[0]) / plot_max_w, (plot[3] - plot[1]) / plot_max_d)
    cx = (plot[0] + plot[2]) / 2
    cy = (plot[1] + plot[3]) / 2

    def rect_for(size: list[float], against_wall: bool = False) -> tuple[float, float, float, float]:
        w = size[0] * scale
        d = size[1] * scale
        if against_wall:
            room_top = cy - final_room[1] * scale / 2
            return (cx - w / 2, room_top, cx + w / 2, room_top + d)
        return (cx - w / 2, cy - d / 2, cx + w / 2, cy + d / 2)

    # One-metre grid inside the final room.
    room_rect = rect_for(final_room)
    draw.rectangle(room_rect, fill=(30, 42, 52, 255), outline=(238, 242, 244, 255), width=3)
    x = room_rect[0] + scale
    while x < room_rect[2] - 1:
        draw.line((x, room_rect[1], x, room_rect[3]), fill=(93, 111, 121, 90), width=1)
        x += scale
    y = room_rect[1] + scale
    while y < room_rect[3] - 1:
        draw.line((room_rect[0], y, room_rect[2], y), fill=(93, 111, 121, 90), width=1)
        y += scale

    against_wall = result.get("mode") == "against_wall"
    soft_rect = rect_for(preferred, against_wall)
    hard_rect = rect_for(hard, against_wall)
    body_rect = rect_for(body, against_wall)
    draw.rectangle(soft_rect, fill=(245, 166, 35, 72), outline=(245, 166, 35, 230), width=3)
    draw.rectangle(hard_rect, fill=(50, 190, 220, 92), outline=(50, 190, 220, 245), width=3)
    draw.rectangle(body_rect, fill=(226, 72, 133, 190), outline=(255, 178, 210, 255), width=3)

    # Draw the original floorplan offer last so an offer that exactly matches
    # the hard zone remains visible instead of disappearing beneath its fill.
    offer_rect = rect_for(offered_room)
    dash = 10
    for start in range(int(offer_rect[0]), int(offer_rect[2]), dash * 2):
        draw.line((start, offer_rect[1], min(start + dash, offer_rect[2]), offer_rect[1]), fill=(190, 201, 207, 245), width=3)
        draw.line((start, offer_rect[3], min(start + dash, offer_rect[2]), offer_rect[3]), fill=(190, 201, 207, 245), width=3)
    for start in range(int(offer_rect[1]), int(offer_rect[3]), dash * 2):
        draw.line((offer_rect[0], start, offer_rect[0], min(start + dash, offer_rect[3])), fill=(190, 201, 207, 245), width=3)
        draw.line((offer_rect[2], start, offer_rect[2], min(start + dash, offer_rect[3])), fill=(190, 201, 207, 245), width=3)

    if against_wall:
        draw.line((room_rect[0], room_rect[1], room_rect[2], room_rect[1]), fill=(238, 242, 244, 255), width=8)
        draw.text((room_rect[0], room_rect[1] - 25), "NORTH WALL", font=small_font, fill=(238, 242, 244, 255))

    draw.text((40, 28), str(decision["display_name"]), font=title_font, fill=(244, 247, 248, 255))
    subtitle = (
        f"{decision['decision'].upper()}  |  "
        f"{offered_room[0]:g}x{offered_room[1]:g} -> "
        f"{final_room[0]:g}x{final_room[1]:g} m"
    )
    draw.text((40, 65), subtitle, font=label_font, fill=(174, 190, 199, 255))

    legend = [
        ("occupied body", (226, 72, 133, 255)),
        ("hard zone", (50, 190, 220, 255)),
        ("preferred zone", (245, 166, 35, 255)),
        ("original offer", (160, 170, 177, 255)),
    ]
    lx = 45
    for label, color in legend:
        draw.rectangle((lx, 510, lx + 18, 528), fill=color)
        draw.text((lx + 25, 510), label, font=small_font, fill=(216, 225, 229, 255))
        lx += 160

    path.parent.mkdir(parents=True, exist_ok=True)
    image.convert("RGB").save(path, quality=94)


def build_report(
    rules: dict[str, Any], offers: dict[str, Any], release_report: dict[str, Any]
) -> dict[str, Any]:
    artifact_rows = list(release_report.get("artifacts", []))
    artifact_rows.extend(release_report.get("test_candidates", []))
    artifact_rows.extend(release_report.get("wave3_candidates", []))
    artifact_rows.extend(release_report.get("wave4_candidates", []))
    artifacts = {
        str(item.get("lookup_name")): item
        for item in artifact_rows
        if isinstance(item, dict)
    }
    decisions: list[dict[str, Any]] = []
    for offer in offers.get("offers", []):
        if not isinstance(offer, dict):
            continue
        lookup = str(offer.get("artifact", ""))
        if lookup not in artifacts:
            raise ValueError(f"offer references artifact absent from release report: {lookup}")
        decision = negotiate(offer, room_for(lookup), artifacts[lookup])
        decision["overlay_image"] = f"negotiation/{lookup}.png"
        decisions.append(decision)

    return {
        "schema": "adaresearch.placement_negotiation_report.v1",
        "title": "Featured-room placement negotiation v1",
        "rules_schema": rules.get("schema"),
        "supported_actions": rules.get("supported_actions", []),
        "summary": {
            "decisions": len(decisions),
            "accepted": sum(d["status"].startswith("accepted") for d in decisions),
            "changed": sum(d["status"] == "accepted_with_changes" for d in decisions),
            "rejected": sum(d["status"] == "rejected" for d in decisions),
            "hard_failures": sum(
                1 for d in decisions for trace in d["rules_used"] if trace["outcome"] == "fail"
            ),
            "soft_compromises": sum(
                1 for d in decisions for trace in d["rules_used"] if trace["outcome"] == "compromised"
            ),
        },
        "decisions": decisions,
    }


def validate_expected(report: dict[str, Any], offers: dict[str, Any]) -> list[str]:
    expected = {
        str(o.get("artifact")): str(o.get("expected_decision"))
        for o in offers.get("offers", []) if isinstance(o, dict) and o.get("expected_decision")
    }
    errors: list[str] = []
    for decision in report.get("decisions", []):
        lookup = str(decision.get("artifact"))
        if lookup in expected and decision.get("decision") != expected[lookup]:
            errors.append(
                f"{lookup}: expected {expected[lookup]!r}, got {decision.get('decision')!r}"
            )
        if decision.get("status") == "rejected":
            errors.append(f"{lookup}: seed offer was rejected")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rules", type=Path, default=DEFAULT_RULES)
    parser.add_argument("--offers", type=Path, default=DEFAULT_OFFERS)
    parser.add_argument("--release-report", type=Path, default=DEFAULT_RELEASE_REPORT)
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT)
    parser.add_argument("--overlay-dir", type=Path, default=DEFAULT_OVERLAYS)
    parser.add_argument("--check", action="store_true", help="validate seeded decisions without writing")
    args = parser.parse_args()

    rules = load_json(args.rules)
    offers = load_json(args.offers)
    release_report = load_json(args.release_report)
    report = build_report(rules, offers, release_report)
    errors = validate_expected(report, offers)
    if errors:
        for error in errors:
            print(f"FAIL  {error}")
        return 1

    if not args.check:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        for decision in report["decisions"]:
            render_overlay(decision, args.overlay_dir / f"{decision['artifact']}.png")
        print(f"wrote {args.out}")
        print(f"wrote {len(report['decisions'])} overlays to {args.overlay_dir}")

    summary = report["summary"]
    print(
        "OK    placement negotiation v1 "
        f"({summary['accepted']}/{summary['decisions']} accepted, "
        f"{summary['hard_failures']} hard failures, {summary['soft_compromises']} soft compromises)"
    )
    for decision in report["decisions"]:
        print(
            f"  {decision['artifact']}: {decision['decision']} "
            f"{decision['offer']['room_m']} -> {decision['result']['room_m']}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
