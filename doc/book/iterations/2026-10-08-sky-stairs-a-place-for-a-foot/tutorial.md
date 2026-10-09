# A place for a foot

## Learning elements

- Sampling an angle into positions
- Circular coordinates with a changing radius
- Turning each tread around Y
- Matching a mesh with collision
- Comparing centres, edges and support

In Air Music, samples made a sound and its visible trace. Here samples place solid parts. The large stair in this hall turns twice while rising. Its height increases evenly; sine changes its radius. Follow its lower steps from the surrounding floor. Where do two neighbouring treads actually meet?

We return to the cube from Primitives and Transformation. Flatten it into a tread, place eleven copies along a quarter turn, and give each copy collision. The pink LineSkin from Lines joins their top centres. That line describes the sampled path; only the treads supply support.

## Continue inside Endless Museum

Keep your Day Zero museum working copy, camera, light and player. Save the two complete files below together. Attach `10_sampled_treads.gd` to an empty Node3D in the Sky Stairs learner bay: **hall-local (16, 0, 10), Y rotation 0, scale (1, 1, 1)**. Run the museum as before. The script constructs its own treads, collision shapes, labels and line. It does not replace the existing tall stair or require named scene children.

Start beside the lower end and inspect from the floor. This is a short construction study, not a completed stair controller. The prepared player determines stepping and jumping; collision alone does not teach that controller to climb.

## Place, then turn

For sample `i`, the angle is `i * angle_step`. The Unit Circle gave us cosine and sine as coordinates. Here they occupy X and Z, leaving Y for height. `index * rise` increases the top height by 0.11 metres per sample. There are ten intervals between eleven treads: the last top is 1.10 metres high.

`radius + amplitude * sin(2.0 * angle)` widens and narrows the path. Sine changes the distance from the centre, not the height. With these settings, sample 0 starts at radius 2.5 metres, sample 5 reaches 2.95, and sample 10 returns to 2.5.

<!-- student-code:10_sampled_treads.gd -->

```gdscript
extends Node3D

const LineSkin = preload("line_skin.gd")
var count := 11
var angle_step := TAU / 40.0
var radius := 2.5
var amplitude := 0.45
var rise := 0.11
var tread_size := Vector3(1.2, 0.12, 0.6)
var points: Array[Vector3] = []
var treads: Array[StaticBody3D] = []
var label: Label3D

func sample_position(index: int) -> Vector3:
    var angle := index * angle_step
    var r := radius + amplitude * sin(2.0 * angle)
    return Vector3(r * cos(angle), index * rise, r * sin(angle))

func text_at(words: String, at: Vector3, size: int = 24) -> Label3D:
    var text := Label3D.new()
    text.text = words
    text.position = at
    text.font_size = size
    text.pixel_size = 0.0025
    text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    add_child(text)
    return text

func _ready() -> void:
    var finish := StandardMaterial3D.new()
    finish.albedo_color = Color(0.87, 0.86, 0.83)
    finish.roughness = 0.7
    for i in range(count):
        var top := sample_position(i)
        points.append(top)
        var tread := StaticBody3D.new()
        tread.position = top - Vector3.UP * tread_size.y * 0.5
        tread.rotation.y = -i * angle_step
        var surface := MeshInstance3D.new()
        var box := BoxMesh.new()
        box.size = tread_size
        surface.mesh = box
        surface.material_override = finish
        tread.add_child(surface)
        var boundary := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = tread_size
        boundary.shape = shape
        tread.add_child(boundary)
        add_child(tread)
        treads.append(tread)
        if i > 0:
            var line := LineSkin.new()
            add_child(line)
            var previous := points[i - 1] + Vector3.UP * 0.025
            var delta := top + Vector3.UP * 0.025 - previous
            line.show_segment(previous, delta, delta.length())
        if i in [0, 5, 10]:
            text_at("%d | top %.2f m" % [i, top.y], top + Vector3.UP * 0.28, 18)
    var inner := edge_distance(4, 5, -1.0)
    var outer := edge_distance(4, 5, 1.0)
    label = text_at("Same rise: %.2f m\n4 to 5: inner %.2f m | outer %.2f m\nDistances between side midpoints, not clear gaps" % [rise, inner, outer], Vector3(0, 1.6, 1.0))

func edge_position(index: int, side: float) -> Vector3:
    var tread := treads[index]
    var local := Vector3(side * tread_size.x * 0.5, tread_size.y * 0.5, 0)
    return tread.transform * local

func edge_distance(a: int, b: int, side: float) -> float:
    return edge_position(a, side).distance_to(edge_position(b, side))
```


The box's origin is its centre. Subtracting half its thickness puts its **top**, rather than its middle, on the sampled position. The collision box uses the same dimensions and the same parent as the visible box. Moving or turning that parent changes both together.

The tread's local X axis points outward from the centre. Godot's Y rotation needs `-angle` for that axis to align with `(cos(angle), 0, sin(angle))`. Local Z then runs around the turn. We use a radial orientation here; it is not the exact tangent of the changing-radius curve. The difference is another construction choice to inspect.

`edge_position()` transforms a point on a tread into the study's local frame. We compare the inner and outer side midpoints of treads 4 and 5. Those are distances between chosen points, **not measurements of an open gap**. Thickness, depth, turning and overlap determine the actual boundary. Stand at the outside of the turn, then look from the inside. A regular rise does not make those two edges equivalent.

## The carried line

This is the unchanged finite-cylinder renderer from earlier lessons. It gives the path a visible thickness. It has no collision and cannot fill a gap between treads.

<!-- student-code:line_skin.gd -->

```gdscript
# Supplied renderer, adapted from commons/primitives/line/line.gd.
# This finite cylinder gives the segment a visible thickness. It is not a collider.
# Inputs share the parent station's local frame; that station has unit scale.
extends MeshInstance3D

func _init() -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.012
	cylinder.bottom_radius = 0.012
	cylinder.radial_segments = 16
	cylinder.rings = 0
	mesh = cylinder
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(0.98, 0.70, 0.82)
	finish.roughness = 0.3
	material_override = finish
	visible = false

func show_segment(start: Vector3, displacement: Vector3, distance: float) -> void:
	# A zero-length segment has no direction. Do not normalize it.
	visible = distance > 0.0001
	if not visible:
		return
	(mesh as CylinderMesh).height = distance
	position = start + displacement * 0.5
	# CylinderMesh runs along local Y. This borrowed basis aligns it to the ends.
	var direction := displacement / distance
	var right := direction.cross(Vector3.UP).normalized()
	if right.length() < 0.001:
		right = Vector3.RIGHT
	var depth := right.cross(direction).normalized()
	basis = Basis(right, direction, depth)
```


## Make a prediction, then check

1. Find labels 0, 5 and 10. Their top heights should be 0, 0.55 and 1.10 metres. Trace the pink path between them.
2. Compare the two reported side distances. The outer pair is farther apart even though the rise is the same. Look at the actual edges before calling that distance a gap.
3. Change only `amplitude` to `0.0` and run again. Predict what remains: eleven treads, the same heights and turns. Their centres now lie on a circle of constant radius. The download includes this complete variation as `10_constant_radius.gd`; attach it instead of the original.
4. Choose one pair of treads. Explain separately how their positions, orientation, width and depth affect the available support. Changing one number can alter more than the silhouette.

The native test extracts these exact code blocks. It checks the three labelled positions, radial orientation, matching collision, real physics ray contacts and a dropped test sphere coming to rest on a tread. It repeats the study in a translated, rotated parent and runs the constant-radius variation. Deliberate missing-collision, wrong-turn and wrong-height faults must fail. These are construction checks; they do not establish a comfortable full ascent or independent student understanding.

Return to the tall museum stair. Its own generator uses 80 treads, two turns, a 0.11-metre rise and changing radius. It also adds connecting membranes whose configured vertical offset is 0.30 metres. Our small study omits those membranes so you can inspect what the boxes alone provide. Neither a continuous-looking line nor a connector's presence proves an accessible route. Next, Trig Walking Path brings two slightly different cycles together and asks how their relation changes over time.
