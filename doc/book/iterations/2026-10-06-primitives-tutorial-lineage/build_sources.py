from pathlib import Path
import shutil, json, textwrap

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
OLD=HERE.parent/'2026-10-06-trace-saved-to-grid'
HALLS=['Point_Triangle_Context','Primitives_Polythedra','Point_Animatedcube','Primitives_Ignorance','Primitives_Godot','Primitives_Columns','Primitives_Profiles','Primitives_Portals','Primitives_Melencolia']
def put(p,s):
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(textwrap.dedent(s).lstrip('\n'),encoding='utf-8',newline='\n')
def copy(src,dst):
    dst.parent.mkdir(parents=True,exist_ok=True); shutil.copyfile(src,dst)

def main():
    shared=HERE/'shared'
    for name in ['point_body.gd','line_skin.gd','trace_archive.gd']:
        copy(OLD/'trace'/name,shared/name)
    put(shared/'face_body.gd','''
        extends Node3D
        ## Visible triangular faces and their edges. This class adds no collision.
        const LineSkin = preload("line_skin.gd")
        var surface := MeshInstance3D.new()
        var edges := Node3D.new()

        func _init() -> void:
            add_child(surface)
            add_child(edges)
            var paper := StandardMaterial3D.new()
            paper.albedo_color = Color(0.92, 0.91, 0.87)
            paper.roughness = 0.75
            surface.material_override = paper

        func show_faces(points: Array[Vector3], faces: Array[Vector3i]) -> bool:
            surface.mesh = null
            for edge in edges.get_children():
                edge.free()
            if faces.is_empty():
                return false
            for face in faces:
                for index in [face.x, face.y, face.z]:
                    if index < 0 or index >= points.size():
                        return false
                var a := points[face.x]
                var b := points[face.y]
                var c := points[face.z]
                if (c - a).cross(b - a).length() < 0.00001:
                    return false
            var builder := SurfaceTool.new()
            builder.begin(Mesh.PRIMITIVE_TRIANGLES)
            for face in faces:
                var a := points[face.x]
                var b := points[face.y]
                var c := points[face.z]
                # Godot's front faces use clockwise winding.
                var normal := (c - a).cross(b - a).normalized()
                for point in [a, b, c]:
                    builder.set_normal(normal)
                    builder.add_vertex(point)
                for pair in [[a, b], [b, c], [c, a]]:
                    var edge := LineSkin.new()
                    edge.material_override.albedo_color = Color(0.04, 0.04, 0.045)
                    edges.add_child(edge)
                    var difference: Vector3 = pair[1] - pair[0]
                    edge.show_segment(pair[0], difference, difference.length())
            surface.mesh = builder.commit()
            return true
    ''')
    put(shared/'cube_body.gd','''
        extends "face_body.gd"
        # Eight shared positions; each triple addresses three entries.
        var points: Array[Vector3] = [
            Vector3(-0.5, 0, -0.5), Vector3(0.5, 0, -0.5),
            Vector3(0.5, 1, -0.5), Vector3(-0.5, 1, -0.5),
            Vector3(-0.5, 0, 0.5), Vector3(0.5, 0, 0.5),
            Vector3(0.5, 1, 0.5), Vector3(-0.5, 1, 0.5)]
        var faces: Array[Vector3i] = [
            Vector3i(4, 7, 5), Vector3i(5, 7, 6),
            Vector3i(0, 4, 1), Vector3i(1, 4, 5),
            Vector3i(2, 6, 3), Vector3i(3, 6, 7),
            Vector3i(1, 2, 0), Vector3i(0, 2, 3),
            Vector3i(0, 3, 4), Vector3i(4, 3, 7),
            Vector3i(5, 6, 1), Vector3i(1, 6, 2)]

        func _init() -> void:
            super()
            show_faces(points, faces)

        func other_diagonal() -> void:
            faces[0] = Vector3i(4, 6, 5)
            faces[1] = Vector3i(4, 7, 6)
            show_faces(points, faces)
    ''')
    put(shared/'circle_samples.gd','''
        extends RefCounted
        # Supplied circle sampler. Angles return in the Waves sequence.
        static func make(sides: int, radius: float) -> Array[Vector3]:
            assert(sides >= 3 and radius > 0.0)
            var points: Array[Vector3] = []
            for side in range(sides):
                var angle := TAU * side / sides
                points.append(Vector3(cos(angle), 0, sin(angle)) * radius)
            return points
    ''')
    copy(HERE.parent/'2026-10-03-primitives-closing-tutorials/column_surface.gd',shared/'column_surface.gd')
    copy(ROOT/'commons/artifacts/glyph_profile_gallery/profile_sweep.gd',shared/'profile_sweep.gd')

    scripts={
    'Point_Triangle_Context': '''
        extends Node3D
        const PointBody = preload("point_body.gd")
        const FaceBody = preload("face_body.gd")
        const Archive = preload("trace_archive.gd")
        const CORNERS := Vector3i(0, 1, 2)
        var handles: Array[Node3D] = []
        var points: Array[Vector3] = []
        var face := FaceBody.new()
        var message := Label3D.new()

        func _ready() -> void:
            add_child(face)
            add_child(message)
            message.position = Vector3(0, 2, 0)
            message.font_size = 32
            message.pixel_size = 0.003
            var drawing := Archive.load_drawing()
            if drawing == null:
                message.text = "Return to Trace; draw and release the point."
                return
            var record: PackedVector3Array = drawing.get_meta("positions")
            drawing.free()
            for index in [CORNERS.x, CORNERS.y, CORNERS.z]:
                if index < 0 or index >= record.size():
                    message.text = "Choose three indices inside the saved record."
                    return
            for index in [CORNERS.x, CORNERS.y, CORNERS.z]:
                var point := PointBody.new()
                point.position = record[index]
                add_child(point)
                handles.append(point)

        func _process(_delta: float) -> void:
            if handles.size() != 3:
                return
            var current: Array[Vector3] = []
            for point in handles:
                current.append(point.position)
            if current == points:
                return
            points = current
            if face.show_faces(points, [Vector3i(0, 1, 2)]):
                message.text = "Three positions; one face."
            else:
                message.text = "Separate the corners; lift one off the line."
    ''',
    'Primitives_Polythedra': '''
        extends Node3D
        const Archive = preload("trace_archive.gd")
        const FaceBody = preload("face_body.gd")
        const CORNERS := Vector3i(0, 1, 2)
        const DEPTH := 0.6
        var points: Array[Vector3] = []
        var faces: Array[Vector3i] = [
            Vector3i(0, 1, 2), Vector3i(0, 3, 1),
            Vector3i(1, 3, 2), Vector3i(2, 3, 0)]
        var body := FaceBody.new()
        var message := Label3D.new()

        func _ready() -> void:
            add_child(body)
            add_child(message)
            message.position = Vector3(0, 2, 0)
            message.pixel_size = 0.003
            var drawing := Archive.load_drawing()
            if drawing == null:
                message.text = "Bring a drawing from Trace."
                return
            var record: PackedVector3Array = drawing.get_meta("positions")
            drawing.free()
            for index in [CORNERS.x, CORNERS.y, CORNERS.z]:
                if index < 0 or index >= record.size():
                    message.text = "Choose three saved indices."
                    return
            for index in [CORNERS.x, CORNERS.y, CORNERS.z]:
                points.append(record[index])
            var normal := (points[2] - points[0]).cross(points[1] - points[0])
            if normal.length() < 0.00001 or DEPTH <= 0.0:
                message.text = "Use a valid triangle and a positive depth."
                return
            var centre := (points[0] + points[1] + points[2]) / 3.0
            points.append(centre - normal.normalized() * DEPTH)
            body.show_faces(points, faces)
            message.text = "Four positions; four faces."
    ''',
    'Point_Animatedcube': '''
        extends Node3D
        const CubeBody = preload("cube_body.gd")
        var first := CubeBody.new()
        var second := CubeBody.new()

        func _ready() -> void:
            first.position = Vector3(-0.7, 0.7, 0)
            second.position = Vector3(0.7, 0.7, 0)
            add_child(first)
            add_child(second)
            second.other_diagonal()
    ''',
    'Primitives_Ignorance': '''
        extends Node3D
        const FaceBody = preload("face_body.gd")
        # Connectivity is supplied; this lesson generates the positions.
        const FACES: Array[Vector3i] = [
            Vector3i(2, 0, 4), Vector3i(2, 4, 1),
            Vector3i(2, 1, 5), Vector3i(2, 5, 0),
            Vector3i(3, 4, 0), Vector3i(3, 1, 4),
            Vector3i(3, 5, 1), Vector3i(3, 0, 5)]
        var small_points: Array[Vector3] = []
        var large_points: Array[Vector3] = []

        func _ready() -> void:
            small_points = octahedron_positions(0.3)
            large_points = octahedron_positions(0.6)
            var small := FaceBody.new()
            var large := FaceBody.new()
            small.position = Vector3(-0.7, 1.1, 0)
            large.position = Vector3(0.7, 1.1, 0)
            add_child(small)
            add_child(large)
            small.show_faces(small_points, FACES)
            large.show_faces(large_points, FACES)

        func octahedron_positions(radius: float) -> Array[Vector3]:
            assert(radius > 0.0)
            var result: Array[Vector3] = []
            for axis in [Vector3.RIGHT, Vector3.UP, Vector3.BACK]:
                result.append(axis * radius)
                result.append(-axis * radius)
            return result
    ''',
    'Primitives_Godot': '''
        extends Node3D
        const ResolutionPoint = preload("resolution_point.gd")
        var point := ResolutionPoint.new()
        var comparison := ResolutionPoint.new()
        var message := Label3D.new()

        func _ready() -> void:
            point.position = Vector3(-0.3, 1.12, 0)
            comparison.position = Vector3(0.3, 1.12, 0)
            add_child(point)
            add_child(comparison)
            add_child(message)
            message.position = Vector3(0, 1.65, 0)
            message.pixel_size = 0.002

        func _process(delta: float) -> void:
            point.advance(delta)
            comparison.advance(delta)
            if Input.is_action_just_pressed("ui_accept"):
                point.reset_resolution()
                comparison.reset_resolution()
            message.text = "RINGS %d   SEGMENTS %d" % [point.sphere.rings, point.sphere.radial_segments]
    ''',
    'Primitives_Columns': '''
        extends Node3D
        const Circle = preload("circle_samples.gd")
        const ColumnSurface = preload("column_surface.gd")
        const PROFILE: Array[float] = [0.35, 0.35, 0.18, 0.25, 0.4, 0.4]
        const HEIGHT := 2.2

        func _ready() -> void:
            var choices := [4, 6, 8, 12, 16]
            for i in range(choices.size()):
                var column := MeshInstance3D.new()
                var points := column_positions(PROFILE, HEIGHT, choices[i])
                column.mesh = ColumnSurface.make(points, choices[i])
                column.position.x = (i - 2) * 1.0
                var finish := StandardMaterial3D.new()
                finish.albedo_color = Color(0.92, 0.91, 0.87)
                finish.roughness = 0.7
                column.material_override = finish
                add_child(column)

        func column_positions(profile: Array[float], height: float, sides: int) -> Array[Vector3]:
            assert(profile.size() >= 2 and height > 0.0 and sides >= 3)
            var result: Array[Vector3] = []
            for ring in range(profile.size()):
                var y := height * ring / (profile.size() - 1)
                for point in Circle.make(sides, profile[ring]):
                    result.append(point + Vector3(0, y, 0))
            return result
    ''',
    'Primitives_Profiles': '''
        extends Node3D
        const Sweep = preload("profile_sweep.gd")
        const FONT = preload("JetBrainsMono-Medium.ttf")
        const WIDTH := 1.4
        const DEPTH := 1.6
        const OFFSET := 0.5
        var section: Dictionary
        var frames: Array[Transform3D] = []
        var body := MeshInstance3D.new()

        func _ready() -> void:
            section = Sweep.profile(FONT, "O")
            for i in range(5):
                var fraction := i / 4.0
                var at := Vector3(OFFSET * fraction, 1.1, DEPTH * fraction)
                var frame := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * WIDTH), at)
                frames.append(frame)
            body.mesh = Sweep.make(section, frames)
            var finish := StandardMaterial3D.new()
            finish.albedo_color = Color(0.78, 0.62, 0.72)
            finish.roughness = 0.4
            body.material_override = finish
            add_child(body)
    ''',
    'Primitives_Portals': '''
        extends Node3D
        const Circle = preload("circle_samples.gd")
        const LineSkin = preload("line_skin.gd")
        const RADIUS := 0.7
        const TOLERANCE := 0.01
        const BUDGET := 96
        var sides := 3
        var points: Array[Vector3] = []
        var error := 0.0
        var met := false
        var message := Label3D.new()

        func _ready() -> void:
            choose_resolution(TOLERANCE, BUDGET)
            for i in range(points.size()):
                var a := points[i] + Vector3(0, 1.1, 0)
                var b := points[(i + 1) % points.size()] + Vector3(0, 1.1, 0)
                var line := LineSkin.new()
                add_child(line)
                line.show_segment(a, b - a, a.distance_to(b))
            add_child(message)
            message.position = Vector3(0, 1.8, 0)
            message.pixel_size = 0.002
            message.text = "%d sides; error %.5f m; met: %s" % [sides, error, str(met)]

        func perimeter(record: Array[Vector3]) -> float:
            var total := 0.0
            for i in range(record.size()):
                total += record[i].distance_to(record[(i + 1) % record.size()])
            return total

        func choose_resolution(tolerance: float, budget: int) -> void:
            assert(tolerance > 0.0 and budget >= 3)
            sides = 3
            while true:
                points = Circle.make(sides, RADIUS)
                error = absf(TAU * RADIUS - perimeter(points))
                met = error <= tolerance
                if met or sides == budget:
                    break
                sides = mini(sides * 2, budget)
    ''',
    'Primitives_Melencolia': '''
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
    '''}
    files={
        'Point_Triangle_Context':['point_body.gd','face_body.gd','line_skin.gd','trace_archive.gd'],
        'Primitives_Polythedra':['face_body.gd','line_skin.gd','trace_archive.gd'],
        'Point_Animatedcube':['cube_body.gd','face_body.gd','line_skin.gd'],
        'Primitives_Ignorance':['face_body.gd','line_skin.gd'],
        'Primitives_Godot':['point_body.gd'],
        'Primitives_Columns':['circle_samples.gd','column_surface.gd'],
        'Primitives_Profiles':['profile_sweep.gd'],
        'Primitives_Portals':['circle_samples.gd','line_skin.gd'],
        'Primitives_Melencolia':['cube_body.gd','face_body.gd','line_skin.gd','point_body.gd']}
    for hall,script in scripts.items():
        put(HERE/hall/'lesson.gd',script)
        for name in files[hall]:copy(shared/name,HERE/hall/name)
    # A later edition exposes the SAME sphere resource; previous lessons stay immutable.
    p=HERE/'Primitives_Godot/point_body.gd'
    s=p.read_text();s=s.replace('const RADIUS := 0.14','const RADIUS := 0.14\nvar sphere := SphereMesh.new()')
    s=s.replace('    var sphere := SphereMesh.new()\n','').replace('\tvar sphere := SphereMesh.new()\n','')
    put(p,s)
    put(HERE/'Primitives_Godot/resolution_point.gd','''
        extends "point_body.gd"
        const START_RINGS := 16
        const START_SEGMENTS := 32
        const STEP_SECONDS := 0.15
        var elapsed := 0.0

        func _init() -> void:
            super()
            reset_resolution()

        func advance(delta: float) -> void:
            if not is_picked_up():
                return
            elapsed += delta
            while elapsed + 0.000001 >= STEP_SECONDS:
                elapsed = maxf(0.0, elapsed - STEP_SECONDS)
                sphere.rings = maxi(1, sphere.rings - 1)
                sphere.radial_segments = maxi(4, sphere.radial_segments - 1)

        func reset_resolution() -> void:
            elapsed = 0.0
            sphere.rings = START_RINGS
            sphere.radial_segments = START_SEGMENTS
    ''')
    for name in ['JetBrainsMono-Medium.ttf','JetBrainsMono-OFL.txt']:
        copy(ROOT/'commons/artifacts/glyph_profile_gallery'/name,HERE/'Primitives_Profiles'/name)
    put(HERE/'lessons.json',json.dumps({'halls':HALLS,'files':{h:[p.name for p in (HERE/h).glob('*.gd')] for h in HALLS}},indent=2)+'\n')

if __name__=='__main__':main()
