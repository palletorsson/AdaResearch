# Crystal Ball

Touch-sensitive glowing sphere context object.

## Key Files
- `touchSphere.gd` — Extends Area3D; interactive sphere with 3.5s cooldown; toggles shader `is_touched` parameter on collision enter for glow effect; creates internal Timer for cooldown
- `cristalball.tscn` — Node3D with Area3D, SphereShape3D collision, ShaderMaterial (cristal_ball.gdshader), Label3D "touch", and SpotLight3D glow
