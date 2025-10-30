extends Node

# Auto-generated from infoboard progression
var text = '''
[center][b]The Triangle[/b][/center]
[center][i]The First Surface[/i][/center]

The triangle as the threshold between line and surface, the minimal polygon, and the atomic unit of all 3D geometry

[hr]
[b]Three Points Define a Plane[/b]
AXIOM 6: Three non-collinear points uniquely determine a plane.
[color=yellow]Code[/color]
[code]
var v_a = Vector3(-0.25, 0, 0)
var v_b = Vector3(0.25, 0, 0)
var v_c = Vector3(0, 0.5, 0)
[/code]
Three vertices -> Three edges -> One face Introduces: INTERIOR, ORIENTATION, AREA
[i]Concepts: three points, plane, vertices, edges, face[/i]

[hr]
[b]Winding Order and Normals[/b]
AXIOM 2: Vertex order determines face direction.
[color=yellow]Code[/color]
[code]
var edge1 = v_b - v_a
var edge2 = v_c - v_a
var normal = edge1.cross(edge2).normalized()
[/code]
Cross product -> Normal vector CCW = front, CW = back Defines light interaction
[i]Concepts: normal vector, cross product, winding order, front/back[/i]

[hr]
[b]Area Calculation[/b]
AXIOM 3: Triangle area = 12 |edge1 x edge2|
[color=yellow]Code[/color]
[code]
var cross = edge1.cross(edge2)
var area = cross.length() * 0.5
[/code]
First shape that can CONTAIN
First 2D measure (not 1D distance)
[i]Concepts: area, cross product magnitude, 2D measure, containment[/i]

[hr]
[b]Building Meshes[/b]
AXIOM 4: Every 3 vertices = 1 triangle.
[color=yellow]Code[/color]
[code]
var st = SurfaceTool.new()
st.begin(Mesh.PRIMITIVE_TRIANGLES)
st.set_normal(normal)
st.add_vertex(v_a)
st.add_vertex(v_b)
st.add_vertex(v_c)
var mesh = st.commit()
[/code]
Foundation of ALL 3D meshes
[i]Concepts: SurfaceTool, PRIMITIVE_TRIANGLES, mesh creation[/i]

[hr]
[b]The Atomic Surface[/b]
AXIOM 5: Every 3D mesh decomposes into triangles.
[color=yellow]Code[/color]
[code]
var sphere = SphereMesh.new()
sphere.radial_segments = 32
sphere.rings = 16
#  1024 triangles
[/code]
Why triangles? - Always planar - GPU optimized - Any polygon -> triangles
[i]Concepts: triangle mesh, GPU rendering, decomposition, atomic unit[/i]
'''
