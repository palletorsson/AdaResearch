"""Bounded form search over the exported production folded_strip vertex graph.

No museum content is modified. Geometry is ideal, zero-thickness, and measured in
the artifact's local metres. The render harness is responsible for showing these
vertices through the actual production update_mesh() implementation.
"""

from __future__ import annotations

import argparse
import hashlib
import itertools
import json
import math
from pathlib import Path
from typing import Sequence


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = ROOT / "doc/book/iterations/2026-09-16-folded-strip-research"
PRODUCTION_SCRIPT = ROOT / "commons/primitives/folded_strip/folded_strip.gd"
EPS = 1e-8
AREA_EPS = 1e-10
Vec = tuple[float, float, float]


def add(a: Sequence[float], b: Sequence[float]) -> Vec:
    return tuple(x + y for x, y in zip(a, b))


def sub(a: Sequence[float], b: Sequence[float]) -> Vec:
    return tuple(x - y for x, y in zip(a, b))


def mul(a: Sequence[float], s: float) -> Vec:
    return tuple(x * s for x in a)


def dot(a: Sequence[float], b: Sequence[float]) -> float:
    return sum(x * y for x, y in zip(a, b))


def cross(a: Sequence[float], b: Sequence[float]) -> Vec:
    return (a[1] * b[2] - a[2] * b[1],
            a[2] * b[0] - a[0] * b[2],
            a[0] * b[1] - a[1] * b[0])


def length(a: Sequence[float]) -> float:
    return math.sqrt(dot(a, a))


def unit(a: Sequence[float]) -> Vec:
    size = length(a)
    if size <= EPS:
        raise ValueError("A zero-length vector cannot define an axis.")
    return mul(a, 1.0 / size)


def rotate_about(p: Vec, origin: Vec, axis: Vec, radians: float) -> Vec:
    """Rodrigues rotation, with an explicit unit hinge axis."""
    v = sub(p, origin)
    k = unit(axis)
    c, s = math.cos(radians), math.sin(radians)
    return add(origin, add(add(mul(v, c), mul(cross(k, v), s)),
                           mul(k, dot(k, v) * (1.0 - c))))


def strip_triangles(count: int) -> list[tuple[int, int, int]]:
    # Production facet code submits all triples in the same order. Reverse the
    # odd triples ONLY for measurement so a flat strip has coherent normals.
    # Vertex positions and connectivity handed to the renderer are unchanged.
    return [(i, i + 1, i + 2) if i % 2 == 0 else (i + 1, i, i + 2)
            for i in range(count)]


def unique_edges(triangles: Sequence[Sequence[int]]) -> list[tuple[int, int]]:
    return sorted({tuple(sorted((a, b)))
                   for tri in triangles
                   for a, b in ((tri[0], tri[1]), (tri[1], tri[2]), (tri[2], tri[0]))})


def triangle_normal(tri: Sequence[Vec]) -> Vec:
    return cross(sub(tri[1], tri[0]), sub(tri[2], tri[0]))


def _inside_triangle(p: Vec, tri: Sequence[Vec]) -> bool:
    """Barycentric containment for a point already on the triangle plane."""
    v0, v1, v2 = sub(tri[1], tri[0]), sub(tri[2], tri[0]), sub(p, tri[0])
    d00, d01, d11 = dot(v0, v0), dot(v0, v1), dot(v1, v1)
    den = d00 * d11 - d01 * d01
    if den <= 4.0 * AREA_EPS * AREA_EPS:
        return False
    u = (d11 * dot(v2, v0) - d01 * dot(v2, v1)) / den
    v = (d00 * dot(v2, v1) - d01 * dot(v2, v0)) / den
    return u >= -EPS and v >= -EPS and u + v <= 1.0 + EPS


def _side(a, b, p):
    return (b[0] - a[0]) * (p[1] - a[1]) - (b[1] - a[1]) * (p[0] - a[0])


def _polygon_area(poly) -> float:
    if len(poly) < 3:
        return 0.0
    return abs(sum(a[0] * b[1] - b[0] * a[1]
                   for a, b in zip(poly, poly[1:] + poly[:1]))) * 0.5


def _coplanar_intersection(a: Sequence[Vec], b: Sequence[Vec], normal: Vec):
    # Orthogonal projection onto the coordinate plane with the largest normal
    # component avoids flattening a nearly edge-on triangle.
    skip = max(range(3), key=lambda k: abs(normal[k]))
    axes = [i for i in range(3) if i != skip]
    pa = [tuple(p[i] for i in axes) for p in a]
    pb = [tuple(p[i] for i in axes) for p in b]
    if _side(pb[0], pb[1], pb[2]) < 0:
        pb.reverse()
    clipped = pa[:]
    for q, r in zip(pb, pb[1:] + pb[:1]):
        edge_tolerance = EPS * math.dist(q, r)
        previous = clipped
        clipped = []
        if not previous:
            break
        start = previous[-1]
        ds = _side(q, r, start)
        for end in previous:
            de = _side(q, r, end)
            if (de >= -edge_tolerance) != (ds >= -edge_tolerance):
                divisor = ds - de
                if abs(divisor) > 1e-20:
                    t = ds / divisor
                    clipped.append(tuple(x + t * (y - x) for x, y in zip(start, end)))
            if de >= -edge_tolerance:
                clipped.append(end)
            start, ds = end, de
    area = _polygon_area(clipped)
    if area > AREA_EPS:
        return "coplanar_overlap"
    return "boundary_contact" if clipped else None


def triangle_intersection(a: Sequence[Vec], b: Sequence[Vec]):
    """Return a contact classification for two ideal triangles, or None.

    Degenerate triangles are excluded and reported separately by measure().
    Bounding boxes, signed plane tests, coplanar polygon clipping, and segment
    intersections provide a small CPU detector; this is not a robust CAD kernel.
    """
    for k in range(3):
        if max(p[k] for p in a) < min(p[k] for p in b) - EPS:
            return None
        if max(p[k] for p in b) < min(p[k] for p in a) - EPS:
            return None
    na, nb = triangle_normal(a), triangle_normal(b)
    if length(na) * 0.5 <= AREA_EPS or length(nb) * 0.5 <= AREA_EPS:
        return None
    na, nb = unit(na), unit(nb)
    da = [dot(sub(p, b[0]), nb) for p in a]
    db = [dot(sub(p, a[0]), na) for p in b]
    if min(da) > EPS or max(da) < -EPS or min(db) > EPS or max(db) < -EPS:
        return None
    if max(abs(d) for d in da + db) <= EPS:
        return _coplanar_intersection(a, b, na)
    hits: list[Vec] = []
    for source, target, distances in ((a, b, da), (b, a, db)):
        for i in range(3):
            j = (i + 1) % 3
            p, q = source[i], source[j]
            dp, dq = distances[i], distances[j]
            if abs(dp) <= EPS and _inside_triangle(p, target):
                hits.append(p)
            if dp * dq < 0.0 and abs(dp - dq) > 1e-20:
                hit = add(p, mul(sub(q, p), dp / (dp - dq)))
                if _inside_triangle(hit, target):
                    hits.append(hit)
    if not hits:
        return None
    span = max((length(sub(p, q)) for p, q in itertools.combinations(hits, 2)), default=0.0)
    return "noncoplanar_intersection" if span > EPS else "boundary_contact"


def measure(vertices: Sequence[Vec], baseline: Sequence[Vec], count: int) -> dict:
    tris = strip_triangles(count)
    normals = [triangle_normal([vertices[i] for i in tri]) for tri in tris]
    areas = [length(n) * 0.5 for n in normals]
    valid = [i for i, area in enumerate(areas) if area > AREA_EPS]
    degenerate = [i for i, area in enumerate(areas) if area <= AREA_EPS]
    creases = []
    for i in range(count - 1):
        if i not in valid or i + 1 not in valid:
            continue
        cosine = max(-1.0, min(1.0, dot(unit(normals[i]), unit(normals[i + 1]))))
        creases.append(math.degrees(math.acos(cosine)))
    reference_index = max(valid, key=lambda i: areas[i]) if valid else None
    max_plane_distance = None
    if reference_index is not None:
        origin = vertices[tris[reference_index][0]]
        normal = unit(normals[reference_index])
        max_plane_distance = max(abs(dot(sub(p, origin), normal)) for p in vertices)
    edges = unique_edges(tris)
    edge_drift, relative_drift = [], []
    for a, b in edges:
        original = length(sub(baseline[a], baseline[b]))
        drift = abs(length(sub(vertices[a], vertices[b])) - original)
        edge_drift.append(drift)
        relative_drift.append(drift / original if original > EPS else 0.0)
    intersections = []
    tested = 0
    skipped = 0
    for i, j in itertools.combinations(range(count), 2):
        if set(tris[i]).intersection(tris[j]) or i in degenerate or j in degenerate:
            skipped += 1
            continue
        tested += 1
        kind = triangle_intersection([vertices[k] for k in tris[i]], [vertices[k] for k in tris[j]])
        if kind:
            intersections.append({"triangles": [i, j], "kind": kind})
    bbox_min = [min(p[k] for p in vertices) for k in range(3)]
    bbox_max = [max(p[k] for p in vertices) for k in range(3)]
    return {
        "vertex_count": len(vertices), "triangle_count": count, "unique_edge_count": len(edges),
        "min_triangle_area_m2": min(areas), "max_triangle_area_m2": max(areas),
        "total_triangle_area_m2": sum(areas), "degenerate_triangles": degenerate,
        "max_crease_degrees": max(creases) if creases else None,
        "mean_crease_degrees": sum(creases) / len(creases) if creases else None,
        "valid_crease_count": len(creases), "reference_plane_triangle": reference_index,
        "max_distance_to_reference_plane_m": max_plane_distance,
        "max_edge_length_drift_m": max(edge_drift),
        "max_edge_length_drift_ratio": max(relative_drift),
        "bbox_min_m": bbox_min, "bbox_max_m": bbox_max,
        "extent_m": [hi - lo for lo, hi in zip(bbox_min, bbox_max)],
        "disjoint_triangle_intersection_count": len(intersections),
        "disjoint_triangle_intersections": intersections,
        "intersection_status": ("not_evaluated_all_degenerate" if not valid else
                                "contacts_detected" if intersections else
                                "no_disjoint_contact_detected"),
        "triangle_pairs_tested": tested, "triangle_pairs_skipped": skipped,
    }


def hinge_fold(vertices: Sequence[Vec], angles: Sequence[float]) -> list[Vec]:
    """Fold the downstream strip across each shared edge in order.

    For hinge i, vertices i+1 and i+2 remain on the hinge and vertices i+3..
    rotate as a rigid group. Every mesh edge stays within one rigid component
    or ends on the hinge. Hence all mesh edge lengths should be preserved.
    """
    out = list(vertices)
    for i, degrees in enumerate(angles):
        a, b = out[i + 1], out[i + 2]
        for j in range(i + 3, len(out)):
            out[j] = rotate_about(out[j], a, sub(b, a), math.radians(degrees))
    return out


def baseline_frame(vertices: Sequence[Vec]):
    origin = mul(tuple(sum(p[k] for p in vertices) for k in range(3)), 1.0 / len(vertices))
    along = unit(sub(vertices[2], vertices[0]))
    diagonal = sub(vertices[1], vertices[0])
    across = unit(sub(diagonal, mul(along, dot(diagonal, along))))
    normal = unit(cross(along, across))
    coordinates = [(dot(sub(p, origin), along), dot(sub(p, origin), across), dot(sub(p, origin), normal))
                   for p in vertices]
    return origin, along, across, normal, coordinates


def deform(vertices: Sequence[Vec], family: str, amount: float, cycles: int = 1) -> list[Vec]:
    origin, along, across, normal, coordinates = baseline_frame(vertices)
    span = max(p[0] for p in coordinates) - min(p[0] for p in coordinates)
    out = []
    for x, y, z in coordinates:
        if family == "bend":
            k = math.radians(amount) / span
            xx, yy, zz = math.sin(k * x) / k, y, (1.0 - math.cos(k * x)) / k + z
        elif family == "twist":
            theta = math.radians(amount) * x / span
            xx, yy, zz = x, y * math.cos(theta) - z * math.sin(theta), y * math.sin(theta) + z * math.cos(theta)
        elif family == "wave":
            xx, yy, zz = x, y, z + amount * math.sin(2.0 * math.pi * cycles * x / span)
        elif family == "collapse":
            xx, yy, zz = x, 0.0, 0.0
        else:
            raise ValueError(f"Unknown deformation {family}")
        out.append(add(origin, add(mul(along, xx), add(mul(across, yy), mul(normal, zz)))))
    return out


COMMON_LIMITS = [
    "Ideal triangle surfaces in artifact-local metres; not shell thickness, grab-handle clearance, collision bodies, or museum placement.",
    "Intersection detector checks only triangle pairs with no shared vertex; adjacent/shared-vertex fold-through can be missed.",
    "Coplanar overlap and boundary contact are reported; floating-point tolerances are not an exact geometric proof.",
    "A geometry check does not establish visual quality, stability, walkability, VR comfort, or suitability for the book.",
]


def generate_cases(vertices: Sequence[Vec], count: int) -> list[dict]:
    cases = []

    def case(case_id, title, family, parameters, positions, limits):
        cases.append({"id": case_id, "title": title, "family": family,
                      "parameters": parameters, "vertices": [list(p) for p in positions],
                      "metrics": measure(positions, vertices, count), "limitations": limits})

    case("shipped", "The shipped strip", "baseline", {}, list(vertices),
         ["Untouched exported production vertex positions; no claim that its starting geometry is pleated."])
    for angle in (30, 70, 120):
        angles = [0.0] * (count - 1)
        angles[(count - 1) // 2] = float(angle)
        case(f"hinge-single-{angle}", f"One crease, {angle} degrees", "hinge_single",
             {"angle_degrees": angle, "hinge_index": (count - 1) // 2, "operation": "downstream rigid rotations"},
             hinge_fold(vertices, angles), ["Preserves triangle edge lengths; does not prevent surfaces passing through each other."])
    for schedule in ("same", "alternating", "paired"):
        for angle in (10, 25, 40, 60, 85, 115, 150, 180):
            signs = ([1] * (count - 1) if schedule == "same" else
                     [(-1) ** i for i in range(count - 1)] if schedule == "alternating" else
                     [(-1) ** (i // 2) for i in range(count - 1)])
            case(f"hinge-{schedule}-{angle}", f"{schedule.title()} hinge turns, {angle} degrees", f"hinge_{schedule}",
                 {"angle_degrees": angle, "schedule": schedule, "operation": "downstream rigid rotations"},
                 hinge_fold(vertices, [angle * sign for sign in signs]),
                 ["Signs describe rotation about the ordered vertex-to-vertex hinge axes; they are not mountain/valley labels.",
                  "Preserves triangle edge lengths; extreme folds may overlap or pass through one another."])
    for angle in (30, 60, 120, 180, 270, 360, 540):
        case(f"bend-{angle}", f"Bend through {angle} degrees", "bend",
             {"total_angle_degrees": angle, "operation": "vertex deformation"}, deform(vertices, "bend", angle),
             ["Sampled cylindrical deformation, not rigid paper folding; straight mesh edges are chords and change length."])
    for angle in (30, 90, 180, 360, 720):
        case(f"twist-{angle}", f"Twist through {angle} degrees", "twist",
             {"total_angle_degrees": angle, "operation": "vertex deformation"}, deform(vertices, "twist", angle),
             ["Vertex rotation about the long axis; connected edge lengths and triangle areas can change."])
    for cycles, amount in itertools.product((1, 2), (0.2, 0.5, 1.0)):
        case(f"wave-{cycles}-{int(amount * 100):03d}", f"{cycles} wave(s), {amount:.1f} m rise", "wave",
             {"cycles": cycles, "amplitude_m": amount, "operation": "vertex deformation"}, deform(vertices, "wave", amount, cycles),
             ["Sine displacement of existing vertices; topology stays fixed while edge lengths change."])
    case("collapsed", "A strip reduced to a line", "failure",
         {"operation": "vertex deformation", "intentional_failure": "all faces degenerate"}, deform(vertices, "collapse", 0),
         ["Intentional counterexample: every triangle has zero area. Normals and crease measurements are undefined."])
    return cases


SELECTION = [
    ("shipped", "Control: keep the exported production starting arrangement visible."),
    ("hinge-single-70", "Isolate one actual crease before comparing repeated hinges."),
    ("hinge-alternating-60", "Keep a crowding stress case: repeated hinge turns preserve lengths but can overlap; measured contacts stay visible."),
    ("hinge-paired-40", "Change the hinge schedule to paired signs without adding triangles."),
    ("bend-180", "Compare a broad curved silhouette with the edge-length-preserving hinge operations."),
    ("twist-360", "Expose rotation along the long direction and its measured edge-length cost."),
    ("wave-1-050", "Use the already familiar sine operation to make one rise and one fall."),
    ("collapsed", "Retain a visible failure: unchanged connectivity does not guarantee a surface with area."),
]


def analytic_checks() -> list[dict]:
    results = []

    def check(name, passed):
        if not passed:
            raise AssertionError(f"Analytic check failed: {name}")
        results.append({"name": name, "passed": True})

    flat = [(0.0, 0.0, 0.0), (0.0, 1.0, 0.0), (1.0, 0.0, 0.0), (1.0, 1.0, 0.0)]
    metrics = measure(flat, flat, 2)
    check("unit square: two half-unit triangles", abs(metrics["min_triangle_area_m2"] - .5) < EPS)
    check("strip winding corrected: flat crease zero", metrics["max_crease_degrees"] < 1e-5)
    check("flat square coplanar", metrics["max_distance_to_reference_plane_m"] < EPS)
    check("shared-edge pair excluded from disjoint checks", metrics["triangle_pairs_tested"] == 0)
    folded = hinge_fold(flat, [90.0])
    fm = measure(folded, flat, 2)
    check("one hinge gives 90-degree crease", abs(fm["max_crease_degrees"] - 90) < 1e-6)
    check("hinge preserves all five mesh edge lengths", fm["max_edge_length_drift_m"] < EPS)
    check("hinge preserves both triangle areas", abs(fm["total_triangle_area_m2"] - 1) < EPS)
    check("hinge vertices remain fixed", folded[1:3] == flat[1:3])
    a = [(0., 0., 0.), (2., 0., 0.), (0., 2., 0.)]
    crossing = [(.5, .5, -1.), (.5, .5, 1.), (1., .5, 0.)]
    check("noncoplanar crossing detected", triangle_intersection(a, crossing) == "noncoplanar_intersection")
    check("crossing symmetric", triangle_intersection(crossing, a) == "noncoplanar_intersection")
    overlap = [(.2, .2, 0.), (.5, .2, 0.), (.2, .5, 0.)]
    check("coplanar containment detected", triangle_intersection(a, overlap) == "coplanar_overlap")
    check("coplanar reversed winding supported", triangle_intersection(a, overlap[::-1]) == "coplanar_overlap")
    boundary = [(2., 0., 0.), (3., 0., 0.), (2., -1., 0.)]
    check("point-only coplanar contact retained", triangle_intersection(a, boundary) == "boundary_contact")
    separate = [(2., 2., 0.), (3., 2., 0.), (2., 3., 0.)]
    check("coplanar separated triangles clear", triangle_intersection(a, separate) is None)
    check("parallel separated planes clear", triangle_intersection(a, [add(p, (0., 0., 1.)) for p in a]) is None)
    line = [(float(i), 0., 0.) for i in range(4)]
    lm = measure(line, flat, 2)
    check("degenerate faces explicitly listed", lm["degenerate_triangles"] == [0, 1])
    check("degenerate crease undefined rather than zero", lm["max_crease_degrees"] is None)
    check("fully degenerate reference plane undefined", lm["max_distance_to_reference_plane_m"] is None)
    return results


def write_json(path: Path, data: dict) -> None:
    temporary = path.with_name(path.name + ".task-tmp")
    temporary.write_text(json.dumps(data, indent=2, ensure_ascii=False, allow_nan=False) + "\n", encoding="utf-8")
    temporary.replace(path)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", type=Path, default=DEFAULT_OUTPUT / "baseline.json")
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    checks = analytic_checks()
    if args.self_test:
        print(json.dumps({"analytic_checks": checks, "passed": len(checks)}))
        return
    baseline_bytes = args.baseline.read_bytes()
    baseline = json.loads(baseline_bytes)
    vertices = [tuple(float(v) for v in p) for p in baseline["vertices"]]
    count = int(baseline["num_triangles"])
    if count != 24 or len(vertices) != 26:
        raise ValueError("This bounded study expects the exported production 26-vertex, 24-triangle strip.")
    if any(len(p) != 3 or not all(math.isfinite(v) for v in p) for p in vertices):
        raise ValueError("Baseline contains invalid vertices.")
    current_source_hash = hashlib.sha256(PRODUCTION_SCRIPT.read_bytes()).hexdigest()
    if baseline["source_sha256"] != current_source_hash:
        raise ValueError("Production folded_strip.gd changed after export. Export a fresh baseline first.")
    cases = generate_cases(vertices, count)
    for case in cases:
        if case["family"].startswith("hinge_"):
            assert case["metrics"]["max_edge_length_drift_m"] < 1e-7, case["id"]
    by_id = {case["id"]: case for case in cases}
    selected = []
    for case_id, reason in SELECTION:
        selected.append({**by_id[case_id], "selection_reason": reason})
    shared = {
        "schema_version": 1,
        "baseline_source_sha256": current_source_hash,
        "baseline_export_sha256": hashlib.sha256(baseline_bytes).hexdigest(),
        "generator_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        "geometry_source": "Production vertex_positions exported by Godot; candidates retain the same vertex indices and triangle graph.",
        "measurement_winding": "Odd strip triangles reversed for coherent normals only; rendering still uses unchanged production update_mesh().",
        "metric_definitions": {
            "area": "0.5 times the cross-product length; a face is degenerate at or below 1e-10 square metres.",
            "crease": "Angle between coherently oriented adjacent face normals: 0 degrees unfolded, 180 degrees folded back; degenerate neighbors skipped.",
            "coplanarity": "Maximum vertex distance from the largest nondegenerate face plane; null if no such face exists. This is a reference-plane test, not a best-fit-plane estimate.",
            "edge_drift": "Maximum absolute and relative length change among every unique mesh edge against the exported baseline.",
            "extent": "Axis-aligned local-space bounding box; orientation-dependent and not a museum footprint.",
            "intersections": "Contacts between ideal triangles with disjoint vertex-index sets; includes coplanar overlap and boundary contact. Shared-vertex pairs and degenerate triangles excluded.",
            "intersection_tolerance": "Distance/barycentric tolerance 1e-8; area tolerance 1e-10 square metres; finite-precision heuristic, not a robust solid collision test.",
        },
        "limitations": COMMON_LIMITS,
        "analytic_checks": checks,
        "selection": {
            "method": "Predetermined contrastive shortlist, not an aesthetic optimizer or ranking.",
            "criteria": [reason for _, reason in SELECTION],
            "selected_ids": [case_id for case_id, _ in SELECTION],
            "count_search_cases": len(cases),
            "count_selected_cases": len(selected),
        },
    }
    args.output_dir.mkdir(parents=True, exist_ok=True)
    write_json(args.output_dir / "all-cases.json", {**shared, "cases": cases})
    write_json(args.output_dir / "selected-cases.json", {**shared, "cases": selected})
    print(json.dumps({"generated": len(cases), "selected": len(selected), "analytic_checks_passed": len(checks),
                      "selected_metrics": [{"id": c["id"], "crease": c["metrics"]["max_crease_degrees"],
                                            "edge_drift_m": c["metrics"]["max_edge_length_drift_m"],
                                            "intersections": c["metrics"]["disjoint_triangle_intersection_count"]}
                                           for c in selected]}))


if __name__ == "__main__":
    main()
