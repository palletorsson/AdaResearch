extends CompositorEffect
## Separable blur of each eye's resolved colour. No cross-eye sampling or camera
## movement. Scratch images belong to the viewport and expire with its buffers.
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
layout(push_constant,std430) uniform Params { vec2 direction; float amount; float pad; } p;
void main() {
    ivec2 size=textureSize(source_image,0);
    vec4 original=texture(source_image,uv);
    // Dense Gaussian taps avoid duplicated edges at severe impairment. Radius
    // scales with resolution; fractional offsets use bilinear filtering.
    vec4 color=vec4(0.0);
    float total=0.0;
    float stride=float(min(size.x,size.y))*0.0015*p.amount;
    for (int i=-12;i<=12;i++) {
        float weight=exp(-float(i*i)/32.0);
        vec2 offset=p.direction*stride*float(i)/vec2(size);
        color+=texture(source_image,uv+offset)*weight;
        total+=weight;
    }
    output_color=mix(original,color/total,min(p.amount*8.0,1.0));
}
"""
var _amount := 0.0
var _mutex := Mutex.new()
var _rd: RenderingDevice
var _shader := RID()
var _pipelines := {}
var _sampler := RID()
var _context: StringName
var _buffers: WeakRef

func _init() -> void:
	effect_callback_type=EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
	access_resolved_color=true
	enabled=false
	_context=StringName("void_sight_%d" % get_instance_id())

func set_amount(amount: float) -> void:
	_mutex.lock()
	_amount=clampf(amount,0.0,1.0)
	_mutex.unlock()
	enabled=amount>0.0001

func _render_callback(kind: int, data: RenderData) -> void:
	if kind!=EFFECT_CALLBACK_TYPE_POST_TRANSPARENT: return
	_mutex.lock()
	var amount := _amount
	_mutex.unlock()
	if amount<=0.0001: return
	var buffers := data.get_render_scene_buffers() as RenderSceneBuffersRD
	if buffers==null: return
	_buffers=weakref(buffers)
	var size := buffers.get_internal_size()
	if size.x<1 or size.y<1: return
	if _rd==null:
		_rd=RenderingServer.get_rendering_device()
		if _rd==null: return
		var source := RDShaderSource.new()
		source.source_vertex=VERTEX; source.source_fragment=FRAGMENT
		var spirv := _rd.shader_compile_spirv_from_source(source)
		if not spirv.compile_error_vertex.is_empty() or not spirv.compile_error_fragment.is_empty():
			push_error("Void sight shader: "+spirv.compile_error_vertex+spirv.compile_error_fragment)
			return
		_shader=_rd.shader_create_from_spirv(spirv)
		var sampler := RDSamplerState.new()
		sampler.mag_filter=RenderingDevice.SAMPLER_FILTER_LINEAR
		sampler.min_filter=RenderingDevice.SAMPLER_FILTER_LINEAR
		sampler.repeat_u=RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_EDGE
		sampler.repeat_v=RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_EDGE
		_sampler=_rd.sampler_create(sampler)
	if not _shader.is_valid(): return
	if buffers.has_texture(_context,&"scratch") and buffers.get_texture_slice_size(_context,&"scratch",0)!=size:
		buffers.clear_context(_context)
	if not buffers.has_texture(_context,&"scratch"):
		# Mobile colour buffers cannot be storage images. Raster passes work in
		# both renderers and preserve the native colour format (10-bit / HDR).
		var format := _rd.texture_get_format(buffers.get_color_layer(0)).format
		buffers.create_texture(_context,&"scratch",format,
			RenderingDevice.TEXTURE_USAGE_COLOR_ATTACHMENT_BIT|RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT,RenderingDevice.TEXTURE_SAMPLES_1,
			size,buffers.get_view_count(),1,false,false)
	# The native XR colour buffer has one layer per eye. Process them separately.
	for view in buffers.get_view_count():
		var color := buffers.get_color_layer(view)
		var scratch := buffers.get_texture_slice(_context,&"scratch",view,0,1,1)
		_pass(color,scratch,Vector2.RIGHT,amount)
		_pass(scratch,color,Vector2.DOWN,amount)

func _pass(source: RID, target: RID, direction: Vector2, amount: float) -> void:
	var read := RDUniform.new()
	read.uniform_type=RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	read.binding=0; read.add_id(_sampler); read.add_id(source)
	var uniforms := UniformSetCacheRD.get_cache(_shader,0,[read])
	var framebuffer := FramebufferCacheRD.get_cache_multipass([target],[],1)
	var format := _rd.framebuffer_get_format(framebuffer)
	if not _pipelines.has(format):
		var blend := RDPipelineColorBlendState.new()
		blend.attachments=[RDPipelineColorBlendStateAttachment.new()]
		_pipelines[format]=_rd.render_pipeline_create(_shader,format,-1,
			RenderingDevice.RENDER_PRIMITIVE_TRIANGLES,RDPipelineRasterizationState.new(),
			RDPipelineMultisampleState.new(),RDPipelineDepthStencilState.new(),blend)
	var params := PackedFloat32Array([direction.x,direction.y,amount,0.0]).to_byte_array()
	var commands := _rd.draw_list_begin(framebuffer)
	_rd.draw_list_bind_render_pipeline(commands,_pipelines[format])
	_rd.draw_list_bind_uniform_set(commands,uniforms,0)
	_rd.draw_list_set_push_constant(commands,params,params.size())
	_rd.draw_list_draw(commands,false,1,3)
	_rd.draw_list_end()

func _notification(what: int) -> void:
	if what==NOTIFICATION_PREDELETE and _shader.is_valid():
		RenderingServer.get_rendering_device().free_rid(_shader)
		if _sampler.is_valid(): RenderingServer.get_rendering_device().free_rid(_sampler)

func release() -> void:
	set_amount(0.0)
	RenderingServer.call_on_render_thread(_release_scratch)

func _release_scratch() -> void:
	# The root viewport outlives a visit to The Void. Don't retain a new full-eye
	# texture on every return to the game menu.
	if _buffers!=null:
		var buffers := _buffers.get_ref() as RenderSceneBuffersRD
		if buffers!=null: buffers.clear_context(_context)
	_buffers=null
