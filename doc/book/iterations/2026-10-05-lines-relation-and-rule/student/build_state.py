"""Compose the proposed Lines state from the exact saved Coordinates file."""
from pathlib import Path
import hashlib
import json

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
PREDECESSOR = ROOT.parent / "ada_encyclopedia/ghost-student/states/002-point-coordinates/point.gd"

def digest(data):
    return hashlib.sha256(data).hexdigest()

def main():
    raw = PREDECESSOR.read_bytes()
    expected_incoming = "ceb274ec9bc3b15b8eba6f03a61895fbd32d477333f4730e8b508afbcd747c7d"
    if digest(raw) != expected_incoming:
        raise SystemExit("Coordinates predecessor has changed; review the transition before composing it.")
    (HERE / "incoming.gd").write_bytes(raw)
    source = raw.decode("utf-8").replace("\r\n", "\n")
    changes = [
        {"id": "line-state", "kind": "insert_after", "anchor": "const CENTRE := Vector3(0, 1.12, 0)\n", "text": '''
# Supplied drawing helper; the station remains in the configured museum.
const LineSkin = preload("line_skin.gd")
var point_a: XRToolsPickable
var point_b: XRToolsPickable
var line: MeshInstance3D
var distance := 0.0
'''},
        {"id": "second-end-and-segment", "kind": "insert_after", "anchor": "\tbody.reparent(solid)\n", "text": '''
\tpoint_a = solid
\tpoint_b = solid.duplicate() as XRToolsPickable
\tpoint_b.name = "SecondPoint"
\tpoint_b.position = CENTRE + Vector3(1.0, 0, 0)
\tadd_child(point_b)
\tline = LineSkin.new()
\tline.name = "Segment"
\tadd_child(line)
'''},
        {"id": "live-relation", "kind": "insert_after", "anchor": "\treturn mat\n", "text": '''
func _process(_delta: float) -> void:
\t# Express both held positions in this station's local coordinates.
\tvar a := to_local(point_a.global_position)
\tvar b := to_local(point_b.global_position)
\tvar displacement := b - a
\tdistance = displacement.length()
\tline.show_segment(a, displacement, distance)
'''}
    ]
    for change in changes:
        if source.count(change["anchor"]) != 1:
            raise SystemExit(f"Non-unique anchor: {change['id']}")
        source = source.replace(change["anchor"], change["anchor"] + change["text"])
    (HERE / "assembled.gd").write_text(source, encoding="utf-8", newline="\n")
    contract = {
        "version": 1, "map": "Point_Lines", "predecessor": "point-coordinates",
        "incoming_path": "ghost-student/states/002-point-coordinates/point.gd",
        "incoming_sha256": digest(raw), "outgoing_sha256": digest(source.encode("utf-8")),
        "operations": changes,
        "given_files": [{"path": "line_skin.gd", "sha256": digest((HERE / "line_skin.gd").read_bytes()), "role": "Explicit borrowed cylinder renderer; rotation basis is not a prerequisite of Lines."}],
        "coordinate_contract": "a, b and displacement are in the unit-scale station's local frame. to_local converts either held endpoint from world position even if its parent changes. Rotation and translation of the station are allowed; scale is fixed at Vector3.ONE.",
        "scope": "Proposed continuation of the historical assumed Coordinates learner state. No museum runtime or published tutorial is changed by composing this state."
    }
    (HERE / "contract.json").write_text(json.dumps(contract, indent=2) + "\n", encoding="utf-8")
    brief = {
        "bring": "Same pickable point, surface and collider from Coordinates.",
        "make": "Two held endpoints; one segment follows their relation.",
        "given": "Configured museum hands; unit-scale station; supplied line_skin.gd renderer.",
        "build": "Keep first point; duplicate once; b-a gives displacement; length gives distance; update each frame.",
        "check": "Either hand moves one end; same segment follows; release stays; coincident ends hide the segment.",
        "later": "Two segments: parallel, +, X. Trace stores positions; a mesh later stores vertices without a pickup body per vertex."
    }
    (HERE / "brief.json").write_text(json.dumps(brief, indent=2) + "\n", encoding="utf-8")
    print("Composed Lines from exact Coordinates predecessor.")

if __name__ == "__main__":
    main()
