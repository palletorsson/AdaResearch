extends "res://addons/godot-xr-tools/staging/scene_base.gd"

## THE STAGED DEATH SCENE'S ROOT — it exists to give the camera back on desktop.
##
## 2026-09-07. Building a camera is not keeping one. vrStaging.load_scene runs:
##
##     $Scene.add_child(current_scene)        -> _ready(), the death scene builds
##                                               and aims its own Camera3D
##     await create_timer(tracking_delay)
##     current_scene.scene_loaded(user_data)  -> scene_base.gd:101,
##                                               $XROrigin3D/XRCamera3D.current = true
##
## so about a tenth of a second after the death scene aims at the cross, the base
## reclaims the viewport for an UNTRACKED rig camera sitting at the origin. On a
## desktop that is a view of the inside of a hillside, and it is the third
## distinct way this one transition has found to show the visitor nothing.
##
## IT WAS NOT FOUND BY EITHER TEST THAT SHOULD HAVE FOUND IT. `--em-die` boots the
## museum directly, so staging never runs and scene_loaded never fires; the scene
## probe instantiated the staged scene without driving the staging sequence. Both
## exercised the PARTS and neither the ORDER. probe_death_scene_builds calls
## scene_loaded by hand now, which is what caught it.
##
## super() first, deliberately: the base also does spawn positioning and signal
## wiring, and skipping all of that to win a camera argument would trade one
## silent breakage for another. Last writer wins, and on desktop that is us.


## XR is running, as against merely present in the scene — base.tscn carries an
## XROrigin3D and an XRCamera3D whether or not a headset is attached.
func _xr_running() -> bool:
	var iface := XRServer.find_interface("OpenXR")
	return iface != null and iface.is_initialized()


## NOBODY WALKS AT THEIR OWN FUNERAL (2026-09-07, Palle: "still can stand in the
## death scene, I falling, either stop gravity in that map, just looking like the
## menu or give me a floor").
##
## A floor was the first answer and it was the wrong one — a WorldBoundaryShape3D
## went in, the probe counted it, and Palle still fell. Chasing why (layers? the
## plane's side? the rig's spawn height?) is chasing a mechanism this scene does
## not need at all.
##
## THE MENU IS THE PRECEDENT AND IT IS SIMPLER THAN A FLOOR: the menu never falls
## because it is loaded straight into staging and has NO XRToolsPlayerBody in it.
## The death scene inherited one from base.tscn, which it needs for the rig and
## the camera and does not need for locomotion. So the body is switched off. No
## gravity, no walking, no collision to get wrong: the visitor stands where
## staging put them, looks at the cross, and presses continue.
##
## `enabled` is the class's own supported setter (player_body.gd:52), not a
## process_mode trick, so XR Tools stays responsible for what that means.
##
## Done in BOTH _ready and scene_loaded on purpose: the first is early enough
## that no frame of falling is rendered, the second is after staging has finished
## touching the rig, in case anything there turns it back on.
func _ready() -> void:
	super()
	_still_the_body()


func _still_the_body() -> void:
	var body := find_child("PlayerBody", true, false)
	if body == null:
		return
	if "enabled" in body:
		body.set("enabled", false)
		print("[death-staged] the player body is stilled — no gravity at the grave")


func scene_loaded(user_data = null):
	super(user_data)
	_still_the_body()
	if _xr_running():
		return                      # in a headset the XR camera IS the eye
	var cam := find_child("DeathCamera", true, false) as Camera3D
	if cam == null:
		push_warning("[death-staged] no DeathCamera to restore — the rig camera keeps the view")
		return
	cam.current = true
	print("[death-staged] desktop: the death scene keeps its own camera")
