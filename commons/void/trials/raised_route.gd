extends Node3D
## Reusable walk-up deck. The original Trans_Pre pickups remain separate objects.
func _ready() -> void:
	var building := get_tree().get_first_node_in_group("void_game")
	var maker: Node3D = building.building if building != null else get_parent().get_parent().get_parent().building
	var timber: Material = maker.material(Color("a99179"), 0.85)
	var steel: Material = maker.material(Color("22272d"), 0.65)
	for i in range(12):
		maker.box(self, "DeckBoard%d" % i, Vector3(0, .56, -4.125+i*.75), Vector3(3,.08,.72), timber)
	for x in [-1.2,1.2]:
		maker.box(self,"Support",Vector3(x,.25,0),Vector3(.1,.5,8.9),steel)
	# A continuous slope works for both capsules; vertical steps block the walker.
	var ramp: Node3D = maker.box(self,"ApproachRamp",Vector3(0,.27,6),Vector3(3,.06,3.06),timber)
	ramp.rotation.x = atan2(.6,3.0)
