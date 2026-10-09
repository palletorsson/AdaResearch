# Point One — follow the corridor

The tutorial follows the museum's order: absent, visible, solid, held, coordinates, target, pedestal. It alternates small executable changes with encounters whose machinery is supplied by the museum.

The project starts in study.tscn, the three-station desktop comparison. position.gd keeps an unused position; visible.gd creates a visible sphere; solid.gd adds a matching physical boundary. TUTORIAL.md identifies the exact lines to change. These scripts and the scene are unchanged from the earlier tested construction study.

The black held point, the target and pedestal are encountered in the full museum. This download has no walking or pickup system; it must not be mistaken for a headset-ready reproduction of the whole hall. Godot's collision debug view makes the fixed study's boundary comparison inspectable.

When the tutorial reaches the coordinate room, coordinates.tscn and points.gd supply the two-marker study. Run that scene with Run Current Scene; the project main scene remains study.tscn. Both scenes inherit the unchanged Day Zero base.tscn.

CONSTRUCTION.md holds the fuller previous construction explanation. POINT_ZERO.md contains the preceding readiness/process tutorial, and DAY_ZERO.md covers preparation. No external plugins or assets are required for either desktop scene.
