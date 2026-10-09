extends Node3D
## Fixed monochrome comparisons before colour. Each operation has its own field.
const Kit = preload("res://commons/artifacts/regularity/room_tools.gd")
const TITLES := ["TRANSLATE", "ALTERNATE", "QUARTER TURN", "REFLECT", "SHIFT ROWS", "ONE EXCEPTION"]
var walls := false
var phase := 0
var exception := false
var surfaces: Array[MeshInstance3D] = []
var readout: Label

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
			Kit.label(self,TITLES[i],at+Vector3(0,3.0,0),turn.y)
		else:
			at = Vector3(-3.2 if i%2==0 else 3.2,0.025,float(i/2)*6.0-6.0)
			turn = Vector3(-90,0,0)
			Kit.label(self,TITLES[i],at+Vector3(0,0.45,-2.5),180)
		surfaces.append(Kit.textured_plane(self,"Rule_"+str(i),Vector2(5.0,5.0),at,turn,texture_for(i)))
	var p := Kit.panel(self,"ONE MOTIF / SIX RELATIONS",Vector3(0,1.2,-10.1))
	p.add_button("TURN MOTIF").pressed.connect(turn_motif)
	p.add_button("EXCEPTION").pressed.connect(toggle_exception)
	readout = p.add_readout("BLACK / WHITE | same tile, different rules")

func apply_grid_config(_config: Dictionary) -> void:
	pass # mode is read once from grid metadata before construction.

func turn_motif() -> void:
	phase = (phase+1)%4
	refresh()

func toggle_exception() -> void:
	exception = not exception
	refresh()

func refresh() -> void:
	for i in surfaces.size(): surfaces[i].material_override.albedo_texture = texture_for(i)
	readout.text = "MOTIF %d degrees | exception %s" % [phase*90,"ON" if exception else "OFF"]

func texture_for(rule: int) -> ImageTexture:
	var image_ := Image.create(256,256,false,Image.FORMAT_RGB8)
	for y in 256:
		for x in 256:
			var px := x
			var cy := y/32
			if rule == 4: px += (cy%2)*16
			var cx := px/32
			var u := px%32
			var v := y%32
			var rotation := phase
			if rule == 2: rotation += (cx+cy)%4
			if rule == 5 and exception and cx==3 and cy==3: rotation += 1
			for r in rotation%4:
				var old_u := u
				u = v
				v = 31-old_u
			if rule == 3 and cx%2==1: u = 31-u
			var black := u > v
			if rule == 1 and (cx+cy)%2==1: black = not black
			image_.set_pixel(x,y,Color.BLACK if black else Color.WHITE)
	return ImageTexture.create_from_image(image_)
