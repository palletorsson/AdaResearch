extends Node3D
class_name PinkTriangle

# @identity
# essence: a pink triangle on a black field — the most charged triangle in modern history. In the Nazi camps it was sewn point-down onto the clothing of men imprisoned for homosexuality, a badge that marked them for death. In 1987 the Silence = Death collective and ACT UP took the same triangle, turned it point-UP, set it on black, and made it a banner of refusal and survival during the AIDS crisis. This object holds both: a pink triangle whose ORIENTATION is the whole argument — point-down is the wound the state inflicted, point-up is the wound reclaimed as a weapon.
# desire: it wants the player to understand that a primitive shape can carry the weight of a history, and that meaning is not in the geometry but in who draws it and which way up. It wants the rotation from down to up to feel like what it was: not decoration but a community seizing the symbol that was meant to erase them and pointing it back. It wants to sit quietly in the lab and be the proof that form is never neutral once people have died under it.
# critical_parameter: inverted. inverted = false is the RECLAIMED triangle (point-up, ACT UP, Silence = Death) — the default, because the project stands with the reclamation. inverted = true is the camp badge (point-down) — included only so the reclaiming rotation can be SHOWN, the 180° that a movement turned a death-mark into a rallying cry. The pink-on-black is non-negotiable: the colour the badge used, the black the banner used.
# triggers: _ready builds the black field and the pink triangle at the chosen orientation; apply_grid_config rebuilds on DNA change. It does not animate — this one holds still, because some things should not pulse.
# emerges: point-up among the other triangles it reads as pride and militancy; flipped point-down it becomes unbearable in the right way — the same shape, the same pink, the violence restored by a half-turn. Beside `three_points_triangle` (image) and `tensegrity_triangle` (structure) it is the triangle as SYMBOL — the one whose meaning was assigned by power and then reassigned by the people power tried to mark.
# needs: the pink triangle [present]; the black field it was reclaimed against [present]; an orientation that carries the argument [inverted flag, present]; stillness [no animation, present]
# relationships: symbol-sibling of `three_points_triangle` and `tensegrity_triangle`; the queer-historical anchor of the Primitives sequence and a hinge to the whole project's QFEP thesis (queerness coded into the most elementary form); cousin to the critical-technology thread — where `redline` is the line that sorted, this is the triangle that marked; descendant of nothing in geometry and everything in history.
# truth: a point is position; a line is relation; a triangle is the first enclosed surface — and the pink triangle is the proof that an enclosed surface can also enclose a people, name them, and be turned, by them, into the sign of their refusal to be named-for-death. The geometry is identical to every other triangle in the lab. Only the history is different, and the history is the point. Form is never neutral once a body has worn it.

## Pink triangle — the triangle as reclaimed symbol (Nazi badge -> ACT UP).
##
## Built procedurally. Origin at the field centre; front faces +Z (hang
## like a banner). Default orientation is point-UP (reclaimed). Holds
## still — it does not animate.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Form")
@export var field_size: float = 1.5
@export var triangle_scale: float = 0.62
## false = reclaimed (point-up, ACT UP). true = camp badge (point-down).
@export var inverted: bool = false

@export_group("Material")
@export var pink: Color = Color(0.92, 0.05, 0.52)     # Silence = Death pink
@export var field_color: Color = Color(0.02, 0.02, 0.03)
@export var pink_emission_energy: float = 1.4

# ── State ─────────────────────────────────────────────────────────────

var _built: bool = false


func _ready() -> void:
	_read_metadata_overrides()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c in get_children():
			c.queue_free()
		_built = false
		_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_field_size"):
		field_size = float(str(get_meta("config_field_size")))
	if has_meta("config_triangle_scale"):
		triangle_scale = float(str(get_meta("config_triangle_scale")))
	if has_meta("config_inverted"):
		var s: String = str(get_meta("config_inverted")).to_lower()
		inverted = s == "true" or s == "1" or s == "yes"
	if has_meta("config_pink"):
		pink = _parse_color(str(get_meta("config_pink")), pink)


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts := raw.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	return fallback


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true

	# Black field.
	var field := MeshInstance3D.new()
	field.name = "Field"
	var fm := BoxMesh.new()
	fm.size = Vector3(field_size, field_size, 0.04)
	field.mesh = fm
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = field_color
	fmat.roughness = 0.95
	fmat.metallic = 0.0
	field.material_override = fmat
	add_child(field)

	# Pink triangle — equilateral, centred, point up (or down if inverted).
	var s: float = field_size * triangle_scale * 0.5
	var v0: Vector3
	var v1: Vector3
	var v2: Vector3
	if inverted:
		# point-down (the camp badge)
		v0 = Vector3(0.0, -s, 0.0)
		v1 = Vector3(-s * 0.92, s * 0.7, 0.0)
		v2 = Vector3(s * 0.92, s * 0.7, 0.0)
	else:
		# point-up (reclaimed)
		v0 = Vector3(0.0, s, 0.0)
		v1 = Vector3(-s * 0.92, -s * 0.7, 0.0)
		v2 = Vector3(s * 0.92, -s * 0.7, 0.0)

	var z := 0.025   # sit proud of the field
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nrm := Vector3(0, 0, 1)
	st.set_normal(nrm); st.add_vertex(v0 + Vector3(0, 0, z))
	st.set_normal(nrm); st.add_vertex(v1 + Vector3(0, 0, z))
	st.set_normal(nrm); st.add_vertex(v2 + Vector3(0, 0, z))
	var tri := MeshInstance3D.new()
	tri.name = "PinkTriangle"
	tri.mesh = st.commit()
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = pink
	pmat.emission_enabled = true
	pmat.emission = pink
	pmat.emission_energy_multiplier = pink_emission_energy
	pmat.roughness = 0.4
	pmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	tri.material_override = pmat
	add_child(tri)
