# GPU_Test.gd
# Simple script to test GPU compute shader support
extends Node

func _ready():
	test_gpu_availability()

func test_gpu_availability():
	print("=== GPU COMPUTE SHADER TEST ===")
	
	# Test 1: Check if we can create a rendering device
	var rd = RenderingServer.create_local_rendering_device()
	if not rd:
		print("❌ FAILED: Cannot create local rendering device")
		print("   Your GPU may not support compute shaders")
		print("   Try updating GPU drivers or use CPU fallback")
		return false
	
	print("✅ SUCCESS: Local rendering device created")
	
	# Test 2: Check device capabilities
	var device_info = rd.get_device_name()
	print("📱 GPU Device: %s" % device_info)
	
	# Test 3: Try to compile a simple compute shader
	var simple_shader_source = """
#version 450
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) restrict writeonly buffer OutputBuffer {
	float values[];
} output_data;

void main() {
	uint index = gl_GlobalInvocationID.x + gl_GlobalInvocationID.y * 8;
	if (index < output_data.values.length()) {
		output_data.values[index] = float(index);
	}
}
"""
	
	var shader_file = RDShaderFile.new()
	shader_file.set_source_code(RenderingDevice.SHADER_STAGE_COMPUTE, simple_shader_source)
	
	var shader_spirv = shader_file.get_spirv()
	if not shader_spirv:
		print("❌ FAILED: Simple compute shader compilation failed")
		print("   Your GPU drivers may be outdated")
		return false
	
	print("✅ SUCCESS: Simple compute shader compiled")
	
	# Test 4: Try to create the shader on GPU
	var compute_shader = rd.shader_create_from_spirv(shader_spirv)
	if not compute_shader.is_valid():
		print("❌ FAILED: Cannot create compute shader on GPU")
		return false
	
	print("✅ SUCCESS: Compute shader created on GPU")
	
	# Test 5: Test buffer creation
	var test_data = PackedFloat32Array([1.0, 2.0, 3.0, 4.0])
	var buffer = rd.storage_buffer_create(test_data.size() * 4)
	if not buffer.is_valid():
		print("❌ FAILED: Cannot create GPU buffer")
		return false
	
	print("✅ SUCCESS: GPU buffer created")
	
	# Cleanup
	if rd:
		if compute_shader != RID() and compute_shader.is_valid():
			rd.free_rid(compute_shader)
		if buffer != RID() and buffer.is_valid():
			rd.free_rid(buffer)
	
	print("🎉 ALL GPU TESTS PASSED!")
	print("   Your system supports compute shaders")
	print("   The marching cubes GPU implementation should work")
	
	return true
