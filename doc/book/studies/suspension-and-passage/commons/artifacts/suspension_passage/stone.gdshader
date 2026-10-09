shader_type spatial;
uniform vec4 stone : source_color = vec4(0.46, 0.445, 0.42, 1.0);
varying vec3 local_position;
void vertex() { local_position = VERTEX; }
float hash(vec3 p) { return fract(sin(dot(p,vec3(12.98,78.23,37.71)))*43758.54); }
float noise(vec3 p) {
    vec3 cell = floor(p);
    vec3 f = fract(p);
    f = f*f*(3.0-2.0*f);
    return mix(mix(mix(hash(cell),hash(cell+vec3(1,0,0)),f.x),mix(hash(cell+vec3(0,1,0)),hash(cell+vec3(1,1,0)),f.x),f.y),
               mix(mix(hash(cell+vec3(0,0,1)),hash(cell+vec3(1,0,1)),f.x),mix(hash(cell+vec3(0,1,1)),hash(cell+vec3(1,1,1)),f.x),f.y),f.z);
}
void fragment() {
    float cloud = noise(local_position * 11.0);
    float aggregate = noise(local_position * 48.0);
    float pore = smoothstep(0.12,0.30,noise(local_position * 85.0));
    ALBEDO = stone.rgb * (0.75 + cloud*0.22 + aggregate*0.16) * mix(0.68,1.0,pore);
    ROUGHNESS = 0.96;
}
