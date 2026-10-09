# Merge Conflict Visualizer — four authored pictures of a disagreement.
# Keeping two versions visible is not an implementation of paraconsistent inference.
# @identity
# essence: compare separate, overlapping, shortened and diverging branches
# desire: let the visitor inspect what a decision keeps and what it suppresses
# truth: the maker chose the resolution; the visitor can return to what preceded it
# @qfep_term: Edge — investigate the conditions under which a difference survives.

extends Node3D
class_name MergeConflictVisualizer

@export var branch_a_color: Color = Color(0.45, 0.75, 1.0, 1.0)
@export var branch_b_color: Color = Color(1.0, 0.55, 0.3, 1.0)
@export var conflict_color: Color = Color(1.0, 0.85, 0.3, 1.0)
@export var pillar_height: float = 1.8

## Author configurations remain available to passive placements. The interactive
## hall exposes all four, without treating any one arrangement as a logical proof.
@export_enum("junction", "overlap", "resolved", "fork") var merge: String = "junction"

@export var interactive: bool = false
@export var marker_visible: bool = true

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")
var _console: Node3D
var _panel: Node3D
var _status: MeshInstance3D

const MERGES: PackedStringArray = ["junction", "overlap", "resolved", "fork"]

## Where each pillar's FOOT stands. Feet never move except under `resolved`, where a
## branch losing its ground is the whole point.
const BASE_X: float = 0.4

## overlap: 14° about z, pivoting at the foot. At 1.8 m tall that swings each top
## 0.44 m inward, so the two centre lines genuinely cross (at y ≈ 1.60) and the box
## volumes interpenetrate from roughly y 1.2 upward — real shared volume, not a
## near miss dressed up by a glow.
const OVERLAP_LEAN_DEG: float = 14.0
const OVERLAP_SPHERE_R: float = 0.35

## fork: 18° swings each top 0.56 m outward — tops at x ±0.95, a 1.9 m spread read
## against a 0.8 m foot spacing. The conflict sphere sits on the floor at ankle height.
const FORK_LEAN_DEG: float = 18.0
const FORK_SPHERE_Y: float = 0.15

## resolved: branch B is not deleted, it is left as a 0.20 m stump. Merges leave scars.
const RESOLVED_STUMP_H: float = 0.20
const RESOLVED_DIM: Color = Color(0.5, 0.5, 0.5, 1.0)

var _t: float = 0.0
var _conflict_glow: MeshInstance3D

## The nodes THIS script made. Only these may ever be freed. The grid adds children of
## its own after _ready — label plates, packaging, tags — and freeing get_children()
## would take those with it.
var _spawned: Array[Node3D] = []

## False until _ready has built once. apply_grid_config can arrive before _ready on the
## grid path, where there is nothing yet to rebuild.
var _built: bool = false


## Build SYNCHRONOUSLY. curation_station calls add_child(inst) and then, on the next
## line, _make_inert(inst) and _hide_labels(inst) — if the pillars and Label3Ds are not
## in place by the time _ready returns, that framing runs on an empty node and this
## artifact's labels go unframed for the whole life of the placement.
func _ready() -> void:
	_build_all()
	_built = true
	_sync_console()


func apply_grid_config(config_data: Dictionary) -> void:
	var before_merge: String = merge
	var before_interactive: bool = interactive
	if config_data.has("merge"):
		merge = _pick_axis(str(config_data["merge"]), MERGES, merge)
	if config_data.has("interactive"):
		interactive = str(config_data["interactive"]).to_lower() in ["true", "1"]
	if config_data.has("marker_visible"):
		marker_visible = str(config_data["marker_visible"]).to_lower() in ["true", "1"]
	if not _built:
		return
	if merge != before_merge or interactive != before_interactive:
		_rebuild_now()
	if is_instance_valid(_conflict_glow):
		_conflict_glow.visible = marker_visible
	_sync_console()


## Accept an axis value only if it names something we actually build. A typo in a map
## token has to land on the legacy look whole — a half-applied value would strand a
## placement with leaning pillars and a sphere still hanging where the uprights were.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## remove_child before queue_free: the node leaves the tree in this same frame, so the
## replacement never renders on top of a corpse waiting for the free queue.
func _rebuild_now() -> void:
	for c: Node3D in _spawned:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_spawned.clear()
	_conflict_glow = null
	_build_all()


func _build_all() -> void:
	match merge:
		"overlap":
			_build_overlap()
		"resolved":
			_build_resolved()
		"fork":
			_build_fork()
		_:
			_build_junction()
	_build_label()


func _process(delta: float) -> void:
	_t += delta * 1.6
	if is_instance_valid(_conflict_glow):
		var mat := _conflict_glow.material_override as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = 2.5 + 1.0 * sin(_t)


# ═══════════════════════════════════════════════════════════════════
# THE FOUR MERGES
# ═══════════════════════════════════════════════════════════════════

## Legacy: two uprights 0.6 m apart, the conflict floating in the air between them.
func _build_junction() -> void:
	var size: Vector3 = Vector3(0.2, pillar_height, 0.2)
	_build_pillar(branch_a_color, Vector3(-BASE_X, 0, 0), size, "branch A", 0.0, false)
	_build_pillar(branch_b_color, Vector3(BASE_X, 0, 0), size, "branch B", 0.0, false)
	_build_conflict_junction(0.25, Vector3(0, pillar_height * 0.6, 0))


## An authored shared volume: both pillars leaned inward so their upper halves occupy
## one volume at x 0, blue and orange interpenetrating with neither cut away.
func _build_overlap() -> void:
	var size: Vector3 = Vector3(0.2, pillar_height, 0.2)
	var lean: float = deg_to_rad(OVERLAP_LEAN_DEG)
	# Negative lean tips a top toward +x, positive toward -x — so the left post leans
	# right and the right post leans left, and they meet over the centre line.
	_build_pillar(branch_a_color, Vector3(-BASE_X, 0, 0), size, "branch A", -lean, false)
	_build_pillar(branch_b_color, Vector3(BASE_X, 0, 0), size, "branch B", lean, false)
	# Height at which the two centre lines actually cross, kept under the tops so the
	# grown sphere sits INSIDE the shared volume rather than capping it.
	var cross_y: float = BASE_X / tan(lean)
	var sphere_y: float = minf(cross_y, pillar_height - OVERLAP_SPHERE_R)
	_build_conflict_junction(OVERLAP_SPHERE_R, Vector3(0, sphere_y, 0))


## This authored resolution: branch A wins the centre at full height, the other is left as
## a stump with its name greyed out. No conflict sphere — there is nothing being held.
func _build_resolved() -> void:
	_build_pillar(branch_a_color, Vector3(0, 0, 0),
		Vector3(0.2, pillar_height, 0.2), "branch A", 0.0, false)
	_build_pillar(branch_b_color, Vector3(BASE_X, 0, 0),
		Vector3(0.2, RESOLVED_STUMP_H, 0.2), "branch B", 0.0, true)


## The other way contradiction stops being held: both branches lean away, the gap opens
## to 1.9 m at the top, and the conflict drops to the floor between their feet.
func _build_fork() -> void:
	var size: Vector3 = Vector3(0.2, pillar_height, 0.2)
	var lean: float = deg_to_rad(FORK_LEAN_DEG)
	_build_pillar(branch_a_color, Vector3(-BASE_X, 0, 0), size, "branch A", lean, false)
	_build_pillar(branch_b_color, Vector3(BASE_X, 0, 0), size, "branch B", -lean, false)
	_build_conflict_junction(0.25, Vector3(0, FORK_SPHERE_Y, 0))


# ═══════════════════════════════════════════════════════════════════
# BUILDERS
# ═══════════════════════════════════════════════════════════════════

## `base_pos` is the FOOT of the pillar and `lean_rad` rotates it about that foot, so a
## leaned branch keeps its ground and only its top travels. At lean 0 this reduces
## exactly to the original centre-offset build.
func _build_pillar(color: Color, base_pos: Vector3, size: Vector3, label_text: String,
		lean_rad: float, dim_label: bool) -> void:
	var h: float = size.y
	var axis: Vector3 = Vector3(-sin(lean_rad), cos(lean_rad), 0.0)

	var pillar := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	pillar.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.5
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.5
	pillar.material_override = mat
	pillar.position = base_pos + axis * (h * 0.5)
	pillar.rotation.z = lean_rad
	add_child(pillar)
	_spawned.append(pillar)
	pillar.set_meta("merge_branch", label_text)
	if interactive:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		body.add_child(shape)
		pillar.add_child(body)

	if interactive:
		var plate := BakedText.make_panel_mesh(label_text, Color(.07,.08,.1), Color(.9,.92,.95), Vector2(.3,.065), 800, true)
		plate.position = base_pos + axis * h + Vector3(signf(base_pos.x)*.3,.16,0)
		plate.material_override.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(plate)
		_spawned.append(plate)
		return
	var label := Label3D.new()
	label.text = label_text
	label.font_size = 22
	label.outline_size = 5
	var label_color: Color = color
	if dim_label:
		label_color = RESOLVED_DIM
	label.modulate = label_color
	label.position = base_pos + axis * h + Vector3(0, 0.2, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
	_spawned.append(label)


func _build_conflict_junction(radius: float, pos: Vector3) -> void:
	_conflict_glow = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	_conflict_glow.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = conflict_color
	mat.emission_enabled = true
	mat.emission = conflict_color
	mat.emission_energy_multiplier = 2.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.7
	_conflict_glow.material_override = mat
	_conflict_glow.position = pos
	_conflict_glow.visible = marker_visible
	add_child(_conflict_glow)
	_spawned.append(_conflict_glow)


func _build_label() -> void:
	if interactive:
		return
	var label := Label3D.new()
	label.text = "hold contradiction, keep running"
	label.font_size = 26
	label.outline_size = 6
	label.modulate = conflict_color
	label.position = Vector3(0, pillar_height + 0.55, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
	_spawned.append(label)


func _sync_console() -> void:
	if not interactive:
		if is_instance_valid(_console):
			remove_child(_console)
			_console.queue_free()
		_console = null
		_status = null
		_panel = null
		return
	if not is_instance_valid(_console):
		_console = Node3D.new()
		_console.name = "MergeConsole"
		add_child(_console)
		var rack: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
		_panel = rack.create_panel("MERGE", [
			[{"type":"button", "label":"JUNCTION"}, {"type":"button", "label":"OVERLAP"}],
			[{"type":"button", "label":"RESOLVED"}, {"type":"button", "label":"FORK"}],
			[{"type":"button", "label":"MARKER"}]
		])
		_panel.position = Vector3(0,1.02,.95)
		_panel.rotation_degrees.x = -20
		_panel.scale = Vector3.ONE * 1.5
		_console.add_child(_panel)
		for i in range(MERGES.size()):
			_panel.find_child("Btn_%d" % i,true,false).get_node("InteractableAreaButton").button_pressed.connect(_choose_merge.bind(MERGES[i]))
		_panel.find_child("Btn_4",true,false).get_node("InteractableAreaButton").button_pressed.connect(_toggle_marker)
		var stand := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.height = .9
		mesh.top_radius = .06
		mesh.bottom_radius = .15
		stand.mesh = mesh
		stand.position = Vector3(0,.45,.86)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(.2,.22,.25)
		stand.material_override = mat
		_console.add_child(stand)
	if is_instance_valid(_status):
		_console.remove_child(_status)
		_status.queue_free()
	var marker_text: String = "NO MARKER" if merge == "resolved" else ("MARKER ON" if marker_visible else "MARKER OFF")
	_status = BakedText.make_panel_mesh(merge.to_upper()+" · "+marker_text, Color(.07,.08,.1), Color(.9,.92,.95), Vector2(.62,.055), 900, true)
	_status.position = Vector3(0,1.38,.95)
	_console.add_child(_status)


func _choose_merge(_body: Variant, choice: String) -> void:
	apply_grid_config({"merge":choice})


func _toggle_marker(_body: Variant) -> void:
	apply_grid_config({"marker_visible":not marker_visible})
