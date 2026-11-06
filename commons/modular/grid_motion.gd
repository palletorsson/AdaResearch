extends RefCounted
## Same YXZ, pivot, composition order and clock as transformation-grid.ts.
static func v(a: Array) -> Vector3:
	return Vector3(a[0],a[1],a[2])

static func clock(m: Dictionary, seconds: float) -> float:
	if not m.enabled: return 0.0
	var u := fposmod(seconds / float(m.period) + float(m.phase), 1.0)
	if m.curve == "loop": return u
	if m.curve == "sine": return .5-.5*cos(TAU*u)
	var half := u*2.0 if u<.5 else 2.0-u*2.0
	return clampf((half-float(m.wait))/(1.0-2.0*float(m.wait)),0,1)

static func pose(p: Dictionary, grid: Dictionary, seconds: float, parts: Dictionary) -> Transform3D:
	var pos := v(p.cell)
	if not p.has("parent"): pos = point(p.cell,grid)
	var orientation := Transform3D(Basis.from_euler(v(p.rotation)*PI/180.0,EULER_ORDER_YXZ)*Basis.from_scale(v(p.mirror)),Vector3.ZERO)
	var m: Dictionary = p.motion
	var q := clock(m,seconds)
	var pivot := Transform3D(Basis.IDENTITY,v(m.pivot))
	var ops := {
		"T":Transform3D(Basis.IDENTITY,v(m.travel)*q),
		"R":pivot*Transform3D(Basis.from_euler(v(m.turn)*q*PI/180.0,EULER_ORDER_YXZ),Vector3.ZERO)*pivot.affine_inverse(),
		"S":pivot*Transform3D(Basis.from_scale(Vector3.ONE+(v(m.scale)-Vector3.ONE)*q),Vector3.ZERO)*pivot.affine_inverse()}
	var movement := Transform3D.IDENTITY
	if m.enabled:
		for letter in str(m.order): movement=ops[letter]*movement
	var result := Transform3D(Basis.IDENTITY,pos)*(orientation*movement if m.frame=="local" else movement*orientation)
	if p.has("parent"): return pose(parts[p.parent],grid,seconds,parts)*result
	return result

static func point(a: Array, grid: Dictionary) -> Vector3:
	return Vector3((float(a[0])+.5-float(grid.columns)/2)*float(grid.cell),a[1],(float(a[2])+.5-float(grid.rows)/2)*float(grid.cell))
