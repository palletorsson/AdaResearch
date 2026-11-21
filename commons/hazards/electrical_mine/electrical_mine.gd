extends Node3D
## A visible charge with a finite life. Rolling pursuit, anchored floor, ceiling
## suspension and tentacles share physical impact / proximity / battery rules.
## Mesh Grammar supplies the shell; Jolt uses a compact sphere collider.
signal exploded(reason: String)
const Grammar := preload("res://commons/mesh_grammar/mesh_grammar_node.gd")
const ContactBody := preload("contact_body.gd")
const RollingShell := preload("rolling_shell.gd")
const MAX_SPLIT_CHILDREN := 2
@export_enum("rolling", "floor", "hanging", "tentacle") var kind := "rolling"
@export_enum("default", "static", "linear", "patrol", "field", "split", "drift", "relay", "memory") var behavior := "default"
@export var proximity_radius := 1.65
@export var shock_radius := 3.4
@export var battery_damage := 25.0
@export var fuse_seconds := .45
@export var arm_delay := 1.0
@export var impact_speed := 1.0
@export var chase_radius := 9.0
@export var max_speed := 2.5
## Clear length from the top of the charge to its ceiling plate.
@export var suspension_length := 2.14
## Optional target motion, in the mine mount's local coordinates.
@export var travel := Vector3.ZERO
@export var travel_period := 4.0
## Practice targets only react to physical impacts. A zero reset time keeps the charge one-shot.
@export var practice := false
@export var rearm_seconds := 0.0
@export var accent := Color("ff358c")
var age := 0.0
var fuse := -1.0
var spent := false
var body: RigidBody3D
var visual: Node3D
var charge_material: StandardMaterial3D
var flash: MeshInstance3D
var shock_ring: MeshInstance3D
var boom_light: OmniLight3D
var boom_shards: Array[Dictionary] = []
var burst_age := 0.0
const BOOM_DURATION := 0.80
var preview := false
var tendrils: Array[Node3D] = []
var impact_sensor: Area3D
var dna_id := ""
var field_radius := 2.3
var field_acceleration := 4.5
var field_sensor: Area3D
var field_ring: MeshInstance3D
var sweep_ring: MeshInstance3D
var show_sweep := false
var travel_phase := 0.0
var motion_curve := "sine"
var monochrome := false
var demonstration := false
var elbow_travel := false
var display_turn := 0.0
var display_pulse := 0.0
var body_radius := .42
var lifetime := 0.0
var split_children: Array[Node3D] = []
var relay_network := ""
var relay_radius := 2.7
var relay_delay := .65
var relay_wave: Dictionary = {}
var memory_seconds := 5.0
var memory_left := 0.0
var first_projectile_id := 0

func apply_grid_config(cfg: Dictionary) -> void:
	for key in ["proximity_radius", "shock_radius", "battery_damage", "fuse_seconds", "chase_radius", "max_speed", "suspension_length", "travel_period"]:
		if cfg.has(key):set(key, maxf(.05, float(cfg[key])))
	var path: Variant = cfg.get("travel", [])
	var mode := str(cfg.get("behavior", behavior))
	if mode in ["default", "static", "linear", "patrol", "field", "split", "relay", "memory"]:
		behavior = mode
	relay_network = str(cfg.get("relay_network", relay_network))
	relay_radius = clampf(float(cfg.get("relay_radius", relay_radius)), 1.0, 3.5)
	relay_delay = clampf(float(cfg.get("relay_delay", relay_delay)), .25, 2.0)
	memory_seconds = clampf(float(cfg.get("memory_seconds", memory_seconds)), 2.0, 12.0)
	if path is Array and path.size() == 3 and (kind != "rolling" or behavior in ["linear", "patrol"]):
		travel = Vector3(float(path[0]), float(path[1]), float(path[2])).limit_length(2.0)
	show_sweep = bool(cfg.get("show_sweep", show_sweep))
	travel_phase = float(cfg.get("travel_phase", travel_phase))
	motion_curve = str(cfg.get("motion_curve", motion_curve)).strip_edges().to_lower()
	monochrome = bool(cfg.get("monochrome", monochrome))
	demonstration = bool(cfg.get("demonstration", demonstration))
	elbow_travel = bool(cfg.get("elbow_travel", false))
	if demonstration:
		display_turn = clampf(float(cfg.get("display_turn", 0)), -180, 180)
		display_pulse = clampf(float(cfg.get("display_pulse", 0)), 0, .5)
	dna_id = str(cfg.get("dna", dna_id))
	field_radius = clampf(float(cfg.get("field_radius", field_radius)), .8, 3.0)
	field_acceleration = clampf(float(cfg.get("field_acceleration", field_acceleration)), .5, 8.0)
	travel_period = maxf(2.0, travel_period)
	practice = bool(cfg.get("practice", practice))
	rearm_seconds = clampf(float(cfg.get("rearm_seconds", rearm_seconds)), 0, 60)
	var spec := RollingShell.recipe(dna_id)
	if not spec.is_empty():accent = Color(spec.glow)
	if cfg.has("accent"):accent = Color.from_string(str(cfg.accent), accent)
	if monochrome:accent = Color("f2f2ef")
	proximity_radius = minf(proximity_radius, shock_radius)
	battery_damage = clampf(battery_damage, 1, 100)

func _ready() -> void:
	add_to_group("electrical_mines")
	body = ContactBody.new();body.name = "ChargeBody";body.mine = self
	body.collision_layer = 1;body.collision_mask = 1 | 2 | 4
	body.mass = 3.0;body.continuous_cd = true;body.contact_monitor = true;body.max_contacts_reported = 8
	body.freeze = not _rolls();body.linear_damp = .15;body.angular_damp = .1
	body.set_meta("electrical_mine", true)
	body.set_meta("inventory_no_place", true)
	if _translates():body.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	var physics := PhysicsMaterial.new();physics.friction = .8;physics.bounce = .15;body.physics_material_override = physics
	add_child(body)
	var collider := CollisionShape3D.new();collider.name = "CollisionShape3D"
	var sphere := SphereShape3D.new();sphere.radius = body_radius;collider.shape = sphere;body.add_child(collider)
	# Frozen anchors do not integrate forces. A contact-sized Area gives them
	# the same moving-object rule as the rolling body's solver contacts.
	impact_sensor = Area3D.new();impact_sensor.collision_layer = 0;impact_sensor.collision_mask = 1 | 4;body.add_child(impact_sensor)
	var sense := CollisionShape3D.new();var near := SphereShape3D.new()
	# An anchored Jolt body can stop a fast projectile before Areas see contact.
	near.radius = body_radius + (.12 if behavior in ["split", "relay", "memory"] else .02)
	sense.shape = near;impact_sensor.add_child(sense)
	visual = Node3D.new();visual.name = "Shell";body.add_child(visual)
	var steel := material(Color("171a22"), .75)
	charge_material = material(accent, .35)
	charge_material.emission_enabled = true;charge_material.emission = accent;charge_material.emission_energy_multiplier = .65
	if kind == "rolling" or not RollingShell.recipe(dna_id).is_empty():
		_build_recipe_shell(steel)
	else:
		_build_anchored_shell(steel)
	if not _rolls() and not _translates() and kind != "hanging":
		var foot := CylinderMesh.new();foot.top_radius = .38;foot.bottom_radius = .6;foot.height = .12
		part(self, "Foot", foot, steel, Vector3(0, -.42, 0))
	if kind == "hanging":
		var cable := CylinderMesh.new();cable.top_radius = .025;cable.bottom_radius = .025;cable.height = suspension_length
		part(self, "Suspension", cable, steel, Vector3(0, .42 + suspension_length * .5, 0))
		var plate := BoxMesh.new();plate.size = Vector3(.65, .08, .65)
		part(self, "CeilingPlate", plate, steel, Vector3(0, .41 + suspension_length, 0))
	if kind == "tentacle":
		for arm in 6:
			var limb := Node3D.new();limb.name = "Tendril%d" % arm;add_child(limb);tendrils.append(limb)
			var angle := TAU * arm / 6.0
			for j in 9:
				var t := float(j) / 8
				var bead := SphereMesh.new();bead.radius = lerpf(.10, .035, t);bead.height = bead.radius * 2;bead.radial_segments = 8;bead.rings = 4
				var r := .32 + t * .9
				part(limb, "Joint%d" % j, bead, charge_material if j == 8 else steel, Vector3(cos(angle) * r, -.18 - .25 * sin(t * PI), sin(angle) * r))
	if _translates():
		if elbow_travel:
			var corner := Vector3(travel.x, 0, 0)
			_build_guide(Vector3.ZERO, corner, steel)
			_build_guide(corner, corner + Vector3(0, 0, travel.z), steel)
		else:
			_build_guide(-travel, travel, steel)
		if show_sweep:
			sweep_ring = _boundary_ring(body, "ProximitySweep", proximity_radius, -.44)
	if behavior == "field":
		_build_field()
	var flash_mat := StandardMaterial3D.new()
	flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flash_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	flash_mat.albedo_color = Color(1.0, 0.98, 0.92, 0.92) if monochrome else Color(accent.lightened(.62), 0.92)
	flash = part(self, "Shock", SphereMesh.new(), flash_mat, Vector3.ZERO)
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;flash.hide()
	if not demonstration and not preview:
		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = 0.76
		ring_mesh.outer_radius = 1.0
		ring_mesh.rings = 24
		ring_mesh.ring_segments = 10
		var ring_mat := StandardMaterial3D.new()
		ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ring_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		ring_mat.albedo_color = Color(1.0, 0.95, 0.86, 0.95) if monochrome else Color(accent.lightened(.42), 0.95)
		shock_ring = part(self, "ShockRing", ring_mesh, ring_mat, Vector3.ZERO)
		shock_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		shock_ring.hide()
		boom_light = OmniLight3D.new()
		boom_light.name = "BoomLight"
		boom_light.light_color = Color(1.0, 0.94, 0.84) if monochrome else accent.lightened(.45)
		boom_light.light_energy = 0.0
		boom_light.omni_range = clampf(shock_radius * 4.5, 9.0, 18.0)
		boom_light.shadow_enabled = false
		boom_light.visible = false
		add_child(boom_light)

func _rolls() -> bool:
	return behavior in ["patrol", "drift"] or (behavior == "default" and kind == "rolling")

func _translates() -> bool:
	return behavior in ["default", "linear"] and not travel.is_zero_approx()

func _build_guide(from: Vector3, to: Vector3, steel: StandardMaterial3D) -> void:
	var span := to - from
	if span.is_zero_approx(): return
	var rail := CylinderMesh.new()
	rail.top_radius = .018
	rail.bottom_radius = .018
	rail.height = span.length()
	var offset := Vector3(0, 0, -.50) if absf(span.normalized().y) > .5 else Vector3(0, -.48, -.28)
	var guide := part(self, "TravelGuide", rail, steel, (from + to) * .5 + offset)
	guide.quaternion = Quaternion(Vector3.UP, span.normalized())

func _travel_offset() -> Vector3:
	var cycle := age / travel_period + travel_phase
	if not elbow_travel:
		if motion_curve == "lerp":
			return travel * lerpf(-1.0, 1.0, pingpong(cycle * 2.0, 1.0))
		return travel * sin(cycle * TAU)
	var leg := pingpong(cycle * 4.0, 2.0)
	return Vector3(travel.x * minf(leg, 1.0), 0, travel.z * maxf(leg - 1.0, 0.0))

func _build_recipe_shell(steel: StandardMaterial3D) -> void:
	var spec := RollingShell.recipe(dna_id)
	var mesh := RollingShell.make() if spec.is_empty() else RollingShell.mesh_for(dna_id)
	var shell := part(visual, "GrammarShell", mesh, null, Vector3.ZERO)
	var radius := .42 if spec.is_empty() else RollingShell.radius_for(dna_id)
	shell.scale = Vector3.ONE * (body_radius / radius)
	steel.cull_mode = BaseMaterial3D.CULL_DISABLED
	charge_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var trim := steel
	if monochrome:
		steel.albedo_color = Color("16181c")
		steel.metallic = 0.25
		trim = material(Color("454952"), 0.2)
		trim.cull_mode = BaseMaterial3D.CULL_DISABLED
	elif not spec.is_empty():
		steel.albedo_color = Color(spec.shell)
		steel.metallic = float(spec.metal)
		trim = material(Color(spec.trim), float(spec.metal))
		trim.cull_mode = BaseMaterial3D.CULL_DISABLED
	for i in mesh.get_surface_count():
		match mesh.surface_get_name(i):
			"surface_charge": shell.set_surface_override_material(i, charge_material)
			"surface_trim": shell.set_surface_override_material(i, trim)
			_: shell.set_surface_override_material(i, steel)

func _build_field() -> void:
	field_sensor = Area3D.new()
	field_sensor.collision_layer = 0
	field_sensor.collision_mask = 1 | 4
	body.add_child(field_sensor)
	var volume := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = field_radius
	volume.shape = sphere
	field_sensor.add_child(volume)
	field_ring = _boundary_ring(self, "FieldBoundary", field_radius, -.40)

func _boundary_ring(parent: Node3D, title: String, radius: float, height: float) -> MeshInstance3D:
	var ring := TorusMesh.new()
	ring.outer_radius = radius
	ring.inner_radius = radius - .023
	ring.rings = 40
	ring.ring_segments = 5
	var marker := part(parent, title, ring, charge_material.duplicate(), Vector3(0, height, 0))
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return marker

func _build_anchored_shell(steel: StandardMaterial3D) -> void:
	var shell := Grammar.new()
	shell.preset = "spike_ball" if kind == "floor" else "barnacle"
	shell.use_grid_material = false
	visual.add_child(shell)
	var mesh := shell.get_node("GrammarMesh") as MeshInstance3D
	var bounds := mesh.mesh.get_aabb()
	var longest := maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
	shell.scale = Vector3.ONE * (.84 / longest)
	shell.position = -bounds.get_center() * shell.scale
	mesh.material_override = steel
	for axis in 3:
		var band := TorusMesh.new();band.inner_radius = .40;band.outer_radius = .435;band.rings = 32;band.ring_segments = 6
		var ring := part(visual, "ChargeSeam%d" % axis, band, charge_material, Vector3.ZERO)
		if axis == 1:ring.rotation.x = PI / 2
		if axis == 2:ring.rotation.z = PI / 2
	var eye := SphereMesh.new();eye.radius = .105;eye.height = .21
	part(visual, "PinkCore", eye, charge_material, Vector3(0, .1, .40))

static func material(colour: Color, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new();m.albedo_color = colour;m.metallic = metal;m.roughness = .32;return m

static func part(parent: Node3D, title: String, mesh: Mesh, mat: Material, at: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new();node.name = title;node.mesh = mesh;node.material_override = mat;node.position = at;parent.add_child(node);return node

func _world() -> Node:
	return get_tree().get_first_node_in_group("void_game")

func _target() -> Vector3:
	var world := _world()
	if world == null or not world.ready_for_play or world.recovering or world.returning:return Vector3.INF
	return world.body.global_position + Vector3.UP * .8

func clear_sight(point: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(body.global_position, point, 1, [body.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()

func receive_impact(projectile_id: int) -> void:
	if preview or demonstration or spent or age < arm_delay: return
	if behavior == "relay" and fuse >= 0.0: return
	if behavior == "memory":
		if projectile_id == first_projectile_id: return
		if memory_left <= 0.0:
			first_projectile_id = projectile_id
			memory_left = memory_seconds
			return
	detonate("object impact")

func _relay_to_neighbours() -> void:
	if relay_network.is_empty(): return
	var wave := relay_wave
	wave[get_instance_id()] = true
	for neighbour in get_tree().get_nodes_in_group("electrical_mines"):
		if neighbour.behavior != "relay" or neighbour.relay_network != relay_network: continue
		if neighbour.preview or neighbour.spent or neighbour.fuse >= 0.0 or neighbour.age < neighbour.arm_delay: continue
		var id := neighbour.get_instance_id()
		if wave.has(id): continue
		var offset: Vector3 = neighbour.body.global_position - body.global_position
		if absf(offset.y) > .8 or offset.length() > relay_radius: continue
		var ray := PhysicsRayQueryParameters3D.create(body.global_position, neighbour.body.global_position, 1,
			[body.get_rid(), neighbour.body.get_rid()])
		if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): continue
		wave[id] = true
		neighbour.relay_wave = wave
		neighbour.fuse = neighbour.relay_delay

func _apply_field() -> void:
	var pull := sin(age * TAU / travel_period) >= 0
	var color := accent if pull else Color("ffad57")
	var marker := field_ring.material_override as StandardMaterial3D
	marker.albedo_color = color
	marker.emission = color
	charge_material.albedo_color = color
	charge_material.emission = color
	for other in field_sensor.get_overlapping_bodies():
		if not other is RigidBody3D or other.freeze or other.has_meta("electrical_mine"): continue
		if other.has_method("is_picked_up") and other.is_picked_up(): continue
		if not other.has_meta("inventory_projectile") and other.linear_velocity.length() < .7: continue
		var offset: Vector3 = other.global_position - body.global_position
		var distance := offset.length()
		if distance < .10 or distance >= field_radius: continue
		var obstruction := PhysicsRayQueryParameters3D.create(body.global_position, other.global_position, 1, [body.get_rid(), other.get_rid()])
		if not get_world_3d().direct_space_state.intersect_ray(obstruction).is_empty(): continue
		var acceleration := field_acceleration * (1.0 - distance / field_radius)
		other.apply_central_force(offset.normalized() * acceleration * other.mass * (-1.0 if pull else 1.0))

func _patrol() -> void:
	var phase := age * TAU / travel_period
	var path := Vector3(travel.x * sin(phase), 0, travel.z * sin(2 * phase))
	var offset := to_global(path) - body.global_position
	offset.y = 0
	var velocity_error := (offset * 2.2).limit_length(max_speed) - body.linear_velocity.slide(Vector3.UP)
	body.apply_torque(Vector3.UP.cross(velocity_error).limit_length(2.0) * 4.0)

func _split(point: Vector3) -> void:
	if not is_inside_tree() or not is_physics_processing(): return
	# A child is owned by this placement and has no split rule of its own.
	var axis := global_basis.x.normalized()
	for side in [-1.0, 1.0]:
		if split_children.size() >= MAX_SPLIT_CHILDREN: break
		var offset: Vector3 = axis * side
		var sample := point + offset * .82
		var space := get_world_3d().direct_space_state
		var ground := space.intersect_ray(PhysicsRayQueryParameters3D.create(sample, sample + Vector3.DOWN * 1.25, 1, [body.get_rid()]))
		if ground.is_empty() or ground.normal.y < .75: continue
		var centre: Vector3 = ground.position + Vector3.UP * .28
		var clearance := PhysicsShapeQueryParameters3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = .23
		clearance.shape = sphere
		clearance.transform = Transform3D(Basis.IDENTITY, centre)
		clearance.collision_mask = 1 | 2 | 4
		clearance.exclude = [body.get_rid()]
		if not space.intersect_shape(clearance, 1).is_empty(): continue
		var child: Node3D = get_script().new()
		child.behavior = "drift"
		child.dna_id = dna_id
		child.body_radius = .22
		child.practice = true
		child.lifetime = 5.0
		child.arm_delay = .30
		child.shock_radius = .8
		child.accent = accent.lightened(.2)
		child.position = to_local(centre)
		add_child(child)
		child.body.apply_central_impulse(offset * 1.3 + Vector3.UP * 1.2)
		split_children.append(child)

func _physics_process(delta: float) -> void:
	if preview:return
	age += delta
	if lifetime > 0.0 and age >= lifetime:
		queue_free()
		return
	if spent:
		burst_age += delta
		var boom_radius := clampf(shock_radius * 2.25, 4.4, 7.2)
		if burst_age <= BOOM_DURATION:
			var t := clampf(burst_age / BOOM_DURATION, 0.0, 1.0)
			var ease_core := 1.0 - pow(1.0 - t, 3.4)
			var ease_ring := 1.0 - pow(1.0 - t, 2.4)
			flash.scale = Vector3.ONE * maxf(.35, boom_radius * 2.15 * ease_core)
			flash.material_override.albedo_color.a = 0.94 * pow(1.0 - t, 1.4)
			if shock_ring != null:
				var ring_r := maxf(.45, boom_radius * 1.55 * ease_ring)
				shock_ring.scale = Vector3(ring_r, maxf(0.18, 0.85 * (1.0 - t)), ring_r)
				shock_ring.material_override.albedo_color.a = 0.96 * pow(1.0 - t, 1.2)
			if boom_light != null:
				boom_light.light_energy = 20.0 * pow(1.0 - t, 2.0)
			for shard in boom_shards:
				var mesh_node: MeshInstance3D = shard.node
				if not is_instance_valid(mesh_node): continue
				shard.vel = (shard.vel as Vector3) + Vector3(0.0, -13.5 * delta, 0.0)
				mesh_node.global_position += (shard.vel as Vector3) * delta
				mesh_node.rotation += (shard.spin as Vector3) * delta
				mesh_node.scale = Vector3.ONE * lerpf(1.15, 0.08, pow(t, 1.7))
		else:
			_hide_boom_fx()
		if burst_age > BOOM_DURATION and rearm_seconds <= 0.0 and lifetime <= 0.0:set_physics_process(false)
		elif rearm_seconds > 0.0 and burst_age >= maxf(BOOM_DURATION, rearm_seconds):_try_rearm()
		return
	if _translates():body.position = _travel_offset()
	if demonstration and monochrome and not _translates() and is_zero_approx(display_turn) and is_zero_approx(display_pulse):
		charge_material.emission_energy_multiplier = 0.45
	else:
		charge_material.emission_energy_multiplier = .5 + .35 * sin(age * (18 if fuse >= 0 else 3))
	if demonstration:
		visual.rotation_degrees.y = fmod(age * display_turn, 360.0)
		var pulse_wave: float = lerpf(-1.0, 1.0, pingpong((age / travel_period + travel_phase) * 2.0, 1.0)) if motion_curve == "lerp" else sin(age * TAU / travel_period)
		visual.scale = Vector3.ONE * (1.0 + display_pulse * pulse_wave)
		return
	if behavior == "memory" and memory_left > 0.0:
		memory_left = maxf(0.0, memory_left - delta)
		var amber := Color("ffb04e")
		var colour := accent.lerp(amber, clampf(memory_left * 3.0, 0.0, 1.0))
		charge_material.emission = colour
		charge_material.albedo_color = colour
	for i in tendrils.size():tendrils[i].rotation.y = sin(age * 1.5 + i) * .1
	if age < arm_delay:return
	if behavior == "field":_apply_field()
	if behavior == "patrol":_patrol()
	for other in impact_sensor.get_overlapping_bodies():
		if other == body or not other is RigidBody3D or other.has_meta("electrical_mine"):continue
		if other.has_method("is_picked_up") and other.is_picked_up():continue
		if other.linear_velocity.length() >= impact_speed:
			receive_impact(other.get_instance_id())
			if spent: return
	var target := _target()
	if not practice and target.is_finite():
		var distance := body.global_position.distance_to(target)
		if distance < maxf(chase_radius, proximity_radius) and clear_sight(target):
			if behavior == "default" and kind == "rolling" and distance < chase_radius:
				var toward := target - body.global_position;toward.y = 0
				if toward.length() > .05 and body.linear_velocity.length() < max_speed:
					body.apply_torque(Vector3.UP.cross(toward.normalized()) * 4.5)
			if distance < proximity_radius and fuse < 0:fuse = fuse_seconds
	if fuse >= 0:
		fuse -= delta
		if fuse <= 0:detonate("relay pulse" if not relay_wave.is_empty() else "proximity")

func _try_rearm() -> void:
	split_children = split_children.filter(is_instance_valid)
	if not split_children.is_empty(): return
	# Restore the charge only when its return point is clear of bodies and the player.
	var target := _target()
	if not target.is_finite() or target.distance_to(global_position) < proximity_radius + .35:return
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = body.get_node("CollisionShape3D").shape
	query.transform = global_transform;query.collision_mask = 1 | 2 | 4 | (1 << 17) | (1 << 19)
	query.exclude = [body.get_rid()]
	if not get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():return
	body.transform = Transform3D.IDENTITY
	PhysicsServer3D.body_set_state(body.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, body.global_transform)
	body.linear_velocity = Vector3.ZERO;body.angular_velocity = Vector3.ZERO
	body.freeze = not _rolls();body.sleeping = false
	body.collision_layer = 1;body.collision_mask = 1 | 2 | 4
	visual.show()
	_hide_boom_fx()
	charge_material.emission = accent
	charge_material.albedo_color = accent
	memory_left = 0.0
	first_projectile_id = 0
	relay_wave = {}
	if field_ring != null:field_ring.show()
	if sweep_ring != null:sweep_ring.show()
	for limb in tendrils:limb.show()
	age = 0.0;fuse = -1.0;spent = false

func _hide_boom_fx() -> void:
	if flash != null and flash.visible: flash.hide()
	if shock_ring != null and shock_ring.visible: shock_ring.hide()
	if boom_light != null and boom_light.visible:
		boom_light.light_energy = 0.0
		boom_light.visible = false
	for shard in boom_shards:
		var mesh_node: MeshInstance3D = shard.node
		if is_instance_valid(mesh_node) and mesh_node.visible:
			mesh_node.hide()

func _spawn_boom_shards(point: Vector3) -> void:
	if boom_shards.is_empty():
		var shard_mesh := BoxMesh.new()
		shard_mesh.size = Vector3(0.22, 0.11, 0.36)
		var shard_mat := StandardMaterial3D.new()
		shard_mat.albedo_color = Color("090a0e")
		shard_mat.metallic = 0.35
		shard_mat.roughness = 0.42
		for i in 22:
			var m := MeshInstance3D.new()
			m.name = "BoomShard%d" % i
			m.mesh = shard_mesh
			m.material_override = shard_mat
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(m)
			boom_shards.append({"node": m, "vel": Vector3.ZERO, "spin": Vector3.ZERO})
	for i in boom_shards.size():
		var shard: Dictionary = boom_shards[i]
		var mesh_node: MeshInstance3D = shard.node
		var angle := TAU * float(i) / float(boom_shards.size()) + randf_range(-0.18, 0.18)
		var speed := randf_range(6.8, 13.5)
		var dir := Vector3(cos(angle), 0.0, sin(angle))
		shard.vel = dir * speed + Vector3(0.0, randf_range(3.0, 7.0), 0.0)
		shard.spin = Vector3(randf_range(-13.0, 13.0), randf_range(-13.0, 13.0), randf_range(-13.0, 13.0))
		mesh_node.global_position = point + dir * 0.30 + Vector3(0.0, 0.15, 0.0)
		mesh_node.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
		mesh_node.scale = Vector3.ONE * 1.15
		mesh_node.show()

func detonate(reason := "object impact") -> void:
	if spent or preview or demonstration or age < arm_delay:return
	spent = true
	burst_age = 0.0
	var point := body.global_position
	visual.hide();body.collision_layer = 0;body.collision_mask = 0;body.freeze = true
	if field_ring != null:field_ring.hide()
	if sweep_ring != null:sweep_ring.hide()
	for limb in tendrils:limb.hide()
	flash.global_position = point;flash.scale = Vector3.ONE * .35;flash.material_override.albedo_color.a = 0.90;flash.show()
	if shock_ring != null:
		shock_ring.global_position = point + Vector3(0.0, 0.08, 0.0)
		shock_ring.scale = Vector3(0.35, 0.72, 0.35)
		shock_ring.material_override.albedo_color.a = 0.95
		shock_ring.show()
	if boom_light != null:
		boom_light.global_position = point + Vector3(0.0, 0.35, 0.0)
		boom_light.light_energy = 16.0
		boom_light.visible = true
	_spawn_boom_shards(point)
	var target := _target()
	var world := _world()
	var hit_player := not practice and target.is_finite() and target.distance_to(point) <= shock_radius and clear_sight(target)
	if world != null and world.has_method("trigger_impact_feedback"):
		world.trigger_impact_feedback(1.0, point, hit_player)
	if hit_player:
		world.charge.discharge(battery_damage, "mine shock")
	if behavior == "split" and reason == "object impact":
		_split(point)
	if behavior == "relay":
		_relay_to_neighbours()
	exploded.emit(reason)
	print("[mine] ", kind, " / ", reason, " / ", point)

func prepare_editor_preview() -> void:
	preview = true;body.freeze = true;set_physics_process(false)
	body.transform = Transform3D.IDENTITY
	if demonstration:
		visual.rotation_degrees.y = 30.0 if not is_zero_approx(display_turn) else 0.0
		visual.scale = Vector3.ONE * (1.0 + display_pulse)
