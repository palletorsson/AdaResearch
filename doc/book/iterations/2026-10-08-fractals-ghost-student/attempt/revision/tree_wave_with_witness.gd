# Observation-led revision: the original generator plus a retained comparison.
# This file changes the reading, not the wave recipe or the hand interaction.
extends "../composition/wave_fork/tree_wave.gd"

@export_range(0, 15) var witness_leaf_index := 3
var witness: Node3D
var reference_record: Dictionary = {}
var composition_record: Dictionary = {}
var witness_tip_distance := 0.0
var witness_direction_difference := 0.0

func _ready() -> void:
    super._ready()
    var source_path: String = get_script().resource_path.get_base_dir().path_join("../reconstructed/Fractal_RecursiveTrees/tree.gd").simplify_path()
    var source := load(source_path) as Script
    assert(source != null and source.can_instantiate())
    var original = source.new()
    original.ratio = ratio
    # Construct a temporary reference hierarchy without running its grip setup.
    # Only local transforms are read; this tree does not enter the scene.
    var reference_tree: Node3D = original.branch(0.7, clampi(generations, 1, 4))
    reference_tree.position = Vector3(0, 0.60, 0)
    var original_leaves := terminal_records(reference_tree)
    var changed_leaves := terminal_records(tree)
    var selected := clampi(witness_leaf_index, 0, original_leaves.size() - 1)
    reference_record = original_leaves[selected]
    composition_record = changed_leaves[selected]
    reference_tree.free()
    original.free()
    create_witness()

func terminal_records(joint: Node3D, ancestor: Transform3D = Transform3D.IDENTITY) -> Array[Dictionary]:
    var pose := ancestor * joint.transform
    var branches: Array[Node3D] = []
    for child in joint.get_children():
        if child is Node3D and child.has_meta("length"):
            branches.append(child)
    var records: Array[Dictionary] = []
    if branches.is_empty():
        records.append({"start": pose.origin, "tip": pose * (Vector3.UP * float(joint.get_meta("length")))})
    else:
        for child in branches:
            records.append_array(terminal_records(child, pose))
    return records

func create_witness() -> void:
    witness = Node3D.new()
    witness.position = Vector3(1.40, 1.25, 0.0)
    add_child(witness)
    var panel := MeshInstance3D.new()
    var panel_mesh := BoxMesh.new()
    panel_mesh.size = Vector3(0.95, 0.85, 0.02)
    panel.mesh = panel_mesh
    panel.position.z = -0.05
    var finish := StandardMaterial3D.new()
    finish.albedo_color = Color("20242d")
    panel.material_override = finish
    witness.add_child(panel)

    var original_start: Vector3 = reference_record.start
    var original_tip: Vector3 = reference_record.tip
    var changed_start: Vector3 = composition_record.start
    var changed_tip: Vector3 = composition_record.tip
    # One translation shared by both records; no independent fitting or scaling.
    var centre := (original_start + original_tip + changed_start + changed_tip) / 4.0
    var reference_colour := Color("76d9d1")
    var changed_colour := Color("e99db8")
    witness_line(original_start - centre, original_tip - centre, reference_colour, 0.006)
    witness_line(changed_start - centre, changed_tip - centre, changed_colour, 0.006)
    witness_line(original_tip - centre, changed_tip - centre, Color("ffe099"), 0.002)
    witness_tip_distance = original_tip.distance_to(changed_tip)
    var original_direction := (original_tip - original_start).normalized()
    var changed_direction := (changed_tip - changed_start).normalized()
    witness_direction_difference = (original_direction - changed_direction).length()
    var degrees := rad_to_deg(acos(clampf(original_direction.dot(changed_direction), -1.0, 1.0)))
    witness_label("INITIAL TWIG / SAME SCALE", Vector3(0, 0.35, 0.01), Color.WHITE)
    witness_label("original", Vector3(-0.23, 0.26, 0.01), reference_colour)
    witness_label("wave", Vector3(0.23, 0.26, 0.01), changed_colour)
    witness_label("tip separation %.3f m\ndirection difference %.2f degrees" % [witness_tip_distance, degrees], Vector3(0, -0.26, 0.01), Color.WHITE)
    witness_label("Retained at construction", Vector3(0, -0.37, 0.01), Color("c0c4cc"))

func witness_line(start: Vector3, end: Vector3, colour: Color, radius: float) -> void:
    var line = LineSkin.new()
    witness.add_child(line)
    (line.mesh as CylinderMesh).top_radius = radius
    (line.mesh as CylinderMesh).bottom_radius = radius
    var finish := StandardMaterial3D.new()
    finish.albedo_color = colour
    line.material_override = finish
    line.show_segment(start, end - start, start.distance_to(end))

func witness_label(words: String, at: Vector3, colour: Color) -> void:
    var tag := Label3D.new()
    tag.text = words
    tag.position = at
    tag.font_size = 24
    tag.pixel_size = 0.001
    tag.modulate = colour
    witness.add_child(tag)
