from pathlib import Path

more_code = {
'Euclid_Parallel': """

## Sum of Angles in a Triangle

```gdscript
# Euclid's 5th postulate implies the triangle angle sum is 180°.
# In non-Euclidean geometries this fails.
static func triangle_angle_sum_euclidean(a: Vector2, b: Vector2, c: Vector2) -> float:
    var ab: Vector2 = b - a
    var ac: Vector2 = c - a
    var ba: Vector2 = a - b
    var bc: Vector2 = c - b
    var ca: Vector2 = a - c
    var cb: Vector2 = b - c
    var angle_a: float = ab.angle_to(ac)
    var angle_b: float = ba.angle_to(bc)
    var angle_c: float = ca.angle_to(cb)
    return abs(angle_a) + abs(angle_b) + abs(angle_c)  # always PI
```
""",
'NonEuclidean_Spaces': """

## Sum of Angles in Curved Spaces

```gdscript
# In hyperbolic geometry, triangle angle sums are less than PI.
# In spherical geometry, they exceed PI.
# The deficit/excess is proportional to the triangle's area times its curvature.
static func hyperbolic_triangle_angle_sum(vertices: Array) -> float:
    var excess: float = spherical_excess(vertices, -1.0)  # negative curvature
    return PI + excess  # less than PI when excess is negative

static func spherical_triangle_angle_sum(vertices: Array) -> float:
    return PI + spherical_excess(vertices, 1.0)  # greater than PI

static func spherical_excess(vertices: Array, curvature: float) -> float:
    var area: float = compute_triangle_area(vertices)
    return curvature * area
```
""",
'Russell_Paradox': """

## ZFC Axioms (Skeleton)

```gdscript
# ZFC resolves Russell's paradox by restricting set formation.
# The Axiom of Separation: only subsets of existing sets can be formed,
# not arbitrary collections described by predicates.
class_name ZFCAxioms

static func separation(parent_set: Array, predicate: Callable) -> Array:
    # Instead of { x : predicate(x) }, we can only form { x in parent_set : predicate(x) }.
    var subset: Array = []
    for x in parent_set:
        if predicate.call(x):
            subset.append(x)
    return subset

static func extensionality(a: Array, b: Array) -> bool:
    # Two sets are equal iff they have the same members.
    return a.sort() == b.sort()
```
""",
'Godel_Incompleteness': """

## Provability vs Truth

```gdscript
# Gödel's theorem relates provability in a formal system to truth.
# For any consistent system F strong enough for arithmetic:
# - There exist true statements F cannot prove.
# - F cannot prove its own consistency.
class_name FormalSystem

var axioms: Array = []
var proved: Array = []

func prove(statement: String) -> bool:
    return statement in proved

func can_prove_self_consistent() -> bool:
    # Gödel's second theorem: no.
    return false

func list_unprovable_truths() -> Array:
    # Gödel's first theorem: this list is non-empty for any sufficiently strong F.
    return ["G_F"]  # the Gödel sentence for F
```
""",
'Escher_Impossible': """

## Projection vs Depth

```gdscript
# Impossible figures exploit the gap between 2D projection and 3D depth.
# Two line segments can share a pixel in the projection while being far apart in 3D.
class_name ImpossibleProjection

static func project_to_2d(point_3d: Vector3, view_matrix: Transform3D) -> Vector2:
    var local: Vector3 = view_matrix * point_3d
    return Vector2(local.x / local.z, local.y / local.z)

static func distance_in_projection(a_3d: Vector3, b_3d: Vector3, view: Transform3D) -> float:
    return project_to_2d(a_3d, view).distance_to(project_to_2d(b_3d, view))

static func distance_in_3d(a_3d: Vector3, b_3d: Vector3) -> float:
    return a_3d.distance_to(b_3d)
```
""",
'Brouwer_Intuitionism': """

## Constructive Proof Scaffold

```gdscript
# A constructive proof provides a witness.
# For existential claims: give an example.
# For universal claims: give an algorithm that constructs the witness for any input.
class_name ConstructiveProof

func exists_even_number_greater_than(n: int) -> int:
    # Constructive proof: return an even number > n
    return n + 2 if (n + 2) % 2 == 0 else n + 3

func all_naturals_have_successor(n: int) -> int:
    # The successor construction
    return n + 1

func classical_fallback_rejected(p: bool) -> String:
    # Classical logic: (NOT NOT P) -> P
    # Intuitionistic: cannot conclude P from NOT NOT P without a construction
    return "construction_required"
```
""",
'Florensky_Paraconsistent': """

## Belnap Four-Valued Logic

```gdscript
# Florensky's antinomic reasoning finds a home in four-valued logic.
enum BelnapValue { NEITHER = 0, TRUE = 1, FALSE = 2, BOTH = 3 }

static func conjunction(a: int, b: int) -> int:
    const TABLE := [
        [0, 0, 2, 2],
        [0, 1, 2, 3],
        [2, 2, 2, 2],
        [2, 3, 2, 3],
    ]
    return TABLE[a][b]

static func information_order(a: int, b: int) -> int:
    # NEITHER < TRUE, FALSE < BOTH in the information ordering
    # Return -1 if a < b, 0 if equal, 1 if a > b
    var order := {0: 0, 1: 1, 2: 1, 3: 2}
    return sign(order[a] - order[b])
```
""",
'Crisis_Synthesis': """

## Post-Crisis Toolkit

```gdscript
# The curriculum's post-crisis toolkit: a set of design principles for
# computational practice that admits its own limits.
class_name PostCrisisPractice

const PRINCIPLES := [
    "Acknowledge the classifier's outside",
    "Carry contradictions rather than eliminate them",
    "Name your standpoint",
    "Build commons from incomplete agents",
    "Grow rhizomatically rather than hierarchically",
    "Use formal systems with awareness of their limits",
]

static func applies_to_project(description: String) -> Dictionary:
    var checks: Dictionary = {}
    for principle in PRINCIPLES:
        checks[principle] = "REQUIRED"
    return checks
```
""",
}

for m, a in more_code.items():
    p = Path('commons/maps/' + m + '/technical.md')
    p.write_text(p.read_text(encoding='utf-8').rstrip() + a, encoding='utf-8')

# Top up short chambers (need <10 more words each)
tiny_adds = {
'Point_Lines': "\n\n## Persistence\n\nPoint positions are not saved; each visit regenerates the grid from scratch. Grabbing and moving a point is a live interaction rather than an authoring workflow.",
'Chamber_Color': "\n\n## Chromatic Axis Layout\n\nThe science screen's chromatic axis is logarithmic rather than linear, approximating human perceptual hue discrimination more faithfully.",
'Random_Game': "\n\n## Game Over\n\nOn death, the arena locks briefly and shows a score summary before offering retry. The summary emphasises distribution exposure over score.",
'Chamber_Noise': "\n\n## Noise Seed Display\n\nThe current noise seed is visible on the parameter bench so learners can reproduce configurations they like.",
'Chamber_Foundations': "\n\n## No Catalyst Entry\n\nUnlike other chambers, no new catalyst is added to the learner's kit on exit. The lesson is a constraint, not a new tool.",
'Trans_Introduction': "\n\n## Translation Order\n\n```gdscript\n# In Godot, Transform3D right-multiplies: a.b() applies b then a when read right-to-left.\nvar rotate_then_translate := Transform3D.IDENTITY.translated(Vector3(5, 0, 0)).rotated(Vector3.UP, PI / 2)\n```",
}

for m, a in tiny_adds.items():
    p = Path('commons/maps/' + m + '/technical.md')
    p.write_text(p.read_text(encoding='utf-8').rstrip() + a, encoding='utf-8')

# Paragraph splits for CA_AgentsCircuits and QFEP_F_Term — these failed last time, try aggressive split
def aggressive_split(path):
    import re
    SENT = re.compile(r"[.!?][\s\n]+")
    text = Path(path).read_text(encoding='utf-8')
    lines = text.split('\n')
    out = []
    in_code = False
    for ln in lines:
        if ln.startswith('```'):
            in_code = not in_code
            out.append(ln); continue
        if in_code:
            out.append(ln); continue
        if ln.startswith('#') or ln.startswith('-') or ln.startswith('*') or ln.startswith('>') or ln.startswith('|'):
            out.append(ln); continue
        # Check sentence count in this single-line paragraph (after the first 80 chars)
        sents = [s for s in SENT.split(ln) if s.strip()]
        if len(sents) > 8:
            mid = len(sents) // 2
            idx = 0
            for s in sents[:mid]:
                found = ln.find(s, idx)
                idx = found + len(s)
            m2 = SENT.match(ln[idx:])
            split_at = idx + m2.end() if m2 else idx
            out.append(ln[:split_at].rstrip())
            out.append('')
            out.append(ln[split_at:].lstrip())
        else:
            out.append(ln)
    Path(path).write_text('\n'.join(out), encoding='utf-8')

for p in ['commons/maps/CA_AgentsCircuits/technical.md', 'commons/maps/QFEP_F_Term/technical.md']:
    aggressive_split(p)

print('done')
