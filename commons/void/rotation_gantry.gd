extends Node3D
## Safe steel ring around the raised cube courses; no deck under the test cubes.
const Parts=preload("res://commons/artifacts/rotation_studies/parts.gd")
var deck_height:=3.5
func _ready() -> void:
	deck_height=float(get_meta("config_deck_height",deck_height))
	for x in [-5.0,5.0]:
		Parts.box(self,"GantryDeck",Vector3(4,.18,17),Vector3(x,deck_height-.09,0),Color("343d46"))
		for z in [-8.0,-4.0,0.0,4.0,8.0]:
			Parts.box(self,"SteelSupport",Vector3(.14,deck_height,.14),Vector3(x,deck_height/2,z),Color("2a3038"))
	for z in [-8.0,8.0]:
		Parts.box(self,"SafeCrosswalk",Vector3(6.1,.18,1),Vector3(0,deck_height-.09,z),Color("343d46"))
		Parts.box(self,"EndRail",Vector3(14,.07,.07),Vector3(0,deck_height+1,z+signf(z)*.5),Color("ff5aa7"))
	# Openings align with the tc lift and the retained return ramp.
	for span in [[-7.0,-8.5,3.3],[-7.0,5.7,8.5],[7.0,-8.5,6.6],[7.0,8.3,8.5]]:
		var x:float=span[0];var start:float=span[1];var end:float=span[2]
		Parts.box(self,"OuterRail",Vector3(.07,.07,end-start),Vector3(x,deck_height+1,(start+end)/2),Color("ff5aa7"))
		for z in [start,end]:Parts.box(self,"RailPost",Vector3(.07,1,.07),Vector3(x,deck_height+.5,z),Color("343d46"))
