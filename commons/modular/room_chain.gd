extends RefCounted
## Repetition becomes architecture. Each solid is an independently editable
## instance of the selected construction prefab, fitted to a structural envelope.
## Keep the numeric grammar in sync with room-chain.ts; parity is tested on exports.
static func expression(e: Dictionary) -> Dictionary:
	var count: int = clampi(int(e.get("count", 3)), 2, 6)
	var s: float = float(e.get("size", 1.0))
	var width := 3.6
	var depth := 3.2
	var height := 2.7
	var thick := .09
	var opening: float = float(e.get("opening", 1.4))
	var corridor: float = float(e.get("corridor", 1.2))
	var offset: float = minf(.55, (width-opening)/2.0-.2)
	var pitch: float = depth+corridor
	var parts: Array = []
	for i in count:
		var z: float = (i-(count-1)/2.0)*pitch
		var prefix := "Room%02d_" % (i+1)
		_panel(parts,e,prefix+"Floor",Vector3(0,-.043,z),Vector3(width+.18,.09,depth+.18),s)
		if int(e.get("roof",1))==1:
			_panel(parts,e,prefix+"Roof",Vector3(0,height+.045,z),Vector3(width+.18,.09,depth+.18),s)
		for side in [-1,1]:
			_panel(parts,e,prefix+("Left" if side==-1 else "Right"),Vector3(side*(width/2+.045),height/2,z),Vector3(thick,height,depth),s)
			var joint: int = i-1 if side==-1 else i
			var door: float = offset if joint%2==0 else -offset
			var face: String = "Entry" if side==-1 else "Exit"
			var edge_z: float = z+side*depth/2
			var left: float = door-opening/2+width/2
			var right: float = width/2-door-opening/2
			_panel(parts,e,prefix+face+"Left",Vector3(-width/2+left/2,height/2,edge_z),Vector3(left,height,thick),s)
			_panel(parts,e,prefix+face+"Right",Vector3(width/2-right/2,height/2,edge_z),Vector3(right,height,thick),s)
			_panel(parts,e,prefix+face+"Lintel",Vector3(door,2.25+(height-2.25)/2,edge_z),Vector3(opening,height-2.25,thick),s)
		if i<count-1:
			var cx: float = offset if i%2==0 else -offset
			var cz: float = z+pitch/2
			var cp := "Corridor%02d_" % (i+1)
			_panel(parts,e,cp+"Floor",Vector3(cx,-.043,cz),Vector3(opening+.18,.09,corridor+.18),s)
			if int(e.get("roof",1))==1:
				_panel(parts,e,cp+"Roof",Vector3(cx,2.295,cz),Vector3(opening+.18,.09,corridor+.18),s)
			for side in [-1,1]:
				_panel(parts,e,cp+("Left" if side==-1 else "Right"),Vector3(cx+side*(opening/2+.045),1.125,cz),Vector3(thick,2.25,corridor),s)
	return {"op":"assemblage","parts":parts}

static func _panel(parts: Array,e: Dictionary,id: String,center: Vector3,size: Vector3,s: float) -> void:
	parts.append({"id":id,"at":[center.x*s,center.y*s,center.z*s],"of":{"p":"prefab","token":str(e.get("source","timber_panel_2x2")),"lab_input":true,"fit_box":[size.x*s,size.y*s,size.z*s]}})
