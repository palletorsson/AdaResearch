extends Node3D
const Kit=preload("geometry.gd")
func _ready() -> void:
	# Three orthogonal edges meet the actual floor/wall corner. The fourth face
	# cuts diagonally across it, replacing the inaccessible right-angle recess.
	var v:=PackedVector3Array([Vector3.ZERO,Vector3(2.3,0,0),Vector3(0,2.3,0),Vector3(0,0,2.3)])
	Kit.solid(self,"CornerTetrahedron",v,Kit.tetra_faces(),Color("d991ad"))
	Kit.label(self,"FOUR FACES / A DIFFERENT CORNER",Vector3(1.2,0.015,2.65),23).rotation.x=-PI/2
