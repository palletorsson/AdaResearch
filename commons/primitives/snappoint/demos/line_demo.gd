extends Node3D

# @identity
# essence: snap_connection(pointA, pointB) → line — demonstrate the SnapConnectionManager wiring
# desire: learner sees the snap system itself as a subject — connections have categories and validation logic
# critical_parameter: SnapConnectionManager — the node that tracks which snap points are linked
# triggers: any snap or unsnap event — CategoryLogicDisplay shows/hides to reflect current connection state
# emerges: that snap networks can encode semantic rules — not just any point connects to any other
# needs: [missing VR controls — purely demonstrative, driven by scene-level snap events]
# relationships: depends on SnapConnectionManager; shows the engine that snap_tetrahedron_puzzle uses
# truth: a connection is not just spatial proximity — it carries categorical meaning about what fits with what

@onready var manager = $SnapConnectionManager
@onready var logic_display = $CategoryLogicDisplay

func _ready() -> void:
	if manager:
		manager.connection_created.connect(_on_connection_created)
		manager.connection_broken.connect(_on_connection_broken)

func _on_connection_created(_point_a, _point_b, _line) -> void:
	# Hide instruction display when a connection is made
	if logic_display:
		logic_display.visible = false

func _on_connection_broken(_point_a, _point_b) -> void:
	# Show instruction display again if connection is broken
	if logic_display:
		logic_display.visible = true
