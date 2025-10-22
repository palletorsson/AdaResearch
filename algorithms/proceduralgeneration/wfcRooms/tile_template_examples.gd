## res://algorithms/proceduralgeneration/wfcRooms/tile_template_examples.gd
## Example tile templates for different dungeon themes
## Copy these into wfc_rooms.gd to generate different tile sets
@tool
extends EditorScript

## EXAMPLE 1: Minimal Dungeon (Just the basics)
static func get_minimal_tiles() -> Array:
	return [
		["Floor",     {"N":"open", "E":"open", "S":"open", "W":"open"}],
		["Wall_N",    {"N":"wall", "E":"open", "S":"open", "W":"open"}],
		["Wall_E",    {"N":"open", "E":"wall", "S":"open", "W":"open"}],
		["Wall_S",    {"N":"open", "E":"open", "S":"wall", "W":"open"}],
		["Wall_W",    {"N":"open", "E":"open", "S":"open", "W":"wall"}],
		["Door_N",    {"N":"door", "E":"open", "S":"open", "W":"open"}],
		["Door_E",    {"N":"open", "E":"door", "S":"open", "W":"open"}],
		["Door_S",    {"N":"open", "E":"open", "S":"door", "W":"open"}],
		["Door_W",    {"N":"open", "E":"open", "S":"open", "W":"door"}],
	]

## EXAMPLE 2: Complete Dungeon (All variations)
static func get_complete_tiles() -> Array:
	return [
		# Basic room
		["Floor",       {"N":"open", "E":"open", "S":"open", "W":"open"}],
		
		# Single walls
		["Wall_N",      {"N":"wall", "E":"open", "S":"open", "W":"open"}],
		["Wall_E",      {"N":"open", "E":"wall", "S":"open", "W":"open"}],
		["Wall_S",      {"N":"open", "E":"open", "S":"wall", "W":"open"}],
		["Wall_W",      {"N":"open", "E":"open", "S":"open", "W":"wall"}],
		
		# Corners
		["Corner_NE",   {"N":"wall", "E":"wall", "S":"open", "W":"open"}],
		["Corner_ES",   {"N":"open", "E":"wall", "S":"wall", "W":"open"}],
		["Corner_SW",   {"N":"open", "E":"open", "S":"wall", "W":"wall"}],
		["Corner_WN",   {"N":"wall", "E":"open", "S":"open", "W":"wall"}],
		
		# T-junctions
		["T_NES",       {"N":"wall", "E":"wall", "S":"wall", "W":"open"}],
		["T_ESW",       {"N":"open", "E":"wall", "S":"wall", "W":"wall"}],
		["T_SWN",       {"N":"wall", "E":"open", "S":"wall", "W":"wall"}],
		["T_WNE",       {"N":"wall", "E":"wall", "S":"open", "W":"wall"}],
		
		# Cross
		["+_Cross",     {"N":"wall", "E":"wall", "S":"wall", "W":"wall"}],
		
		# Doors
		["Door_N",      {"N":"door", "E":"open", "S":"open", "W":"open"}],
		["Door_E",      {"N":"open", "E":"door", "S":"open", "W":"open"}],
		["Door_S",      {"N":"open", "E":"open", "S":"door", "W":"open"}],
		["Door_W",      {"N":"open", "E":"open", "S":"open", "W":"door"}],
	]

## EXAMPLE 3: Hallway System (Corridors and rooms)
static func get_hallway_tiles() -> Array:
	return [
		# Rooms (all open - connects to hallways)
		["Room",         {"N":"open", "E":"open", "S":"open", "W":"open"}],
		
		# Hallways (straight corridors)
		["Hall_NS",      {"N":"door", "E":"wall", "S":"door", "W":"wall"}],
		["Hall_EW",      {"N":"wall", "E":"door", "S":"wall", "W":"door"}],
		
		# Hallway corners
		["HallCorner_NE", {"N":"door", "E":"door", "S":"wall", "W":"wall"}],
		["HallCorner_ES", {"N":"wall", "E":"door", "S":"door", "W":"wall"}],
		["HallCorner_SW", {"N":"wall", "E":"wall", "S":"door", "W":"door"}],
		["HallCorner_WN", {"N":"door", "E":"wall", "S":"wall", "W":"door"}],
		
		# Hallway T-junctions
		["HallT_NES",    {"N":"door", "E":"door", "S":"door", "W":"wall"}],
		["HallT_ESW",    {"N":"wall", "E":"door", "S":"door", "W":"door"}],
		["HallT_SWN",    {"N":"door", "E":"wall", "S":"door", "W":"door"}],
		["HallT_WNE",    {"N":"door", "E":"door", "S":"wall", "W":"door"}],
		
		# Hallway cross
		["HallCross",    {"N":"door", "E":"door", "S":"door", "W":"door"}],
		
		# Room connectors (rooms with doors on each side)
		["RoomDoor_N",   {"N":"door", "E":"open", "S":"open", "W":"open"}],
		["RoomDoor_E",   {"N":"open", "E":"door", "S":"open", "W":"open"}],
		["RoomDoor_S",   {"N":"open", "E":"open", "S":"door", "W":"open"}],
		["RoomDoor_W",   {"N":"open", "E":"open", "S":"open", "W":"door"}],
	]

## EXAMPLE 4: Prison/Jail (Cells with bars)
static func get_prison_tiles() -> Array:
	return [
		# Hallway
		["Hall",         {"N":"wall", "E":"wall", "S":"wall", "W":"wall"}],
		
		# Cells with bars (using "bars" socket type)
		["Cell_Bars_N",  {"N":"bars", "E":"wall", "S":"wall", "W":"wall"}],
		["Cell_Bars_E",  {"N":"wall", "E":"bars", "S":"wall", "W":"wall"}],
		["Cell_Bars_S",  {"N":"wall", "E":"wall", "S":"bars", "W":"wall"}],
		["Cell_Bars_W",  {"N":"wall", "E":"wall", "S":"wall", "W":"bars"}],
		
		# Hallway facing bars
		["Guard_N",      {"N":"bars", "E":"wall", "S":"open", "W":"wall"}],
		["Guard_E",      {"N":"wall", "E":"bars", "S":"wall", "W":"open"}],
		["Guard_S",      {"N":"open", "E":"wall", "S":"bars", "W":"wall"}],
		["Guard_W",      {"N":"wall", "E":"open", "S":"wall", "W":"bars"}],
		
		# Corridor
		["Corridor_NS",  {"N":"open", "E":"wall", "S":"open", "W":"wall"}],
		["Corridor_EW",  {"N":"wall", "E":"open", "S":"wall", "W":"open"}],
	]

## EXAMPLE 5: Cave System (Irregular, natural)
static func get_cave_tiles() -> Array:
	return [
		# Open cavern (all open)
		["Cavern",       {"N":"open", "E":"open", "S":"open", "W":"open"}],
		
		# Partial rock walls
		["Rock_N",       {"N":"rock", "E":"open", "S":"open", "W":"open"}],
		["Rock_E",       {"N":"open", "E":"rock", "S":"open", "W":"open"}],
		["Rock_S",       {"N":"open", "E":"open", "S":"rock", "W":"open"}],
		["Rock_W",       {"N":"open", "E":"open", "S":"open", "W":"rock"}],
		
		# Tunnels (narrow passages)
		["Tunnel_NS",    {"N":"open", "E":"rock", "S":"open", "W":"rock"}],
		["Tunnel_EW",    {"N":"rock", "E":"open", "S":"rock", "W":"open"}],
		
		# Rock corners
		["RockCorner_NE", {"N":"rock", "E":"rock", "S":"open", "W":"open"}],
		["RockCorner_ES", {"N":"open", "E":"rock", "S":"rock", "W":"open"}],
		["RockCorner_SW", {"N":"open", "E":"open", "S":"rock", "W":"rock"}],
		["RockCorner_WN", {"N":"rock", "E":"open", "S":"open", "W":"rock"}],
		
		# Crevices (narrow gaps in rock)
		["Crevice_N",    {"N":"crevice", "E":"rock", "S":"rock", "W":"rock"}],
		["Crevice_E",    {"N":"rock", "E":"crevice", "S":"rock", "W":"rock"}],
		["Crevice_S",    {"N":"rock", "E":"rock", "S":"crevice", "W":"rock"}],
		["Crevice_W",    {"N":"rock", "E":"rock", "S":"rock", "W":"crevice"}],
	]

## EXAMPLE 6: Multi-Story (With stairs)
static func get_multistory_tiles() -> Array:
	return [
		# Regular rooms
		["Floor",        {"N":"open", "E":"open", "S":"open", "W":"open", "U":"ceiling", "D":"floor"}],
		
		# Walls
		["Wall_N",       {"N":"wall", "E":"open", "S":"open", "W":"open", "U":"ceiling", "D":"floor"}],
		["Wall_E",       {"N":"open", "E":"wall", "S":"open", "W":"open", "U":"ceiling", "D":"floor"}],
		["Wall_S",       {"N":"open", "E":"open", "S":"wall", "W":"open", "U":"ceiling", "D":"floor"}],
		["Wall_W",       {"N":"open", "E":"open", "S":"open", "W":"wall", "U":"ceiling", "D":"floor"}],
		
		# Stairs going up
		["Stairs_Up_N",  {"N":"door", "E":"wall", "S":"wall", "W":"wall", "U":"stairs", "D":"floor"}],
		["Stairs_Up_E",  {"N":"wall", "E":"door", "S":"wall", "W":"wall", "U":"stairs", "D":"floor"}],
		["Stairs_Up_S",  {"N":"wall", "E":"wall", "S":"door", "W":"wall", "U":"stairs", "D":"floor"}],
		["Stairs_Up_W",  {"N":"wall", "E":"wall", "S":"wall", "W":"door", "U":"stairs", "D":"floor"}],
		
		# Stairs going down (top floor)
		["Stairs_Down_N", {"N":"door", "E":"wall", "S":"wall", "W":"wall", "U":"ceiling", "D":"stairs"}],
		["Stairs_Down_E", {"N":"wall", "E":"door", "S":"wall", "W":"wall", "U":"ceiling", "D":"stairs"}],
		["Stairs_Down_S", {"N":"wall", "E":"wall", "S":"door", "W":"wall", "U":"ceiling", "D":"stairs"}],
		["Stairs_Down_W", {"N":"wall", "E":"wall", "S":"wall", "W":"door", "U":"ceiling", "D":"stairs"}],
		
		# Doors
		["Door_N",       {"N":"door", "E":"open", "S":"open", "W":"open", "U":"ceiling", "D":"floor"}],
		["Door_E",       {"N":"open", "E":"door", "S":"open", "W":"open", "U":"ceiling", "D":"floor"}],
		["Door_S",       {"N":"open", "E":"open", "S":"door", "W":"open", "U":"ceiling", "D":"floor"}],
		["Door_W",       {"N":"open", "E":"open", "S":"open", "W":"door", "U":"ceiling", "D":"floor"}],
	]

## EXAMPLE 7: Zelda-Style (Rooms and locked doors)
static func get_zelda_tiles() -> Array:
	return [
		# Empty room
		["Room",         {"N":"open", "E":"open", "S":"open", "W":"open"}],
		
		# Walls
		["Wall_N",       {"N":"wall", "E":"open", "S":"open", "W":"open"}],
		["Wall_E",       {"N":"open", "E":"wall", "S":"open", "W":"open"}],
		["Wall_S",       {"N":"open", "E":"open", "S":"wall", "W":"open"}],
		["Wall_W",       {"N":"open", "E":"open", "S":"open", "W":"wall"}],
		
		# Normal doors
		["Door_N",       {"N":"door", "E":"open", "S":"open", "W":"open"}],
		["Door_E",       {"N":"open", "E":"door", "S":"open", "W":"open"}],
		["Door_S",       {"N":"open", "E":"open", "S":"door", "W":"open"}],
		["Door_W",       {"N":"open", "E":"open", "S":"open", "W":"door"}],
		
		# Locked doors (need key)
		["LockedDoor_N", {"N":"locked", "E":"open", "S":"open", "W":"open"}],
		["LockedDoor_E", {"N":"open", "E":"locked", "S":"open", "W":"open"}],
		["LockedDoor_S", {"N":"open", "E":"open", "S":"locked", "W":"open"}],
		["LockedDoor_W", {"N":"open", "E":"open", "S":"open", "W":"locked"}],
		
		# Boss room entrance (locked from hallway side, open from inside)
		["BossRoom_N",   {"N":"locked", "E":"wall", "S":"wall", "W":"wall"}],
		["BossRoom_E",   {"N":"wall", "E":"locked", "S":"wall", "W":"wall"}],
		["BossRoom_S",   {"N":"wall", "E":"wall", "S":"locked", "W":"wall"}],
		["BossRoom_W",   {"N":"wall", "E":"wall", "S":"wall", "W":"locked"}],
		
		# Treasure room
		["Treasure",     {"N":"wall", "E":"wall", "S":"wall", "W":"wall"}],
	]

## Helper: Print a tile set to console for easy copying
static func print_tile_set(tiles: Array, set_name: String):
	print("\n=== ", set_name, " ===")
	print("var tiles : Array = [")
	for tile in tiles:
		var name = tile[0]
		var sockets = tile[1]
		var socket_str = JSON.stringify(sockets)
		print('    ["', name, '", ', socket_str, '],')
	print("]")

## Run this script to print all example tile sets
func _run():
	print("\n🎨 WFC Tile Template Examples\n")
	print("Copy any of these into wfc_rooms.gd's _run() function:\n")
	
	print_tile_set(get_minimal_tiles(), "Minimal Dungeon (9 tiles)")
	print_tile_set(get_complete_tiles(), "Complete Dungeon (18 tiles)")
	print_tile_set(get_hallway_tiles(), "Hallway System (16 tiles)")
	print_tile_set(get_prison_tiles(), "Prison/Jail (10 tiles)")
	print_tile_set(get_cave_tiles(), "Cave System (15 tiles)")
	print_tile_set(get_multistory_tiles(), "Multi-Story (16 tiles)")
	print_tile_set(get_zelda_tiles(), "Zelda-Style (18 tiles)")
	
	print("\n✅ Done! Copy the tile set you want into wfc_rooms.gd")
