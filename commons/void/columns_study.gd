extends RefCounted
## The museum's column profiles now span from their bases to the Void ceiling.
## Outline and sampling stay independent; all bodies share the same height.
## resolution_colonnade still generates the original materials and collisions.
const Columns = preload("res://commons/artifacts/resolution_colonnade/resolution_colonnade_museum.gd")
const Kit = preload("res://commons/artifacts/ignorance_gallery/gallery_kit.gd")
const CEILING_HEIGHT := 5.64 # Six-metre storey minus the 0.36 m upper slab.
const BODY_HEIGHT := CEILING_HEIGHT - Columns.PLINTH_HEIGHT
const MIXED_POSITIONS := [Vector3(-14.8,0,-5.6),Vector3(-14.8,0,5.6),Vector3(14.8,0,-5.6),Vector3(14.8,0,5.6),Vector3(-10,0,-5.5)]

static func build(hall: Node3D) -> void:
	var factory := Columns.new()
	for row in 5:
		for col in 5:
			var count: int=Columns.COUNTS[col]
			var sides := 16
			var rings := 8
			var kind := 0
			var metres := BODY_HEIGHT
			var width := 1.0
			var at := Vector3.ZERO
			var yaw := 0.0
			var family := ""
			var caption := ""
			match row:
				0:
					sides=count;at=Vector3(-6+col*3,0,-5.5);yaw=PI
					family="sides";caption="01 / %d SIDES"%count
				1:
					kind=col;at=Vector3(-18.5,0,5.4-col*2.7);yaw=-PI/2
					family="outline";caption="03 / "+Columns.Totem.PROFILE_NAMES[kind].to_upper()
				2:
					rings=count;at=Vector3(6-col*3,0,5.5)
					family="divisions";caption="02 / %d DIVISIONS"%count
				3:
					at=Vector3(18.5,0,-5.4+col*2.7);yaw=PI/2
					family="height";caption="04 / SAME HEIGHT"
				4:
					sides=count;rings=16;kind=(row+col)%Columns.Totem.PROFILE_NAMES.size()
					width=[1.0,.92,1.02,.96,1.0][(row*2+col)%5]
					at=MIXED_POSITIONS[col];yaw=PI if at.z<0 else 0.0
					family="composition";caption="05 / "+Columns.Totem.PROFILE_NAMES[kind].to_upper()
			factory._column("Column",Vector3.ZERO,sides,rings,kind,metres,width,caption)
			var group := Node3D.new()
			# Keep saved editor part IDs stable even when a comparison gets new values.
			group.name="Sides_%02d"%count if row==0 else "Grove_%02d_%02d"%[count,Columns.COUNTS[row]]
			group.position=at;group.rotation.y=yaw
			hall.add_child(group)
			for child in factory.get_children(): child.reparent(group,false)
			group.set_meta("comparison",family)
			group.set_meta("editor_label",caption.capitalize()+" / "+family)
			group.set_meta("radial_segments",sides);group.set_meta("profile_rings",rings)
			# Lift the existing cards to a reading height; a post makes the support real.
			group.get_node("Plaque_Column").position.y=.97
			for child in group.get_children():
				if child is Label3D:
					child.position.y=.97;child.font_size=27;child.pixel_size=.00175
					child.text=caption+"\n"+"%s / %.2f M"%[Columns.Totem.PROFILE_NAMES[kind].to_upper(),metres]+"\n%d SIDES / %d DIVISIONS"%[sides,rings]
			Kit.block(group,Vector3(.035,.74,.035),Vector3(0,.59,-.95),Color("343038"),false)
	factory.free()
	_grove(hall)
	# Signs and lighting are named children, so the editor can move/copy them too.
	_sign(hall,"SidesGuide","01 / AROUND THE COLUMN","4   6   8   12   16 sides\nVessel / 5.42 m / 8 profile divisions",Vector3(0,5.24,-4.48),0,Color("e9c18d"))
	_sign(hall,"DivisionsGuide","02 / ALONG THE PROFILE","4   6   8   12   16 divisions per curved section\nVessel / 5.42 m / 16 sides",Vector3(0,4.3,5.5),PI,Color("e9c18d"))
	_sign(hall,"OutlineGuide","03 / CHANGE THE OUTLINE","Vessel / Reed / Bell / Spindle / Cairn\nAll 5.42 m / 16 sides / 8 divisions",Vector3(-17.45,5.0,0),PI/2,Color("edb5ba"))
	_sign(hall,"HeightGuide","04 / MEET THE CEILING","Five identical bodies / one shared height\n5.42 m column + 0.22 m base = 5.64 m",Vector3(17.45,5.05,0),-PI/2,Color("b6ced8"))
	_sign(hall,"CompositionGuide","05 / MAKE A FAMILY","Combine the choices.\nMore divisions do not decide the better sculpture.",Vector3(-10,2.95,8.05),PI,Color("edb5ba"))
	for data in [["SidesLight",Vector3(0,4.6,-3.3),Vector3(0,2.3,-5.5),12.0],
		["DivisionsLight",Vector3(0,4.0,3.3),Vector3(0,1.6,5.5),12.0],
		["OutlineLight",Vector3(-15.8,4.8,0),Vector3(-18.5,2,0),11.0],
		["HeightLight",Vector3(15.8,4.8,0),Vector3(18.5,2,0),11.0]]:
		var light := SpotLight3D.new();light.name=data[0];light.position=data[1]
		light.light_color=Color("ffe8c6");light.light_energy=2.2
		light.spot_range=data[3];light.spot_angle=74;light.spot_attenuation=.65
		light.shadow_enabled=false
		hall.add_child(light);light.look_at(hall.to_global(data[2]))

static func _grove(hall: Node3D) -> void:
	# A walk-through interior, surrounded by the controlled comparison rows.
	# Keep the saved comparison parts intact; each added column is another part.
	var positions: Array[Vector3]=[]
	for x in [-5.0,-1.7,1.7,5.0]:
		for z in [-2.0,0.0,2.0]: positions.append(Vector3(x,0,z))
	for x in [-14.5,14.5]:
		for z in [-2.5,0.0,2.5]: positions.append(Vector3(x,0,z))
	positions.append_array([Vector3(10,0,-5.5),Vector3(10,0,5.5)])
	var factory := Columns.new()
	for i in positions.size():
		var kind := (i*3)%5
		var sides: int=Columns.COUNTS[(i*2)%5]
		var rings: int=Columns.COUNTS[(i+2)%5]
		var metres := BODY_HEIGHT
		var width: float=[.82,.95,.78,.90,1.0][i%5]
		factory._column("Column",Vector3.ZERO,sides,rings,kind,metres,width,"")
		var group := Node3D.new();group.name="InteriorColumn_%02d"%(i+1)
		group.position=positions[i];hall.add_child(group)
		for child in factory.get_children():
			# Comparisons carry the explanations. Leave room to walk among these bodies.
			if child is Label3D or child.name=="Plaque_Column": child.free()
			else: child.reparent(group,false)
		group.set_meta("grove_column",true)
		group.set_meta("editor_label","Grove %02d / %s / %.2f m / %d sides"%[i+1,Columns.Totem.PROFILE_NAMES[kind],metres,sides])
	factory.free()
	for x in [-3.35,3.35]:
		var lamp := OmniLight3D.new()
		lamp.name="GroveLightWest" if x<0 else "GroveLightEast"
		lamp.position=Vector3(x,3.8,0);lamp.light_color=Color("f6d0b1")
		lamp.light_energy=.85;lamp.omni_range=5.0;lamp.shadow_enabled=false
		hall.add_child(lamp)

static func _sign(hall: Node3D, id: String, title: String, note: String, at: Vector3, yaw: float, colour: Color) -> void:
	var sign := Node3D.new();sign.name=id;sign.position=at;sign.rotation.y=yaw
	hall.add_child(sign)
	Kit.block(sign,Vector3(5.5,.58,.045),Vector3.ZERO,Color("25232d"),false)
	var heading := Kit.label(sign,title,Vector3(0,.15,.028),.004);heading.modulate=colour
	var detail := Kit.label(sign,note,Vector3(0,-.12,.028),.0026);detail.modulate=Color("ede4d5")
