extends "res://commons/artifacts/spine_films/film_stage.gd"
const G=preload("res://commons/artifacts/spine_films/early/geometry.gd")
const SOURCE="res://algorithms/primitives/rainbow/rainbow.gd"
var groups: Array[Node3D]=[]
var counts: Array[int]=[]
var widths: Array[float]=[]
var readout:Label3D
var boundaries: Array[Node3D]=[]

func _build()->void:
	title_text="How many colours fit the same arch?"
	phases=["TWO BANDS","SIX BANDS","SEVEN BANDS","FORTY-EIGHT SAMPLES"]
	notes=["The source's warm/cool pair divides a fixed mesh width.","Six authored colours occupy the same inner and outer radius.","The seven-colour preset gives indigo a band of its own.","The preset called continuous still consists of 48 discrete HSV samples."]
	source_paths=[SOURCE]
	var src:Node3D=load(SOURCE).new();src.substance="solid"
	for mode:String in ["two","six","roygbiv","continuous"]:
		src.banding=mode;src.rainbow_colors=src._band_colors(mode)
		var group:=Node3D.new();display.add_child(group);groups.append(group);group.scale=Vector3.ONE*.15
		counts.append(src.rainbow_colors.size());widths.append(src._band_thickness()*src.rainbow_colors.size())
		for i in src.rainbow_colors.size():
			# create_rainbow() chooses a random name; call its deterministic mesh function directly.
			var band:MeshInstance3D=src.create_color_band(i,1.0,false,Vector3.ZERO)
			group.add_child(band)
		var outlines:=Node3D.new();display.add_child(outlines);boundaries.append(outlines)
		for radius in [src.RAINBOW_RADIUS,src.RAINBOW_RADIUS+widths.back()]:
			for step in range(32):
				var a:=PI*step/32.0;var b:=PI*(step+1)/32.0
				G.line(outlines,Vector3(cos(a)*radius,sin(a)*radius,.03)*.15,Vector3(cos(b)*radius,sin(b)*radius,.03)*.15,G.WHITE,.008)
	G.box(display,Vector3(0,-.11,0),Vector3(7,.2,2.6),Color("20384b"))
	readout=G.label(display,"",Vector3(0,.17,.8),G.WHITE,.20)
	evidence={"band_counts":counts,"widths_m":widths,"radius_m":src.RAINBOW_RADIUS,"segments_per_band":src.RAINBOW_SEGMENTS,"method":"_band_colors / _band_thickness / create_color_band","optical_simulation":false,"presentation_scale":.15}
	src.free();frame_scene(Vector3(0,1.5,0),11.4,.27,.13)

func _draw(time:float)->void:
	var p:=phase_index(time);var u:=phase_progress(time)
	for i in groups.size():
		groups[i].visible=i==p;boundaries[i].visible=i==p
		if i!=p:continue
		var join:=smoothstep(.05,.64,u)
		for j in groups[i].get_child_count():
			# Pull source bands apart in depth before returning them to their actual common plane.
			groups[i].get_child(j).position.z=(1.0-join)*float(j)*(.9/float(counts[i]))/.15
	readout.text="%d bands / %.1f m total width" % [counts[p],widths[p]]

func validation()->Dictionary:
	var okay:=counts==[2,6,7,48]
	for width in widths:okay=okay and is_equal_approx(width,5.6)
	return {"passed":okay,"evidence":evidence}
