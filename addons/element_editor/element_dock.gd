@tool
extends Control
## Dock panel for selecting elements to place.

var plugin  # Reference to ElementEditorPlugin
var subset_data: ElementSubsetData

var current_layout = null
var current_subset_id: String = ""

# UI elements
var subset_selector: OptionButton
var category_tabs: TabContainer
var element_lists: Dictionary = {}  # category_id -> ItemList
var info_label: Label
var status_label: Label


func _ready():
	name = "Elements"
	custom_minimum_size = Vector2(200, 300)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)
	
	# Header
	var header = Label.new()
	header.text = "Element Editor"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 16)
	vbox.add_child(header)
	
	vbox.add_child(HSeparator.new())
	
	# Subset selector
	var subset_hbox = HBoxContainer.new()
	vbox.add_child(subset_hbox)
	
	var subset_label = Label.new()
	subset_label.text = "Subset:"
	subset_hbox.add_child(subset_label)
	
	subset_selector = OptionButton.new()
	subset_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	subset_selector.item_selected.connect(_on_subset_selected)
	subset_hbox.add_child(subset_selector)
	
	# Info label
	info_label = Label.new()
	info_label.text = "Select an ElementLayoutNode"
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(info_label)
	
	# Category tabs
	category_tabs = TabContainer.new()
	category_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	category_tabs.tab_changed.connect(_on_category_changed)
	vbox.add_child(category_tabs)
	
	vbox.add_child(HSeparator.new())
	
	# Status label
	status_label = Label.new()
	status_label.text = "Ready"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(status_label)
	
	# Cable legend (collapsible)
	var legend_toggle = Button.new()
	legend_toggle.text = "▶ Cable Colors"
	legend_toggle.flat = true
	legend_toggle.toggle_mode = true
	legend_toggle.toggled.connect(_on_legend_toggled)
	vbox.add_child(legend_toggle)
	
	_cable_legend = VBoxContainer.new()
	_cable_legend.name = "CableLegend"
	_cable_legend.visible = false
	vbox.add_child(_cable_legend)
	
	_populate_cable_legend()
	
	# Populate subset selector
	call_deferred("_populate_subsets")


var _cable_legend: VBoxContainer

const CABLE_COLORS = {
	"frequency": Color(0.2, 0.8, 1.0),
	"amplitude": Color(0.2, 1.0, 0.4),
	"duration": Color(1.0, 0.8, 0.2),
	"cutoff": Color(1.0, 0.4, 0.2),
	"resonance": Color(1.0, 0.2, 0.6),
	"attack": Color(0.6, 0.2, 1.0),
	"release": Color(0.4, 0.4, 1.0),
}


func _populate_cable_legend():
	for param in CABLE_COLORS:
		var hbox = HBoxContainer.new()
		
		var color_rect = ColorRect.new()
		color_rect.custom_minimum_size = Vector2(16, 16)
		color_rect.color = CABLE_COLORS[param]
		hbox.add_child(color_rect)
		
		var label = Label.new()
		label.text = "  " + param
		label.add_theme_font_size_override("font_size", 11)
		hbox.add_child(label)
		
		_cable_legend.add_child(hbox)


func _on_legend_toggled(pressed: bool):
	_cable_legend.visible = pressed
	var toggle = _cable_legend.get_parent().get_child(_cable_legend.get_index() - 1) as Button
	if toggle:
		toggle.text = ("▼ " if pressed else "▶ ") + "Cable Colors"


func _populate_subsets():
	if not subset_data:
		return
	
	subset_selector.clear()
	subset_selector.add_item("-- Select Subset --", 0)
	
	var ids = subset_data.get_subset_ids()
	for i in range(ids.size()):
		var id = ids[i]
		var subset = subset_data.get_subset(id)
		var display_name = subset.get("name", id)
		subset_selector.add_item(display_name, i + 1)
		subset_selector.set_item_metadata(i + 1, id)


func set_layout(layout):
	"""Called when an ElementLayoutNode is selected."""
	current_layout = layout
	
	if layout == null:
		info_label.text = "Select an ElementLayoutNode"
		info_label.visible = true
		category_tabs.visible = false
		subset_selector.disabled = true
		return
	
	info_label.visible = false
	category_tabs.visible = true
	subset_selector.disabled = false
	
	# Try to get subset from layout
	var layout_subset = layout.subset_id if layout.get("subset_id") else ""
	if not layout_subset.is_empty():
		_select_subset_by_id(layout_subset)


func _select_subset_by_id(subset_id: String):
	for i in range(subset_selector.item_count):
		if subset_selector.get_item_metadata(i) == subset_id:
			subset_selector.select(i)
			_on_subset_selected(i)
			return


func _on_subset_selected(index: int):
	var subset_id = subset_selector.get_item_metadata(index)
	if subset_id == null or subset_id == "":
		current_subset_id = ""
		_clear_categories()
		return
	
	current_subset_id = subset_id
	_populate_categories(subset_id)
	
	# Update layout's subset
	if current_layout and current_layout.has_method("set_subset"):
		current_layout.set_subset(subset_id)
	elif current_layout:
		current_layout.subset_id = subset_id
		current_layout.grid_size = subset_data.get_grid_size(subset_id)
		current_layout.orientation_plane = subset_data.get_orientation_plane(subset_id)


func _clear_categories():
	for child in category_tabs.get_children():
		child.queue_free()
	element_lists.clear()


func _populate_categories(subset_id: String):
	_clear_categories()
	
	var categories = subset_data.get_categories(subset_id)
	
	for category in categories:
		var cat_id = category.get("id", "")
		var cat_name = category.get("name", cat_id)
		var cat_color = Color.from_string(category.get("color", "#FFFFFF"), Color.WHITE)
		
		# Create scroll container for this category
		var scroll = ScrollContainer.new()
		scroll.name = cat_name
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		category_tabs.add_child(scroll)
		
		# Item list for elements
		var item_list = ItemList.new()
		item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
		item_list.max_columns = 1
		item_list.icon_mode = ItemList.ICON_MODE_LEFT
		item_list.select_mode = ItemList.SELECT_SINGLE
		item_list.item_selected.connect(_on_element_selected.bind(cat_id))
		item_list.item_activated.connect(_on_element_activated.bind(cat_id))
		scroll.add_child(item_list)
		
		element_lists[cat_id] = item_list
		
		# Populate with elements
		var elements = subset_data.get_elements_by_category(subset_id, cat_id)
		for element in elements:
			var elem_id = element.get("id", "")
			var elem_name = element.get("name", elem_id)
			var elem_icon = element.get("icon", "?")
			var elem_size = element.get("size", [1, 1])
			
			# Build display string with parameter info
			var display = "%s %s (%dx%d)" % [elem_icon, elem_name, elem_size[0], elem_size[1]]
			
			# Add parameter indicator for controls
			if element.has("control"):
				var ctrl = element["control"]
				var param = ctrl.get("parameter", "")
				if param != "":
					display += " → %s" % param
				elif ctrl.has("action"):
					display += " [%s]" % ctrl["action"]
			
			# Add binding indicator for displays
			if element.has("display"):
				var disp = element["display"]
				var bind_count = 0
				if disp.has("freq_param"): bind_count += 1
				if disp.has("amp_param"): bind_count += 1
				if bind_count > 0:
					display += " ← %d param" % bind_count
			
			var idx = item_list.add_item(display)
			item_list.set_item_metadata(idx, elem_id)
			
			# Build detailed tooltip
			var tooltip = element.get("description", "")
			if element.has("control"):
				var ctrl = element["control"]
				tooltip += "\n\nControl: %s" % ctrl.get("type", "slider")
				if ctrl.has("parameter"):
					tooltip += "\nParameter: %s" % ctrl["parameter"]
					tooltip += "\nRange: %.2f - %.2f" % [ctrl.get("min", 0.0), ctrl.get("max", 1.0)]
					tooltip += "\nDefault: %.2f" % ctrl.get("default", 0.5)
			if element.has("display"):
				var disp = element["display"]
				tooltip += "\n\nDisplay: %s" % disp.get("type", "monitor")
				if disp.has("freq_param"):
					tooltip += "\nFreq binding: %s" % disp["freq_param"]
				if disp.has("amp_param"):
					tooltip += "\nAmp binding: %s" % disp["amp_param"]
			
			item_list.set_item_tooltip(idx, tooltip)


func _on_category_changed(tab_index: int):
	pass  # Could highlight category color or something


func _on_element_selected(index: int, category_id: String):
	var item_list = element_lists.get(category_id)
	if not item_list:
		return
	
	var element_id = item_list.get_item_metadata(index)
	
	# Show parameter info for audio elements
	var element = subset_data.get_element(current_subset_id, element_id)
	var info_parts = ["Selected: " + element_id]
	
	if element.has("control"):
		var ctrl = element["control"]
		var param = ctrl.get("parameter", "")
		var p_min = ctrl.get("min", 0.0)
		var p_max = ctrl.get("max", 1.0)
		if param != "":
			info_parts.append("→ %s [%.1f - %.1f]" % [param, p_min, p_max])
	
	if element.has("display"):
		var disp = element["display"]
		var bindings = []
		if disp.has("freq_param"):
			bindings.append("freq:" + disp["freq_param"])
		if disp.has("amp_param"):
			bindings.append("amp:" + disp["amp_param"])
		if bindings.size() > 0:
			info_parts.append("← " + ", ".join(bindings))
	
	status_label.text = " | ".join(info_parts)


func _on_element_activated(index: int, category_id: String):
	"""Double-click starts placement mode."""
	var item_list = element_lists.get(category_id)
	if not item_list:
		return
	
	var element_id = item_list.get_item_metadata(index)
	
	if plugin and plugin.has_method("start_placing"):
		plugin.start_placing(element_id)
		var element = subset_data.get_element(current_subset_id, element_id)
		var param_hint = ""
		if element.has("control"):
			param_hint = " [%s]" % element["control"].get("parameter", "")
		status_label.text = "Placing: " + element_id + param_hint + " (R=rotate, Right-click=cancel)"
