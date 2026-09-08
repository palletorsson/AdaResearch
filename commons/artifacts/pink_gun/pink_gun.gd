## THE PINK GUN (2026-08-29, Palle: "we are going to need a gun too and the guns
## should be very very pink and queer").
##
## Held in VR like the laser measure — this node sits inside a grab_stick
## pickable and listens to its trigger. It fires the museum's own catalyst
## projectile, which already knows how to hit a foe (hit_by_projectile /
## hit_by_catalyst_mode), so nothing new has to be taught to anything: what it
## hits, it does not kill. It colours in. A grey silhouette shot with this goes
## pink and walks with you. The gun is very pink because the gun IS the argument.
##
## Built procedurally so it can be swept: `form` is the DNA axis, three bodies
## of the same weapon — a stub, a long one, and a cluster of barrels that fire
## together. No hard edges anywhere on it. Glossy, clearcoated, lit from inside.
extends Node3D
class_name PinkGun

@export_enum("stub", "long", "cluster") var form: String = "stub"
@export var fire_rate_s: float = 0.22
@export var projectile_speed: float = 14.0
@export var glow: float = 1.6

const PINK := Color(1.0, 0.24, 0.66)
const PINK_HOT := Color(1.0, 0.45, 0.80)
const PINK_DEEP := Color(0.78, 0.10, 0.50)

var _cooldown: float = 0.0
var _pulse: float = 0.0
var _mat: StandardMaterial3D = null
var _muzzles: Array[Node3D] = []
var _muzzle_glow: Array[MeshInstance3D] = []
var _pickable: Node = null
## Every mesh THIS build made. Kept as a list rather than read back off
## get_children(), because _rebuild starts by queue_free()ing the old body and a
## queued node is still a child for the rest of the frame — fitting the collider
## from get_children() would fit it to the previous gun merged with this one.
var _body: Array[MeshInstance3D] = []


func apply_grid_config(config: Dictionary) -> void:
	if config.has("form"):
		var f := String(config.get("form", "")).to_lower()
		if f in ["stub", "long", "cluster"]:
			form = f
	if config.has("fire_rate_s"):
		fire_rate_s = maxf(0.05, float(config.get("fire_rate_s", 0.22)))
	if is_inside_tree():
		_rebuild()


func _ready() -> void:
	_rebuild()
	# the pickable is the parent (grab_stick.tscn); its trigger is our trigger
	_pickable = get_parent()
	if _pickable != null and _pickable.has_signal("action_pressed"):
		_pickable.action_pressed.connect(_on_action_pressed)
	# the base pickable is a grab STICK and draws one; this has its own grip
	if _pickable != null:
		var stick: Node = _pickable.get_node_or_null("MeshInstance3D")
		if stick is MeshInstance3D:
			(stick as MeshInstance3D).visible = false


func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	_pulse += delta
	if _mat != null:
		_mat.emission_energy_multiplier = glow * (0.85 + 0.15 * sin(_pulse * 3.1))
	for i in range(_muzzle_glow.size()):
		var g := _muzzle_glow[i]
		if is_instance_valid(g):
			g.scale = Vector3.ONE * (1.0 + 0.08 * sin(_pulse * 4.0 + float(i)))


# ── the body ──────────────────────────────────────────────────────────────

func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	_muzzles.clear()
	_muzzle_glow.clear()
	_body.clear()

	_mat = StandardMaterial3D.new()
	_mat.albedo_color = PINK
	_mat.roughness = 0.18
	_mat.metallic = 0.05
	_mat.clearcoat_enabled = true
	_mat.clearcoat = 0.9
	_mat.clearcoat_roughness = 0.1
	_mat.emission_enabled = true
	_mat.emission = PINK_HOT
	_mat.emission_energy_multiplier = glow

	var deep := _mat.duplicate() as StandardMaterial3D
	deep.albedo_color = PINK_DEEP
	deep.emission = PINK

	# the grip: a fat rounded capsule, tilted back into the hand
	var grip := CapsuleMesh.new()
	grip.radius = 0.028
	grip.height = 0.13
	var g := _mesh(grip, deep, Vector3(0, -0.055, 0.02))
	g.rotation_degrees = Vector3(18, 0, 0)

	match form:
		"long":
			_barrel(Vector3(0, 0.0, 0.0), 0.42, 0.024, _mat)
			for i in range(5):
				_ring(Vector3(0, 0, -0.06 - i * 0.075), 0.034, 0.009, deep)
			_muzzle(Vector3(0, 0, -0.44), 0.03)
		"cluster":
			var offs := [Vector3(0, 0.03, 0), Vector3(-0.028, -0.015, 0), Vector3(0.028, -0.015, 0)]
			for o in offs:
				_barrel(o, 0.20, 0.018, _mat)
				_muzzle(o + Vector3(0, 0, -0.22), 0.022)
			_ring(Vector3(0, 0, -0.05), 0.052, 0.012, deep)
			_ring(Vector3(0, 0, -0.14), 0.052, 0.012, deep)
		_:   # stub
			_barrel(Vector3(0, 0, 0), 0.19, 0.03, _mat)
			_ring(Vector3(0, 0, -0.05), 0.042, 0.012, deep)
			_ring(Vector3(0, 0, -0.11), 0.042, 0.012, deep)
			_muzzle(Vector3(0, 0, -0.21), 0.036)

	# a heart is not subtle, and it is not meant to be: the sight
	var heart := SphereMesh.new()
	heart.radius = 0.014
	heart.height = 0.028
	_mesh(heart, _mat, Vector3(-0.009, 0.045, -0.02))
	_mesh(heart, _mat, Vector3(0.009, 0.045, -0.02))
	var tip := CapsuleMesh.new()
	tip.radius = 0.012
	tip.height = 0.03
	var tm := _mesh(tip, _mat, Vector3(0, 0.032, -0.02))
	tm.rotation_degrees = Vector3(0, 0, 0)

	_fit_collider()


## THE GUN YOU SEE MUST BE THE GUN YOU CAN GRAB.
##
## 2026-09-08, Palle, with a screenshot of the crosshair dead centre on the gun
## in its cabinet: "when clicking on the gun nothing happens".
##
## It was not the click. This node builds its own body and hides grab_stick's
## cube (see _ready), but it inherited the STICK'S COLLIDER and never resized
## it: a 2.4 x 20.4 x 2 cm bar whose long axis is our X — lying ACROSS the
## barrel, not along it. weapon_cabinet then hangs the gun turned 90 degrees, so
## that bar points at the visitor and presents a 2 cm square. Measured with
## commons/testing/probe_grab_reach.gd: ONE of 121 sample points across the
## cabinet's face answered the grab ray, 1%. Every ring and the whole barrel had
## no collision on them at all.
##
## It matters because a pickable is grabbable exactly where its SHAPE is and
## never where its mesh is: the desktop hand casts one ray on the grab mask and
## takes the first body it hits (DesktopInteractionPointer._find_grabbable), and
## an XR hand asks the same physics world. A body that outgrew its collider is
## invisible to both.
##
## DERIVED, NOT TYPED, because `form` changes the extent — stub reaches z -0.25,
## long reaches -0.47, cluster is wider and shorter — so one transcribed box
## would be wrong for two of the three bodies this artifact ships. The grab
## points are untouched: they are their own nodes with their own transforms, so
## the VR grip arithmetic probe_pink_gun_grip.gd asserts is unaffected.
func _fit_collider() -> void:
	var p: Node = get_parent()
	if p == null:
		return
	var cs: CollisionShape3D = p.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if cs == null:
		return
	var box := AABB()
	var got := false
	for mi in _body:
		if not is_instance_valid(mi) or mi.mesh == null:
			continue
		var b: AABB = mi.transform * mi.mesh.get_aabb()
		box = b if not got else box.merge(b)
		got = true
	if not got:
		return
	# our frame -> the pickable's frame (identity in the shipped scene, composed
	# anyway so a repositioned child cannot silently offset the grab volume)
	box = transform * box
	var shape := BoxShape3D.new()
	shape.size = box.size.maxf(0.03)   # never a zero-thickness slab
	cs.shape = shape
	cs.transform = Transform3D(Basis.IDENTITY, box.get_center())


func _barrel(at: Vector3, length: float, radius: float, m: Material) -> void:
	var c := CapsuleMesh.new()          # rounded at both ends — no hard edge anywhere
	c.radius = radius
	c.height = length
	var mi := _mesh(c, m, at + Vector3(0, 0, -length * 0.5))
	mi.rotation_degrees = Vector3(90, 0, 0)


func _ring(at: Vector3, radius: float, tube: float, m: Material) -> void:
	var t := TorusMesh.new()
	t.inner_radius = radius - tube
	t.outer_radius = radius + tube
	var mi := _mesh(t, m, at)
	mi.rotation_degrees = Vector3(90, 0, 0)


func _muzzle(at: Vector3, radius: float) -> void:
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	var gm := StandardMaterial3D.new()
	gm.albedo_color = PINK_HOT
	gm.emission_enabled = true
	gm.emission = Color(1.0, 0.6, 0.9)
	gm.emission_energy_multiplier = glow * 2.2
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var mi := _mesh(s, gm, at)
	_muzzle_glow.append(mi)
	var anchor := Node3D.new()
	anchor.position = at
	add_child(anchor)
	_muzzles.append(anchor)
	var light := OmniLight3D.new()
	light.light_color = PINK_HOT
	light.light_energy = 0.9
	light.omni_range = 1.4
	anchor.add_child(light)


func _mesh(mesh: Mesh, m: Material, at: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = at
	add_child(mi)
	_body.append(mi)
	return mi


# ── firing ────────────────────────────────────────────────────────────────

func _on_action_pressed(_pickable_node) -> void:
	fire()


## Fire from every muzzle. The projectile is the museum's own CatalystProjectile,
## which dispatches to hit_by_catalyst_mode / hit_by_projectile on whatever it
## meets on layer 2 — a foe, a silhouette, a dark sphere — so the gun teaches
## nothing new to anything it hits. It only colours it.
func fire() -> void:
	if _cooldown > 0.0 or not is_inside_tree():
		return
	_cooldown = fire_rate_s
	var dir: Vector3 = -global_transform.basis.z
	for mz in _muzzles:
		if not is_instance_valid(mz):
			continue
		var proj := CatalystProjectile.new()
		proj.speed = projectile_speed
		proj.lifetime = 3.0
		proj.projectile_scale = 0.7
		proj.color_primary = PINK
		proj.color_secondary = PINK_HOT
		proj.emission_energy = 2.4
		proj.direction = dir
		get_tree().current_scene.add_child(proj)
		proj.global_position = mz.global_position + dir * 0.12
	# a kick in the hand that holds it
	if _pickable != null and _pickable.has_method("get_picked_up_by_controller"):
		var ctrl = _pickable.get_picked_up_by_controller()
		if ctrl != null and ctrl.has_method("trigger_haptic_pulse"):
			ctrl.trigger_haptic_pulse("haptic", 0.0, 0.1, 0.5, 0.0)
