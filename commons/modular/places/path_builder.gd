extends RefCounted
## Explicit ground paths join curated places. Width changes tile count, never part scale.
## Points are centre-line [x,z] metres. No automatic obstacle routing or raised bridges.
static func validate(raw:Dictionary)->PackedStringArray:
	var errors:=PackedStringArray();var paths:Variant=raw.get("paths",[])
	if not paths is Array:return PackedStringArray(["paths must be an array"])
	var ids:Dictionary={}
	for path in paths:
		if not path is Dictionary:errors.append("Path must be an object");continue
		var id:=str(path.get("id",""))
		if not id.is_valid_identifier() or ids.has(id):errors.append("Path needs a unique stable id: "+id)
		ids[id]=true
		for key in path:
			if key not in ["id","points","width"]:errors.append(id+": unknown path field "+str(key))
		var width:Variant=path.get("width",2)
		if not (width is int or width is float) or (width!=2 and width!=4):errors.append(id+": ground path width must be 2 or 4 metres")
		var points:Variant=path.get("points",null)
		if not points is Array or points.size()<2 or points.size()>16:errors.append(id+": path needs 2..16 points");continue
		var valid:=true
		for point in points:
			if not point is Array or point.size()!=2 or not point.all(func(n):return (n is int or n is float) and is_finite(float(n)) and absf(n)<=48 and is_equal_approx(float(n),roundf(n))):
				errors.append(id+": points need whole [x,z] metres within 48m");valid=false
		if not valid:continue
		for i in range(1,points.size()):
			var a:Array=points[i-1];var b:Array=points[i]
			if (a[0]==b[0])==(a[1]==b[1]):errors.append(id+": each segment must move along exactly one axis")
	return errors

static func build_all(builder:Object,raw:Dictionary)->void:
	for path in raw.get("paths",[]):
		var width:int=path.get("width",2);var half:int=width/2
		for i in range(1,path.points.size()):
			var a:Array=path.points[i-1];var b:Array=path.points[i]
			# Square ends fill turns and junctions; the existing tile deduplication
			# gives each one-metre cell one owner, including overlapping paths.
			builder.floor_rect(str(path.id)+"_%02d"%i,minf(a[0],b[0])-half,minf(a[1],b[1])-half,int(absf(a[0]-b[0]))+width,int(absf(a[1]-b[1]))+width,.02,1)
		builder.recipe.get_or_add("paths",[]).append(path.duplicate(true))
