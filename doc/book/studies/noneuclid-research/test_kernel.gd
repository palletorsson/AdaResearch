extends SceneTree
const K = preload("geometry_kernel.gd")
var checks: Array[Dictionary] = []

func check(name: String, ok: bool) -> void:
    checks.append({"name":name, "passed":ok})
    if not ok: push_error(name)

func near(a: float, b: float, tolerance: float = 0.003) -> bool:
    return absf(a-b) < tolerance

func _initialize() -> void:
    var o := K.origin()
    var source := Transform3D(Basis(Vector3.UP, 0.43), Vector3(1,0,2))
    var target := Transform3D(Basis(Vector3.UP, -0.7), Vector3(-3,1,4))
    var forward := K.portal_transfer(source,target)
    var back := K.portal_transfer(target,source)
    var p := source * Vector3(0.3, 1.2, -0.2)
    check("portal: inverse traversal restores point", (back*(forward*p)).distance_to(p)<0.0001)
    check("portal: side changes from behind entrance to in front of exit", (target.affine_inverse()*(forward*p)).z > 0)
    var velocity := Vector3(1,2,-3)
    check("portal: speed is preserved", near((forward.basis*velocity).length(),velocity.length()))
    check("portal: separation of held point and hand preserved", near((forward*(p+velocity)-forward*p).length(),velocity.length()))
    check("portal: handedness preserved", near(forward.basis.determinant(),1.0))
    check("topology: returns to same torus address", K.wrap_xz(Vector3(15,2,-12),10,8).is_equal_approx(Vector3(-5,2,-4)))
    check("topology: repeated wrapping is idempotent", K.wrap_xz(K.wrap_xz(Vector3(37,2,23),10,8),10,8).is_equal_approx(K.wrap_xz(Vector3(37,2,23),10,8)))
    var arrow := Vector3.UP
    arrow = K.transport_sphere(arrow,Vector3.RIGHT,Vector3.UP)
    arrow = K.transport_sphere(arrow,Vector3.UP,Vector3.BACK)
    arrow = K.transport_sphere(arrow,Vector3.BACK,Vector3.RIGHT)
    check("sphere: octant loop rotates tangent by ninety degrees", near(arrow.dot(Vector3.UP),0))
    check("sphere: transported tangent has unit length", near(arrow.length(),1))
    check("sphere: returned tangent stays tangent", near(arrow.dot(Vector3.RIGHT),0))
    for radius in [0.0,0.2,0.5,0.8]:
        var ball := Vector3(radius,0,0)
        var hp := K.from_ball(ball)
        check("ball round trip r="+str(radius), K.to_ball(hp).distance_to(ball)<0.0001)
        check("hyperboloid constraint r="+str(radius),near(K.lorentz(hp,hp),-1))
        check("radial distance matches log ratio r="+str(radius),near(K.distance(o,hp),log((1+radius)/(1-radius))))
    var a := K.from_ball(Vector3(-0.45,0,-0.2))
    var b := K.from_ball(Vector3(0.5,0,-0.15))
    var c := K.from_ball(Vector3(0.0,0,0.55))
    check("H2: nondegenerate triangle has positive deficit",K.triangle_sum(a,b,c)>0 and K.triangle_sum(a,b,c)<PI)
    var previous := 0.0
    var step_lengths: Array[float] = []
    for i in range(9):
        var t := i/8.0
        var hp := K.geodesic(a,b,t)
        check("geodesic stays on hyperboloid "+str(i),near(K.lorentz(hp,hp),-1))
        check("geodesic equal intrinsic steps "+str(i),near(K.distance(a,hp),t*K.distance(a,b)))
        var moved := K.boost(hp,Vector3(1,0.4,-0.2),0.7)
        check("H3 boost preserves norm "+str(i),near(K.lorentz(moved,moved),-1))
        check("H3 inverse boost "+str(i),K.boost(moved,Vector3(1,0.4,-0.2),-0.7).distance_to(hp)<0.0001)
        check("H3 boost preserves distance "+str(i),near(K.distance(K.boost(a,Vector3(1,0.4,-0.2),0.7),moved),K.distance(a,hp)))
    for i in range(1,6):
        var hp := K.boost(o,Vector3.RIGHT,float(i)*0.5)
        var radius: float = K.to_ball(hp).x
        step_lengths.append(radius-previous)
        previous=radius
    check("disk: equal travel takes less display space near edge",step_lengths[4]<step_lengths[0])
    var h := K.boost(o,Vector3.RIGHT,1.0)
    check("product: one horizontal plus two vertical distance sqrt5",near(K.h2xr_distance(o,0,h,2),sqrt(5)))
    check("product: log-map respects diagonal",K.h2xr_display(h,2).distance_to(Vector3(1,2,0))<0.0001)
    var up := K.boost(o,Vector3.UP,1.0)
    check("H3: vertical distance is also hyperbolic",near(K.distance(o,up),1))
    var x := K.boost(o,Vector3.RIGHT,1)
    check("H3: perpendicular unit legs obey hyperbolic cosine law",near(K.distance(x,up),K.acosh_safe(cosh(1)*cosh(1))))
    check("H3: vertical plane also has angle deficit",K.triangle_sum(o,x,up)<PI)
    var all_passed := true
    for item in checks: all_passed = all_passed and item.passed
    var result := {"scope":"author feasibility, not ghost-student or XR verification", "passed":all_passed,"count":checks.size(),"checks":checks}
    var file := FileAccess.open("res://kernel-results.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(result,"  "))
    print("GEOMETRY FEASIBILITY: ",checks.size()," checks, passed=",all_passed)
    quit(0 if all_passed else 1)
