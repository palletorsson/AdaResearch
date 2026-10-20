extends Node3D
## Controller-aimed rays and bounded visual feedback. No museum-wide damage.
const Target := preload("target.gd")
const LineSkin := preload("forms/line_skin.gd")
const BoxBody := preload("forms/box_body.gd")
const RANGE := 65.0
const INTERVAL := 0.22
const MAX_EFFECTS := 16
const MINT := Color("8cffe1")
signal target_broken
var may_fire: Callable
var cooldowns := {}
var effects: Array[Dictionary] = []
var sights: Array[Dictionary] = []
var shots := 0
var broken := 0

func register_hand(hand: XRController3D) -> void:
	var gun := BoxBody.new(Vector3(0.065,0.065,0.2))
	gun.name = "RunnerBlaster"
	gun.position = Vector3(0,0,-0.1)
	gun.material_override = material(Color("343648"))
	hand.add_child(gun)
	var muzzle := BoxBody.new(Vector3(0.07,0.025,0.012))
	muzzle.position = Vector3(0,0,-0.205)
	muzzle.material_override = material(MINT)
	hand.add_child(muzzle)
	var guide := LineSkin.new()
	guide.mesh.top_radius = 0.006
	guide.mesh.bottom_radius = 0.006
	guide.material_override = material(MINT)
	add_child(guide)
	var dot := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.055
	sphere.height = 0.11
	dot.mesh = sphere
	dot.material_override = material(MINT)
	add_child(dot)
	sights.append({"hand":hand,"guide":guide,"dot":dot})

func update_sights(visible_now: bool) -> void:
	for sight in sights:
		sight.guide.visible = visible_now
		sight.dot.visible = visible_now
		if not visible_now: continue
		var origin: Vector3 = sight.hand.to_global(Vector3(0,0,-0.22))
		var direction: Vector3 = -sight.hand.global_basis.z.normalized()
		var hit := aim(origin,direction)
		var end: Vector3 = hit.get("position",origin+direction*RANGE)
		sight.guide.show_segment(to_local(origin),end-origin,origin.distance_to(end))
		sight.dot.position = to_local(end)
		var target: Object = hit.get("collider")
		var colour := MINT if is_instance_of(target,Target) else Color("c8b8d0")
		sight.guide.material_override.albedo_color = colour
		sight.dot.material_override.albedo_color = colour

func aim(origin: Vector3, direction: Vector3) -> Dictionary:
	if direction.length_squared() < 0.001: return {}
	# Floor and ordinary hazards stop the ray too. Gold pickups are collectible,
	# and the running sphere (layer 8) cannot shoot itself.
	var query := PhysicsRayQueryParameters3D.create(origin,origin+direction.normalized()*RANGE,1|2|16)
	query.hit_from_inside = true
	return get_world_3d().direct_space_state.intersect_ray(query)

func fire_from(origin: Vector3, direction: Vector3, channel := 0) -> bool:
	if not may_fire.is_valid() or not may_fire.call(): return false
	if cooldowns.get(channel,0.0)>0 or direction.length_squared()<0.001: return false
	cooldowns[channel] = INTERVAL
	shots += 1
	var hit := aim(origin,direction)
	var end: Vector3 = hit.get("position",origin+direction.normalized()*RANGE)
	var ray := LineSkin.new()
	ray.show_segment(to_local(origin),end-origin,origin.distance_to(end))
	ray.mesh.top_radius = 0.026
	ray.mesh.bottom_radius = 0.026
	ray.material_override = material(MINT)
	add_child(ray)
	_keep({"node":ray,"age":0.0,"duration":0.11})
	var target: Object = hit.get("collider")
	if is_instance_of(target,Target) and target.hit_by_runner_shot():
		broken += 1
		burst(end,target.fragment_colour)
		target_broken.emit()
	return true

func burst(at: Vector3, colour: Color) -> void:
	# Eight small rendered cubes, not physics debris or a mesh-fracture claim.
	var view := MultiMeshInstance3D.new()
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	var unit := BoxBody.new(Vector3.ONE*0.13)
	batch.mesh = unit.mesh
	unit.free()
	batch.instance_count = 8
	view.multimesh = batch
	view.material_override = material(colour)
	view.position = to_local(at)
	add_child(view)
	var velocities: Array[Vector3] = []
	for i in range(8):
		velocities.append(Vector3(-1.0 if i&1 else 1.0,1.5 if i&2 else 0.6,-1.0 if i&4 else 1.0)*1.8)
		batch.set_instance_transform(i,Transform3D.IDENTITY)
	_keep({"node":view,"age":0.0,"duration":0.55,"velocities":velocities})

func tick(delta: float, scroll: float) -> void:
	for channel in cooldowns: cooldowns[channel] = maxf(0.0,cooldowns[channel]-delta)
	for i in range(effects.size()-1,-1,-1):
		var effect: Dictionary = effects[i]
		effect.age += delta
		if effect.age>=effect.duration:
			effect.node.free()
			effects.remove_at(i)
			continue
		if effect.has("velocities"):
			effect.node.position.z += scroll
			var age: float = effect.age
			for part in range(8):
				var pose := Transform3D(Basis(Vector3(1,1,0).normalized(),age*(part+1)),effect.velocities[part]*age+Vector3.DOWN*3*age*age)
				pose.basis = pose.basis.scaled(Vector3.ONE*(1.0-age/effect.duration))
				effect.node.multimesh.set_instance_transform(part,pose)

func _keep(effect: Dictionary) -> void:
	effects.append(effect)
	while effects.size()>MAX_EFFECTS: effects.pop_front().node.free()

func reset() -> void:
	for effect in effects: effect.node.free()
	effects.clear()
	cooldowns.clear()
	shots = 0
	broken = 0

static func material(colour: Color) -> StandardMaterial3D:
	var finish := StandardMaterial3D.new()
	finish.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	finish.albedo_color = colour
	return finish
