extends ScrollContainer

@onready var infoboard_check = $VBoxContainer/InfoboardCheck

func _ready():
	if GameManager:
		infoboard_check.button_pressed = GameManager.show_infoboard

func _on_infoboard_check_toggled(toggled_on):
	if GameManager:
		GameManager.set_show_infoboard(toggled_on)
