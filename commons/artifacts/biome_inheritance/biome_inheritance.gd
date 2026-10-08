extends Node3D
## A bridge experiment: actual later BiomeObject cover reads the early panel
## specimen. Candidates and community DNA are retained when panel width changes.
## No in-world interface. Appearance/clearance only; not ecological growth.
const Model := preload("res://commons/artifacts/biome_primitives/encounter_model.gd")
const Clearance := preload("res://commons/biome_layers/inherited_form_clearance.gd")
const Banners := preload("res://commons/artifacts/biome_inheritance/rising_banners.gd")
const Grammar := preload("res://commons/biome_layers/biome_grammar.gd")
@export_enum("Primitives_Melencolia", "full") var habitat_stage: String = "full"
@export_range(.6,1.25) var panel_width_factor: float = .6
@export var automatic: bool = true
## The scene enables this second study; the original width experiment remains
## available on the same script with banners disabled.
@export var banners: bool = false
## A hall supplies cumulative capabilities. Empty is the older recording study.
## Map-authored states hold indefinitely; waiting does not advance evolution.
@export var evolution_stage: String = ""
@export var seed: int = 7
@export_range(0.0,1.0) var clearance_m: float = .35
var habitat: Node3D
## A live early encounter can be handed in BEFORE adding this bridge to the tree.
## Reparenting preserves its record and existing panel bodies. F6 uses a fixture.
var sculpture: Node3D
var inherited_record: Dictionary = {}
var cover_sources: Array[Dictionary] = []
var excluded: Array[Dictionary] = []
var accepted: Array[String] = []
var foundations: Array[float] = []
var _pins: Array[Node3D] = []
var _guides: Array[Node3D] = []
var _time: float = 0.0
var _last_factor: float = -1.0
var banner_study: RefCounted
var occupancy_forms: Array = []
var stage_history: Array[String] = []
var _supports: Array[Node3D] = []

func apply_grid_config(config: Dictionary) -> void:
	var hall := str(config.get("stage",config.get("map",evolution_stage)))
	if hall.is_empty() or not bool(Grammar.position_of(hall).known): return
	if is_node_ready():
		set_hall(hall)
	else:
		evolution_stage = hall
		banners = true

func set_hall(hall: String) -> bool:
	# Unknown stages must never silently reveal the mature biome.
	if not bool(Grammar.position_of(hall).known): return false
	if not is_node_ready():
		evolution_stage = hall
		banners = true
		return true
	if hall == evolution_stage and not stage_history.is_empty(): return true
	evolution_stage = hall
	habitat_stage = hall
	# Preserve the live encounter and its bodies. Only the habitat renderer
	# rebuilds, using the same DNA and the existing cumulative biome grammar.
	habitat.apply_grid_config({"stage":hall})
	_cache_cover()
	_prepare_stage_pose()
	_build_foundations()
	apply_width(panel_width_factor)
	if banner_study == null:
		banners = true
		banner_study = Banners.new()
		banner_study.setup(self)
	_apply_hall_state()
	return true

func _prepare_stage_pose() -> void:
	var capabilities := Grammar.closure(evolution_stage)
	sculpture.model.hinge_angle = PI*.25 if Grammar.allows(capabilities,"rotate") else 0.0
	panel_width_factor = .6 if Grammar.allows(capabilities,"scale") else 1.0
	sculpture.model.width_factor = panel_width_factor

func _apply_hall_state() -> void:
	banner_study.apply_stage(evolution_stage)
	var face := Grammar.allows(Grammar.closure(evolution_stage),"face")
	for support in _supports: support.visible = face
	stage_history.append(evolution_stage)
	set_process(false)

func _ready() -> void:
	if not evolution_stage.is_empty():
		if not bool(Grammar.position_of(evolution_stage).known): evolution_stage = "Point_One"
		habitat_stage = evolution_stage
		banners = true
	if sculpture != null:
		assert(sculpture.model.stage_index == 7, "This first bridge accepts the scale encounter.")
		seed = sculpture.model.seed
	habitat = load("res://commons/artifacts/biome_object/biome_object.tscn").instantiate()
	habitat.seed = seed
	habitat.stage = habitat_stage
	habitat.record = "off"
	habitat.moisture = .5
	habitat.relief = .5
	habitat.wildness = .6
	add_child(habitat)
	_cache_cover()
	if sculpture == null:
		sculpture = load("res://commons/artifacts/biome_primitives/biome_primitives.tscn").instantiate()
		sculpture.stage = "Trans_Scale"
		sculpture.seed = seed
		sculpture.demo = true
		sculpture.hinge_preview_degrees = 45
		sculpture.scale_preview_factor = panel_width_factor
		add_child(sculpture)
	else:
		sculpture.reparent(self)
		sculpture.transform = Transform3D.IDENTITY # both records use ground-local metres
		panel_width_factor = sculpture.model.width_factor
	sculpture.set_process(false)
	sculpture.set_physics_process(false)
	# The habitat now supplies the ground. Retain the same panel renderer and
	# collision bodies. Disable their own observer/motor; this experiment varies
	# width at a fixed 45-degree pose to isolate its effect on habitat occupancy.
	for child in sculpture.get_node("Ground").get_children():
		if child.name != "Forms": child.free()
	for child in sculpture.get_node("Ground/Forms").get_children():
		# Godot may replace repeated sibling names with generated @ names.
		if child is MeshInstance3D and child.mesh is CylinderMesh: _pins.append(child)
		if child is MeshInstance3D and child.mesh is ImmediateMesh: _guides.append(child)
	if not evolution_stage.is_empty(): _prepare_stage_pose()
	_build_foundations()
	apply_width(panel_width_factor)
	if banners:
		banner_study = Banners.new()
		banner_study.setup(self)
		if evolution_stage.is_empty(): apply_banner_time(0.0)
		else: _apply_hall_state()
	set_process(automatic and evolution_stage.is_empty())

func _cache_cover() -> void:
	cover_sources.clear()
	# Read the existing CPU plan. The dummy renderer cannot round-trip instance
	# transforms, and re-running the generator could change the candidate stream.
	var by_type := {}
	for tuft in habitat._cover_tufts:
		var kind := str(tuft.type)
		if not by_type.has(kind): by_type[kind] = []
		for member in tuft.members: by_type[kind].append(member)
	for kind in by_type:
		var node: MultiMeshInstance3D = habitat._patch.get_node("Cover_"+kind)
		var items: Array = []
		for i in range(by_type[kind].size()):
			var member: Array = by_type[kind][i]
			var envelope := Clearance.footprint(member[0], node.multimesh.mesh)
			items.append({"id":"%s_%04d" % [kind,i],"transform":member[0],"color":member[1],
				"point":envelope.point,"radius":envelope.radius,"height":envelope.height})
		cover_sources.append({"kind":kind,"node":node,"mesh":node.multimesh.mesh,"items":items})

func _build_foundations() -> void:
	for support in _supports: support.free()
	_supports.clear()
	foundations.clear()
	# x/z identities survive; height adapts explicitly to the later terrain. Use
	# the widest footprint once, so widening never lifts or relocates the hinges.
	var original: float = sculpture.model.width_factor
	sculpture.model.width_factor = 1.25
	for form in sculpture.model.forms():
		var pivot := Model._vec(form.pivot)
		var direction := Basis(Vector3.UP,float(form.yaw)) * Vector3.RIGHT
		var top: float = habitat._h_at(pivot.x,pivot.z)
		for sample in range(9):
			var p := pivot + direction * float(form.size[0]) * sample/8.0
			top = maxf(top,habitat._h_at(p.x,p.z))
		top += .10
		foundations.append(top)
		var foot: float = habitat._h_at(pivot.x,pivot.z)
		sculpture._box(self,Vector3(pivot.x,(foot+top)*.5,pivot.z),Vector3(.12,top-foot,.12),Color("45433b"))
		_supports.append(get_child(get_child_count()-1))
	sculpture.model.width_factor = original

func apply_width(factor: float) -> void:
	panel_width_factor = clampf(factor,.6,1.25)
	sculpture.model.width_factor = panel_width_factor
	sculpture._update_form_poses()
	for i in range(foundations.size()):
		sculpture._form_bodies[i].position.y += foundations[i]
		_pins[i].position.y = foundations[i] + float(sculpture.model.form_dna.height)*.5 + .07
		# A flat sweep would run through the later terrain. Omit that mark here.
		_guides[i].visible = false
	inherited_record = sculpture.get_state()
	apply_clearance(inherited_record.forms)
	_last_factor = panel_width_factor

func apply_clearance(forms: Array) -> void:
	occupancy_forms = forms.duplicate(true)
	excluded.clear()
	accepted.clear()
	for source in cover_sources:
		var keep: Array = []
		for member in source.items:
			var owner := Clearance.blocked_by(member.point,member.radius,forms,clearance_m,member.height)
			if owner.is_empty():
				keep.append(member)
				accepted.append(member.id)
			else:
				excluded.append({"id":member.id,"by":owner,"position":[member.point.x,member.point.y],"radius":member.radius})
		var mm: MultiMesh = source.node.multimesh
		# Stable meshes/materials, fixed candidates; only membership changes.
		mm.instance_count = keep.size()
		for i in range(keep.size()):
			mm.set_instance_transform(i,keep[i].transform)
			mm.set_instance_color(i,keep[i].color)

func _process(delta: float) -> void:
	if not evolution_stage.is_empty(): return
	if banner_study != null:
		_time = fmod(_time + minf(delta,.1),20.0)
		apply_banner_time(_time)
		return
	_time = fmod(_time + minf(delta,.1),12.0)
	var factor: float = width_at(_time)
	if absf(factor-_last_factor) >= .002: apply_width(factor)

func apply_banner_time(seconds: float) -> void:
	if banner_study != null: banner_study.apply_time(seconds)

static func width_at(seconds: float) -> float:
	var t := fposmod(seconds,12.0)
	if t < 2: return .6
	if t < 6: return lerpf(.6,1.25,smoothstep(0,1,(t-2)/4))
	if t < 8: return 1.25
	return lerpf(1.25,.6,smoothstep(0,1,(t-8)/4))

func get_state() -> Dictionary:
	var record := {"schema":"ada.biome-inheritance.v1","source":"biome_primitives","habitat_generation":habitat.GENERATION,
		"habitat_stage":habitat_stage,"inherited_encounter":inherited_record,"clearance_m":clearance_m,
		"foundations_y":foundations,"candidate_cover":accepted.size()+excluded.size(),"standing_cover":accepted.size(),
		"excluded_cover":excluded.duplicate(true),"accepted_ids":accepted.duplicate(),
		"habitat":habitat.get_state(),"scope":"cover occupancy only; candidates retained; no growth or ecological feedback"}
	if banner_study != null: record["banners"] = banner_study.get_state()
	if not evolution_stage.is_empty():
		record["evolution"] = {"stage":evolution_stage,"history":stage_history.duplicate(),
			"capabilities":Grammar.closure(evolution_stage),"driver":"hall entry; no elapsed-time evolution",
			"persistence":"live encounter retained by set_hall; same DNA rebuilds stage habitat; no cross-session save yet"}
	return record
