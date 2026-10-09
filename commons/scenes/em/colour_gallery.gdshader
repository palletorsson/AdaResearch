shader_type spatial;
render_mode cull_back;
// Dress the existing grid; retain its meshes, instance addresses and collisions.
uniform mat4 world_to_grid;
uniform bool addressed_floor = false;
uniform vec4 stone : source_color = vec4(0.80,0.78,0.73,1.0);
uniform vec4 plaster : source_color = vec4(0.94,0.925,0.89,1.0);
// Compatibility with the existing floor colour mutator; no wireframe overlay.
uniform vec4 modelColor : source_color = vec4(1.0);
uniform float wireframeOpacity = 0.0;
uniform bool show_interior = true;
uniform float modelOpacity = 1.0;
varying vec3 world_position;
varying vec4 instance_colour;
void vertex() {
 world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 instance_colour=COLOR;
}
void fragment() {
 vec3 p=(world_to_grid*vec4(world_position,1.0)).xyz;
 float floor_mask=1.0-smoothstep(0.51,0.54,p.y);
 vec3 floor_colour=addressed_floor ? instance_colour.rgb*modelColor.rgb : stone.rgb;
 float pitch=addressed_floor ? 1.0 : 2.0;
 vec2 tile=fract((p.xz+0.5)/pitch);
 vec2 q=min(tile,1.0-tile)*pitch;
 float edge=min(q.x,q.y);
 float joint=1.0-smoothstep(0.004,0.014,edge);
 float grain=sin(p.x*321.0)*sin(p.z*273.0)*0.007;
 floor_colour*=1.0-joint*0.16+grain;
 ALBEDO=mix(plaster.rgb,floor_colour,floor_mask);
 ROUGHNESS=mix(0.88,0.36,floor_mask);
 SPECULAR=0.35;
}
