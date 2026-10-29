extends Node3D
## Paint the wood: six of the kit's one-metre timber panels on an easel wall, emulsion tins and stain
## jars on a bench. A coat of emulsion lays its colour over what is there by its share (one coat 70 %,
## so the grain still shows; two coats 91 %); a coat of stain (85 %) filters everything beneath it, multiplying,
## so cyan stain over yellow stain is green. All mixing in linear light. SAND takes every panel back to
## bare wood. The panels stay the kit's own carryable panels: a painted one can be taken and built with.
const TimberPanel := preload("res://commons/artifacts/primitive_encounters/timber_panel_1x1.tscn")
const Timber := preload("res://commons/artifacts/primitive_encounters/timber_finish.gd")
const Bucket := preload("bucket.gd")
const PaintShader := preload("paint_wood.gdshader")
const ButtonScene := preload("res://commons/interactables/cube_button.tscn")
const COVER_SHARE := 0.7
const GLAZE_SHARE := 0.85
## paint name, colour, finish
const PAINTS := [["RED","d63a2f","cover"],["YELLOW","f2c230","cover"],["BLUE","2a4fb8","cover"],["WHITE","f4f0e6","cover"],["BLACK","1d1d1f","cover"],["PINK","ec8fba","cover"],
	["CYAN","00a6d6","glaze"],["MAGENTA","d6248f","glaze"],["YELLOW","f2d000","glaze"]]
const WOOD_MEAN := Color("b48a5c")   # the wood texture's mean under its tint, for the readout's estimate only
var panels: Array[Dictionary] = []
var by_body: Dictionary = {}
var readout: Label3D

func _ready() -> void:
	# the easel: two posts, three rails, all of the kit's timber, static
	for x in [-1.62, 1.62]:_wood("Post", Vector3(x, 1.35, -.08), Vector3(.09, 2.7, .25))
	for y in [.38, 1.475, 2.55]:_wood("Rail", Vector3(0, y, -.08), Vector3(3.33, .09, .09))
	for row in 2:
		for col in 3:
			var p: Node3D = TimberPanel.instantiate();p.name = "Panel%d" % (row * 3 + col + 1)
			p.position = Vector3((col - 1) * 1.05, .45 + row * 1.05 + .5, -.03);p.rotation_degrees.x = 90
			add_child(p)
			var sheet: MeshInstance3D = p.get_node("TimberSheet")
			var mat := ShaderMaterial.new();mat.shader = PaintShader
			var wood := Timber.material();mat.set_shader_parameter("wood", wood.albedo_texture);mat.set_shader_parameter("wood_tint", wood.albedo_color)
			sheet.material_override = mat   # this panel's own: the shared timber finish is not touched
			var state := {"node": p, "mat": mat, "cover": Color(1, 1, 1), "a": 0.0, "glaze": Color(1, 1, 1), "coats": [] as Array[String], "tween": null}
			panels.append(state);by_body[p.get_instance_id()] = state
	# the bench and what is on it
	_wood("BenchTop", Vector3(0, .62, 1.0), Vector3(3.4, .06, .5))
	for x in [-1.5, 1.5]:_wood("BenchLeg", Vector3(x, .3, 1.0), Vector3(.1, .6, .44))
	for i in PAINTS.size():
		var b: Node3D = Bucket.new();b.name = ("Stain" if PAINTS[i][2] == "glaze" else "Tin") + str(PAINTS[i][0]).capitalize()
		b.paint = Color(PAINTS[i][1]);b.paint_name = PAINTS[i][0];b.finish = PAINTS[i][2];b.station = weakref(self)
		b.position = Vector3(-1.48 + i * .345, .65, 1.0);add_child(b)
	var button: Node3D = ButtonScene.instantiate();button.name = "SAND";button.label = "SAND";button.cube_size = .055;button.cap_color = Color("b48a5c")
	button.position = Vector3(1.55, .68, 1.32);add_child(button);button.pressed.connect(sand)
	readout = Label3D.new();readout.name = "Readout";readout.font_size = 26;readout.pixel_size = .0016;readout.position = Vector3(0, .5, 1.27);readout.rotation_degrees.x = -12
	readout.modulate = Color("f4f0e6");readout.outline_size = 6;readout.outline_modulate = Color(0, 0, 0, .7);add_child(readout)
	var sign := Label3D.new();sign.name = "Sign";sign.font_size = 34;sign.pixel_size = .0018;sign.position = Vector3(0, 2.82, 0);sign.modulate = Color("f4f0e6")
	sign.text = "PAINT THE WOOD\nA TIN COVERS WHAT IS THERE · A STAIN FILTERS WHAT IS BENEATH";add_child(sign)
	_say("HOLD A TIN OR A JAR · AIM AT A PANEL · PULL THE TRIGGER")

func _wood(id: String, at: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new();body.name = id;body.position = at;add_child(body)
	var m := MeshInstance3D.new();m.mesh = Timber.mesh(size);m.material_override = Timber.material();body.add_child(m)
	var s := CollisionShape3D.new();var b := BoxShape3D.new();b.size = size;s.shape = b;body.add_child(s)

## One coat on whatever panel `body` is; false when it is not one of these panels.
func coat_body(body: Object, paint: Color, finish: String, name: String) -> bool:
	if body == null or not by_body.has(body.get_instance_id()):return false
	coat(panels.find(by_body[body.get_instance_id()]), paint, finish, name);return true

func coat(index: int, paint: Color, finish: String, name: String) -> void:
	var s: Dictionary = panels[index];var c := paint.srgb_to_linear()
	if finish == "glaze":
		s.glaze = Color(s.glaze.r * lerpf(1, c.r, GLAZE_SHARE), s.glaze.g * lerpf(1, c.g, GLAZE_SHARE), s.glaze.b * lerpf(1, c.b, GLAZE_SHARE))
	else:
		var a: float = s.a;var na := COVER_SHARE + a * (1.0 - COVER_SHARE)
		var prev: Color = s.cover
		s.cover = Color((c.r * COVER_SHARE + prev.r * a * (1 - COVER_SHARE)) / na, (c.g * COVER_SHARE + prev.g * a * (1 - COVER_SHARE)) / na, (c.b * COVER_SHARE + prev.b * a * (1 - COVER_SHARE)) / na)
		s.a = na
		s.glaze = Color(lerpf(s.glaze.r, 1, COVER_SHARE), lerpf(s.glaze.g, 1, COVER_SHARE), lerpf(s.glaze.b, 1, COVER_SHARE))   # emulsion hides the stain beneath
	(s.coats as Array).append(name + (" STAIN" if finish == "glaze" else ""))
	_show(s, true)
	_say("PANEL %d · %s\n≈ %s · #%s" % [index + 1, " · ".join(PackedStringArray(s.coats)), colour_name(shown(index)), shown(index).to_html(false).to_upper()])

func _show(s: Dictionary, wet: bool) -> void:
	var mat: ShaderMaterial = s.mat
	mat.set_shader_parameter("cover", (s.cover as Color).linear_to_srgb());mat.set_shader_parameter("cover_a", s.a)
	mat.set_shader_parameter("glaze", (s.glaze as Color).linear_to_srgb())
	if wet:   # fresh paint shines, and dries over four seconds
		if s.tween != null and (s.tween as Tween).is_valid():(s.tween as Tween).kill()
		mat.set_shader_parameter("wet", 1.0)
		if is_inside_tree():
			var t := create_tween();t.tween_method(func(v: float):mat.set_shader_parameter("wet", v), 1.0, 0.0, 4.0);s.tween = t
	else:
		mat.set_shader_parameter("wet", 0.0)

## Back to bare wood, every panel.
func sand() -> void:
	for s in panels:
		s.cover = Color(1, 1, 1);s.a = 0.0;s.glaze = Color(1, 1, 1);(s.coats as Array).clear();_show(s, false)
	_say("SANDED · BARE WOOD")

## What a panel shows on average, as sRGB: the wood's mean under the coats (the readout's estimate).
func shown(index: int) -> Color:
	var s: Dictionary = panels[index];var w := WOOD_MEAN.srgb_to_linear();var a: float = s.a
	var c: Color = s.cover;var g: Color = s.glaze
	return Color((w.r * (1 - a) + c.r * a) * g.r, (w.g * (1 - a) + c.g * a) * g.g, (w.b * (1 - a) + c.b * a) * g.b).linear_to_srgb()

static func colour_name(c: Color) -> String:
	if c.s < .18:return "WHITE" if c.v > .82 else ("BLACK" if c.v < .2 else "GREY")
	if c.v < .22:return "BLACK"
	var h := c.h * 360.0
	if h < 15 or h >= 345:return "RED"
	if h < 40:return "BROWN" if c.v < .6 else "ORANGE"
	if h < 68:return "OLIVE" if c.v < .5 else "YELLOW"
	if h < 160:return "GREEN"
	if h < 200:return "CYAN"
	if h < 245:return "BLUE"
	if h < 275:return "BLUE-VIOLET"   # what real cyan and magenta make
	if h < 300:return "VIOLET"
	return "PINK" if c.v > .75 and c.s < .55 else "MAGENTA"

func _say(text: String) -> void:
	if readout != null:readout.text = text

func apply_grid_config(_config: Dictionary) -> void:
	pass
