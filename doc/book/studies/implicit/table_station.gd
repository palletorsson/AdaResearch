extends Node
## Given: the code-critique station. It tests the borrowed table against itself
## and prints what it finds. Open table_station.tscn and run it with F6.
## The test needs no field. For each of the 256 cases, the corner bits alone
## say which of a cell's 12 edges are crossed: an edge is crossed when its two
## corners are on different sides. Both of Ada's lists have to agree with that.

const Table := preload("res://mc_table.gd")

func _ready() -> void:
	var triangles := 0
	var wrong_triangle_rows: Array[int] = []
	var wrong_edge_rows: Array[int] = []
	var thirteenth: Array[int] = []
	for which in 256:
		var crossed := 0   # one bit for each edge whose corners are on different sides
		for edge in 12:
			var a: int = Table.EDGE_CONNECTIONS[edge][0]
			var b: int = Table.EDGE_CONNECTIONS[edge][1]
			if ((which >> a) & 1) != ((which >> b) & 1):
				crossed |= 1 << edge
		var used := 0      # one bit for each edge the triangles of this row stand on
		for edge: int in Table.TRIANGLE_TABLE[which]:
			used |= 1 << edge
		@warning_ignore("integer_division")
		triangles += Table.TRIANGLE_TABLE[which].size() / 3
		if used != crossed:
			wrong_triangle_rows.append(which)
		if Table.EDGE_TABLE[which] != crossed:
			wrong_edge_rows.append(which)
		if Table.EDGE_TABLE[which] >= 1 << 12:
			thirteenth.append(which)
	print("triangle table: ", Table.TRIANGLE_TABLE.size(), " rows, ", triangles, " triangles; rows that disagree with the corner bits: ", wrong_triangle_rows)
	print("edge table: ", Table.EDGE_TABLE.size(), " rows; rows that disagree with the corner bits: ", wrong_edge_rows)
	print("edge table: rows that name a thirteenth edge: ", thirteenth)
