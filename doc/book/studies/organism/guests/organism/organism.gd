extends Node3D
## The Organism guest: the limb that moves.
## It is the lesson's organism.gd with three things changed. There is no lattice
## in the room, so the line that tells it where the toe is has gone. A bar is
## 0.24 m and not 0.3 m, so that the limb, turning about its hip, stays on one
## place of the room. And the colours are those of the course look, written out
## here as hex, because a guest names nothing outside its folder.
## The pins stand on the ground; the hip is 0.11 m above it.

const BODY := Color("c6ff3d")     # the bars
const SECOND := Color("22d9ff")   # the toe
const BONE := Color("f4efe6")     # the hip and the pins

# 0 at the end   1 at one third   2 at the centre   3 outside
@export_enum("at the end", "at one third", "at the centre", "outside") var pivot := 0

var fractions := [0.0, 1.0 / 3.0, 0.5, -0.5]
var length := 0.24   # metres: one bar
var speed := 0.6   # radians per second
var angle := 0.0

func _ready() -> void:
	var slide: float = fractions[pivot] * length
	$Hip/Upper.position.z = slide
	$Hip/Upper/Bar.position.z = length / 2.0 - slide
	$Hip/Upper/Lower/Bar.position.z = length / 2.0 - slide
	$Hip/Upper/Lower/Foot/Bar.position.z = length / 2.0 - slide
	$Hip/Upper/Lower/Foot/Toe.position.z = length - slide
	paint($Hip, BONE)
	paint($Hip/Upper, BONE)
	paint($Hip/Upper/Lower, BONE)
	paint($Hip/Upper/Lower/Foot, BONE)
	paint($Hip/Upper/Bar, BODY)
	paint($Hip/Upper/Lower/Bar, BODY)
	paint($Hip/Upper/Lower/Foot/Bar, BODY)
	paint($Hip/Upper/Lower/Foot/Toe, SECOND)

func _process(delta: float) -> void:
	angle += speed * delta
	$Hip/Upper.rotation.y = angle
	$Hip/Upper/Lower.rotation.y = angle
	$Hip/Upper/Lower/Foot.rotation.y = angle

func paint(part: MeshInstance3D, colour: Color) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.8
	part.material_override = material
