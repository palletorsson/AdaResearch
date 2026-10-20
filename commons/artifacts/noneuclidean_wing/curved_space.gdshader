shader_type spatial;
render_mode unshaded, cull_disabled, skip_vertex_transform, shadows_disabled;

// Hyperboloid vertices, observer-relative projection. The head/eye offset is
// applied per view; this avoids baking a monoscopic camera into the geometry.
uniform mat4 observer = mat4(1.0);
uniform mat4 anchor_world = mat4(1.0);
uniform mat4 anchor_inverse = mat4(1.0);
uniform float radius = 4.0;
uniform bool product_space = false;
uniform float product_height = 0.0;
uniform vec4 tone : source_color = vec4(0.9,0.9,0.9,1.0);

vec4 boost(vec4 q, vec3 displacement) {
	float d = length(displacement);
	if(d < 0.00001) return q;
	vec3 n = displacement/d;
	float c = cosh(d), s = sinh(d), along = dot(n,q.xyz);
	return vec4(q.xyz+n*((c-1.0)*along+s*q.w), c*q.w+s*along);
}
void vertex() {
	// Godot multiview shares a head-centre view matrix. EYE_OFFSET supplies
	// the individual eye; the view projection already includes its translation.
	vec3 eye = (anchor_inverse * INV_VIEW_MATRIX * vec4(EYE_OFFSET,1.0)).xyz/radius;
	vec3 v = VERTEX;
	float height = v.y;
	if(product_space) v.y=0.0;
	vec4 q = observer * vec4(v,sqrt(1.0+dot(v,v)));
	vec3 display;
	if(product_space) {
		q=boost(q,-vec3(eye.x,0.0,eye.z));
		float r=length(q.xz);
		float factor=r<0.00001 ? 1.0 : log(r+sqrt(r*r+1.0))/r;
		display=vec3(q.x*factor,height-eye.y-product_height,q.z*factor)*radius;
	} else {
		q=boost(q,-eye);
		// Klein projection: geodesics are chords; angle measurements use the metric.
		display=q.xyz/q.w*radius;
	}
	VERTEX=(VIEW_MATRIX * anchor_world * vec4(display,0.0)).xyz+EYE_OFFSET;
}
void fragment() {
	ALBEDO=tone.rgb*COLOR.rgb;
}
