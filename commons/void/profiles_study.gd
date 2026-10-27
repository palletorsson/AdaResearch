extends RefCounted
## The six museum sweeps at architectural scale. Letter geometry is unchanged;
## the tower supplies access, reading positions and light.
const Profiles = preload("res://commons/artifacts/glyph_profile_gallery/glyph_profile_gallery.gd")
const Kit = preload("res://commons/artifacts/ignorance_gallery/gallery_kit.gd")
const Wedge = preload("res://commons/artifacts/primitive_encounters/wedge_blocker.tscn")
const Cube = preload("res://commons/artifacts/primitive_encounters/platform_block.tscn")
const POSITIONS := [Vector3(0,0,1),Vector3(17,0,-4.4),Vector3(17.2,0,3.5),Vector3(-17.5,0,-3.8),Vector3(-17,0,4.2),Vector3(0,0,-5.4)]
const CARDS := [Vector3(-2.8,0,3.5),Vector3(-2.3,0,1.7),Vector3(0,0,2.7),Vector3(1,0,3.8),Vector3(0,0,3),Vector3(-3,0,0)]
const NAMES := ["O / Walk through the outline","O / Flared vessel","B / Two twisting wells","C / Curved channel","I / A path makes a hole",": / Two separate bodies"]
const HEADINGS := ["01 / O BECOMES A PASSAGE","02 / O BECOMES A VESSEL","03 / B BECOMES TWO WELLS","04 / C BECOMES A CHANNEL","05 / I CLOSES A PATH","06 / ONE GLYPH, TWO BODIES"]
const NOTES := ["Its hole has depth.\nThe sill remains.\nRamps take you over it.","Width changes.\nBoth ends stay open.\nThe floor is below.","B has two holes.\nBoth twist upward.\nNeither joins the other.","An open profile.\nA curved path.\nA channel, not a hole.","I has no hole.\nClose its path:\na new opening.","One character.\nTwo separate parts.\nThey remain separate."]

static func build(hall: Node3D) -> void:
	var source:=Profiles.new();source.name="ProfileSource";hall.add_child(source)
	for i in source.stations.size():
		var station: Node3D=source.stations[i]
		station.reparent(hall,false)
		# Stable IDs retain the user's saved placements and part copies.
		station.name="Profile_%d_%s"%[i+1,Profiles.GLYPHS[i].replace(":","Colon")]
		station.position=POSITIONS[i];station.rotation=Vector3.ZERO;station.scale=Vector3.ONE
		station.set_meta("editor_label",NAMES[i]);station.set_meta("profile_index",i)
		station.set_meta("void_source","res://commons/artifacts/glyph_profile_gallery/glyph_profile_gallery.tscn")
		station.get_node("Plinth").free();station.get_node("ProfileBacking").free()
		for child in station.get_children():
			if child is Label3D:child.free()
		station.get_node("Sculpture").position.y=.02
		_card(station,i)
		var lamp:=OmniLight3D.new();lamp.name="ProfileLight"
		lamp.position=Vector3(0,2.8,1.6) if i in [0,5] else Vector3(0,2.1,0)
		lamp.light_color=Color("ffd8c7") if i in [0,1] else Color("d5d9f5")
		lamp.light_energy=1.7;lamp.omni_range=5 if i==0 else 4.2
		lamp.shadow_enabled=false;station.add_child(lamp)
	source.free()
	_passage_access(hall.get_node("Profile_1_O"))
	# These two low sections let the eye look down into the B channels while
	# the original five-metre twisting body keeps its full scale beside them.
	_well_sections(hall)
	preload("res://commons/void/profile_suspensions.gd").build(hall)

static func _card(station: Node3D, index: int) -> void:
	var card:=Node3D.new();card.name="ReadingCard";card.position=CARDS[index];station.add_child(card)
	Kit.block(card,Vector3(2.6,1.3,.06),Vector3(0,1.25,0),Color("302b37"),false)
	for x in [-1.05,1.05]:Kit.block(card,Vector3(.035,.65,.035),Vector3(x,.325,0),Color("49414c"),false)
	var profile: Node3D=station.get_node("SourceProfile")
	profile.reparent(card,false);profile.position=Vector3(-.91,1.15,.05);profile.scale=Vector3.ONE*.75
	var heading:=Kit.label(card,HEADINGS[index],Vector3(0,1.72,.05),.0021)
	heading.font_size=36;heading.modulate=Color("eec6d8")
	var note:=Kit.label(card,NOTES[index],Vector3(.35,1.14,.05),.0021)
	note.font_size=25;note.modulate=Color("f2e7df")

static func _passage_access(station: Node3D) -> void:
	# Three structure-2 cubes, then wp on both ends: the same metre and join
	# learned in Polyhedra/Cube. The letter itself is not cut into a doorway.
	for z in [-1,0,1]:
		var cube: Node3D=Cube.instantiate();cube.name="SillCube"+str(z+1)
		cube.position=Vector3(0,0,z);station.add_child(cube)
	for side in [-1,1]:
		var ramp: Node3D=Wedge.instantiate();ramp.name="ApproachRamp" if side==1 else "ExitRamp"
		ramp.position=Vector3(0,0,side*2.5);ramp.rotation.y=PI if side==1 else 0.0
		station.add_child(ramp)

static func _well_sections(hall: Node3D) -> void:
	# The source B's two holes are easier to inspect at hand height. These are
	# actual end sections of its sweep, not substitute cylindrical wells.
	var factory:=Profiles.new()
	factory.font.load_dynamic_font(Profiles.FONT_PATH)
	var section: Dictionary=Profiles.Sweep.profile(factory.font,"B")
	var frames: Array[Transform3D]=factory._frames(2)
	for i in 2:
		var part:=Node3D.new();part.name="WellSectionBase" if i==0 else "WellSectionTop"
		part.position=Vector3(14.8+i*2.9,0,-.25)
		part.set_meta("editor_label","B / Lower section" if i==0 else "B / Turned upper section")
		hall.add_child(part)
		var pose: Transform3D=frames[0 if i==0 else -1]
		pose.origin=Vector3(0,.78,0)
		pose.basis=pose.basis.scaled_local(Vector3(.48,.48,1))
		var upper:=pose;upper.origin.y+=.10
		var sections: Array[Transform3D]=[pose,upper]
		var mesh:=MeshInstance3D.new();mesh.name="Section";mesh.mesh=Profiles.Sweep.make(section,sections)
		mesh.material_override=Kit.material(Color("bfc9bd"));part.add_child(mesh)
		factory._mesh_collision(mesh)
		Kit.block(part,Vector3(1.9,.10,2),Vector3(0,.72,0),Color("36313c"))
		for x in [-.8,.8]:Kit.block(part,Vector3(.07,.67,.07),Vector3(x,.335,0),Color("36313c"))
		var label:=Kit.label(part,"B / START" if i==0 else "B / AFTER THE TURN",Vector3(0,.62,1.012),.002)
		label.modulate=Color("eee3d9");label.font_size=26
	factory.free()
