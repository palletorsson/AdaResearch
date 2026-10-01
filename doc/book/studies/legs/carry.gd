extends Node3D
## Supplied with this kit: the scene where one leg is carried by its foot.
## Contract: every frame it hands the Hand's place to the leg, $Leg.follow(...),
## and writes on the Readout what came of it: how far the leg's end is from the
## hand, and how far the loop led the chain's upper end away from the hip.
## W A S D, or the arrows, carry the Hand; mover.gd, on the Hand, hears them.

const Look := preload("res://supplied/look.gd")

func _ready() -> void:
	$Hand.material_override = Look.paint(Look.BONE)
	$Post.material_override = Look.ghost()
	$Readout.modulate = Look.INK
	$Readout.outline_modulate = Look.SHADE

func _process(_delta: float) -> void:
	var hand: Vector3 = $Hand.global_position
	$Leg.follow(hand)
	$Readout.text = "foot to hand %.2f m    hip led %.2f m away\nW A S D or the arrows carry the hand" % [
		$Leg.tip().distance_to(hand), $Leg.led.distance_to($Leg.global_position)]
