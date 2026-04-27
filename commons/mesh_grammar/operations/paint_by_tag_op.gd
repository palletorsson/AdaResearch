## PaintByTagOp — Set per-face colour based on tag membership.
##
## Encodes the substrate's color-by-role channel into mesh-grammar.
## For each selected face, looks up its tags against a palette dict and
## writes the first matching colour into face_metadata[i]["color"].
## A small change in mesh_data.to_array_mesh applies these as
## SurfaceTool vertex colours when present.
##
## The MeshInstance3D's material must have vertex_color_use_as_albedo
## set true to display the colours; the unified renderer config flag
## "apply_face_colors": true triggers that material treatment.
##
## Params:
##   palette: Dictionary{String -> Array[3]/Color}
##     Maps tag (with optional prefix stripping) to RGB triple in 0..1
##     or to a Color directly.
##   tag_prefix: String = ""
##     If set, tags must start with this prefix to be considered.
##   default: Array[3] / Color  (optional)
##     Colour for faces with no matching tag. Default = white.
extends MeshRule
class_name PaintByTagOp


func _execute(mesh: MeshData, selected: PackedInt32Array) -> void:
	var palette_raw: Dictionary = params.get("palette", {})
	var tag_prefix: String = String(params.get("tag_prefix", ""))
	var default_raw = params.get("default", [1.0, 1.0, 1.0])
	var default_color: Color = _to_color(default_raw)

	# Resolve palette to Color values.
	var palette: Dictionary = {}
	for key in palette_raw.keys():
		palette[String(key)] = _to_color(palette_raw[key])

	for fi in selected:
		if fi >= mesh.faces.size():
			continue
		var color: Color = default_color
		var matched := false
		if fi < mesh.face_tags.size():
			for raw_tag in mesh.face_tags[fi]:
				var tag := String(raw_tag)
				if tag_prefix != "" and not tag.begins_with(tag_prefix):
					continue
				var key := tag if tag_prefix == "" else tag.substr(tag_prefix.length())
				if palette.has(key):
					color = palette[key]
					matched = true
					break
				# also try the full tag
				if palette.has(tag):
					color = palette[tag]
					matched = true
					break
		_ensure_metadata_size(mesh, fi)
		mesh.face_metadata[fi]["color"] = color
		if matched:
			# Mark presence so the renderer can detect "this mesh has paint_by_tag".
			mesh.face_metadata[fi]["painted"] = true


func _to_color(raw) -> Color:
	if raw is Color:
		return raw
	if raw is Array and raw.size() >= 3:
		var r := float(raw[0])
		var g := float(raw[1])
		var b := float(raw[2])
		var a := float(raw[3]) if raw.size() >= 4 else 1.0
		return Color(r, g, b, a)
	if raw is String:
		var s := String(raw)
		if s.begins_with("#"):
			return Color.html(s)
	return Color.WHITE


func _ensure_metadata_size(mesh: MeshData, fi: int) -> void:
	while mesh.face_metadata.size() <= fi:
		mesh.face_metadata.append({})
