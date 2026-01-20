# Bricolage_Chair - Technical

## Core Concept in Code

The chair as constraint-satisfying assembly:

```gdscript
# Chair emerges when constraints are satisfied
class ChairValidator:
    func is_valid_chair(assembly: Assembly) -> ChairValidation:
        var result = ChairValidation.new()

        # Check required parts
        var seat = assembly.get_part_by_affordance("seat")
        var back = assembly.get_part_by_affordance("back_support")
        var legs = assembly.get_parts_by_affordance("support")

        if seat == null:
            result.add_error("Missing seat surface")
        if back == null:
            result.add_warning("No back support (stool, not chair)")
        if legs.size() < 3:
            result.add_error("Insufficient support (need 3+ legs)")

        # Check constraint satisfaction
        if not check_gravity_path(seat, legs):
            result.add_error("Seat not supported by legs")
        if not check_balance(assembly):
            result.add_error("Assembly will tip")
        if not check_seat_height(seat):
            result.add_warning("Seat height not ergonomic")
        if back and not check_back_angle(seat, back):
            result.add_warning("Back angle uncomfortable")

        return result

    func check_seat_height(seat: Part) -> bool:
        # Typical chair seat: 40-50cm from ground
        return seat.position.y >= 0.4 and seat.position.y <= 0.5

    func check_back_angle(seat: Part, back: Part) -> bool:
        var angle = seat.get_angle_to(back)
        return angle >= 90 and angle <= 110  # Comfortable recline
```

## Implementation: Chair Parts Inventory

```gdscript
# Chair parts as typed inventory
var CHAIR_PARTS = {
    "seat": {
        "type": "plane",
        "dimensions": Vector3(0.45, 0.02, 0.45),
        "affordance": "horizontal_support"
    },
    "back": {
        "type": "plane",
        "dimensions": Vector3(0.45, 0.45, 0.02),
        "affordance": "vertical_support"
    },
    "legs": {
        "type": "cylinder",
        "dimensions": Vector3(0.025, 0.45, 0.025),  # radius, height, radius
        "affordance": "vertical_support",
        "count": 4
    }
}

# Inventory display: parts laid out separately
func create_chair_inventory_display() -> Node3D:
    var display = Node3D.new()

    # Seat plane lying flat
    var seat = create_part("seat")
    seat.position = Vector3(0, 0.1, 0)
    display.add_child(seat)

    # Back plane lying flat beside it
    var back = create_part("back")
    back.position = Vector3(0.6, 0.1, 0)
    display.add_child(back)

    # Four leg cylinders lying horizontally
    for i in range(4):
        var leg = create_part("leg")
        leg.rotation_degrees.x = 90  # Lying down
        leg.position = Vector3(-0.3 + i * 0.2, 0.1, 0.5)
        display.add_child(leg)

    return display
```

## Chair Assembly Logic

```gdscript
# Assembling chair from parts
class ChairAssembler:
    var parts: Dictionary  # Available parts
    var assembly: Assembly

    func assemble_chair() -> Assembly:
        assembly = Assembly.new()

        # 1. Place seat at sitting height
        var seat = parts["seat"]
        seat.position = Vector3(0, 0.45, 0)
        assembly.add_part(seat)

        # 2. Attach legs at corners
        var corners = seat.get_corners()
        for i in range(4):
            var leg = parts["legs"][i]
            leg.position = corners[i] + Vector3(0, -0.225, 0)  # Centered under corner
            assembly.add_part(leg)
            assembly.add_bond(Bond.new(seat, leg, BondType.RIGID))

        # 3. Attach back (optional but expected for "chair")
        var back = parts["back"]
        back.position = seat.position + Vector3(0, 0.225, -0.225)
        back.rotation_degrees.x = -10  # Slight recline
        assembly.add_part(back)
        assembly.add_bond(Bond.new(seat, back, BondType.RIGID))

        return assembly
```

## Interactive Chair Builder

```gdscript
# Interactive assembly station
class ChairBuilder extends InteractableBase:
    var snap_points: Array[SnapPoint]
    var placed_parts: Dictionary

    func _ready():
        # Define where parts can attach
        snap_points = [
            SnapPoint.new(Vector3(0, 0.45, 0), "seat", ["horizontal_plane"]),
            SnapPoint.new(Vector3(-0.2, 0.225, -0.2), "leg", ["vertical_cylinder"]),
            SnapPoint.new(Vector3(0.2, 0.225, -0.2), "leg", ["vertical_cylinder"]),
            SnapPoint.new(Vector3(-0.2, 0.225, 0.2), "leg", ["vertical_cylinder"]),
            SnapPoint.new(Vector3(0.2, 0.225, 0.2), "leg", ["vertical_cylinder"]),
            SnapPoint.new(Vector3(0, 0.67, -0.22), "back", ["vertical_plane"]),
        ]

    func on_part_dropped(part: Part, position: Vector3):
        var nearest_snap = find_nearest_compatible_snap(part, position)
        if nearest_snap and is_within_range(position, nearest_snap):
            snap_part(part, nearest_snap)
            check_completion()
        else:
            # Part doesn't fit here
            part.return_to_inventory()

    func check_completion():
        var validator = ChairValidator.new()
        var result = validator.is_valid_chair(get_current_assembly())
        if result.is_complete():
            trigger_completion_effect()
```

## Why These Design Choices

1. **Inventory-vs-assembled comparison**: Same parts, different configurations—makes bricolage visible
2. **Interactive builder**: Learning by doing, not watching
3. **Constraint feedback**: Failed placements are felt, not explained
4. **Simple layout**: Three elements only—focus on application

## Key Takeaway

The chair is not an invention but a discovery—what satisfies sit-ability constraints given available parts. The bricoleur finds the chair by satisfying gravity, balance, and connectivity.
