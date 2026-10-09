# Lab Equipment Simulation

A clean bench, a molecular designer, a void pit under the floor. Build formalization that knows its own edges.

Declare an atom.

```gdscript
class_name Atom
extends RigidBody3D

@export var element: String = "C"
@export var valence: int = 4
var bonds: Array = []
```

Each atom carries its element, its valence, and its current bond list. The valence is the rule; the bond list is what the rule has allowed.

Snap atoms to valence.

```gdscript
func can_bond(a: Atom, b: Atom) -> bool:
    if a.bonds.size() >= a.valence: return false
    if b.bonds.size() >= b.valence: return false
    return true
```

An atom with full valence refuses new bonds. The rule is enforced at the point of attempt, not afterwards.

Form the bond.

```gdscript
func bond_atoms(a: Atom, b: Atom) -> void:
    if not can_bond(a, b): return
    a.bonds.append(b)
    b.bonds.append(a)
    spawn_bond_mesh(a, b)
```

The bond is symmetric and visible. A cylinder appears between the two atoms when the rule succeeds. When it fails, nothing happens and the learner sees why.

Constrain bond geometry.

```gdscript
func enforce_bond_angles(a: Atom) -> void:
    match a.valence:
        2: set_linear(a)
        3: set_trigonal(a)
        4: set_tetrahedral(a)
```

Carbon spreads to tetrahedral, nitrogen to trigonal, oxygen to linear. The formal rule has a geometric consequence. The bench expresses chemistry as posture.

Render the void pit.

```gdscript
func reveal_pit_under(cell: Vector2i) -> void:
    var pit := preload("res://commons/maps/elements/void_pit.tscn").instantiate()
    pit.position = Vector3(cell.x, -4.0, cell.y)
    add_child(pit)
```

One floor cell drops away to show the underside. The laboratory is clean above and unresolved below. Formal systems rest on something they cannot themselves justify.

Label the pit.

```gdscript
func label_pit(label: Label3D) -> void:
    label.text = "axioms (unproven)"
    label.modulate = Color(0.8, 0.8, 0.3)
```

The plaque names what the pit is. Not an error. A foundation.

Let the learner build a molecule.

```gdscript
func _on_designer_submit() -> void:
    var mol := designer.get_current_molecule()
    if validate_valence(mol):
        anchor_on_bench(mol)
    else:
        flash_error(designer)
```

The designer either accepts a valid molecule or flashes red. The error is visible, local, and revisable. Formalization works — inside its scope.

Carry the finished molecule to the archive shelf.

```gdscript
func archive_molecule(mol: Node3D) -> void:
    var slot := shelf.get_next_free_slot()
    if slot == null: return
    mol.reparent(slot)
    mol.position = Vector3.ZERO
```

The shelf preserves the build. The lab does not consume its outputs. Earlier maps' caution is built into the furniture.

You have built a lab where formal rules hold on the bench and unproven axioms sit one cell below the floor. The final map, PostCrisis Synthesis, gathers the arc into a closing sentence.
