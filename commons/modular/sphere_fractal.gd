extends RefCounted
## Finite, editable pose of meshfractal/fractal.gd's five-child hierarchy.
## Its sag is a prescribed rotation, not a gravity/rigid-body simulation.
## Same Park–Miller draws and YXZ poses as sphere-fractal.ts.
static func coefficients(e: Dictionary) -> Array:
	var result: Array=[]
	var rng := [maxi(1,int(e.get("seed",17)))]
	var count := 1
	for level in clampi(int(e.get("depth",4)),1,4):
		var row: Array=[]
		for i in count:
			var sign_value := -1.0 if _rand(rng)<float(e.get("reverse",.25)) else 1.0
			row.append({"speed":sign_value*float(e.get("speed",22.5))*lerpf(.88888889,1.11111111,_rand(rng)),"sag":float(e.get("sag",20))*lerpf(.75,1.25,_rand(rng))})
		result.append(row);count*=5
	return result

static func expression(e: Dictionary) -> Dictionary:
	var parts: Array=[]
	var rows := coefficients(e)
	var rotations := [Basis.IDENTITY,Basis(Vector3.BACK,PI/2),Basis(Vector3.BACK,-PI/2),Basis(Vector3.RIGHT,PI/2),Basis(Vector3.RIGHT,-PI/2)]
	var previous: Array=[]
	var scale_value := float(e.get("size",1.2))
	for level in rows.size():
		var current: Array=[]
		for i in rows[level].size():
			var settings: Dictionary=rows[level][i]
			var spin := Basis(Vector3.UP,deg_to_rad(settings.speed*float(e.get("phase",0))))
			var frame := spin
			var position := Vector3(0,float(e.get("size",1.2)),0)
			var id := "Root"
			if level>0:
				var parent: Dictionary=previous[i/5]
				var child: Basis=rotations[i%5]
				var up: Vector3=parent.frame*child*Vector3.UP
				var sag_axis := Vector3.UP.cross(up)
				var base: Basis=parent.frame
				if sag_axis.length()>.0000001:base=Basis(sag_axis.normalized(),deg_to_rad(settings.sag)*sag_axis.length())*base
				frame=base*child*spin
				position=parent.position+frame*Vector3(0,float(e.get("spacing",1.5))*scale_value,0)
				id=parent.id+"_%d"%(i%5+1)
			var token: String=str(e.get("source","trace_point_ball"))
			if level==rows.size()-1:token=str(e.get("tip_source","construction_cube"))
			elif level>0 and level%2==0:token=str(e.get("inner_source",token))
			var rot := frame.get_euler()*180/PI
			parts.append({"id":id,"at":[position.x,position.y,position.z],"rot":[rot.x,rot.y,rot.z],"of":{"p":"prefab","token":token,"lab_input":true,"fit_box":[scale_value,scale_value,scale_value]}})
			current.append({"id":id,"frame":frame,"position":position})
		previous=current;scale_value*=float(e.get("ratio",.5))
	return {"op":"assemblage","parts":parts}

static func _rand(state: Array) -> float:
	state[0]=(int(state[0])*48271)%2147483647
	return float(state[0])/2147483647.0
