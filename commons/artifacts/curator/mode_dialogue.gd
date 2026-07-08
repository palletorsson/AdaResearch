extends Node3D
class_name CuratorModeDialogue

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: THE DIALOGUE display mode — two works facing each other across a held axis, a tension sentence baked into the floor between them. After the Worcester court (ancient mosaic vs contemporary mural). The compiler places the two artifacts at the plinth cells; this kit builds the axis that makes them argue.
# desire: to stage a tension instead of resolving it — hero and anti-hero as architecture.
# critical_parameter: gap — the distance the argument is held across; tension — the sentence on the floor.
# triggers: _ready builds facing plinths, axis strip, tension tag, two cross-lights; config {gap, tension}.
# emerges: standing at the midpoint the visitor is inside the disagreement — both works watch you decide.
# needs: two artifacts placed by the compiler at ±gap/2; the tension text from heroes.json.
# relationships: mode-kit 2 of the Curator's display grammar; stages heroes.json pairs; sibling of [[mode_crown]] and [[mode_witness_wall]].
# truth: a curated tension is not indecision — it is the claim that the question is the exhibit.

@export var gap: float = 7.0
@export var tension: String = "the same desire, two grammars"

func _ready() -> void:
	_read_meta_overrides()
	_build()

func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_meta_overrides()

func _read_meta_overrides() -> void:
	if has_meta("config_gap"):
		gap = float(str(get_meta("config_gap")))
	if has_meta("config_tension"):
		tension = str(get_meta("config_tension")).replace("_", " ")

func _build() -> void:
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.16, 0.15, 0.17)
	stone.roughness = 0.55

	# the axis strip — a low dark runway between the two works
	var strip := MeshInstance3D.new()
	var sb := BoxMesh.new()
	sb.size = Vector3(gap - 1.6, 0.04, 1.2)
	strip.mesh = sb
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.45, 0.12, 0.14)
	sm.roughness = 0.7
	strip.material_override = sm
	strip.position = Vector3(0, 0.02, 0)
	add_child(strip)

	# two facing plinths (the compiler stands the artifacts on these cells)
	for side_i in 2:
		var s: float = -1.0 + 2.0 * float(side_i)
		var plinth := MeshInstance3D.new()
		var pb := BoxMesh.new()
		pb.size = Vector3(1.6, 0.35, 1.6)
		plinth.mesh = pb
		plinth.material_override = stone
		plinth.position = Vector3(s * gap * 0.5, 0.175, 0)
		add_child(plinth)
		# a soft cross-light aimed at the OPPOSITE work
		var light := SpotLight3D.new()
		light.position = Vector3(s * gap * 0.5, 3.4, 0)
		light.look_at_from_position(light.position, Vector3(-s * gap * 0.5, 1.0, 0), Vector3.UP)
		light.spot_angle = 24.0
		light.spot_range = gap + 2.0
		light.light_energy = 1.8
		light.light_color = Color(1.0, 0.97, 0.9)
		add_child(light)

	# the tension, held at the midpoint
	var tag: Node3D = BakedText.make_tag(tension, Color(0.95, 0.9, 0.85), 0.07,
		Color(0.1, 0.08, 0.09), true, Color(0.86, 0.40, 0.16))
	if tag:
		tag.position = Vector3(0, 1.35, 0)
		add_child(tag)
