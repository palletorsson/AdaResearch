extends Node

# Auto-generated from infoboard progression
var text = '''
[center][b]Vectors[/b][/center]
[center][i]The Bridge Between Points[/i][/center]

Understanding vectors as both positions and directions - the mathematical bridge between points and lines

[hr]
[b]Vector Duality: Position vs Direction[/b]
AXIOM 1: A vector can represent two different concepts:
[color=yellow]Code[/color]
[code]
var position = Vector3(3, 4, 0)  # A point 3 units right, 4 units up
var direction = Vector3(1, 0, 0)  # Direction: 'to the right'
[/code]
- Position: A point in space relative to the origin - Direction: A magnitude and direction, independent of position
The same Vector3(3, 4, 0) can mean 'the point at (3,4,0)' or 'move 3 right, 4 up'.
[i]Concepts: vector duality, position, direction, Vector3, context[/i]

[hr]
[b]Vector Subtraction: From Point A to Point B[/b]
AXIOM 2: Vector subtraction gives the direction and distance between two points.
[color=yellow]Code[/color]
[code]
var point_a = Vector3(1, 2, 3)
var point_b = Vector3(4, 6, 3)
var direction = point_b - point_a  # Vector3(3, 4, 0)
print("Direction from A to B: ", direction)
[/code]
Subtraction answers: 'If I'm at point A, how do I get to point B?'
[i]Concepts: vector subtraction, direction, distance, point to point[/i]

[hr]
[b]Vector Magnitude: The Distance[/b]
AXIOM 3: The magnitude (length) of a vector gives the distance.
[color=yellow]Code[/color]
[code]
var direction = Vector3(3, 4, 0)
var distance = direction.length()  # 5.0
print("Distance: ", distance)  # Uses Pythagorean theorem: (32 + 42 + 02)
[/code]
The .length() method calculates the straight-line distance using the 3D Pythagorean theorem.
[i]Concepts: magnitude, length, distance, Pythagorean theorem, .length()[/i]

[hr]
[b]Vector Normalization: Pure Direction[/b]
AXIOM 4: A normalized vector has length 1 and represents pure direction.
[color=yellow]Code[/color]
[code]
var direction = Vector3(3, 4, 0)
var unit_direction = direction.normalized()  # Vector3(0.6, 0.8, 0)
print("Unit direction: ", unit_direction)
print("Length: ", unit_direction.length())  # 1.0
[/code]
Normalization removes the distance, keeping only the direction. Perfect for 'which way to go' without 'how far'.
[i]Concepts: normalization, unit vector, .normalized(), pure direction, length 1[/i]

[hr]
[b]From Points to Lines[/b]
AXIOM 5: A line is defined by a point and a direction vector.
[color=yellow]Code[/color]
[code]
var start_point = Vector3(1, 2, 3)
var end_point = Vector3(4, 6, 3)
var direction = (end_point - start_point).normalized()
print("Line: start at ", start_point, " going ", direction)
[/code]
Now we can connect points with lines! The direction vector tells us which way the line points.
[i]Concepts: line definition, point and direction, connecting points, geometry foundation[/i]
'''
