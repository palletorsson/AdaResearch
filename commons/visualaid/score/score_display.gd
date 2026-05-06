extends Node3D

## Score Display - Shows a score counter that can be incremented
## Emits signals when score changes

signal score_changed(new_score: int)

@export var initial_score: int = 0
@export var title_text: String = "SCORE"
@export var score_color: Color = Color(0.2, 1.0, 0.4)  # Green

@onready var value_label: Label3D = $DisplayBody/ValueLabel
@onready var title_label: Label3D = $TitleLabel

var _score: int = 0

func _ready() -> void:
	_score = initial_score
	_update_display()

	if title_label:
		title_label.text = title_text

func get_score() -> int:
	return _score

func set_score(value: int) -> void:
	_score = value
	_update_display()
	score_changed.emit(_score)

func add_score(amount: int = 1) -> void:
	_score += amount
	_update_display()
	score_changed.emit(_score)
	_flash_score()

func reset_score() -> void:
	_score = 0
	_update_display()
	score_changed.emit(_score)

func _update_display() -> void:
	if value_label:
		value_label.text = str(_score)
		value_label.modulate = score_color

func _flash_score() -> void:
	if not value_label:
		return

	# Brief flash animation
	var original_color = score_color
	value_label.modulate = Color.WHITE

	var tween = create_tween()
	tween.tween_property(value_label, "modulate", original_color, 0.3)
