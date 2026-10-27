extends Node3D
## Fixed monochrome comparisons before colour. Each operation has its own field.
const Pattern = preload("res://commons/artifacts/regularity/tiling_pattern.gd")
const RuleStudy = preload("res://commons/artifacts/regularity/tiling_rule_study.gd")
const Kit = preload("res://commons/artifacts/regularity/room_tools.gd")
const TITLES := ["TRANSLATE", "ALTERNATE", "QUARTER TURN", "REFLECT", "SHIFT ROWS", "ONE EXCEPTION"]
## The RULES button: the six fields become six ADDRESS RULES (address_rules.gd, the palette floor's
## twenty rules) setting each tile's turn, mirror or inversion; pressed again, the hall's six return.
## Off at load, so both tiling halls open as they always have. The hall's own relations are rules of
## this kind already: ALTERNATE is sum at 2 states setting the inversion, QUARTER TURN sum at 4.
const RULE_FIELDS := [
	["scatter", "turn", "triangle", "TRUCHET / CHANCE TURNS"],
	["scatter", "turn", "quarters", "QUARTER CIRCLES / CHANCE"],
	["pascal", "invert", "triangle", "PASCAL / INVERT"],
	["xor", "turn", "triangle", "XOR / TURN"],
	["rings", "turn + invert", "triangle", "RINGS / TURN + INVERT"],
	["spiral", "turn", "triangle", "SPIRAL / TURN"],   # at 2 states the spiral is the sum checkerboard; at 4 it is its own
]
signal patterns_changed
var walls := false
var phase := 0
var exception := false
var rules_mode := false
var titles: Array[Label3D] = []
var surfaces: Array[MeshInstance3D] = []
var readout: Label
var rule_study: Node3D

func _ready() -> void:
	walls = str(get_meta("config_mode","floor")) == "walls"
	for i in 6:
		var at: Vector3
		var turn: Vector3
		if walls:
			at = Vector3(-6.7 if i%2==0 else 6.7,2.7,float(i/2)*6.0-6.0)
			turn = Vector3(0,90 if i%2==0 else -90,0)
			Kit.box(self,"WallBacking",at,Vector3(0.12,5.4,5.2),Color(0.08,0.08,0.08))
			# Offset into the room, clear of the solid backing.
			at.x += 0.07 if i%2==0 else -0.07
			titles.append(Kit.label(self,TITLES[i],at+Vector3(0,3.0,0),turn.y))
		else:
			at = Vector3(-3.2 if i%2==0 else 3.2,0.025,float(i/2)*6.0-6.0)
			turn = Vector3(-90,0,0)
			titles.append(Kit.label(self,TITLES[i],at+Vector3(0,0.45,-2.5),180))
		surfaces.append(Kit.textured_plane(self,"Rule_"+str(i),Vector2(5.0,5.0),at,turn,texture_for(i)))
	var p := Kit.panel(self,"ONE MOTIF / SIX RELATIONS",Vector3(0,1.2,-10.1))
	p.add_button("TURN MOTIF").pressed.connect(turn_motif)
	p.add_button("EXCEPTION").pressed.connect(toggle_exception)
	p.add_button("RULES").pressed.connect(toggle_rules)
	readout = p.add_readout("BLACK / WHITE | same tile, different rules")
	rule_study = RuleStudy.new()
	rule_study.name = "LocalRuleStudy"
	add_child(rule_study)

func apply_grid_config(_config: Dictionary) -> void:
	pass # mode is read once from grid metadata before construction.

func turn_motif() -> void:
	phase = (phase+1)%4
	refresh()

func toggle_exception() -> void:
	exception = not exception
	refresh()

func toggle_rules() -> void:
	rules_mode = not rules_mode
	refresh()

func refresh() -> void:
	for i in surfaces.size(): surfaces[i].material_override.albedo_texture = texture_for(i)
	for i in titles.size(): titles[i].text = RULE_FIELDS[i][3] if rules_mode else TITLES[i]
	if rules_mode:
		readout.text = "RULES | MOTIF %d degrees | each address chooses the turn" % [phase*90]
	else:
		readout.text = "MOTIF %d degrees | exception %s" % [phase*90,"ON" if exception else "OFF"]
	patterns_changed.emit()

func texture_for(rule: int) -> ImageTexture:
	if rules_mode:
		var f: Array = RULE_FIELDS[rule]
		return ImageTexture.create_from_image(Pattern.rule_image(f[0], f[1], f[2], phase))
	return ImageTexture.create_from_image(Pattern.image_for(rule, phase, exception))
