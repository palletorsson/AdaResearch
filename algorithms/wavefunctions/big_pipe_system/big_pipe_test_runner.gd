@tool
extends Node3D

func _ready():
	# Allow time for children to be ready?
	# Just call generate
	if $SystemTest:
		$SystemTest.generate_pipes("f,s,f,t,f,x,f,l,f,r,f,u,f,d,f,vu,f,vd,f,cap")
