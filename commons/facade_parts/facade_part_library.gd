class_name FacadePartLibrary
extends RefCounted

## Central factory for all facade parts. Each part is a Node3D subtree (usually CSG).
## Usage: var node = FacadePartLibrary.create("arched_window", 2.0, 3.0, {"keystone": true})

const _Col := preload("res://commons/facade_parts/parts/column_parts.gd")
const _Open := preload("res://commons/facade_parts/parts/opening_parts.gd")
const _Arch := preload("res://commons/facade_parts/parts/arch_parts.gd")
const _Bal := preload("res://commons/facade_parts/parts/balcony_parts.gd")
const _Cor := preload("res://commons/facade_parts/parts/cornice_parts.gd")
const _Shut := preload("res://commons/facade_parts/parts/shutter_parts.gd")
const _Rail := preload("res://commons/facade_parts/parts/railing_parts.gd")
const _Surf := preload("res://commons/facade_parts/parts/surface_parts.gd")
const _Orn := preload("res://commons/facade_parts/parts/ornament_parts.gd")

static func create(part_name: String, w: float, h: float, params: Dictionary = {}) -> Node3D:
	# Delegate to category part files
	match part_name:
		# Columns
		"col_tuscan", "col_doric", "col_ionic", "col_corinthian", "pilaster", \
		"col_solomonic", "col_composite":
			return _Col.create(part_name, w, h, params)
		# Openings (windows + doors)
		"rect_window", "arched_window", "venetian_bifora", "rose_window", "porthole", \
		"single_door", "double_door", "arched_door", "portal":
			return _Open.create(part_name, w, h, params)
		# Arches
		"round_arch", "pointed_arch", "arcade_arch", "segmental_arch":
			return _Arch.create(part_name, w, h, params)
		# Balconies
		"juliet_balcony", "projecting_balcony", "loggia":
			return _Bal.create(part_name, w, h, params)
		# Cornices
		"dentil_cornice", "cyma_recta", "string_course", "fascia", "modillion":
			return _Cor.create(part_name, w, h, params)
		# Shutters
		"louvered_shutter", "paneled_shutter":
			return _Shut.create(part_name, w, h, params)
		# Railings
		"simple_railing", "balustrade", "iron_railing":
			return _Rail.create(part_name, w, h, params)
		# Wall surfaces
		"plain_wall", "rusticated_block", "stucco", "ashlar":
			return _Surf.create(part_name, w, h, params)
		# Ornaments
		"pediment_tri", "pediment_broken", "medallion", "cartouche", "pilaster_orn":
			return _Orn.create(part_name, w, h, params)
		_:
			push_warning("FacadePartLibrary: unknown part '%s'" % part_name)
			var placeholder = Node3D.new()
			placeholder.name = part_name
			return placeholder


static func get_all_part_names() -> PackedStringArray:
	var names: PackedStringArray = []
	names.append_array(_Col.get_names())
	names.append_array(_Open.get_names())
	names.append_array(_Arch.get_names())
	names.append_array(_Bal.get_names())
	names.append_array(_Cor.get_names())
	names.append_array(_Shut.get_names())
	names.append_array(_Rail.get_names())
	names.append_array(_Surf.get_names())
	names.append_array(_Orn.get_names())
	return names
