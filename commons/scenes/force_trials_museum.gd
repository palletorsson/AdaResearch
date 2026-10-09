@tool
extends "res://commons/scenes/endless_museum.gd"
## Optional curation walk. Supply its order without altering the book's main spine.
func _ready() -> void:
	if Engine.is_editor_hint():return
	_order_file="res://commons/artifacts/force_trials/review_order.json"
	plan_file="res://commons/artifacts/force_trials/review_plan.json"
	super()
