@tool
extends Control
const Document = preload("document.gd")
const Canvas = preload("canvas.gd")
var document := Document.new()
var canvas: Control
var floor_select: OptionButton
var tool_select: OptionButton
var prop_select: OptionButton
var list: ItemList
var search: LineEdit
var status: Label
var inspector: Label
var x_value: SpinBox
var z_value: SpinBox
var height_value: SpinBox
var listing: Array[int] = []
var wall_start = null
var reload_dialog: ConfirmationDialog
var rows: VBoxContainer
var draft_path := ""

func _ready() -> void:
	custom_minimum_size=Vector2(1000,480)
	var background := ColorRect.new();background.color=Color("18212b");background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);background.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(background)
	rows=VBoxContainer.new();rows.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);rows.add_theme_constant_override("separation",8);add_child(rows)
	var bar := HBoxContainer.new();rows.add_child(bar)
	floor_select=OptionButton.new();bar.add_child(floor_select)
	floor_select.item_selected.connect(func(i): document.floor_index=i;document.selected=-1;wall_start=null;refresh())
	button(bar,"Undo",func(): document.undo();refresh())
	button(bar,"Redo",func(): document.redo();refresh())
	button(bar,"Reload",request_reload)
	button(bar,"Validate",func(): run_io(false))
	button(bar,"Save layout",func(): run_io(true))
	button(bar,"Walk this floor",walk_preview)
	button(bar,"Open source",func(): OS.shell_open(ProjectSettings.globalize_path("res://commons/void/rooms.json")))
	var tools_row := HBoxContainer.new();rows.add_child(tools_row)
	tool_select=OptionButton.new()
	for t in ["Select / drag","Draw unfinished wall","Place prefab","Add route waypoint"]: tool_select.add_item(t)
	tools_row.add_child(tool_select)
	tool_select.item_selected.connect(func(i): canvas.move_tool=i==0;wall_start=null;canvas.hint_start=null;canvas.queue_redraw())
	prop_select=OptionButton.new();tools_row.add_child(prop_select)
	var snap_select := OptionButton.new();snap_select.add_item("Snap 0.5 m");snap_select.add_item("Snap 1 m");snap_select.add_item("Snap 0.1 m");tools_row.add_child(snap_select)
	snap_select.item_selected.connect(func(i): canvas.cell=[.5,1.0,.1][i])
	height_value=number(tools_row,"Wall height",3.2,.5,4.5)
	button(tools_row,"Set wall height",set_wall_height)
	button(tools_row,"Rotate 90°",rotate_selected)
	button(tools_row,"Delete",delete_selected)
	var body := HSplitContainer.new();body.size_flags_vertical=Control.SIZE_EXPAND_FILL;rows.add_child(body)
	canvas=Canvas.new();canvas.document=document;canvas.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_child(canvas)
	canvas.picked.connect(select_entry)
	canvas.moved.connect(func(i,at): document.move_entry(document.entries()[i],at);refresh())
	canvas.placed.connect(place)
	var side := VBoxContainer.new();side.custom_minimum_size.x=265;body.add_child(side)
	search=LineEdit.new();search.placeholder_text="Find an artifact, part or wall…";side.add_child(search);search.text_changed.connect(func(_text): refresh_list())
	list=ItemList.new();list.custom_minimum_size=Vector2(265,220);list.size_flags_vertical=Control.SIZE_EXPAND_FILL;side.add_child(list);list.item_selected.connect(func(i): select_entry(listing[i]))
	inspector=Label.new();side.add_child(inspector)
	var values := HBoxContainer.new();side.add_child(values)
	x_value=number(values,"X",0,-30,30);z_value=number(values,"Z",0,-20,20)
	button(side,"Move selected to X / Z",move_selected)
	status=Label.new();status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;rows.add_child(status)
	reload_dialog=ConfirmationDialog.new();reload_dialog.dialog_text="Discard unsaved edits and reload the current layout?";reload_dialog.confirmed.connect(load_layout);add_child(reload_dialog)
	load_layout()

func button(parent: Node,title: String,action: Callable) -> void:
	var b := Button.new();b.text=title;b.pressed.connect(action);parent.add_child(b)
func number(parent: Node,title: String,value: float,minimum: float,maximum: float) -> SpinBox:
	var label := Label.new();label.text=title;parent.add_child(label)
	var spin := SpinBox.new();spin.min_value=minimum;spin.max_value=maximum;spin.step=.1;spin.value=value;spin.custom_minimum_size.x=78;parent.add_child(spin);return spin
func load_layout() -> void:
	document.load_source();floor_select.clear();prop_select.clear()
	for i in range(document.data.floors.size()): floor_select.add_item("%02d / %s"%[i,document.data.floors[i].title])
	for key in document.catalog.props: prop_select.add_item(str(key))
	floor_select.select(document.floor_index);refresh()
	status.text="Drag a part or assembly. Draw walls with two clicks. Route is an editorial guide, not an in-game restriction."
func request_reload() -> void:
	if document.dirty(): reload_dialog.popup_centered()
	else: load_layout()
func refresh() -> void:
	refresh_list();canvas.queue_redraw()
	inspector.text="Select an item to move."
	var entries := document.entries()
	if document.selected>=0 and document.selected<entries.size():
		var e: Dictionary = entries[document.selected];inspector.text=str(e.label).strip_edges();x_value.value=e.position.x;z_value.value=e.position.y
	status.text=("Unsaved changes. " if document.dirty() else "Saved layout. ")+"Structure stays fixed. Save validates clearances; Walk checks the experience."
func refresh_list() -> void:
	list.clear();listing.clear()
	var entries := document.entries()
	for i in range(entries.size()):
		var e: Dictionary = entries[i]
		if e.kind=="part" and str(e.key).begins_with("Caption") and search.text.is_empty(): continue
		if not search.text.is_empty() and not str(e.label).to_lower().contains(search.text.to_lower()): continue
		listing.append(i);list.add_item(str(e.label))
		if document.selected==i: list.select(list.item_count-1)
func select_entry(index: int) -> void:
	document.selected=index;refresh()
func move_selected() -> void:
	if document.selected<0: return
	document.move_entry(document.entries()[document.selected],Vector2(x_value.value,z_value.value));refresh()
func rotate_selected() -> void:
	if document.selected<0: return
	document.rotate_entry(document.entries()[document.selected]);refresh()
func set_wall_height() -> void:
	if document.selected<0: return
	var e: Dictionary = document.entries()[document.selected]
	if e.kind!="walls": status.text="Select a partition to change its height.";return
	document.remember();document.floor_data().walls[e.index].height=height_value.value;refresh()
func delete_selected() -> void:
	if document.selected<0: return
	var done := document.erase(document.entries()[document.selected]);refresh()
	if not done: status.text="Teaching artifacts stay in the lesson. Move or rotate their parts; Delete removes walls, props and waypoints."
func place(at: Vector2) -> void:
	match tool_select.selected:
		1:
			if wall_start==null:
				wall_start=at;canvas.hint_start=at;canvas.queue_redraw();status.text="Click the other end. Wall locks to its nearest grid axis."
			else:
				var b := at
				if absf(b.x-wall_start.x)>absf(b.y-wall_start.y): b.y=wall_start.y
				else: b.x=wall_start.x
				document.add_wall(wall_start,b,height_value.value);wall_start=null;canvas.hint_start=null;refresh()
		2: document.add_prop(prop_select.get_item_text(prop_select.selected),at);refresh()
		3: document.add_route(at);refresh()
func write_draft() -> String:
	var directory := ProjectSettings.globalize_path("res://ada_run/void-editor")
	DirAccess.make_dir_recursive_absolute(directory)
	FileAccess.open(directory.path_join(".gdignore"),FileAccess.WRITE).close()
	# Each editor instance owns its draft; failed saves keep this file.
	draft_path=directory.path_join("draft-%d.json"%OS.get_process_id())
	FileAccess.open(draft_path,FileAccess.WRITE).store_string(JSON.stringify(document.data,"  ")+"\n")
	return draft_path
func run_io(save: bool) -> bool:
	var arguments := PackedStringArray([ProjectSettings.globalize_path("res://tools/void_editor_io.py"),"--draft",write_draft()])
	if save: arguments.append_array(["--expected",document.revision])
	var output: Array = []
	var code := OS.execute("python",arguments,output,true,false)
	var message := "".join(output).strip_edges()
	var result = JSON.parse_string(message)
	if code!=0 or not result is Dictionary or not result.get("ok",false):
		status.text="Not saved. "+("; ".join(result.get("errors",[])) if result is Dictionary else message)+" Draft: "+draft_path
		return false
	if save:
		document.revision=result.revision;document.saved=JSON.stringify(document.data)
	status.text=result.message
	return true
func walk_preview() -> void:
	if not run_io(false): return
	var args := PackedStringArray(["--path",ProjectSettings.globalize_path("res://"),"--xr-mode","off","res://commons/void/void.tscn","--","--no-bridges","--void-start-floor="+str(document.floor_index),"--void-draft="+draft_path])
	var pid := OS.create_process(OS.get_executable_path(),args,false)
	status.text="Preview launched from this draft. Save layout to use it in the normal VR game." if pid>0 else "Could not start Godot preview."
