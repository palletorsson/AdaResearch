# export_wall_gltf.gd — author the labwall segment family IN GODOT and export
# each variant as .glb for the Three.js map-viewer. Run headless:
#   godot --path . --xr-mode off --no-window --script res://commons/testing/export_wall_gltf.gd
# Output: ../ada_encyclopedia/public/wall-gltf/<name>.glb + manifest.json
# Each variant is ONE grid-edge module: 1.0 long (X), 3.2 high, 0.16 thick (Z),
# origin at bottom-centre so the viewer sets position=(edge midpoint, floor).
extends SceneTree

const H := 3.2
const T := 0.16
const L := 1.0
const HOVER := 0.06
const KICK_H := 0.28
const TRIM_H := 0.55
const ACCENT_H := 0.08

var mat_panel: StandardMaterial3D
var mat_dark: StandardMaterial3D
var mat_amber: StandardMaterial3D
var mat_glass: StandardMaterial3D
var mat_white: StandardMaterial3D
var mat_screen: StandardMaterial3D
var mat_hazard: StandardMaterial3D

func _init() -> void:
	_make_materials()
	var out_dir := ProjectSettings.globalize_path("res://").path_join("../ada_encyclopedia/public/wall-gltf")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var variants := {
		"plain": _v_plain(), "glass": _v_glass(), "whiteboard": _v_whiteboard(),
		"display": _v_display(), "conduit": _v_conduit(), "vent": _v_vent(),
		"hazard": _v_hazard(), "locker": _v_locker(), "rib": _v_rib(),
		"beam": _v_beam(),
	}
	var weights := {"plain": 6, "glass": 2, "whiteboard": 1, "display": 1,
		"conduit": 2, "vent": 2, "hazard": 1, "locker": 2, "rib": 2, "beam": 2}
	var manifest := []
	for vname in variants:
		var node: Node3D = variants[vname]
		node.name = "wall_" + vname
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		var err := doc.append_from_scene(node, state)
		if err != OK:
			print("EXPORT FAIL append %s: %d" % [vname, err])
			continue
		var path := out_dir.path_join(vname + ".glb")
		err = doc.write_to_filesystem(state, path)
		if err != OK:
			print("EXPORT FAIL write %s: %d" % [vname, err])
			continue
		manifest.append({"name": vname, "file": vname + ".glb",
			"weight": weights.get(vname, 1)})
		print("exported ", path)
		node.free()
	var f := FileAccess.open(out_dir.path_join("manifest.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"length": L, "height": H, "thickness": T,
		"variants": manifest}, " "))
	f.close()
	print("manifest: %d variants" % manifest.size())
	quit()

func _make_materials() -> void:
	mat_panel = StandardMaterial3D.new()
	mat_panel.albedo_color = Color(0.52, 0.54, 0.55)
	mat_panel.roughness = 0.9
	mat_dark = StandardMaterial3D.new()
	mat_dark.albedo_color = Color(0.12, 0.13, 0.14)
	mat_dark.roughness = 0.6
	mat_dark.metallic = 0.35
	mat_amber = StandardMaterial3D.new()
	mat_amber.albedo_color = Color(1.0, 0.62, 0.18)
	mat_amber.emission_enabled = true
	mat_amber.emission = Color(1.0, 0.55, 0.15)
	mat_amber.emission_energy_multiplier = 1.6
	mat_glass = StandardMaterial3D.new()
	mat_glass.albedo_color = Color(0.62, 0.78, 0.82, 0.28)
	mat_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_glass.roughness = 0.05
	mat_glass.metallic = 0.1
	mat_white = StandardMaterial3D.new()
	mat_white.albedo_color = Color(0.93, 0.93, 0.91)
	mat_white.roughness = 0.15
	mat_screen = StandardMaterial3D.new()
	mat_screen.albedo_color = Color(0.1, 0.35, 0.4)
	mat_screen.emission_enabled = true
	mat_screen.emission = Color(0.2, 0.85, 1.0)
	mat_screen.emission_energy_multiplier = 1.2
	mat_hazard = StandardMaterial3D.new()
	mat_hazard.albedo_color = Color(0.95, 0.75, 0.1)
	mat_hazard.roughness = 0.7

func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)

# the shared chassis: hovering kick, amber accent, dark trim. panel zone is
# y in [KICK_TOP .. ACCENT_BOTTOM]; variants fill it differently.
func _chassis(root: Node3D) -> Dictionary:
	var kick_top := HOVER + KICK_H
	var trim_y := H - TRIM_H * 0.5
	var accent_y := H - TRIM_H - ACCENT_H * 0.5
	var panel_top := accent_y - ACCENT_H * 0.5
	_box(root, Vector3(L, KICK_H, T * 1.35), Vector3(0, HOVER + KICK_H * 0.5, 0), mat_dark)
	_box(root, Vector3(L, ACCENT_H, T * 1.18), Vector3(0, accent_y, 0), mat_amber)
	_box(root, Vector3(L, TRIM_H, T * 1.25), Vector3(0, trim_y, 0), mat_dark)
	return {"bottom": kick_top, "top": panel_top}

func _panel(root: Node3D, z: Dictionary) -> void:
	var h: float = z["top"] - z["bottom"]
	_box(root, Vector3(L, h, T), Vector3(0, z["bottom"] + h * 0.5, 0), mat_panel)

func _v_plain() -> Node3D:
	var n := Node3D.new()
	var z := _chassis(n)
	_panel(n, z)
	_box(n, Vector3(L, 0.09, T * 1.06), Vector3(0, 1.15, 0), mat_dark)
	return n

func _v_glass() -> Node3D:
	var n := Node3D.new()
	var z := _chassis(n)
	var h: float = z["top"] - z["bottom"]
	var mid: float = z["bottom"] + h * 0.5
	_box(n, Vector3(0.09, h, T * 1.1), Vector3(-0.455, mid, 0), mat_dark)
	_box(n, Vector3(0.09, h, T * 1.1), Vector3(0.455, mid, 0), mat_dark)
	_box(n, Vector3(0.86, h - 0.1, 0.04), Vector3(0, mid, 0), mat_glass)
	_box(n, Vector3(0.86, 0.06, T * 0.9), Vector3(0, mid, 0), mat_dark)
	return n

func _v_whiteboard() -> Node3D:
	var n := _v_plain()
	_box(n, Vector3(0.9, 1.1, 0.03), Vector3(0, 1.65, T * 0.52 + 0.015), mat_white)
	_box(n, Vector3(0.9, 0.05, 0.08), Vector3(0, 1.07, T * 0.52 + 0.04), mat_dark)
	return n

func _v_display() -> Node3D:
	var n := Node3D.new()
	var z := _chassis(n)
	_panel(n, z)
	_box(n, Vector3(0.82, 0.64, 0.05), Vector3(0, 1.85, T * 0.5 + 0.02), mat_dark)
	_box(n, Vector3(0.74, 0.56, 0.02), Vector3(0, 1.85, T * 0.5 + 0.05), mat_screen)
	return n

func _v_conduit() -> Node3D:
	var n := Node3D.new()
	var z := _chassis(n)
	_panel(n, z)
	for i in 3:
		_box(n, Vector3(L, 0.07, 0.07), Vector3(0, 0.62 + i * 0.16, T * 0.5 + 0.035), mat_dark)
	return n

func _v_vent() -> Node3D:
	var n := Node3D.new()
	var z := _chassis(n)
	_panel(n, z)
	for i in 5:
		_box(n, Vector3(0.7, 0.045, 0.03), Vector3(0, 1.35 + i * 0.14, T * 0.5 + 0.015), mat_dark)
	return n

func _v_hazard() -> Node3D:
	var n := Node3D.new()
	var z := _chassis(n)
	_panel(n, z)
	for i in 5:
		var m := mat_hazard if i % 2 == 0 else mat_dark
		_box(n, Vector3(0.2, 0.5, 0.02), Vector3(-0.4 + i * 0.2, 0.62, T * 0.5 + 0.01), m)
	return n

func _v_locker() -> Node3D:
	var n := Node3D.new()
	var z := _chassis(n)
	_panel(n, z)
	_box(n, Vector3(0.04, z["top"] - z["bottom"], T * 1.04), Vector3(-0.17, 1.4, 0), mat_dark)
	_box(n, Vector3(0.04, z["top"] - z["bottom"], T * 1.04), Vector3(0.17, 1.4, 0), mat_dark)
	_box(n, Vector3(0.03, 0.12, 0.05), Vector3(-0.28, 1.35, T * 0.5 + 0.025), mat_dark)
	_box(n, Vector3(0.03, 0.12, 0.05), Vector3(0.06, 1.35, T * 0.5 + 0.025), mat_dark)
	return n

func _v_rib() -> Node3D:
	var n := Node3D.new()
	var z := _chassis(n)
	_panel(n, z)
	_box(n, Vector3(0.22, H - HOVER, T * 1.8), Vector3(0, HOVER + (H - HOVER) * 0.5, 0), mat_dark)
	return n

func _v_beam() -> Node3D:
	var n := Node3D.new()
	var z := _chassis(n)
	_panel(n, z)
	_box(n, Vector3(L, 0.18, T * 1.5), Vector3(0, 2.05, 0), mat_dark)
	_box(n, Vector3(L, 0.04, T * 1.55), Vector3(0, 1.94, 0), mat_amber)
	return n
