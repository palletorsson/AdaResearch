extends Node3D
## Simultaneous versions at everyday scale. The visitor compares by moving and looking.
const Encounter=preload("encounter.gd")
const BestGuess=preload("best_guess.gd")
const Objects=preload("objects.gd")
const WallText=preload("wall_text.gd")
const Typeface=preload("res://commons/utils/baked_text_albedo.gd")
@export_range(0,6) var kind:=0
var versions: Array[Node3D]=[]
var wall_text: Node3D
var elapsed:=0.0
var automatic:=true
var last_step:=-1
const WALL_POSITIONS=[Vector3(3.48,1.42,0),Vector3(-4.48,1.42,0),Vector3(-8.48,1.42,0),Vector3(2.25,1.42,0.18),Vector3(5.48,1.42,0),Vector3(8.48,1.42,0),Vector3(-8.48,1.42,0)]
const WALL_TURNS=[-90,90,90,0,-90,-90,90]
const EXPLANATIONS=[
 "Four inventories, eight chairs each. Imagine drawing one chair\nat equal chance, returning it, and recording only its colour.\nShannon entropy measures uncertainty in that next colour.\nRearranging the same colours leaves their probabilities intact.\nA more predictable colour gives a smaller reading.",
 "Each version has four pink and four black chairs on eight sites.\nThe brief keeps only the number of pink chairs on the left.\nA macrostate is this partial description; a microstate assigns\na colour to every site. Omega counts matching assignments.\nChairs of the same colour are treated as interchangeable.",
 "Four groups become harder to recognise as a simple pattern.\nTheir recipes remain beside them on this wall. Even the scatter\ncomes from a short seeded generator. Algorithmic complexity\nasks for the shortest generating program in a chosen language.\nThese are candidate recipes, not measured shortest programs.",
 "Two driven door pairs repeat the same nine-step cycle.\nThe translucent leaf starts just 1/512 of the range away.\nClosing halves the angle; expanding doubles it and wraps.\nLOW/HIGH records divide the angle range into two bins.\nCompare growing records across 1024 equally likely starts.",
 "Five cups, one table; the same 25% milk in each surface.\nWhite swirls become an even mixture. This is an illustration:\nthe swirl image does not give a thermodynamic entropy.\nSeparately, the labelled cooling model transfers heat from\neach cup to a finite bath. Its combined entropy increases.",
 "One chair, five panes. Each label declares a record.\nBefore it, eight identities are equally likely: two colours,\nwith or without arms, with or without a lower back rail.\nConditional entropy counts what the record leaves unknown.\nC and D look different but keep the same colour record.",
 "The same question at all three trays: which colour comes next?\nImagine choosing one ball with equal chance, then returning it.\nAll balls have the same size. Only the colour counts change.\nChoose the colour that would win most often.\nMin-entropy is -log2(that chance): easier guessing, fewer bits."
]
const COMPARISONS=[
 "A  4 pink / 4 black: H = 1 bit\nB  Same counts, new places: H = 1 bit\nC  7 pink / 1 black: H = 0.544 bits\nD  8 pink / 0 black: H = 0 bits",
 "A  4 pink on left: Omega = 1; S/kB = 0\nB  2 pink on left: Omega = 36; S/kB = 3.584\nC  Another matching arrangement: the same 36\nColour-draw H = 1 bit in all three. A counting model, not heat.",
 "1  Two rows of three chairs\n2  Same grid, one chair shifted and turned\n3  Repeat a three-chair offset motif\n4  Jitter positions and turns: seed 435 + shared generator",
 "A  Closing: H(8-symbol record) = 1 bit\nB  Expanding: H(8-symbol record) = 8 bits\nFinite record comparison, not a measured asymptotic rate.\nThe centre doorway stays open. Cycle step: 0 / 8",
 "", # Thermal readings are generated from the model in _ready().
 "A  Identity: 1 candidate remains / H = 0 bits\nB  Colour + arms: 2 candidates / H = 1 bit\nC  Colour: 4 candidates / H = 2 bits\nD  Colour again: 4 candidates / H = 2 bits\nE  No detail: all 8 candidates / H = 3 bits\nDeclared records, not measurements of human recognition.",
 "A  8 pink / 8 teal: either guess wins 8/16; H-min = 1 bit\nB  12 pink / 4 teal: pink wins 12/16; H-min = 0.415 bits\nC  16 pink / 0 teal: pink wins 16/16; H-min = 0 bits\nShannon averages surprise over outcomes. Min-entropy\nasks only how likely the most likely outcome is."
]

func _ready() -> void:
	match kind:
		0:
			for i in 4:
				var p:=Vector3((i%2-0.5)*3.8,0,(0.5-i/2)*4.0)
				version(p,[0,0,2,1][i],436 if i==1 else 435)
				caption(["A / 4 : 4","B / 4 : 4","C / 7 : 1","D / 8 : 0"][i],p+Vector3(0,0.018,1.15))
		1:
			for i in 3:
				var p:=Vector3((i-0.5)*3.8 if i<2 else 0.0,0,2.0 if i<2 else -2.0)
				version(p,0 if i==0 else 1,436 if i==2 else 435)
				caption(["A / 1 assignment","B / 36 assignments","C / 36 assignments"][i],p+Vector3(0,0.02,1.15))
		2:version(Vector3.ZERO,1)
		3:
			build_door_wall()
			version(Vector3(4.5,0,0),0);version(Vector3(-4.5,0,0),1);version(Vector3.ZERO,2)
			caption("A / CLOSING",Vector3(4.5,0.02,2.8));caption("B / EXPANDING",Vector3(-4.5,0.02,2.8))
		4:
			Objects.table(self,3.6,1.1);build_donut_plate()
			for i in 5:
				var p:=Vector3((i-2)*0.55,0,0.22)
				var copy:=version(p,0);copy.seconds=Encounter.TIMES[i];copy.mixing=float(i)/4;copy.milk_fraction=0.25;copy.rebuild()
				Objects.ink(self,"%s / %d s" % ["ABCDE"[i],Encounter.TIMES[i]],p+Vector3(0,0.67,0.35),24,0.0016)
		5:
			for i in 5:
				var p:=Vector3((i-2)*2.6,0,0)
				var copy:=version(p,[0,3,1,1,2][i]);copy.selected=3;copy.glass_obscurity=[0.0,0.16,0.4,0.78,1.0][i];copy.rebuild()
				caption(["A / IDENTITY","B / COLOUR + ARMS","C / COLOUR","D / COLOUR","E / NO DETAIL"][i],p+Vector3(0,0.02,1.1))
		6:
			for i in 3:
				var p:=Vector3((i-1)*5.0,0,0)
				var copy:=BestGuess.new();copy.pink_count=[8,12,16][i];copy.position=p;add_child(copy);versions.append(copy)
				caption(["A / HALF THE CHANCES","B / THREE QUARTERS","C / CERTAIN"][i],p+Vector3(0,0.02,1.75))
	wall_text=WallText.new();wall_text.heading=Encounter.TITLES[kind]
	wall_text.explanation=EXPLANATIONS[kind];wall_text.comparisons=COMPARISONS[kind]
	# Derive the thermal captions from the same model as the visible snapshots.
	if kind==4:
		var lines: Array[String]=[]
		for i in 5:
			var t: float=versions[i].seconds;var heat: Dictionary=Encounter.Model.thermal(t)
			lines.append("%s  %d s: cup %.1f K; bath %.1f K; total +%.2f J/K" % ["ABCDE"[i],t,heat.hot,heat.cold,heat.total])
		wall_text.comparisons="\n".join(lines)+"\nFixed thermal snapshots. Animated swirls do not drive this model."
	wall_text.position=WALL_POSITIONS[kind];wall_text.rotation_degrees.y=WALL_TURNS[kind];add_child(wall_text)
	set_process(kind in [3,4])
	if kind==3:advance_doors(0)

func version(p: Vector3,state: int,seed_value: int=435) -> Node3D:
	var copy:=Encounter.new();copy.kind=kind;copy.controls_enabled=false
	if kind==4:copy.cup_table_enabled=false
	copy.chair_spacing=0.86;copy.setting=state;copy.experiment_seed=seed_value
	copy.position=p;add_child(copy);versions.append(copy);return copy

func caption(words: String,p: Vector3) -> void:
	var label:=Label3D.new();add_child(label);label.text=words;label.position=p
	label.rotation_degrees.x=-90;label.font=Typeface.project_font()
	label.font_size=32;label.pixel_size=0.002;label.outline_size=0;label.modulate=Objects.DARK

func _process(delta: float) -> void:
	if not automatic:return
	elapsed+=delta
	if kind==3:advance_doors(mini(8,int(fposmod(elapsed,11.0))))
	elif kind==4:
		for copy in versions:copy.coffee_clock=elapsed;copy.coffee.set_shader_parameter("clock",copy.coffee_clock)

func build_door_wall() -> void:
	var wall:=Node3D.new();wall.name="DoorWall";add_child(wall)
	for ends in [Vector2(-9,-5.73),Vector2(-3.27,-1.23),Vector2(1.23,3.27),Vector2(5.73,9)]:
		Objects.box(wall,Vector3((ends.x+ends.y)/2,1.165,0),Vector3(ends.y-ends.x,2.33,0.24),Color("d4d0c2"),true)
	Objects.box(wall,Vector3(0,2.49,0),Vector3(18,0.32,0.24),Color("d4d0c2"),true)

func build_donut_plate() -> void:
	var plate:=Objects.lathe(self,[Vector2(0,0),Vector2(0.17,0),Vector2(0.195,0.02),Vector2(0.18,0.025),Vector2(0.13,0.012),Vector2(0,0.012)],Vector3(0,0.752,-0.25),Color("eee8dd"));plate.name="Plate"
	var mesh:=TorusMesh.new();mesh.inner_radius=0.035;mesh.outer_radius=0.105;mesh.rings=40;mesh.ring_segments=16
	var donut:=MeshInstance3D.new();donut.name="Donut";donut.mesh=mesh;donut.material_override=Objects.material(Color("bb713c"));add_child(donut);donut.position=Vector3(0,0.80,-0.25)

func advance_doors(step: int) -> void:
	if step==last_step:return
	last_step=step
	for i in 2:versions[i].steps=step;versions[i].update_motion()
	wall_text.reading.text=COMPARISONS[3].replace("Cycle step: 0 / 8","Cycle step: %d / 8" % step)
