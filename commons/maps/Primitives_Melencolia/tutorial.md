# Arrange what you can already make

## Learning elements

- Composition with known classes
- Independent instances
- Placement versus construction
- Reusing a learned capability

## In the museum

Dürer's objects gather in the museum's Melencolia hall. Our tutorial closes this sequence with a smaller task: make an arrangement from two instances of your cube and the familiar sphere point. The reflective text can ask what geometry promises; the tutorial gives you enough control to make an arrangement of your own.

There is no new mesh recipe here. Keep CubeBody from Cube and PointBody from the earlier point lessons.

## Make this study

Attach lesson.gd to a unit-scale Node3D named ArrangementStudy in this hall's working copy. Place that study at floor level. The cube's local bottom is y = 0; the sphere's centre is one radius above the floor. PointBody retains pickup and frozen release; the cubes remain visible mesh objects without colliders.

Carried unchanged from [Lines](../Point_Lines/tutorial.md): `point_body.gd`, `line_skin.gd`. Carried unchanged from [Triangle](../Point_Triangle_Context/tutorial.md): `face_body.gd`. Carried unchanged from [Cube](../Point_Animatedcube/tutorial.md): `cube_body.gd`.

### The program

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D
const CubeBody = preload("cube_body.gd")
const PointBody = preload("point_body.gd")
var places: Array[Vector3] = [Vector3(-0.8, 0, 0), Vector3(0.5, 0, -0.7)]
var cubes: Array[Node3D] = []
var point := PointBody.new()

func _ready() -> void:
    for place in places:
        var cube := CubeBody.new()
        cube.position = place
        add_child(cube)
        cubes.append(cube)
    point.position = Vector3(0.1, PointBody.RADIUS, 0.6)
    add_child(point)
```

## Read the construction

The loop constructs two independent CubeBody instances and assigns positions from places. Reusing a class does not mean sharing one mutable vertex array. Moving an instance should leave its geometry and its neighbour unchanged.

The point is the same white sphere with the same size and interaction settings. It can be picked up and left somewhere else during a run. That temporary placement is not written back into this script. To keep an arrangement across runs, put your chosen coordinates in the source; persistent composition is a later capability.

The program uses constructors, arrays, a loop and positions you have already met. Scale and rotation stay for Transformation. You can still change the relation between bodies through distance, overlap and placement. The resulting arrangement is your decision, not the inevitable output of the cube rule.

## Make it your own

Make a second arrangement by changing only places and the point's initial position. Keep the classes unchanged. Show how a different interval or overlap changes what you notice. You should be able to reconstruct both arrangements from their saved script values.

## After the chapter: an arrangement without a recipe

Choose a different arrangement in a clear part of your working museum hall. Use the earlier files as references, but write your own small main script. This is an independent challenge; there is no new construction hidden in a supplied answer.

- Generate a list of at least five positions with a rule you can explain. Keep an unchanged source list and modify an independently owned copy.
- Reuse PointBody and FaceBody. Choose three non-collinear entries from the list and connect them as a face.
- Show two spheres of equal radius with different resolutions, using the construction already studied in Godot Primitives.
- Decide their spacing and arrangement. Keep the known collider behaviour; making a new walkable structure is outside this task.

Show the arrangement to someone who has not seen your script. Locate the stored values, the variable referring to each body, and the indices establishing the face. Explain what the generator decided, what resolution changed, what you preserved, and one aesthetic choice that no calculation required.

Run your script and check that changing the copy leaves the source intact, that the selected face has area, and that each sphere keeps its own mesh. Then change one choice and predict the result before running again. Successful execution is evidence about the program; explaining and transferring the choices gives evidence about what you learned.

Carry CubeBody and PointBody into Transformation. A body that you can place is ready to become a body whose position, rotation or scale changes over time.


[Current lesson.gd](../../../doc/book/iterations/2026-10-06-starter-one-course/lessons/Primitives_Melencolia/lesson.gd) · [Complete working project](../../../doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip) · [Verification and changes](../../../doc/book/iterations/2026-10-06-starter-one-course/index.html)
