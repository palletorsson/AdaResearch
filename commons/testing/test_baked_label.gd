extends SceneTree
## BakedTextAlbedo drop-in mesh helpers — verify they return valid textured quads
## (the integrated-text replacement for surface Label3D). Headless-safe.
##   godot --headless --xr-mode off --path . --script res://commons/testing/test_baked_label.gd
const BTA = preload("res://commons/utils/baked_text_albedo.gd")

var _fails := 0
func _ok(c: bool, l: String) -> void:
	print(("  PASS  " if c else "  FAIL  ") + l)
	if not c: _fails += 1

func _initialize() -> void:
	var m = BTA.make_label_mesh("EMPLOYEES ONLY", Color(0.96, 0.96, 0.96), Vector2(0.46, 0.13))
	_ok(m != null and m is MeshInstance3D, "make_label_mesh returns a MeshInstance3D")
	if m != null:
		var mat = m.material_override
		_ok(mat != null and mat.albedo_texture != null, "label quad has a baked albedo_texture")
		_ok(m.mesh is QuadMesh and (m.mesh as QuadMesh).size == Vector2(0.46, 0.13), "quad size matches world_size")
		_ok(mat.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA, "label quad is alpha-transparent")

	var p = BTA.make_panel_mesh("FIRE HOSE", Color(0.72, 0.10, 0.10), Color.WHITE, Vector2(0.5, 0.12))
	_ok(p != null and p.material_override != null and p.material_override.albedo_texture != null, "make_panel_mesh returns an opaque textured quad")
	if p != null:
		_ok(p.material_override.transparency != BaseMaterial3D.TRANSPARENCY_ALPHA, "panel quad is opaque (bg fills it)")

	_ok(BTA.make_label_mesh("", Color.WHITE, Vector2(0.2, 0.1)) == null, "empty text returns null")

	print("RESULT: ", "OK" if _fails == 0 else "%d FAIL" % _fails)
	quit(_fails)
