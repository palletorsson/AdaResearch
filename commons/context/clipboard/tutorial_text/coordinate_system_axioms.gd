extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''
[center][b]The Coordinate System[/b][/center]
[center][i]The Stage of Space[/i][/center]

The 3D coordinate system that defines the stage upon which all geometry exists

[hr]
[b]The Origin: Zero Point[/b]
- The origin (0, 0, 0) is the reference point from which all positions in 3D space are defined.
[color=yellow]Code[/color]
[code]
var origin = Vector3(0, 0, 0)
[/code]
The origin is like the center of a stage - everything else is positioned relative to this fixed point.
[i]Concepts: origin, reference point, Vector3(0,0,0), coordinate system[/i]

[hr]
[b]The Three Axes[/b]
- Three perpendicular axes - x, y, and z define 3D space.
[color=yellow]Code[/color]
[code]
var x_axis = Vector3(1, 0, 0)  # Right
var y_axis = Vector3(0, 1, 0)  # Up
var z_axis = Vector3(0, 0, 1)  # Forward
[/code]
[i]Concepts: X-axis, Y-axis, Z-axis, perpendicular, dimensions[/i]
'''
