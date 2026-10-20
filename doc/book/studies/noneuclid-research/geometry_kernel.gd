extends RefCounted
## Research kernel, radius=1. Not the lesson or a replacement for Godot physics.
## Hyperboloid coordinates (x,y,z,w); <p,p>_L=-1, w>0.

static func lorentz(a: Vector4, b: Vector4) -> float:
    return a.x*b.x + a.y*b.y + a.z*b.z - a.w*b.w

static func origin() -> Vector4:
    return Vector4(0, 0, 0, 1)

static func from_ball(p: Vector3) -> Vector4:
    assert(p.length_squared() < 1.0, "The ball boundary is not a finite point")
    var d := 1.0 - p.length_squared()
    return Vector4(2*p.x/d, 2*p.y/d, 2*p.z/d, (1+p.length_squared())/d)

static func to_ball(p: Vector4) -> Vector3:
    return Vector3(p.x, p.y, p.z) / (p.w + 1.0)

static func to_klein(p: Vector4) -> Vector3:
    return Vector3(p.x, p.y, p.z) / p.w

static func acosh_safe(x: float) -> float:
    var v := maxf(1.0, x)
    return log(v + sqrt(maxf(0.0, v*v - 1.0)))

static func distance(a: Vector4, b: Vector4) -> float:
    if a.is_equal_approx(b): return 0.0
    return acosh_safe(-lorentz(a, b))

static func boost(p: Vector4, axis: Vector3, length: float) -> Vector4:
    assert(axis.length() > 0.00001)
    var n := axis.normalized()
    var v := Vector3(p.x, p.y, p.z)
    var along := n.dot(v)
    var c := cosh(length)
    var s := sinh(length)
    var out := v + n*((c-1.0)*along + s*p.w)
    return Vector4(out.x, out.y, out.z, c*p.w + s*along)

static func geodesic(a: Vector4, b: Vector4, t: float) -> Vector4:
    var d := distance(a, b)
    if d < 0.00001: return a
    return (sinh((1.0-t)*d)*a + sinh(t*d)*b) / sinh(d)

static func tangent(a: Vector4, b: Vector4) -> Vector4:
    var v := b + lorentz(a, b)*a
    var norm := sqrt(maxf(0.0, lorentz(v, v)))
    assert(norm > 0.00001, "Distinct points required")
    return v / norm

static func angle(a: Vector4, b: Vector4, c: Vector4) -> float:
    return acos(clampf(lorentz(tangent(b,a), tangent(b,c)), -1.0, 1.0))

static func triangle_sum(a: Vector4, b: Vector4, c: Vector4) -> float:
    return angle(c,a,b) + angle(a,b,c) + angle(b,c,a)

static func h2xr_display(horizontal: Vector4, height: float) -> Vector3:
    # View from the horizontal origin. The product metric needs its own log map.
    var v := Vector2(horizontal.x, horizontal.z)
    var s := v.length()
    var factor := 1.0 if s < 0.00001 else log(s + sqrt(s*s+1.0))/s
    return Vector3(v.x*factor, height, v.y*factor)

static func h2xr_distance(a: Vector4, ah: float, b: Vector4, bh: float) -> float:
    return Vector2(distance(a,b), bh-ah).length()

static func transport_sphere(v: Vector3, a: Vector3, b: Vector3) -> Vector3:
    # Along the short great-circle arc. Unit endpoints; antipodes excluded.
    assert(a.dot(b) > -0.9999)
    var axis := a.cross(b)
    if axis.length() < 0.00001: return v
    return v.rotated(axis.normalized(), atan2(axis.length(), a.dot(b)))

static func portal_transfer(source: Transform3D, target: Transform3D) -> Transform3D:
    # Both door fronts face local +Z. Rigid frames only, no scale changes.
    return target * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO) * source.affine_inverse()

static func wrap_xz(p: Vector3, width: float, depth: float) -> Vector3:
    assert(width > 0.0 and depth > 0.0)
    return Vector3(fposmod(p.x + width/2.0, width)-width/2.0, p.y, fposmod(p.z+depth/2.0,depth)-depth/2.0)

