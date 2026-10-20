extends Node3D
var bench: Node3D
var amount: HSlider
var status: Label
var experiment_row: HBoxContainer
var gallery_row: HBoxContainer
var comparison: Control
var comparison_note: Label
var capture_folder: String=""
func _ready() -> void:
	bench=$Bench
	var layer:=CanvasLayer.new();add_child(layer)
	var row:=HBoxContainer.new();row.position=Vector2(20,20);layer.add_child(row);experiment_row=row
	var title:=Label.new();title.text="ORIGINAL / PARTS / HYBRIDS ";row.add_child(title)
	amount=HSlider.new();amount.min_value=0;amount.max_value=1;amount.step=0.01;amount.custom_minimum_size=Vector2(360,44);row.add_child(amount)
	amount.value_changed.connect(bench.user_disorder)
	for key in ["ORIGINAL","PARTS","HYBRIDS","SEED +1","KEEP","REPLAY","GALLERY","WATCH","FOLLOW PART"]:
		var button:=Button.new();button.text=key;button.custom_minimum_size=Vector2(100,44);row.add_child(button)
		button.pressed.connect(bench.act.bind(key))
	gallery_row=HBoxContainer.new();gallery_row.position=Vector2(20,20);layer.add_child(gallery_row)
	for i in 4:
		var button:=Button.new();button.text="REPLAY "+str(i+1);button.custom_minimum_size=Vector2(150,44);gallery_row.add_child(button)
		button.pressed.connect(bench.gallery.replay_slot.bind(i))
	for key in ["PREVIOUS","NEXT","BACK"]:
		var button:=Button.new();button.text=key;button.custom_minimum_size=Vector2(130,44);gallery_row.add_child(button)
		button.pressed.connect(bench.gallery.act.bind(key))
	status=Label.new();status.position=Vector2(20,76);layer.add_child(status)
	build_comparison(layer)
	bench.changed.connect(sync);sync()

func build_comparison(layer: CanvasLayer) -> void:
	var controls:=HBoxContainer.new();controls.position=Vector2(20,110);layer.add_child(controls)
	var toggle:=Button.new();toggle.text="COMPARE CAMERAS";toggle.toggle_mode=true;controls.add_child(toggle)
	var capture:=Button.new();capture.text="SAVE BOTH VIEWS";controls.add_child(capture)
	var browse:=Button.new();browse.text="OPEN CAPTURES";browse.disabled=true;controls.add_child(browse)
	browse.pressed.connect(func():OS.shell_open(ProjectSettings.globalize_path(capture_folder)))
	comparison_note=Label.new();comparison_note.text="WATCH compares tables and follows the marked CRT screen.";controls.add_child(comparison_note)
	comparison=PanelContainer.new();comparison.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	comparison.offset_top=155;comparison.offset_bottom=-16;comparison.offset_left=16;comparison.offset_right=-16;layer.add_child(comparison);comparison.hide()
	var background:=StyleBoxFlat.new();background.bg_color=Color("10181f");comparison.add_theme_stylebox_override("panel",background)
	var row:=HBoxContainer.new();comparison.add_child(row)
	for i in 2:
		var column:=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(column)
		var title:=Label.new();title.text="GHOST'S EYES / follows the head" if i==0 else "OUTSIDE / the same moment";column.add_child(title)
		var image:=TextureRect.new();image.texture=bench.ghost.observer.views[i].get_texture()
		image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(image)
	toggle.toggled.connect(func(enabled):comparison.visible=enabled;bench.ghost.observer.set_live(enabled))
	capture.pressed.connect(func():
		var folder:="user://ghost-students/prefab/manual-%d" % Time.get_ticks_usec()
		bench.ghost.observer.request_pair(folder,"comparison"))
	bench.ghost.observer.captured.connect(func(receipt):
		comparison_note.text="Saved both views: "+receipt.label if receipt.status=="saved" else "Capture "+receipt.status
		if receipt.status=="saved":
			capture_folder=receipt.folder;browse.disabled=false
			comparison_note.tooltip_text=ProjectSettings.globalize_path(receipt.record))

func sync() -> void:
	amount.set_value_no_signal(bench.disorder)
	experiment_row.visible=not bench.gallery_open;gallery_row.visible=bench.gallery_open
	status.text="0 original objects / 0.5 separated parts / 1 hybrids    |    %s %.2f    Seed %d" % [bench.stage_name(),bench.disorder,bench.experiment_seed]
	if bench.gallery_open: status.text=bench.gallery.status.text+" / BACK returns without changing the experiment"
