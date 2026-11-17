extends CompositorEffect
## What a mushroom does to the eyes: one of the camera study's pixel operations (commons/artifacts/camera_glitch_study)
## applied to the visitor's own sight, per eye, the same in both eyes (nothing pulls the two views apart).
## Raster passes on each eye's resolved colour, as commons/void/sight_blur.gd does: Forward+ and Mobile, desktop
## and headset. Modes (the camera study's names):
##   0 CHOP THE BANDS              alternate bands read from opposite horizontal offsets
##   1 CHANNELS LOSE REGISTRATION  red and blue read beside where green reads
##   2 EXCHANGE THE BLOCKS         a grid of blocks drifts toward other blocks' places
##   3 REPEAT A SCANLINE           one row stands for a group of rows
##   4 FEWER COLOUR VALUES         each channel rounded to a few levels
##   5 TEAR ONE BAND               one band, wandering up and down, slides sideways
const VERTEX := """
#version 450
layout(location=0) out vec2 uv;
void main() {
    uv=vec2(float((gl_VertexIndex<<1)&2),float(gl_VertexIndex&2));
    gl_Position=vec4(uv*2.0-1.0,0.0,1.0);
}
"""
const FRAGMENT := """
#version 450
layout(location=0) in vec2 uv;
layout(location=0) out vec4 output_color;
layout(set=0,binding=0) uniform sampler2D source_image;
layout(push_constant,std430) uniform Params { float mode; float amount; float time; float pad; } p;
float hash(vec2 q) { return fract(sin(dot(q,vec2(127.1,311.7)))*43758.5453); }
void main() {
    int m=int(p.mode+0.5);
    float a=clamp(p.amount,0.0,1.0);
    vec2 q=uv;
    if (m<0 || a<=0.0001) { output_color=texture(source_image,uv); return; }
    vec2 size=vec2(textureSize(source_image,0));
    vec4 c;
    if (m==0) {
        float band=floor(q.y*22.0);
        float dir=mod(band,2.0)<1.0?1.0:-1.0;
        q.x=fract(q.x+dir*a*0.03*(0.65+0.35*sin(p.time*0.8+band)));
        c=texture(source_image,q);
    } else if (m==1) {
        float off=a*0.011*(0.8+0.2*sin(p.time*1.3));
        c=vec4(texture(source_image,q+vec2(off,0.0)).r,texture(source_image,q).g,texture(source_image,q-vec2(off,0.0)).b,1.0);
    } else if (m==2) {
        vec2 grid=vec2(8.0,6.0);
        vec2 block=floor(q*grid);
        vec2 other=floor(vec2(hash(block),hash(block+17.0))*grid);
        float drift=a*0.35*(0.75+0.25*sin(p.time*0.5+hash(block)*6.28));
        q=fract(q+(other-block)/grid*drift);
        c=texture(source_image,q);
    } else if (m==3) {
        float rows=floor(mix(1.0,size.y/18.0,a));
        q.y=(floor(q.y*size.y/rows)*rows+0.5)/size.y;
        c=texture(source_image,q);
    } else if (m==4) {
        c=texture(source_image,q);
        // rounded where the eye judges steps (gamma), not in the linear buffer, where three levels make the
        // darks one black
        float levels=mix(40.0,6.0,a);
        vec3 g=pow(max(c.rgb,vec3(0.0)),vec3(1.0/2.2));
        g=floor(g*levels+0.5)/levels;
        c.rgb=pow(g,vec3(2.2));
    } else {
        float y0=0.5+0.32*sin(p.time*0.37);
        float inside=1.0-smoothstep(0.07,0.1,abs(q.y-y0));
        q.x=fract(q.x+inside*a*0.09);
        c=texture(source_image,q);
    }
    output_color=vec4(c.rgb,1.0);
}
"""
var _mode := -1
var _amount := 0.0
var _time := 0.0
var _mutex := Mutex.new()
var _rd: RenderingDevice
var _shader := RID()
var _pipelines := {}
var _sampler := RID()
var _context: StringName
var _buffers: WeakRef


func _init() -> void:
	effect_callback_type = EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
	access_resolved_color = true
	enabled = false
	_context = StringName("mushroom_sight_%d" % get_instance_id())


func set_state(mode: int, amount: float, time: float) -> void:
	_mutex.lock()
	_mode = mode
	_amount = clampf(amount, 0.0, 1.0)
	_time = time
	_mutex.unlock()
	enabled = mode >= 0 and amount > 0.0001


func _render_callback(kind: int, data: RenderData) -> void:
	if kind != EFFECT_CALLBACK_TYPE_POST_TRANSPARENT: return
	_mutex.lock()
	var mode := _mode
	var amount := _amount
	var time := _time
	_mutex.unlock()
	if mode < 0 or amount <= 0.0001: return
	var buffers := data.get_render_scene_buffers() as RenderSceneBuffersRD
	if buffers == null: return
	_buffers = weakref(buffers)
	var size := buffers.get_internal_size()
	if size.x < 1 or size.y < 1: return
	if _rd == null:
		_rd = RenderingServer.get_rendering_device()
		if _rd == null: return
		var source := RDShaderSource.new()
		source.source_vertex = VERTEX
		source.source_fragment = FRAGMENT
		var spirv := _rd.shader_compile_spirv_from_source(source)
		if not spirv.compile_error_vertex.is_empty() or not spirv.compile_error_fragment.is_empty():
			push_error("Mushroom sight shader: " + spirv.compile_error_vertex + spirv.compile_error_fragment)
			return
		_shader = _rd.shader_create_from_spirv(spirv)
		var sampler := RDSamplerState.new()
		sampler.mag_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
		sampler.min_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
		sampler.repeat_u = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_EDGE
		sampler.repeat_v = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_EDGE
		_sampler = _rd.sampler_create(sampler)
	if not _shader.is_valid(): return
	if buffers.has_texture(_context, &"scratch") and buffers.get_texture_slice_size(_context, &"scratch", 0) != size:
		buffers.clear_context(_context)
	if not buffers.has_texture(_context, &"scratch"):
		var format := _rd.texture_get_format(buffers.get_color_layer(0)).format
		buffers.create_texture(_context, &"scratch", format,
			RenderingDevice.TEXTURE_USAGE_COLOR_ATTACHMENT_BIT | RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT, RenderingDevice.TEXTURE_SAMPLES_1,
			size, buffers.get_view_count(), 1, false, false)
	# one layer per eye in a headset: each eye is read and written on its own, by the same operation
	for view in buffers.get_view_count():
		var color := buffers.get_color_layer(view)
		var scratch := buffers.get_texture_slice(_context, &"scratch", view, 0, 1, 1)
		_pass(color, scratch, float(mode), amount, time)
		_pass(scratch, color, -1.0, 0.0, time)


func _pass(source: RID, target: RID, mode: float, amount: float, time: float) -> void:
	var read := RDUniform.new()
	read.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	read.binding = 0
	read.add_id(_sampler)
	read.add_id(source)
	var uniforms := UniformSetCacheRD.get_cache(_shader, 0, [read])
	var framebuffer := FramebufferCacheRD.get_cache_multipass([target], [], 1)
	var format := _rd.framebuffer_get_format(framebuffer)
	if not _pipelines.has(format):
		var blend := RDPipelineColorBlendState.new()
		blend.attachments = [RDPipelineColorBlendStateAttachment.new()]
		_pipelines[format] = _rd.render_pipeline_create(_shader, format, -1, RenderingDevice.RENDER_PRIMITIVE_TRIANGLES,
			RDPipelineRasterizationState.new(), RDPipelineMultisampleState.new(), RDPipelineDepthStencilState.new(), blend)
	var params := PackedFloat32Array([mode, amount, time, 0.0]).to_byte_array()
	var commands := _rd.draw_list_begin(framebuffer)
	_rd.draw_list_bind_render_pipeline(commands, _pipelines[format])
	_rd.draw_list_bind_uniform_set(commands, uniforms, 0)
	_rd.draw_list_set_push_constant(commands, params, params.size())
	_rd.draw_list_draw(commands, false, 1, 3)
	_rd.draw_list_end()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _shader.is_valid():
		RenderingServer.get_rendering_device().free_rid(_shader)
		if _sampler.is_valid(): RenderingServer.get_rendering_device().free_rid(_sampler)


func release() -> void:
	set_state(-1, 0.0, 0.0)
	RenderingServer.call_on_render_thread(_release_scratch)


func _release_scratch() -> void:
	if _buffers != null:
		var buffers := _buffers.get_ref() as RenderSceneBuffersRD
		if buffers != null: buffers.clear_context(_context)
	_buffers = null
