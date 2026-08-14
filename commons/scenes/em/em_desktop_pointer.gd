extends "res://commons/scenes/DesktopInteractionPointer.gd"
## The museum walker's desktop hand.
##
## The SAME crosshair interaction the map scenes prove out — LMB press/drag
## on handles and buttons, RMB carry-grab, wheel = hold distance — mounted on
## the endless museum's walker. Artifacts ship their interaction layers with
## their scenes, so the museum needs no per-artifact wiring; what works in a
## map works in the museum the moment the ray can reach it.
##
## The shared pointer expects to live under a "Head" whose sibling is named
## Camera3D; the museum's walker parents its camera (which carries the pitch)
## directly to the CharacterBody3D. Rather than restructure a proven walker,
## this adapter is TOLD its camera and mirrors the camera's global transform
## every frame, so the ray is always exactly the view ray. Event delivery,
## press lock, grab masks — all inherited untouched.

var cam: Camera3D = null


func _ready() -> void:
	super()
	_camera = cam


func _process(delta: float) -> void:
	if cam != null and is_instance_valid(cam):
		global_transform = cam.global_transform
	super(delta)
