extends SceneTree
## WHICH FACES CAN STAND AS LETTERS (the pass, 2026-11-15)
## Which of the project's heavy faces give every capital a front face in a TextMesh? A glyph whose contours cross
## themselves fails to triangulate ('Convex decomposing failed') and its letter shows only its extruded sides:
## standing_word's ERROR first stood with hollow R's in Roboto-Black. Prints one line a face.
##
##   godot --headless --path . --xr-mode off --script res://tools/probes/standing_word_faces.gd


func _initialize() -> void:
	var faces := ["res://commons/font/JetBrainsMono-Medium.ttf", "res://commons/font/cormorant-garamond/CormorantGaramond.ttf"]
	var dir := DirAccess.open("res://commons/font/static")
	if dir != null:
		for f in dir.get_files():
			if f.ends_with(".ttf") and (f.contains("Black") or f.contains("Bold") or f.contains("ExtraBold")) and not f.contains("Italic"): faces.append("res://commons/font/static/" + f)
	for path in faces:
		var face: Font = load(path)
		if face == null: continue
		var missing := ""
		for code in range(65, 91):
			var mesh := TextMesh.new()
			mesh.font = face
			mesh.text = char(code)
			mesh.font_size = 96
			mesh.pixel_size = 1.0 / 96.0
			mesh.depth = 0.2
			var arrays: Array = mesh.surface_get_arrays(0)
			var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var front := 0.0
			for t in range(0, idx.size(), 3):
				var n := (v[idx[t + 1]] - v[idx[t]]).cross(v[idx[t + 2]] - v[idx[t]])
				if absf(n.z) > maxf(absf(n.x), absf(n.y)) and v[idx[t]].z > 0.0: front += absf(n.z) * 0.5
			if front < 0.02: missing += char(code)
		print("[faces] ", path.get_file(), "  capitals without a front: ", missing if missing != "" else "none")
	quit()
