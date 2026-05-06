var text = '''[b]Arrays and For Loops[/b]
[i]Data Structures for Collections[/i]

Arrays are collections of values that allow you to store multiple items in a single variable.

For loops are control structures that let you repeat code a specific number of times, making them perfect for working with arrays.

Together, arrays and for loops form the backbone of data manipulation in programming.

[hr]

[b]1D Arrays: Creating Rows[/b]

1D arrays are simple lists of values, with each value accessible by a single index. They're perfect for creating rows of UI elements, menu items, or any linear collection of objects.

[code]
var panel_data = ["Item 1", "Item 2", "Item 3"]

for i in range(panel_data.size()):
    var panel = Panel.new()
    panel.position.x = i * (panel_size.x + margin)
    panel.text = panel_data[i]
    add_child(panel)
[/code]

[hr]

[b]2D Arrays: Building Grids[/b]

2D arrays are arrays of arrays, creating a grid-like structure with rows and columns. Each value is accessed using two indices: one for the row and one for the column.

[code]
var grid_data = [
    [1, 2, 3, 4],
    [5, 6, 7, 8],
    [9, 10, 11, 12]
]

for y in range(grid_data.size()):
    for x in range(grid_data[y].size()):
        var panel = Panel.new()
        panel.position = Vector2(x, y) * (size + margin)
        panel.text = str(grid_data[y][x])
        add_child(panel)
[/code]

[hr]

[b]3D Arrays: Volumetric Data[/b]

3D arrays add a third dimension to our data structure, allowing us to represent volumes of data. They're accessed using three indices: one each for x, y, and z coordinates.

3D arrays are valuable for voxel-based games, 3D simulations, and complex data visualizations.

[code]
var cube_data = []
for z in range(3):
    var plane = []
    for y in range(3):
        var row = []
        for x in range(3):
            row.append(x + y*3 + z*9)
        plane.append(row)
    cube_data.append(plane)
[/code]

[hr]

[b]Advanced Techniques[/b]

Arrays and loops can be combined with other programming concepts for powerful results:
- Array methods like append(), erase(), and sort()
- Dictionary arrays for complex data with named properties
- Lambda functions to transform array data on the fly
- Array slicing for working with specific portions of data

[code]
var numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
var even_numbers = numbers.filter(
    func(n): return n % 2 == 0
)
[/code]
'''
