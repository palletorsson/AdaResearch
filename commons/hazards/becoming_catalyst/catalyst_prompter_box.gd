# @identity
# essence: floor_hatch(1m) -> prompter_box(catalyst) -- the stage floor opens and offers the crystal
# desire: to be walked over unnoticed, then to open — the understage whispering up
# critical_parameter: shape (flat|plinth) / open_range -- when the floor decides to speak
# triggers: player approaches within open_range; lid tips open on its strut; crystal rises
# emerges: theater from below — the prompter feeds the player their next ability
# needs: CatalystPedestal base [extends]; becoming_catalyst scene [spawns]; lease clock [manager]
# relationships: sibling of catalyst_pedestal; the Aliens deck-plate reading of the same invitation
# truth: the prompter is never seen from the audience — the floor speaks, then closes again.

# CatalystPrompterBox.gd
# The catalyst presented from BELOW instead of within a cage: a one-meter
# floor hatch (one grid cell) whose diamond-plate lid tips open on a
# gas-strut angle when the player comes near. The crystal rises out of the
# glowing recess; on pickup (or when the player walks away) the lid closes.
# With a timed lease, the floor simply takes the crystal back — the
# pedestal return countdown is inherited unchanged from CatalystPedestal.
#
# Token grammar: catalyst_prompter_box:0:0#shape:plinth#emergence:doors#sequence:auto#lease_s:45
#   shape        — "flat" (0.10 m flush hatch) | "plinth" (0.45 m raised box)
#   emergence    — HOW the crystal arrives: "hatch" (rear-hinged deck plate),
#                  "doors" (two half-lids part like stage trap doors),
#                  "slide" (the plate slips away beneath the stage),
#                  "vent" (no lid — grate + standing light shaft)
#   always_open  — truthy: lid stays open regardless of distance (staging)
#   ...all catalyst_pedestal keys (sequence, lease_s, start_mode, ...) work.
extends "res://commons/hazards/becoming_catalyst/catalyst_pedestal.gd"
class_name CatalystPrompterBox

const OPEN_ANGLE_DEG := -55.0   # lid tip, hinged at the back edge
const OPEN_RANGE := 3.0         # m: player closer than this -> lid opens
const CLOSE_RANGE := 4.2        # m: hysteresis so the lid doesn't flutter
const LID_TIME := 0.7
const RISE_TIME := 0.9
const FLAT_H := 0.10
const PLINTH_H := 0.45

@export_enum("flat", "plinth") var shape: String = "flat"
@export_enum("hatch", "doors", "slide", "vent") var emergence: String = "hatch"
# Untyped on purpose: sweep fixtures set this DIRECTLY pre-_ready with the
# string "true", and a typed bool silently rejects that assignment.
var always_open = false

var _body: Node3D = null
var _hinge: Node3D = null           # hatch: rear hinge
var _hinge_l: Node3D = null         # doors: left half
var _hinge_r: Node3D = null         # doors: right half
var _slide_lid: MeshInstance3D = null
var _shaft_mat: StandardMaterial3D = null   # vent: light shaft
var _plate_mat: StandardMaterial3D = null
var _lid_open: bool = false
var _lid_tween: Tween = null
var _crystal_tween: Tween = null


func _body_h() -> float:
	return PLINTH_H if shape == "plinth" else FLAT_H


func _ready() -> void:
	# Deliberately NOT calling super — the cage never existed here. The
	# inherited _process still runs bob/pulse/lease-return; _fading is
	# never set so the cage-fade branch stays dormant.
	_build_body()
	_spawn_crystal()


func _process(delta: float) -> void:
	super._process(delta)
	_update_lid()


# ═══════════════════════════════════════════════════════════════════════════
# BODY — hatch frame, lid on a rear hinge, glowing recess
# ═══════════════════════════════════════════════════════════════════════════

func _build_body() -> void:
	if _body:
		_body.queue_free()
	_body = Node3D.new()
	_body.name = "HatchBody"
	add_child(_body)
	var h: float = _body_h()

	# the box mass (flat tray or raised plinth)
	var block := MeshInstance3D.new()
	var block_mesh := BoxMesh.new()
	block_mesh.size = Vector3(1.0, h, 1.0)
	block.mesh = block_mesh
	block.position = Vector3(0, h * 0.5, 0)
	var block_mat := StandardMaterial3D.new()
	block_mat.albedo_color = Color(0.72, 0.74, 0.77)
	block_mat.metallic = 0.85
	block_mat.roughness = 0.38
	block.material_override = block_mat
	_body.add_child(block)

	# checker-frame lip around the opening
	var lip_mat := StandardMaterial3D.new()
	lip_mat.albedo_color = Color(0.80, 0.82, 0.85)
	lip_mat.metallic = 0.9
	lip_mat.roughness = 0.3
	var lip_y: float = h + 0.01
	for spec in [
		[Vector3(1.0, 0.02, 0.07), Vector3(0, lip_y, 0.465)],
		[Vector3(1.0, 0.02, 0.07), Vector3(0, lip_y, -0.465)],
		[Vector3(0.07, 0.02, 1.0), Vector3(0.465, lip_y, 0)],
		[Vector3(0.07, 0.02, 1.0), Vector3(-0.465, lip_y, 0)],
	]:
		var strip := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = spec[0]
		strip.mesh = sm
		strip.position = spec[1]
		strip.material_override = lip_mat
		_body.add_child(strip)

	# the glowing recess plate — what the audience glimpses when the floor speaks
	var plate := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.82, 0.006, 0.82)
	plate.mesh = pm
	plate.position = Vector3(0, h + 0.006, 0)
	_plate_mat = StandardMaterial3D.new()
	_plate_mat.albedo_color = Color(0.10, 0.16, 0.22)
	_plate_mat.emission_enabled = true
	_plate_mat.emission = Color(0.35, 0.7, 1.0)
	_plate_mat.emission_energy_multiplier = 1.6
	plate.material_override = _plate_mat
	_body.add_child(plate)

	_build_closure(h, lip_mat)

	# interior light — assigned to _cage_light so the inherited pulse drives it
	_cage_light = OmniLight3D.new()
	_cage_light.name = "RecessLight"
	_cage_light.light_color = Color(0.4, 0.7, 1.0)
	_cage_light.light_energy = 1.5
	_cage_light.omni_range = 1.8
	_cage_light.omni_attenuation = 1.5
	_cage_light.position = Vector3(0, h + 0.18, 0)
	_cage_light.visible = false
	_body.add_child(_cage_light)


# The emergence axis — HOW the crystal arrives. Box, floor, or vent:
#   hatch  — the box: one rear-hinged deck plate tips open on its strut
#   doors  — the floor: two half-lids part like stage trap doors
#   slide  — the floor: the plate slips away beneath the stage
#   vent   — the vent: no lid at all; the crystal rises through a grate
#            inside a standing light shaft (kin of catalyst_vent's pillar)
func _build_closure(h: float, lip_mat: StandardMaterial3D) -> void:
	_hinge = null
	_hinge_l = null
	_hinge_r = null
	_slide_lid = null
	_shaft_mat = null

	var top_mat := StandardMaterial3D.new()
	top_mat.albedo_color = Color(0.13, 0.13, 0.14)
	top_mat.roughness = 0.95

	match emergence:
		"doors":
			for side in [-1, 1]:
				var hinge := Node3D.new()
				hinge.name = "DoorHingeL" if side < 0 else "DoorHingeR"
				hinge.position = Vector3(0.43 * side, h + 0.025, 0)
				_body.add_child(hinge)
				var door := MeshInstance3D.new()
				var dm := BoxMesh.new()
				dm.size = Vector3(0.42, 0.018, 0.86)
				door.mesh = dm
				door.position = Vector3(-0.21 * side, 0.009, 0)
				door.material_override = top_mat
				hinge.add_child(door)
				if side < 0:
					_hinge_l = hinge
				else:
					_hinge_r = hinge
		"slide":
			_slide_lid = MeshInstance3D.new()
			var sl := BoxMesh.new()
			sl.size = Vector3(0.86, 0.018, 0.86)
			_slide_lid.mesh = sl
			_slide_lid.position = Vector3(0, h + 0.034, 0)
			_slide_lid.material_override = top_mat
			_body.add_child(_slide_lid)
		"vent":
			# grate bars either side of the rise path
			for z_off in [-0.21, 0.21]:
				var bar := MeshInstance3D.new()
				var bm := BoxMesh.new()
				bm.size = Vector3(0.86, 0.015, 0.05)
				bar.mesh = bm
				bar.position = Vector3(0, h + 0.03, z_off)
				bar.material_override = lip_mat
				_body.add_child(bar)
			# the standing light shaft the crystal rises through
			var shaft := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.24
			cm.bottom_radius = 0.30
			cm.height = 1.3
			shaft.mesh = cm
			shaft.position = Vector3(0, h + 0.65, 0)
			_shaft_mat = StandardMaterial3D.new()
			_shaft_mat.albedo_color = Color(0.4, 0.75, 1.0, 0.07)
			_shaft_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			_shaft_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			_shaft_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			shaft.material_override = _shaft_mat
			_body.add_child(shaft)
		_:
			# hatch (the default): rear-hinged deck plate + gas strut
			_hinge = Node3D.new()
			_hinge.name = "LidHinge"
			_hinge.position = Vector3(0, h + 0.025, -0.43)
			_body.add_child(_hinge)

			var lid_top := MeshInstance3D.new()
			var lt := BoxMesh.new()
			lt.size = Vector3(0.86, 0.018, 0.86)
			lid_top.mesh = lt
			lid_top.position = Vector3(0, 0.016, 0.43)
			lid_top.material_override = top_mat
			_hinge.add_child(lid_top)

			var lid_under := MeshInstance3D.new()
			var lu := BoxMesh.new()
			lu.size = Vector3(0.84, 0.012, 0.84)
			lid_under.mesh = lu
			lid_under.position = Vector3(0, 0.002, 0.43)
			lid_under.material_override = lip_mat
			_hinge.add_child(lid_under)

			var strut := MeshInstance3D.new()
			var sc := CylinderMesh.new()
			sc.top_radius = 0.008
			sc.bottom_radius = 0.008
			sc.height = 0.34
			strut.mesh = sc
			strut.position = Vector3(0.30, -0.06, 0.28)
			strut.rotation_degrees = Vector3(52, 0, 0)
			var strut_mat := StandardMaterial3D.new()
			strut_mat.albedo_color = Color(0.15, 0.15, 0.17)
			strut_mat.metallic = 0.6
			strut_mat.roughness = 0.4
			strut.material_override = strut_mat
			_hinge.add_child(strut)


# ═══════════════════════════════════════════════════════════════════════════
# LID — proximity open/close, crystal rise/lower
# ═══════════════════════════════════════════════════════════════════════════

func _update_lid() -> void:
	var has_crystal: bool = is_instance_valid(_crystal) and _crystal.get_parent() == self
	var want_open: bool = _is_truthy(always_open) and has_crystal
	if not want_open and has_crystal:
		var vp := get_viewport()
		var cam: Camera3D = vp.get_camera_3d() if vp else null
		if cam:
			var d: float = cam.global_position.distance_to(global_position)
			want_open = d < (CLOSE_RANGE if _lid_open else OPEN_RANGE)
		else:
			want_open = true  # headless/capture context — show the offer
	if want_open != _lid_open:
		_set_lid_open(want_open)


func _set_lid_open(open: bool) -> void:
	_lid_open = open
	if _lid_tween:
		_lid_tween.kill()
	_lid_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_lid_tween.set_parallel(true)
	match emergence:
		"doors":
			if _hinge_l:
				_lid_tween.tween_property(_hinge_l, "rotation_degrees:z", 80.0 if open else 0.0, LID_TIME)
			if _hinge_r:
				_lid_tween.tween_property(_hinge_r, "rotation_degrees:z", -80.0 if open else 0.0, LID_TIME)
		"slide":
			if _slide_lid:
				_lid_tween.tween_property(_slide_lid, "position:z", -0.78 if open else 0.0, LID_TIME)
		"vent":
			if _shaft_mat:
				_lid_tween.tween_property(_shaft_mat, "albedo_color:a", 0.26 if open else 0.07, LID_TIME)
		_:
			if _hinge:
				_lid_tween.tween_property(_hinge, "rotation_degrees:x", OPEN_ANGLE_DEG if open else 0.0, LID_TIME)
	if _cage_light:
		_cage_light.visible = open
	if open:
		_raise_crystal()
	else:
		_lower_crystal()


func _raise_crystal() -> void:
	if not is_instance_valid(_crystal) or _crystal.get_parent() != self:
		return
	_crystal.visible = true
	if _crystal_tween:
		_crystal_tween.kill()
	_crystal_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_crystal_tween.tween_property(self, "_crystal_base_y", _body_h() + 0.55, RISE_TIME)


func _lower_crystal() -> void:
	if _crystal_tween:
		_crystal_tween.kill()
	if not is_instance_valid(_crystal) or _crystal.get_parent() != self:
		return
	_crystal_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_crystal_tween.tween_property(self, "_crystal_base_y", _body_h() - 0.02, RISE_TIME * 0.6)
	_crystal_tween.tween_callback(_hide_lowered_crystal)


func _hide_lowered_crystal() -> void:
	if is_instance_valid(_crystal) and _crystal.get_parent() == self:
		_crystal.visible = false


# ═══════════════════════════════════════════════════════════════════════════
# OVERRIDES of the pedestal lifecycle
# ═══════════════════════════════════════════════════════════════════════════

func _spawn_crystal() -> void:
	super._spawn_crystal()
	if not is_instance_valid(_crystal):
		return
	# Crystal starts seated in the recess, hidden until the lid opens.
	_crystal_base_y = _body_h() - 0.02
	_crystal.position = Vector3(0, _crystal_base_y, 0)
	_crystal.visible = _lid_open


func _on_crystal_taken(_pickable) -> void:
	catalyst_taken.emit()
	_set_lid_open(false)
	if _lease_s > 0.0:
		_return_left = _lease_s + RETURN_GRACE
		_leased_out = true
		print("[PrompterBox] Crystal taken on a %.0fs lease — the floor waits" % _lease_s)
	else:
		print("[PrompterBox] Crystal taken — the hatch closes")


func _rematerialize() -> void:
	_return_left = 0.0
	_leased_out = false
	_fading = false
	_pending_crystal_cfg = _last_crystal_cfg.duplicate()
	_spawn_crystal()
	catalyst_returned.emit()
	print("[PrompterBox] Lease over — the crystal is back beneath the floor")


func apply_grid_config(config_data: Dictionary) -> void:
	var rebuild: bool = false
	if config_data.has("shape"):
		var s: String = String(config_data["shape"]).to_lower()
		if s in ["flat", "plinth"] and s != shape:
			shape = s
			rebuild = true
	if config_data.has("emergence"):
		var e: String = String(config_data["emergence"]).to_lower()
		if e in ["hatch", "doors", "slide", "vent"] and e != emergence:
			emergence = e
			rebuild = true
	if rebuild and is_inside_tree():
		# guarded rebuild — only fires on an actual shape/emergence change
		_build_body()
		_lid_open = false
		if is_instance_valid(_crystal) and _crystal.get_parent() == self:
			_crystal_base_y = _body_h() - 0.02
			_crystal.position = Vector3(0, _crystal_base_y, 0)
			_crystal.visible = false
	if config_data.has("always_open"):
		always_open = _is_truthy(config_data["always_open"])
	super.apply_grid_config(config_data)
