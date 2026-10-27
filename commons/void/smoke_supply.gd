extends Node3D
## Reusable, locally replenishing canister cradle. No unlock or ammunition menu.
const BOMB_PATH := "res://commons/void/smoke_bomb.gd"
const FX := preload("laser_fx.gd")
const Supply := preload("hardware_supply.gd")
var bomb: XRToolsPickable
var wait_left := 0.0
var readout: Label3D

func _ready() -> void:
	var cream := FX.finish(Color("e5e0cf"))
	var dark := FX.finish(Color("30332f"))
	FX.box(self,Vector3(0,1.16,-0.10),Vector3(0.52,0.62,0.12),cream,"SupplyBracket")
	FX.box(self,Vector3(0,1.02,0.06),Vector3(0.45,0.06,0.4),dark,"Cradle")
	FX.box(self,Vector3(0,1.75,-0.03),Vector3(1.05,0.53,0.08),cream,"InstructionPlate")
	readout=Label3D.new(); readout.font_size=30; readout.pixel_size=0.0018
	readout.outline_size=0;readout.modulate=Color("30332f")
	readout.position=Vector3(0,1.75,0.02);add_child(readout)
	Supply.connect_unit(self,Vector3(0,2.04,-0.15))
	_stock()

func _stock() -> void:
	bomb=load(BOMB_PATH).new();bomb.name="SmokeCanister";add_child(bomb)
	bomb.position=Vector3(0,1.18,0.12)
	readout.text="CATALYST / SMOKE\nHOLD · PULL PIN · THROW\nVR: pull ring with other hand\nMouse: R grab · L pin · L throw"
	wait_left=5.0

func _process(delta: float) -> void:
	# One canister per cradle, and a hard total limit for unattended supplies.
	if is_instance_valid(bomb):
		if bomb.is_picked_up(): return
		# Keep an untouched supply. A safely dropped tool may be recovered, but
		# cannot permanently strand the cradle or fill the tower with duplicates.
		if not bomb.held_once: return
	wait_left-=delta
	readout.text="SMOKE / REPLENISHING\n"+str(ceili(maxf(0,wait_left)))+" s"
	if wait_left<=0 and get_tree().get_nodes_in_group("void_smoke_bomb").size()<8:
		if is_instance_valid(bomb) and not bomb.armed: bomb._retire()
		_stock()
