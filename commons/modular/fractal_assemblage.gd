extends RefCounted
## A finite recursive assembly: beam + joint + deck, with a separate terminal.
## Each child inherits its parent's local frame, then turns and shrinks.
## Mirrors fractal-assemblage.ts. Fitted original meshes; no structural solver.
static func expression(e: Dictionary) -> Dictionary:
	var parts: Array = []
	_grow(parts,e,Vector3.ZERO,Basis.IDENTITY,float(e.get("size",.85)),0,"Root")
	return {"op":"assemblage","parts":parts}

static func _grow(parts: Array,e: Dictionary,base: Vector3,frame: Basis,s: float,level: int,id: String) -> void:
	var end := base+frame*Vector3(0,1.5*s,0)
	_member(parts,id+"_Branch",str(e.source),(base+end)/2,frame,Vector3(.16,1.5,.16)*s)
	_member(parts,id+"_Joint",str(e.joint_source),end,frame,Vector3.ONE*.34*s)
	_member(parts,id+"_Deck",str(e.deck_source),end+frame*Vector3(0,-.24*s,0),frame,Vector3(.92,.09,.92)*s)
	var depth := clampi(int(e.get("depth",3)),0,3)
	var branches := clampi(int(e.get("branches",3)),1,3)
	if level==depth:
		_member(parts,id+"_Tip",str(e.tip_source),end+frame*Vector3(0,.43*s,0),frame,Vector3(.5,.5,.5)*s)
	else:
		for i in branches:
			var turn := Basis(Vector3.UP,deg_to_rad(float(e.get("twist",35))+i*360.0/branches))
			var lean := Basis(Vector3.BACK,deg_to_rad(float(e.get("angle",42))))
			_grow(parts,e,end,frame*turn*lean,s*float(e.get("ratio",.66)),level+1,id+"_%d"%(i+1))

static func _member(parts: Array,id: String,token: String,at: Vector3,frame: Basis,dims: Vector3) -> void:
	var rot := frame.get_euler()*180/PI
	parts.append({"id":id,"at":[at.x,at.y,at.z],"rot":[rot.x,rot.y,rot.z],"of":{"p":"prefab","token":token,"lab_input":true,"fit_box":[dims.x,dims.y,dims.z]}})
