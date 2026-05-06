# sladd_generator.py — Cable/cord path generator
# Source gist: https://gist.github.com/palletorsson/92fbec5b836d94972885ec60583886b9
# Doc section: Corded generator
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy
import mathutils
import random

# Namnge skriptet "SladdGenerator"

# Definiera start- och slutpositioner
start_location = mathutils.Vector((0, 0, 0))  # Start på golvet
end_location = mathutils.Vector((2, 2, 0))    # Slutpunkt på golvet
num_points = 10  # Antal punkter längs linjen, inklusive start och slut

# Skapa ny kurvdata
curve_data = bpy.data.curves.new('CableCurve', 'CURVE')
curve_data.dimensions = '3D'

# Skapa en ny spline i kurvan som Bezier
spline = curve_data.splines.new('BEZIER')
spline.bezier_points.add(num_points - 1)  # Lägg till punkter

# Ställ in handtag och positioner för varje punkt med slumpmässighet
for i, point in enumerate(spline.bezier_points):
    # Interpolera mellan start- och slutposition
    interp_factor = i / (num_points - 1)
    interp_location = start_location.lerp(end_location, interp_factor)

    # Lägg till slumpmässighet i x- och y-koordinaterna
    random_offset_x = random.uniform(-0.5, 0.5)  # Öka intervallet för mer slumpmässighet
    random_offset_y = random.uniform(-0.5, 0.5)  # Öka intervallet för mer slumpmässighet

    # Ställ in punktposition med slumpmässighet
    point.co = (
        interp_location.x + random_offset_x,
        interp_location.y + random_offset_y,
        interp_location.z
    )

    # Ställ in handtagstyper
    point.handle_left_type = point.handle_right_type = 'AUTO'

# Skapa ett nytt objekt med kurvdatan
curve_obj = bpy.data.objects.new('Cable', curve_data)
bpy.context.collection.objects.link(curve_obj)

# Sätt kurvobjektet som aktivt
bpy.context.view_layer.objects.active = curve_obj
curve_obj.select_set(True)
