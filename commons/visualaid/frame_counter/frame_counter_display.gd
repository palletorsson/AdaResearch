extends Node3D

# @identity
# essence: label.text = Engine.get_process_frames() — a live counter of rendered frames since startup
# desire: learner understands that VR runs as a discrete sequence of frames, not a continuous flow
# critical_parameter: the update rate — _process fires once per frame, so the counter increments with each render
# triggers: every rendered frame — the number ticks up continuously; pausing the game stops the counter
# emerges: the frame as the fundamental unit of VR time — everything the player experiences is discretised into frames
# needs: [has Label3D [has], missing frame-rate (FPS) display alongside absolute frame count]
# relationships: utility display used alongside interactive scenes; reminds learner of the discrete substrate of 3D
# truth: there is no continuous time in real-time 3D — only discrete frame steps, typically 72 or 90 per second in VR

@onready var label: Label3D = $StartButton/Label3D

func _process(_delta):
	var frame_count = Engine.get_process_frames()
	label.text = "%d" % frame_count
