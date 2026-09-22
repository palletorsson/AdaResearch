extends Node3D
## A shared address in two existing fields; the hall owns the comparison.
const Kit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")
const SAMPLES: Array[Vector2] = [Vector2(-1,0.5),Vector2(1,-1),Vector2(-1,-1),Vector2.ZERO,Vector2(0.5,1)]
var pair: Array[Node3D] = []
var markers: Array[MeshInstance3D] = []
var sample_index: int = 0
var plate: bool = false
var label: Label3D
var elapsed: float = 0.0

func build(first: Node3D) -> void:
	name = "PairStudy"
	var twin: Node3D = first._twin()
	if twin == null: return
	pair = [first,twin]
	for work in pair:
		# The authored approach is on -z. The old panels faced the field.
		work._panel_node.rotation_degrees = Vector3(-30,180,0)
		var sphere := SphereMesh.new();sphere.radius=0.075;sphere.height=0.15
		var marker := MeshInstance3D.new();marker.mesh=sphere;marker.material_override=Kit.emissive(Color(1,0.35,0.63),1.5)
		marker.name = "SharedAddress";work.add_child(marker);markers.append(marker)
	var case: Node3D = first.get_node("Witness/Case")
	case.position.y = 0.3;case.rotation_degrees = Vector3(-40,180,0)
	# Keep the existing generator plate; give its evidence a supported, readable case.
	var shell: MeshInstance3D = case.get_child(0)
	(shell.mesh as BoxMesh).size = Vector3(1.65,0.94,0.025)
	first._witness_label.position = Vector3(-0.76,0.37,0.025)
	label=Label3D.new();label.font_size=18;label.pixel_size=0.0018;label.modulate=Color(1,0.63,0.78)
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT;label.vertical_alignment=VERTICAL_ALIGNMENT_TOP
	label.position=Vector3(-0.76,-0.18,0.028);case.add_child(label)
	var stone := StandardMaterial3D.new();stone.albedo_color=Color(0.17,0.20,0.22)
	for x in [1.92,3.08]: add_child(Kit.box(Vector3(x,-0.55,-2.7),Vector3(0.1,1.1,0.1),stone))
	var rack: GDScript=load("res://commons/audio/rack_templates/RackTemplates.gd")
	var controls: Node3D=rack.create_panel("",[[{"type":"button","label":"SAMPLE"},{"type":"button","label":"VIEW"},{"type":"button","label":"MATCH"}]],true)
	controls.name="Controls";controls.position=Vector3(2.5,-0.05,-3.15);controls.rotation_degrees=Vector3(-35,180,0);controls.scale=Vector3.ONE*2.0;add_child(controls)
	var actions: Array[Callable]=[next_sample,toggle_view,match_pair]
	for i in range(3):
		var action: Callable=actions[i]
		controls.find_child("Btn_%d"%i,true,false).get_node("InteractableAreaButton").button_pressed.connect(func(_b):action.call())
	var hall: Node=first._hall_ancestor()
	var terrain: Node3D=hall.find_child("PerlinNoiseTerrain",true,false) if hall else null
	if terrain:
		terrain.add_child(Kit.box(Vector3(0,-0.75,0),Vector3(1.2,0.5,1.2),stone))
		terrain.add_child(Kit.box_collider(Vector3(1.2,0.5,1.2),Vector3(0,-0.75,0)))
		var caption:=Label3D.new();caption.text="A 3D FIELD / ANOTHER SLICE\n0.5 seconds per step";caption.font_size=22;caption.pixel_size=0.0015
		caption.position=Vector3(0,-0.65,-0.61);caption.rotation_degrees.y=180;terrain.add_child(caption)
	refresh()

func _process(delta: float) -> void:
	elapsed+=delta
	if elapsed>=0.15:
		elapsed=0;refresh()

func next_sample() -> void:
	sample_index=(sample_index+1)%SAMPLES.size();refresh()

func toggle_view() -> void:
	plate=not plate
	for work in pair:work.apply_grid_config({"readout":"plate" if plate else "relief"})
	refresh()

func match_pair() -> void:
	for work in pair:work.replay()
	refresh()

func sample_pair(p: Vector2) -> Vector2:
	return Vector2(pair[0].sample_at(p.x,p.y), pair[1].sample_at(p.x,p.y))

func selected() -> Dictionary:
	var p: Vector2=SAMPLES[sample_index];var values: Vector2=sample_pair(p)
	return {"sample":sample_index,"p":[p.x,p.y],"values":[values.x,values.y],"difference":values.y-values.x,"view":"plate" if plate else "relief"}

func refresh() -> void:
	if pair.size()!=2 or not is_instance_valid(pair[1]):return
	var rec: Dictionary=selected();var p: Vector2=SAMPLES[sample_index]
	for i in range(2):
		var work: Node3D=pair[i]
		markers[i].position=Vector3(p.x,(0.0 if plate else rec.values[i]*work.noise_field.amplitude)+0.36,p.y)
		work._refresh_witness()
	label.text="SAMPLE %d/5 · x %.1f z %.1f · %s\n"%[sample_index+1,p.x,p.y,rec.view.to_upper()]
	label.text+="simplex %+.4f | perlin %+.4f\n"%[rec.values[0],rec.values[1]]
	label.text+="perlin - simplex = %+.4f"%rec.difference
