extends RefCounted
## White adjustable worktable and clear specimen chamber; visual reference, not a new kit part.
const Kit=preload("res://commons/artifacts/primitive_encounters/geometry.gd")
const Gate=preload("chamber_gate.gd")
static func tube(parent:Node,title:String,a:Vector3,b:Vector3,radius:float,color:Color,solid:bool=false)->MeshInstance3D:
	var mesh:=MeshInstance3D.new();mesh.name=title;var cylinder:=CylinderMesh.new()
	cylinder.top_radius=radius;cylinder.bottom_radius=radius;cylinder.height=a.distance_to(b);cylinder.radial_segments=16
	mesh.mesh=cylinder;mesh.material_override=Kit.material(color);mesh.position=(a+b)*.5
	mesh.quaternion=Quaternion(Vector3.UP,(b-a).normalized());parent.add_child(mesh)
	if solid:
		var body:=StaticBody3D.new();var shape:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new()
		capsule.radius=radius;capsule.height=maxf(radius*2,cylinder.height);shape.shape=capsule;body.add_child(shape);mesh.add_child(body)
	return mesh
static func table(parent:Node3D)->void:
	var white:=Color("e7e9e4");var chrome:=Color("969f9f")
	# The near-edge grid is fully supported, with a visible margin in front.
	Kit.box(parent,"Worktop",Vector3(0,1.05,.16),Vector3(2.2,.10,1.72),white)
	for x in [-1.08,1.08]:tube(parent,"RoundedRim",Vector3(x,1.055,-.65),Vector3(x,1.055,.975),.045,white)
	tube(parent,"FrontRim",Vector3(-1.06,1.055,.975),Vector3(1.06,1.055,.975),.045,white)
	for x in [-.88,.88]:
		tube(parent,"AdjustableLeg",Vector3(x,.12,0),Vector3(x,1.02,0),.047,white,true)
		tube(parent,"Collar",Vector3(x,.62,0),Vector3(x,.86,0),.058,chrome)
		tube(parent,"Foot",Vector3(x,.065,-.57),Vector3(x,.065,.57),.047,white,true)
		for z in [-.57,.57]:tube(parent,"RubberFoot",Vector3(x,.065,z-.055),Vector3(x,.065,z+.055),.052,Color("40494a"))
		tube(parent,"HeightLever",Vector3(x,.67,0),Vector3(x+.13,.67,0),.018,chrome)
	tube(parent,"CrossBrace",Vector3(-.88,.22,0),Vector3(.88,.22,0),.03,white,true)
	Kit.box(parent,"FrontApron",Vector3(0,.93,.93),Vector3(1.85,.14,.055),white,false)
	var title:=Kit.label(parent,"ASSEMBLY / 1 : 10",Vector3(0,.94,.962),20);title.modulate=Color("556165")
	# Recessed perimeter details stay below the hand model and its stock.
	for x in [-1.02,1.02]:
		Kit.box(parent,"InsetSeam",Vector3(x,1.102,.16),Vector3(.008,.002,1.5),chrome,false)
	for x in [-.98,.98]:
		for z in [-.57,.57]:
			var screw:=Kit.box(parent,"FlushFastener",Vector3(x,1.104,z),Vector3(.018,.003,.018),chrome,false)
			screw.rotation.y=PI/4

static func visor_table(parent:Node3D)->Node3D:
	# A separate landing for the visor, just forward of the right-hand corner.
	# Table and glasses share Controls, so moving that group keeps them together.
	var dock:=Node3D.new();dock.name="HeadsetDock";parent.add_child(dock)
	dock.position=Vector3(1.35,1.04,1.32)
	var white:=Color("e7e9e4");var chrome:=Color("969f9f")
	Kit.box(dock,"SideTableTop",Vector3(0,-.04,0),Vector3(.60,.08,.50),white)
	for x in [-.22,.22]:
		tube(dock,"SideTableLeg",Vector3(x,-.97,0),Vector3(x,-.08,0),.032,white,true)
		tube(dock,"SideTableCollar",Vector3(x,-.48,0),Vector3(x,-.34,0),.041,chrome)
		tube(dock,"SideTableFoot",Vector3(x,-.99,-.17),Vector3(x,-.99,.17),.03,white,true)
		for z in [-.17,.17]:Kit.box(dock,"RubberFoot",Vector3(x,-1.018,z),Vector3(.09,.024,.08),Color("40494a"),false)
	tube(dock,"LowBrace",Vector3(-.22,-.82,0),Vector3(.22,-.82,0),.022,chrome)
	Kit.box(dock,"Rest",Vector3(0,.007,-.035),Vector3(.35,.014,.28),Color("879b96"),false)
	var label:=Kit.label(dock,"WEAR TO ENTER / ¼ SIZE",Vector3(0,.003,.18),11)
	label.rotation.x=-PI/2;label.modulate=Color("203333")
	var front:=Kit.label(dock,"MODEL VISOR",Vector3(0,-.04,.253),12);front.modulate=Color("455657")
	return dock

static func panel_shell(parent:Node3D,panel:Node3D,size:Vector2,vertical:bool=false)->void:
	# Close the wedge down to the tabletop: no hovering plates or unsupported text.
	var corners:=PackedVector3Array()
	for corner in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
		var p:=Vector3(corner.x*size.x*.5,corner.y*size.y*.5,-.012) if vertical else Vector3(corner.x*size.x*.5,-.012,corner.y*size.y*.5)
		corners.append(panel.transform*p)
	for i in 4:corners.append(Vector3(corners[i].x,1.10,corners[i].z))
	Kit.solid(parent,str(panel.name)+"Housing",corners,[[0,1,2,3],[7,6,5,4],[0,4,5,1],[1,5,6,2],[2,6,7,3],[3,7,4,0]],Color("b9c4c0"),false)

static func control_plate(parent:Node3D)->Node3D:
	var plate:=Node3D.new();plate.name="ControlPlate";parent.add_child(plate)
	plate.position=Vector3(.73,1.20,.54);plate.rotation.x=deg_to_rad(12)
	panel_shell(parent,plate,Vector2(.50,.78))
	Kit.box(plate,"Faceplate",Vector3.ZERO,Vector3(.50,.024,.78),Color("25343b"),false)
	var title:=Kit.label(plate,"OPERATE",Vector3(0,.014,-.325),12);title.rotation.x=-PI/2;title.modulate=Color("bbc9c5")
	for x in [-.224,.224]:
		for z in [-.362,.362]:Kit.box(plate,"Fastener",Vector3(x,.014,z),Vector3(.012,.003,.012),Color("9caaa6"),false)
	return plate

static func rectangular_button(scene:PackedScene)->Node3D:
	# Keep the established pointer, hand collider, press signal, sound and haptics.
	var button:Node3D=scene.instantiate()
	var cap:=BoxMesh.new();cap.size=Vector3(.075,.02,.047)
	button.get_node("Button/ButtonMesh").mesh=cap
	var shape:=BoxShape3D.new();shape.size=Vector3(.075,.024,.047)
	button.get_node("Button/CollisionShape3D").shape=shape
	var area:=BoxShape3D.new();area.size=Vector3(.089,.056,.061)
	button.get_node("InteractableAreaButton/CollisionShape3D").shape=area
	button.get_node("AccentRing").hide()
	return button

static func discard_basket(parent:Node3D)->Node3D:
	var basket:=Node3D.new();basket.name="DiscardBasket";parent.add_child(basket)
	basket.position=Vector3(-.74,1.10,.85)
	var grey:=Color("8b9e9a")
	Kit.box(basket,"Base",Vector3(0,.009,0),Vector3(.32,.018,.26),Color("33423f"),false)
	for x in [-.153,.153]:
		for y in [.04,.095,.15]:tube(basket,"Wire",Vector3(x,y,-.123),Vector3(x,y,.123),.006,grey)
		for z in [-.12,0,.12]:tube(basket,"Upright",Vector3(x,.018,z),Vector3(x,.155,z),.005,grey)
	for z in [-.123,.123]:
		for y in [.04,.095,.15]:tube(basket,"Wire",Vector3(-.153,y,z),Vector3(.153,y,z),.006,grey)
		for x in [-.10,0,.10]:tube(basket,"Upright",Vector3(x,.018,z),Vector3(x,.155,z),.005,grey)
	Kit.box(basket,"Nameplate",Vector3(0,.075,.133),Vector3(.20,.065,.008),Color("25343b"),false)
	var label:=Kit.label(basket,"REMOVE",Vector3(0,.075,.138),12);label.modulate=Color("deebe7")
	return basket

static func work_area(parent:Node3D,bay_at:Vector3,size:float)->void:
	# One floor-level footprint: six-metre result bay, joined counter and approach.
	# Belongs to Support so it follows this editable group, not the miniature graph.
	var zone:=Node3D.new();zone.name="SafetyZone";parent.add_child(zone)
	var half:float=size*.5+.30
	var back:float=bay_at.z-half;var front:=2.2
	zone.set_meta("workshop_safe_rect",Rect2(bay_at.x-half,back,half*2,front-back))
	zone.add_to_group("workshop_safe_zones")
	var amber:=Color("d4b759")
	for x in [bay_at.x-half,bay_at.x+half]:
		Kit.box(zone,"BoundaryTape",Vector3(x,.018,(back+front)*.5),Vector3(.08,.004,front-back),amber,false)
	Kit.box(zone,"BoundaryTape",Vector3(bay_at.x,.018,back),Vector3(half*2,.004,.08),amber,false)
	# An open entrance makes the tape a readable threshold, not another barrier.
	for side in [-1,1]:
		Kit.box(zone,"EntryTapeLeft" if side<0 else "EntryTapeRight",Vector3(bay_at.x+side*(half+.7)*.5,.018,front),Vector3(half-.7,.004,.08),amber,false)
		for i in 5:
			var mark:=Kit.box(zone,"CautionMark",Vector3(bay_at.x+side*(half-.12-i*.16),.021,front),Vector3(.055,.003,.08),Color("303b3e"),false)
			mark.rotation.y=PI/6
	var legend:=Kit.label(zone,"ASSEMBLY AREA   /   KEEP CLEAR",Vector3(bay_at.x,.022,front-.19),26)
	legend.rotation.x=-PI/2;legend.modulate=Color("c8c5b5")
	# The short counter meets the front of the chamber; no bar above the grid.
	var edge:float=bay_at.z+size*.5
	Kit.box(parent,"CounterLink",Vector3(0,1.05,(edge-.65)*.5),Vector3(1.85,.10,-.65-edge),Color("e7e9e4"))
	for x in [-.85,.85]:
		tube(parent,"ServiceLink",Vector3(x,.22,-.30),Vector3(x,.22,edge),.035,Color("a3b2b0"))
	Kit.box(parent,"BayDock",Vector3(0,.54,edge+.035),Vector3(1.85,1.08,.07),Color("d2dad5"))
	var plate:=Kit.label(parent,"01 / MAKE                  02 / BUILD                  03 / TEST",Vector3(0,1.105,-.5),15)
	plate.rotation.x=-PI/2
	# Recessed task lighting: no lamp or crossbar between hands and result.
	for x in [-.78,.78]:
		var strip:=Kit.box(parent,"TaskLightLens",Vector3(x,1.106,-.54),Vector3(.30,.008,.035),Color("eff3e9"),false)
		strip.material_override.emission_enabled=true;strip.material_override.emission=Color("e5e9df")
		strip.material_override.emission_energy_multiplier=.65
		var light:=OmniLight3D.new();light.name="TaskLight";parent.add_child(light)
		light.position=Vector3(x,1.24,-.48);light.light_color=Color("f6f2e6")
		light.light_energy=.24;light.light_specular=.12;light.omni_range=2.4;light.shadow_enabled=false
static func glass_cube(parent:Node3D,size:float=4.6,height:float=-1,grid_scale:float=1.0)->void:
	if height<0:height=size
	var half:float=size/2;var pale:=Color("c4cccc")
	Kit.box(parent,"GlassBase",Vector3(0,-.065,0),Vector3(size,.13,size),Color("b7c0bd"))
	# The lattice spans the entire floor, rather than shrinking with the model.
	var extent:float=half-.10;var divisions:=floori((extent+.0001)/grid_scale)
	for i in range(-divisions,divisions+1):
		var width:float=.012 if i%2==0 else .006
		var ink:=Color("718784") if i%2==0 else Color("93a39f")
		Kit.box(parent,"MetreX",Vector3(0,.004,i*grid_scale),Vector3(extent*2,.003,width),ink,false)
		Kit.box(parent,"MetreZ",Vector3(i*grid_scale,.004,0),Vector3(width,.003,extent*2),ink,false)
	for x in [-half,half]:
		for z in [-half,half]:
			tube(parent,"GlassCorner",Vector3(x,0,z),Vector3(x,height,z),.045,pale)
			Kit.box(parent,"GroundShoe",Vector3(x,.025,z),Vector3(.18,.05,.18),pale,false)
	for y in [0.0,height]:
		for side in [-half,half]:
			tube(parent,"GlassEdge",Vector3(-half,y,side),Vector3(half,y,side),.021,pale)
			tube(parent,"GlassEdge",Vector3(side,y,-half),Vector3(side,y,half),.021,pale)
	var glass:=StandardMaterial3D.new();glass.albedo_color=Color(.8,.92,.94,.07)
	glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS;glass.roughness=.18;glass.metallic=.05
	glass.cull_mode=BaseMaterial3D.CULL_DISABLED
	for side in [-half,half]:
		for axis in [0,2]:
			if axis==2 and side==half:continue
			var pos:=Vector3(0,height*.5,0);pos[axis]=side
			var dims:=Vector3(size,height,.014) if axis==2 else Vector3(.014,height,size)
			var mesh:=Kit.box(parent,"GlassPane",pos,dims,Color.WHITE);mesh.material_override=glass
			mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var gate:=Gate.new();gate.name="EntryGate";parent.add_child(gate)
	gate.position.z=half;gate.configure(size,height,glass)
	var roof:=Kit.box(parent,"GlassRoof",Vector3(0,height,0),Vector3(size,.014,size),Color.WHITE)
	roof.material_override=glass;roof.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Instrumentation lives at the edges, leaving the working eye-line empty.
	for x in [-half,half]:
		Kit.box(parent,"ServiceCassette",Vector3(x,.24,-half),Vector3(.23,.48,.25),Color("d9dfdc"),false)
		for i in 4:
			Kit.box(parent,"Vent",Vector3(x,.14+i*.06,-half+.128),Vector3(.15,.018,.008),Color("26333b"),false)
		var line:=tube(parent,"ChamberLight",Vector3(x,.58,-half),Vector3(x,height-.15,-half),.012,Color("bdced0"))
		line.material_override.emission_enabled=true;line.material_override.emission=Color("b4d7d9")
		line.material_override.emission_energy_multiplier=.55
		Kit.box(parent,"UpperSocket",Vector3(x,height-.1,-half),Vector3(.18,.2,.21),pale,false)
	Kit.box(parent,"ChamberHeader",Vector3(0,height-.12,-half),Vector3(2.2,.18,.08),Color("27343a"),false)
	var nameplate:=Kit.label(parent,"ASSEMBLY / OBSERVATION VOLUME",Vector3(0,height-.12,-half+.045),24)
	nameplate.modulate=Color("d4e5e4")
	for z in [-half+.08,half-.08]:
		var edge:=Kit.box(parent,"FloorLight",Vector3(0,.008,z),Vector3(size-.3,.004,.013),Color("cadedd"),false)
		edge.material_override.emission_enabled=true;edge.material_override.emission=Color("c4dedc")
		edge.material_override.emission_energy_multiplier=.4

static func visitor_start(parent:Node3D,at:Vector3)->void:
	var start:=Marker3D.new();start.name="VisitorStart";parent.add_child(start);start.position=at
	# Markings stay flush with the floor; the marker is the actual arrival transform.
	for x in [-.35,.35]:
		Kit.box(start,"StartEdge",Vector3(x,-at.y+.009,0),Vector3(.018,.003,.65),Color("e1e9df"),false)
	for z in [-.325,.325]:
		Kit.box(start,"StartEdge",Vector3(0,-at.y+.009,z),Vector3(.70,.003,.018),Color("e1e9df"),false)
	var title:=Kit.label(start,"START",Vector3(0,-at.y+.012,.10),28);title.rotation.x=-PI/2;title.modulate=Color("314844")
	for side in [-1,1]:
		var arrow:=Kit.box(start,"FaceInward",Vector3(side*.065,-at.y+.012,-.15),Vector3(.018,.003,.18),Color("314844"),false)
		arrow.rotation.y=side*PI/4

static func prefab_shelf(parent:Node3D)->Node3D:
	var shelf:=Node3D.new();shelf.name="PrefabShelf";parent.add_child(shelf)
	shelf.position=Vector3(-1.39,1.10,.65)
	Kit.box(shelf,"Shelf",Vector3(0,-.035,0),Vector3(.64,.07,.44),Color("e7e9e4"))
	for x in [-.30,.30]:tube(shelf,"Rim",Vector3(x,.006,-.2),Vector3(x,.006,.2),.018,Color("bcc8c5"))
	tube(shelf,"Leg",Vector3(-.15,-1.03,0),Vector3(-.15,-.07,0),.032,Color("abb8b4"),true)
	tube(shelf,"Bracket",Vector3(.32,-.10,0),Vector3(.58,-.10,0),.025,Color("abb8b4"))
	for i in 2:
		var x:float=-.16+i*.32
		Kit.box(shelf,"StockPlate",Vector3(x,.003,0),Vector3(.26,.006,.28),Color("405250"),false)
		var label:=Kit.label(shelf,"WEDGE / 1 M" if i==0 else "PYRAMID / 1 M",Vector3(x,.008,.17),10)
		label.rotation.x=-PI/2;label.modulate=Color("314440")
	return shelf

static func stock_addresses(parent:Node3D,tier:int)->void:
	# Lights only: no bar, tray or solid geometry between fingers and stock.
	for i in 5:
		var available:bool=i<=[0,2,3,4][tier]
		var x:float=(i-2)*.31
		Kit.box(parent,"StockAddress",Vector3(x,-.244,-.35),Vector3(.24,.004,.045),Color("27333a"),false)
		var light:=Kit.box(parent,"AddressLight",Vector3(x,-.240,-.35),Vector3(.16,.003,.008),Color("bed1d1") if available else Color("5e6a70"),false)
		if available:
			light.material_override.emission_enabled=true;light.material_override.emission=Color("c5d9d8");light.material_override.emission_energy_multiplier=.3
		else:
			var label:=Kit.label(parent,"—",Vector3(x,-.237,-.46),12);label.rotation.x=-PI/2;label.modulate=Color("687b82")
