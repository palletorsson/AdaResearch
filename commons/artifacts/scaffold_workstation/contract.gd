extends RefCounted
## Authority for the opt-in workshop-built playground recipes. Legacy recipes
## are unaffected. A legal shape also needs its earlier point/edge construction.
const Model=preload("model.gd")
const INTRO={"point":"Point_One","rod":"Point_Lines","rod_short":"Point_Lines","panel":"Point_Triangle_Context","quad":"Point_Animatedcube","wedge":"Primitives_Polythedra","pyramid":"Primitives_Polythedra"}
const SIZES={"point":Vector3(.36,.36,.36),"rod":Vector3(.15,2,.15),"rod_short":Vector3(.15,1,.15),"panel":Vector3(2,.072,2),"quad":Vector3(2,.072,2),"wedge":Vector3(1.6,1,2),"pyramid":Vector3(2,1,2)}

static func validate(recipe:Dictionary)->PackedStringArray:
	var errors:=PackedStringArray()
	if not recipe.has("authorizedKit"):return errors
	if not is_equal_approx(float(recipe.authorizedKit.get("unitMetres",0)),Model.WORLD_STEP):errors.append("Wrong module size")
	var ids:Dictionary={}
	for part in recipe.get("parts",[]):
		if part.get("workshop_profile","") not in ["","fitted"]:errors.append("Unknown workshop fit profile: "+str(part.id))
		if ids.has(part.id):errors.append("Duplicate part: "+part.id)
		ids[part.id]=true
		var r:=Model.canonical(part.get("workshop_record",{}))
		if r.is_empty() or part.get("source","")!="workshop_"+str(r.get("kind","")):
			errors.append("Unauthorized part: "+str(part.get("id","")));continue
		var size:Vector3=Vector3(part.size[0],part.size[1],part.size[2])
		var nominal:Vector3=SIZES[r.kind]
		if r.kind in ["panel","quad"]:nominal*=Vector3(r.get("span",1),1,r.get("span",1))
		if not size.is_equal_approx(nominal):errors.append("Resized member: "+part.id)
		if part.get("introduced","")!=INTRO[r.kind]:errors.append("Missing lineage: "+part.id)
		# JSON uses floats; compare values rather than Array's element type tags.
		var scale_vector:=Vector3(part.motion.scale[0],part.motion.scale[1],part.motion.scale[2])
		var mirror_vector:=Vector3(part.mirror[0],part.mirror[1],part.mirror[2])
		if not scale_vector.is_equal_approx(Vector3.ONE) or not mirror_vector.is_equal_approx(Vector3.ONE):errors.append("Non-rigid member: "+part.id)
	var covered:Dictionary={}
	for assembly in recipe.get("assemblies",[]):
		if not Model.new().restore(assembly.records):errors.append("Unbuildable assembly: "+assembly.id)
		for id in assembly.members:
			if not ids.has(id):errors.append("Missing member: "+id)
			covered[id]=true
	for id in ids:
		if not covered.has(id):errors.append("Member outside any construction: "+id)
	return errors
