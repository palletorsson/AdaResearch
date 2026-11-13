extends "res://commons/modular/recipe_area.gd"
## Live five-way recursion. Saved part poses are offsets from the authored pose;
## they survive animation, scale changes and temporary depth reduction.
const SphereRule = preload("res://commons/modular/sphere_fractal.gd")
var running := true
var preview_frozen := false
var runtime_speed := 22.5
var runtime_size := 1.2
var runtime_depth := 4
var phase_clock := 0.0 # equivalent seconds at 22.5 degrees/s; speed changes never jump
var _members: Dictionary = {}
var _offsets: Dictionary = {}
var _depth_pending := false

func rebuild() -> void:
	# Complete defaults also make the registered catalogue entry usable directly.
	var defaults: Dictionary=Composite.terms()["lab_sphere_fractal"].parameters.duplicate(true)
	defaults.merge(bindings,true);bindings=defaults;recipe="lab_sphere_fractal"
	runtime_speed=float(bindings.speed);runtime_size=float(bindings.size);runtime_depth=int(bindings.depth)
	phase_clock=float(bindings.phase)*runtime_speed/22.5
	preview_frozen=false;running=true
	super.rebuild()
	_cache_members()
	set_physics_process(only_parts.is_empty())

func _cache_members() -> void:
	_members.clear();_offsets.clear()
	for child in get_children():
		var id := str(child.name)
		if not part_defaults.has(id):continue
		_members[id]=child
		var base: Dictionary=part_defaults[id]
		var reference := Basis.from_euler(Vector3(base.rotation[0],base.rotation[1],base.rotation[2])*PI/180)
		_offsets[id]={"position":child.position-Vector3(base.position[0],base.position[1],base.position[2]),"basis":child.basis*reference.inverse()}
		# Moving solids follow the physics clock, with unscaled collision shapes.
		var source: Node3D=child.get_node("Source")
		var old: StaticBody3D=source.get_node_or_null("StructuralCollision")
		if old!=null and not old is AnimatableBody3D:
			var body:=AnimatableBody3D.new();body.name="StructuralCollision";body.sync_to_physics=false
			body.collision_layer=old.collision_layer;body.collision_mask=old.collision_mask
			source.remove_child(old);source.add_child(body)
			for shape in old.get_children():shape.reparent(body,false)
			old.free()

func _apply_parts() -> void:
	# Config updates arrive against the saved editor pose, not the current frame.
	for child in get_children():
		var id := str(child.name)
		if not part_defaults.has(id):continue
		var base: Dictionary=part_defaults[id]
		child.position=Vector3(base.position[0],base.position[1],base.position[2])
		child.rotation_degrees=Vector3(base.rotation[0],base.rotation[1],base.rotation[2])
	super._apply_parts()
	if is_inside_tree() and not _members.is_empty():_cache_members()

func _physics_process(delta: float) -> void:
	if preview_frozen or not only_parts.is_empty():return
	if running:phase_clock+=delta*runtime_speed/22.5
	_apply_motion()

func _apply_motion() -> void:
	var settings: Dictionary=bindings.duplicate()
	settings.speed=22.5;settings.phase=phase_clock;settings.size=runtime_size;settings.depth=runtime_depth
	var pose: Dictionary=SphereRule.expression(settings)
	var factor: float=runtime_size/float(bindings.size)
	for member in pose.parts:
		if not _members.has(member.id):continue
		var node: Node3D=_members[member.id]
		var offset: Dictionary=_offsets[member.id]
		node.position=Vector3(member.at[0],member.at[1],member.at[2])+offset.position
		node.basis=offset.basis*Basis.from_euler(Vector3(member.rot[0],member.rot[1],member.rot[2])*PI/180)
		var source: Node3D=node.get_node("Source")
		source.original.scale=Vector3.ONE*factor
		var shape: CollisionShape3D=source.get_node("StructuralCollision").get_child(0)
		shape.shape.size=source.fit_box*factor

func set_parameter(key: String,value: float) -> void:
	if preview_frozen or not is_finite(value):return
	match key:
		"speed":runtime_speed=clampf(value,0,45)
		"size":runtime_size=clampf(value,.4,1.8)
		"depth":
			var depth_value:=clampi(roundi(value),1,4)
			if depth_value==runtime_depth:return
			runtime_depth=depth_value
			if not _depth_pending:
				_depth_pending=true;_rebuild_depth.call_deferred()
	if not _depth_pending:_apply_motion()

func _rebuild_depth() -> void:
	_depth_pending=false
	if preview_frozen:return
	var authored: Dictionary=bindings.duplicate(true)
	bindings.depth=runtime_depth
	# Keep authored time, dimensions and edits as the reference for every level.
	super.rebuild();bindings=authored
	_cache_members();_apply_motion()

func prepare_editor_preview() -> void:
	# Stable exported models use the saved pose, never a random animation frame.
	preview_frozen=true;set_physics_process(false)
	super.rebuild();_cache_members()
	await super.prepare_editor_preview()

func is_live_study() -> bool:
	return true
