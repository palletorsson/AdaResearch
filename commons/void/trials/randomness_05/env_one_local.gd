extends "res://algorithms/randomness/envOne.gd"
## Trial-only adapter (randomness_05, R4) for env_one (`env_one:0:4:0.5#seed_controls:true`).
##
## env_one builds its own WorldEnvironment and a DirectionalLight3D in apply_lighting().
## floor_content neutralises both once, after the placement enters the tree. The source's
## seed console (PREVIOUS / REPLAY / NEXT / NEW SEED) and the regenerate emitters call
## apply_lighting() again: a fresh environment and an unscoped sun would then light every
## floor of the tower. Static inference; the focused case `seedlight` presses the console.
##
## The kitbash, its seed stream, its spot lights and its console are unchanged. Only the
## import rule floor_content already applies is applied again after every rebuild.
func apply_lighting() -> void:
	super.apply_lighting()
	for environment in find_children("*", "WorldEnvironment", true, false):
		(environment as WorldEnvironment).environment = null
	for sun in find_children("*", "DirectionalLight3D", true, false):
		(sun as DirectionalLight3D).hide()
