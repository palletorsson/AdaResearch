extends Node3D
## Compare existing generators, retaining their own geometry and seeded rules.
const Stage = preload("res://commons/artifacts/randomness_space/museum_exhibit_stage.gd")
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
@export var textile: bool = false
var specimens: Array[Node3D] = []
var base_seed: int = 41
var variant: int = 0
var plate: Label3D
const GARMENTS = ["sheath","crinoline","quilted","bloom","fringe"]

func _ready() -> void:
	Stage.box(self,Vector3(0,-0.08,0),Vector3(5.4,0.16,1.6),Color(0.16,0.23,0.27),true)
	for i in range(3):
		var path: String = "res://commons/artifacts/ten_print_textile/ten_print_textile.tscn" if textile else "res://commons/artifacts/dream_bodies/figures/couture_beast.tscn"
		var specimen: Node3D = load(path).instantiate()
		specimen.position = Vector3((i-1)*1.7,0.25 if textile else 0.0,0)
		if textile:
			specimen.weave_seed = base_seed; specimen.weaving = false
			specimen.alphabet = ["diagonals","orthogonals","blocks"][i]
		else:
			specimen.seed = base_seed+i; specimen.head = "hare"; specimen.garment = GARMENTS[variant]
		add_child(specimen); specimens.append(specimen)
	var panel := Rack.create_panel("SAME DRAWS / OTHER MARKS" if textile else "THREE SEEDS / ONE RECIPE",[[{"type":"button","label":"NEXT SEED"},{"type":"button","label":"RESET"}]] if textile else [[{"type":"button","label":"NEXT SEED"},{"type":"button","label":"GARMENT"}],[{"type":"button","label":"RESET"}]])
	panel.position = Vector3(0,1.1,-1.7); panel.rotation.y = PI; add_child(panel)
	panel.find_child("Btn_0",true,false).pressed.connect(next_seed)
	panel.find_child("Btn_1",true,false).pressed.connect(reset if textile else change_garment)
	if not textile: panel.find_child("Btn_2",true,false).pressed.connect(reset)
	plate = Stage.label(self,"",Vector3(0,0.55,-1.72),PI)
	plate.font_size = 22; plate.pixel_size = 0.0016
	Stage.box(self,plate.position+Vector3(0,0,0.025),Vector3(1.4,0.2,0.035),Color(0.07,0.12,0.16))
	_readout()

func next_seed() -> void:
	base_seed += 3; refresh()

func change_garment() -> void:
	variant = (variant+1)%GARMENTS.size(); refresh()

func reset() -> void:
	base_seed = 41; variant = 0; refresh()

func refresh() -> void:
	for i in range(3):
		if textile: specimens[i].apply_grid_config({"weave_seed":base_seed,"weaving":false})
		else: specimens[i].apply_grid_config({"seed":base_seed+i,"head":"hare","garment":GARMENTS[variant]})
	_readout()

func _readout() -> void:
	plate.text = ("SEED %d / THREE PAIRS OF MARKS" % base_seed) if textile else ("SEEDS %d / %d / %d\nHARE / %s" % [base_seed,base_seed+1,base_seed+2,GARMENTS[variant].to_upper()])
