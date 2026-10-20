extends Node3D
## Four floor groups; distinguish the distribution's tail before the certain ending.
const Table = preload("guess_table.gd")
const WallText = preload("wall_text.gd")
const Objects = preload("objects.gd")
var kind := 6
var versions: Array[Node3D] = []
var wall_text: Node3D

func _ready() -> void:
	set_meta("em_keep_scale",true)
	for i in 4:
		var table:=Table.new()
		table.baseline=[[8,8,0],[8,4,4],[12,4,0],[16,0,0]][i]
		table.movable=true
		table.floor_mode=true
		table.cohort=["A","B","C","D"][i]
		table.title=["A / TWO TYPES","B / THREE TYPES","C / PINK MORE LIKELY","D / COLOUR CERTAIN — MOVE THE CHAIRS"][i]
		table.position=Vector3((-1 if i%2==0 else 1)*4.4,0,2.4 if i<2 else -2.4)
		add_child(table);versions.append(table)
	wall_text=WallText.new();wall_text.heading="7 / ONE GUESS"
	wall_text.explanation="Four pyramids: 9 + 4 + 2 + 1 full-size chairs each.\nGrab a support or walk into the stack. What changes?\nChoose a type, then DRAW: each group has 16 equal chances.\nThe gold ring marks an ID; drawing does not move it.\nEach chair keeps its lettered group wherever it goes."
	wall_text.comparisons="A: 8/8 — H-min 1, Shannon 1 bit\nB: 8/4/4 — H-min 1, Shannon 1.5 bits\nB records colour + arms; colour alone still gives 1 bit.\nC: 12/4 — best 75%; D: all pink — best 100%.\nSeeded draws illustrate the declared probabilities.\nKnowing the generator state can reveal the next ID."
	wall_text.comparisons+="\nA pile changes space, not the best colour guess.\nCHANGE ONE changes a type; RESET rebuilds the pyramid."
	wall_text.position=Vector3(-8.48,1.42,0);wall_text.rotation_degrees.y=90
	add_child(wall_text)
