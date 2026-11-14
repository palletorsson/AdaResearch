extends Node3D
class_name WardrobeTunnel
## THE WARDROBE TUNNEL (2026-11-14; Palle, shown the wardrobe's skins lining the corridors of its comfort test: "add this
## the or a map"). One skin of the boolean cave's wardrobe (commons/artifacts/boolean_cave/wardrobe.gdshader) as a ROOM:
## a tunnel you walk into, its floor, walls, ceiling and far end all wearing the skin, inside a shell of black latex
## (the black of Boolean_Verbs' monolith). Worn on a swatch or a stroke a skin is a surface you look AT; here it is the
## place you stand IN - which is what the wardrobe's comfort pass was for: its fine patterns fade to their own average
## before they could sizzle, and its motion loops with TIME's 30 s rollover, so a body can stay inside for minutes.
##
## The mouth is the origin: the tunnel runs from it along local -Z, so a row's position is where a visitor enters and
## its facing turns the mouth toward them. A lintel over the mouth carries the skin's name. Fourteen of these, seven a
## side, line two slabs of Shader_11_QueerRubber (floor 105) - the queer-materials hall whose boards show leather,
## oil-slick latex, pop plastic and velvet on bodies: beside them, the same materials are walked into.
##
## Config (row `config`, all optional): skin (one of SKINS), hue (a colour - "#rrggbb" or [r, g, b] - else the skin's
## own), length / width / height (the inside, metres), label (bool).

const WARDROBE := preload("res://commons/artifacts/boolean_cave/wardrobe.gdshader")
## The wardrobe in the shader's own order: index IS the shader's mode.
const SKINS := ["latex", "pvc", "rubber", "leather", "chrome", "glitter", "sequin", "holo", "fishnet", "rainbow", "neon", "pearl", "velvet", "drag"]
## Each skin's own colour - the ones its alcoves wear on Boolean_Verbs, with a few made truer to the material (crimson
## velvet, blush pearl, cyan neon, hot pink drag).
const HUES := {
	"latex": Color(0.62, 0.30, 0.92), "pvc": Color(0.86, 0.22, 0.52), "rubber": Color(0.30, 0.42, 0.95),
	"leather": Color(0.20, 0.78, 0.72), "chrome": Color(0.98, 0.45, 0.70), "glitter": Color(0.95, 0.85, 0.30),
	"sequin": Color(0.40, 0.85, 0.35), "holo": Color(0.62, 0.30, 0.92), "fishnet": Color(0.98, 0.25, 0.60),
	"rainbow": Color(1.0, 1.0, 1.0), "neon": Color(0.20, 0.95, 0.85), "pearl": Color(0.95, 0.85, 0.90),
	"velvet": Color(0.85, 0.10, 0.25), "drag": Color(1.0, 0.08, 0.58),
}
## The shell: black latex, as Boolean_Verbs' monolith wears it (Palle, 2026-11-14: "very bigger and black").
const SHELL_HUE := Color(0.03, 0.028, 0.035)
const WALL := 0.2        ## the shell's side walls and far wall (m)
const LINTEL := 0.6      ## the roof over the inside, which carries the name over the mouth (m)
const LIFT := 0.006      ## the lining stands this far inside the shell, so the two never fight for a pixel (m)
const CELL := 1.0        ## the wardrobe's pattern scale: metres to a unit, as the big walk-in cave wears it

@export_enum("latex", "pvc", "rubber", "leather", "chrome", "glitter", "sequin", "holo", "fishnet", "rainbow", "neon", "pearl", "velvet", "drag") var skin: String = "latex"
@export var length: float = 7.6     ## inside, from the mouth to the far wall (m)
@export var width: float = 2.4      ## inside (m)
@export var height: float = 2.6     ## inside (m)
@export var label: bool = true      ## the skin's name on the lintel over the mouth
@export var hue: Color = Color(0, 0, 0, 0)   ## alpha 0: the skin's own colour (HUES)

var _built: Node3D
var _queued := false


func _ready() -> void:
	_queue_build()


## The tower adds a work and THEN configures it: both ask for one build, made once, at the end of the frame.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("skin"):
		var s := str(config_data.skin).strip_edges().to_lower()
		if SKINS.has(s):
			skin = s
		else:
			push_warning("wardrobe_tunnel: no skin '%s' - keeping %s" % [s, skin])
	if config_data.has("length"): length = clampf(float(config_data.length), 2.0, 20.0)
	if config_data.has("width"): width = clampf(float(config_data.width), 1.2, 6.0)
	if config_data.has("height"): height = clampf(float(config_data.height), 2.1, 5.0)
	if config_data.has("label"): label = _truthy(config_data.label)
	if config_data.has("hue"):
		var h = config_data.hue
		if h is Color: hue = h
		elif h is String and Color.html_is_valid(h): hue = Color.html(h)
		elif h is Array and h.size() >= 3: hue = Color(float(h[0]), float(h[1]), float(h[2]))
	_queue_build()


func _truthy(v) -> bool:
	if v is String: return v.strip_edges().to_lower() in ["1", "true", "yes", "on"]
	return bool(v)


func _queue_build() -> void:
	if _queued: return
	_queued = true
	_build.call_deferred()


## The colour the skin is worn in.
func worn_hue() -> Color:
	return hue if hue.a > 0.0 else HUES.get(skin, Color.WHITE)


## The tunnel's inside, in local metres: x across, y up, z from the mouth (0) inward (negative).
func inside() -> AABB:
	return AABB(Vector3(-width / 2.0, 0.0, -length), Vector3(width, height, length))


func _build() -> void:
	_queued = false
	if _built != null:
		remove_child(_built)
		_built.free()
	_built = Node3D.new()
	_built.name = "Tunnel"
	add_child(_built)
	if not SKINS.has(skin): skin = "latex"
	var lining := _material(SKINS.find(skin), worn_hue())
	var shell := _material(0, SHELL_HUE)
	var w := width
	var h := height
	var l := length
	# the lining, facing in: floor, ceiling, the two walls and the far end
	_quad(lining, Vector3(0.0, LIFT, -l / 2.0), Vector2(w, l), Vector3.UP, "Floor")
	_quad(lining, Vector3(0.0, h - LIFT, -l / 2.0), Vector2(w, l), Vector3.DOWN, "Ceiling")
	_quad(lining, Vector3(-w / 2.0 + LIFT, h / 2.0, -l / 2.0), Vector2(l, h), Vector3.RIGHT, "WallLeft")
	_quad(lining, Vector3(w / 2.0 - LIFT, h / 2.0, -l / 2.0), Vector2(l, h), Vector3.LEFT, "WallRight")
	_quad(lining, Vector3(0.0, h / 2.0, -l + LIFT), Vector2(w, h), Vector3.BACK, "End")
	# the shell round it, black latex, and its collision (the slab under it is the floor a body stands on)
	var body := StaticBody3D.new()
	body.name = "Shell"
	_built.add_child(body)
	var deep := l + WALL
	_box(body, shell, Vector3(-w / 2.0 - WALL / 2.0, (h + LINTEL) / 2.0, -deep / 2.0), Vector3(WALL, h + LINTEL, deep))
	_box(body, shell, Vector3(w / 2.0 + WALL / 2.0, (h + LINTEL) / 2.0, -deep / 2.0), Vector3(WALL, h + LINTEL, deep))
	_box(body, shell, Vector3(0.0, h + LINTEL / 2.0, -deep / 2.0), Vector3(w, LINTEL, deep))
	_box(body, shell, Vector3(0.0, h / 2.0, -l - WALL / 2.0), Vector3(w, h, WALL))
	if label:
		var name_label := Label3D.new()
		name_label.name = "Name"
		name_label.text = skin.to_upper()
		name_label.font_size = 96
		name_label.pixel_size = 0.0035
		name_label.outline_size = 18
		name_label.modulate = Color(1, 1, 1)
		name_label.outline_modulate = Color(worn_hue(), 1.0) if skin != "rainbow" else Color(0.89, 0.01, 0.01)
		name_label.double_sided = false
		name_label.position = Vector3(0.0, h + LINTEL / 2.0, 0.012)
		_built.add_child(name_label)


func _material(mode: int, colour: Color) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = WARDROBE
	m.set_shader_parameter("mode", mode)
	m.set_shader_parameter("hue", colour)
	m.set_shader_parameter("cell", CELL)
	m.set_shader_parameter("shimmer", 1.0)
	return m


## One face of the lining: a quad whose front (+Z of the quad) looks along n, into the tunnel.
func _quad(mat: Material, centre: Vector3, size: Vector2, n: Vector3, node_name: String) -> void:
	var q := QuadMesh.new()
	q.size = size
	var m := MeshInstance3D.new()
	m.name = node_name
	m.mesh = q
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var up := Vector3.FORWARD if absf(n.y) > 0.9 else Vector3.UP
	m.transform = Transform3D(Basis.looking_at(-n, up), centre)
	_built.add_child(m)


func _box(body: StaticBody3D, mat: Material, centre: Vector3, size: Vector3) -> void:
	var b := BoxMesh.new()
	b.size = size
	var m := MeshInstance3D.new()
	m.mesh = b
	m.material_override = mat
	m.position = centre
	_built.add_child(m)
	var shape := BoxShape3D.new()
	shape.size = size
	var c := CollisionShape3D.new()
	c.shape = shape
	c.position = centre
	body.add_child(c)
