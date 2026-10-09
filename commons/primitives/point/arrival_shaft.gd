extends Node3D
## A hollow entrance shaft. The museum supplies gravity and arrival height.
## The shaft has no floor: falling reaches the hall's existing collision floor.
##
## THE LONG DROP (2026-09-30, Palle: "make it 4 times longer and have a circus
## stripe pattern, drop the player more far up in the cylinder so we experience
## more drop and falling"). The wall is four times its first height, 16.8 m instead
## of 4.2, and the mouth stays where it was, 2.5 m over the floor, so the visitor
## still lands on the hall's floor and walks out under the rim. The top is at
## 19.3 m. The museum's lobby drop (em_layout.json lobby.drop_m, read only by the
## lobby's own arrival branch) now starts the visitor 17 m up, inside the stripes.
##
## WHY THE STRIPES TURN. Stripes that run straight up and down are the circus tent,
## and they are also parallel to a straight-down fall: a body dropping past them
## sees the same stripes at every height, so the fall reads as nothing moving. A
## helix, the fairground helter-skelter, crosses the line of fall, and a new red
## band passes the eye every metre, about twenty a second at the bottom of a 17 m
## drop. `twist` = 0 gives back the vertical tent stripes.

## Metres from the floor to the lower edge of the wall: the mouth the visitor
## falls out of and walks out under.
@export var mouth_m: float = 2.5
## Height of the wall itself. The first shaft was 4.2 m.
@export var height_m: float = 16.8
## Distance from the axis to the middle of each panel.
@export var radius_m: float = 1.22
## Red and cream stripe pairs around the circumference.
@export var stripes: int = 8
## Turns of the helix per metre of height. 0 = vertical circus-tent stripes.
## 0.125 with 8 pairs brings a new band past a fixed point every metre of fall.
@export var twist: float = 0.125
@export var stripe_color: Color = Color(0.80, 0.06, 0.09)
@export var ground_color: Color = Color(0.96, 0.93, 0.86)
## Share of each stripe's own colour it gives off, so the stripes read inside a
## narrow shaft the museum's lamps barely reach.
@export var glow: float = 0.25

const PANELS := 16

const STRIPE_SHADER := """
shader_type spatial;
render_mode cull_disabled;

uniform vec4 stripe_color : source_color = vec4(0.80, 0.06, 0.09, 1.0);
uniform vec4 ground_color : source_color = vec4(0.96, 0.93, 0.86, 1.0);
uniform float stripes = 8.0;
uniform float twist = 0.125;
uniform float glow = 0.25;
// This panel's place on the shaft: its angle around the axis, the radius, and the
// height of its centre. The panels are flat chords, so a point's angle is the
// panel's own angle plus its sideways offset over the radius; close enough for a
// stripe, and continuous from one panel to the next.
uniform float panel_angle = 0.0;
uniform float radius = 1.22;
uniform float centre_y = 10.9;

varying vec2 shaft_uv;

void vertex() {
	shaft_uv = vec2(panel_angle + VERTEX.x / radius, centre_y + VERTEX.y);
}

void fragment() {
	float phase = stripes * (shaft_uv.x / TAU + twist * shaft_uv.y);
	float s = sin(TAU * phase);
	float aa = max(fwidth(s), 1e-4);
	float m = smoothstep(-aa, aa, s);
	vec3 col = mix(ground_color.rgb, stripe_color.rgb, m);
	ALBEDO = col;
	ROUGHNESS = 0.6;
	EMISSION = col * glow;
}
"""


func _ready() -> void:
	var shader := Shader.new()
	shader.code = STRIPE_SHADER
	var centre_y: float = mouth_m + height_m * 0.5
	for i in range(PANELS):
		var angle := TAU * float(i) / float(PANELS)
		var panel := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.50, height_m, 0.09)
		panel.mesh = box
		panel.position = Vector3(sin(angle) * radius_m, centre_y, cos(angle) * radius_m)
		panel.rotation.y = angle
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("stripe_color", stripe_color)
		mat.set_shader_parameter("ground_color", ground_color)
		mat.set_shader_parameter("stripes", float(stripes))
		mat.set_shader_parameter("twist", twist)
		mat.set_shader_parameter("glow", glow)
		mat.set_shader_parameter("panel_angle", angle)
		mat.set_shader_parameter("radius", radius_m)
		mat.set_shader_parameter("centre_y", centre_y)
		panel.material_override = mat
		add_child(panel)
		panel.create_trimesh_collision()
