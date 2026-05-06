# csv_to_space.py — CSV rows → 3D space placement
# Source gist: https://gist.github.com/palletorsson/c4120dd96cda730647f02fa3633fa5da
# Doc section: Use csv to create a room from prefabs
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import csv
import bpy

# Create floor grid
grid_size = (4, 5)  # Adjust the dimensions as needed
tile_size = 1.0  # Adjust the size of each tile as needed
wall_offset = 0.475
ceil_height = 3.5
import bpy
import csv

# Path to the CSV file
csv_file_path = r'C:\Users\palle\Documents\Blender_Work\VR\marchingcubes\mySpace.csv'

# Function to read CSV data
def read_csv_data(file_path):
    grid_data = []
    with open(file_path, newline='') as csvfile:
        csvreader = csv.reader(csvfile, delimiter=',')
        for row in csvreader:
            grid_data.append(row)
    return grid_data

# Use the function to read the CSV file
grid_data = read_csv_data(csv_file_path)

# Get the grid size from the grid data
grid_size = (len(grid_data), len(grid_data[0]))
print(grid_size)

def duplicate_object(object_name):
    """
    Duplicate the specified object in Blender.

    Parameters:
    object_name (str): The name of the object to duplicate.

    Returns:
    bpy.types.Object: The duplicated object.
    """
    # Deselect all objects
    bpy.ops.object.select_all(action='DESELECT')
    # Select the object by name
    bpy.data.objects[object_name].select_set(True)
    # Duplicate the selected object
    bpy.ops.object.duplicate_move()
    # Return the duplicated object
    return bpy.context.selected_objects[0]

# Iterate over the grid data and map the numbers to the floor tiles
for x in range(grid_size[0]):
    for y in range(grid_size[1]):
        # Get the tile type from the grid data
        tile_type = grid_data[x][y]
        

        
        # Construct the base object name from the tile type
        base_object_name = tile_type
        print(x,y, base_object_name)
  
        
        # Construct the floor object name by prefixing the base object name with "Floor_"
        floor_object_name = "Floor_" + base_object_name.strip()
        # Duplicate the floor object
        duplicated_object = duplicate_object(floor_object_name)
       
        # Set the location of the duplicated floor object
        duplicated_object.location = (x * tile_size, y * tile_size, 0)

        # Construct the wall object name by prefixing the base object name with "Wall_"
        wall_object_name = "Wall_" + base_object_name.strip()
        # Only create a wall object if the tile is not a regular tile
        if wall_object_name != "Wall_Regular":
            # Duplicate the wall object
            duplicated_object = duplicate_object(wall_object_name)
            
            # Get the duplicated wall object
            duplicated_wall = bpy.context.selected_objects[0]
            
            # Set the location of the duplicated wall object, applying the wall offset
            duplicated_wall.location = (x * tile_size, y * tile_size, wall_offset)
            
            if base_object_name.strip() != "Empty":
                # Split the wall object name to get the type and direction
                my_type  = wall_object_name.split("_")[1]
                direction = wall_object_name.split("_")[2]
                
                # If the wall is a side wall, adjust its location based on the direction
                if my_type == "Side":
                    x_offset = 0
                    y_offset = 0                
                    if direction[1] == "X":
                        x_offset = wall_offset 
                    if direction[1] == "Y":
                        y_offset = wall_offset
                    if direction[0] == "N":
                        y_offset = -y_offset  
                        x_offset = -x_offset    

                    duplicated_wall.location = (x * tile_size+(x_offset), y * tile_size+(y_offset), 0.2)
                else:
                    duplicated_wall.location = (x * tile_size, y * tile_size, 0.0)
       
        # Add the Ceiling tile     
        ceil_object_name = "Ceil_"+base_object_name.strip()
        # Create the Wall tile by duplicating the object
        duplicated_object = duplicate_object(ceil_object_name)
         
        # Place the duplicated wall object at the same location as the tile
        duplicated_wall = bpy.context.selected_objects[0]
        
        duplicated_wall.location = (x * tile_size, y * tile_size, ceil_height)
        