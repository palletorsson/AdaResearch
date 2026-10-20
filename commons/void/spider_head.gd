extends Node3D
## Original procedural industrial head: pale armour, respirator, optical slit.
const Stock := preload("res://commons/artifacts/construction_site/stock.gd")
var optic: MeshInstance3D
var jaws: Array[Node3D] = []
var bite_left := 0.0
var rest := Vector3.ZERO

func _ready() -> void:
	var armour := Stock.finish("b9bdb5",.65,.25)
	var dark := Stock.finish("1d232c",.58,.55)
	var steel := Stock.finish("626d77",.5,.7)
	Stock.box(self,"BrainCase",Vector3(0,.01,.06),Vector3(.53,.27,.51),dark,false)
	for side in [-1,1]:
		var cheek := Stock.box(self,"CheekArmour",Vector3(side*.27,.04,-.03),Vector3(.12,.32,.48),armour,false)
		cheek.rotation.z=side*-.24
		Stock.box(self,"TempleRail",Vector3(side*.31,-.05,.03),Vector3(.04,.06,.42),steel,false)
		for vent in 3:
			Stock.box(self,"Vent",Vector3(side*.335,.075-float(vent)*.05,.08),Vector3(.018,.022,.16),dark,false)
		Stock.tube(self,"Antenna",Vector3(side*.22,.15,.18),Vector3(side*.25,.34,.2),.014,steel,false)
	var brow := Stock.box(self,"Brow",Vector3(0,.14,-.17),Vector3(.51,.095,.28),armour,false)
	brow.rotation.x=-.25
	Stock.box(self,"OpticSocket",Vector3(0,0,-.225),Vector3(.42,.135,.12),dark,false)
	Stock.box(self,"Respirator",Vector3(0,-.125,-.16),Vector3(.24,.11,.18),steel,false)
	for slot in 4:
		Stock.box(self,"Grille",Vector3(-.075+slot*.05,-.125,-.256),Vector3(.021,.075,.012),dark,false)
	Stock.batch_static(self)
	var glow := StandardMaterial3D.new()
	glow.emission_enabled=true; glow.emission_energy_multiplier=2.0; glow.roughness=.3
	optic=Stock.box(self,"PowerCore",Vector3(0,.01,-.29),Vector3(.31,.04,.025),glow,false)
	for side in [-1,1]:
		var jaw := Node3D.new()
		jaw.name="GripperJaw"; jaw.position=Vector3(side*.18,-.15,-.20)
		add_child(jaw); jaws.append(jaw)
		Stock.box(jaw,"Clamp",Vector3(0,-.06,-.075),Vector3(.055,.12,.20),dark,false)
		Stock.box(jaw,"Tooth",Vector3(-side*.035,-.09,-.17),Vector3(.10,.055,.05),steel,false)
	rest=position

func bite() -> void:
	bite_left=.5

func _process(delta: float) -> void:
	bite_left=maxf(0.0,bite_left-delta)
	var pulse := sin(PI*bite_left/.5)
	position=rest+Vector3(0,.10*pulse,-.16*pulse)
	for i in jaws.size(): jaws[i].rotation.y=(1 if i==0 else -1)*pulse*.65
