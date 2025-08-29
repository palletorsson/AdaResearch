extends Node

# Queer Texture Generator
# Creates vibrant, pride-inspired textures for cave lighting

static func create_pride_gradient_texture(width: int = 256, height: int = 64) -> ImageTexture:
	"""
	Creates a beautiful pride flag gradient texture with flowing colors
	"""
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	
	# Pride flag colors (classic 6-stripe)
	var pride_colors = [
		Color(0.91, 0.11, 0.14, 1.0),  # Red - Life
		Color(1.0, 0.53, 0.0, 1.0),   # Orange - Healing
		Color(1.0, 0.93, 0.0, 1.0),   # Yellow - Sunlight
		Color(0.0, 0.51, 0.16, 1.0),  # Green - Nature
		Color(0.0, 0.32, 0.82, 1.0),  # Blue - Harmony
		Color(0.46, 0.11, 0.53, 1.0)  # Purple - Spirit
	]
	
	for y in range(height):
		for x in range(width):
			var u = float(x) / float(width)
			var v = float(y) / float(height)
			
			# Create flowing gradient across width
			var color_position = u * (pride_colors.size() - 1)
			var color_index = int(color_position)
			var blend_factor = color_position - color_index
			
			var color1 = pride_colors[color_index]
			var color2 = pride_colors[min(color_index + 1, pride_colors.size() - 1)]
			
			# Blend between adjacent colors
			var base_color = color1.lerp(color2, blend_factor)
			
			# Add some vertical variation for texture
			var intensity = 0.8 + 0.2 * sin(v * PI * 2.0 + u * PI * 4.0)
			base_color = base_color * intensity
			
			# Add some shimmer effect
			var shimmer = 0.9 + 0.1 * sin(u * PI * 8.0 + v * PI * 6.0)
			base_color = base_color * shimmer
			
			# Ensure alpha is 1.0
			base_color.a = 1.0
			
			image.set_pixel(x, y, base_color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

static func create_trans_gradient_texture(width: int = 256, height: int = 64) -> ImageTexture:
	"""
	Creates a trans pride flag gradient texture
	"""
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	
	# Trans flag colors
	var trans_colors = [
		Color(0.34, 0.81, 0.98, 1.0),  # Light blue
		Color(0.96, 0.68, 0.81, 1.0),  # Pink
		Color(1.0, 1.0, 1.0, 1.0),     # White
		Color(0.96, 0.68, 0.81, 1.0),  # Pink
		Color(0.34, 0.81, 0.98, 1.0)   # Light blue
	]
	
	for y in range(height):
		for x in range(width):
			var u = float(x) / float(width)
			var v = float(y) / float(height)
			
			# Create flowing gradient
			var color_position = u * (trans_colors.size() - 1)
			var color_index = int(color_position)
			var blend_factor = color_position - color_index
			
			var color1 = trans_colors[color_index]
			var color2 = trans_colors[min(color_index + 1, trans_colors.size() - 1)]
			
			var base_color = color1.lerp(color2, blend_factor)
			
			# Add gentle wave pattern
			var wave = 0.85 + 0.15 * sin(v * PI * 3.0 + u * PI * 2.0)
			base_color = base_color * wave
			
			base_color.a = 1.0
			image.set_pixel(x, y, base_color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

static func create_rainbow_shimmer_texture(width: int = 256, height: int = 64) -> ImageTexture:
	"""
	Creates a shimmering rainbow texture with dynamic lighting effects
	"""
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	
	for y in range(height):
		for x in range(width):
			var u = float(x) / float(width)
			var v = float(y) / float(height)
			
			# Create HSV-based rainbow
			var hue = u * 360.0  # Full rainbow across width
			var saturation = 0.9 + 0.1 * sin(v * PI * 4.0)
			var value = 0.8 + 0.2 * sin(u * PI * 6.0 + v * PI * 3.0)
			
			# Add shimmer pattern
			var shimmer = 0.7 + 0.3 * sin(u * PI * 12.0) * cos(v * PI * 8.0)
			value *= shimmer
			
			var color = Color.from_hsv(hue / 360.0, saturation, value, 1.0)
			image.set_pixel(x, y, color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

static func create_aurora_texture(width: int = 256, height: int = 64) -> ImageTexture:
	"""
	Creates an aurora-like texture with flowing queer colors
	"""
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	
	# Aurora-inspired colors
	var aurora_colors = [
		Color(0.5, 0.0, 1.0, 1.0),     # Purple
		Color(0.0, 0.8, 1.0, 1.0),     # Cyan
		Color(0.0, 1.0, 0.5, 1.0),     # Green
		Color(1.0, 0.0, 0.8, 1.0),     # Magenta
		Color(1.0, 0.5, 0.0, 1.0)      # Orange
	]
	
	for y in range(height):
		for x in range(width):
			var u = float(x) / float(width)
			var v = float(y) / float(height)
			
			# Create flowing aurora effect
			var wave1 = sin(u * PI * 3.0 + v * PI * 2.0) * 0.5 + 0.5
			var wave2 = cos(u * PI * 4.0 - v * PI * 3.0) * 0.5 + 0.5
			var wave3 = sin(u * PI * 2.0 + v * PI * 4.0) * 0.5 + 0.5
			
			# Blend multiple aurora colors
			var color_blend = (wave1 + wave2 + wave3) / 3.0
			var color_index = color_blend * (aurora_colors.size() - 1)
			var index1 = int(color_index)
			var index2 = min(index1 + 1, aurora_colors.size() - 1)
			var blend_factor = color_index - index1
			
			var color = aurora_colors[index1].lerp(aurora_colors[index2], blend_factor)
			
			# Add intensity variation
			var intensity = 0.6 + 0.4 * wave1 * wave2
			color = color * intensity
			
			color.a = 1.0
			image.set_pixel(x, y, color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

static func save_queer_textures_to_resources():
	"""
	Saves all queer textures as resource files
	"""
	var base_path = "res://algorithms/proceduralgeneration/marchingcave/Textures/"
	
	# Create pride gradient
	var pride_texture = create_pride_gradient_texture()
	ResourceSaver.save(pride_texture, base_path + "queer_pride_gradient.tres")
	
	# Create trans gradient  
	var trans_texture = create_trans_gradient_texture()
	ResourceSaver.save(trans_texture, base_path + "queer_trans_gradient.tres")
	
	# Create rainbow shimmer
	var rainbow_texture = create_rainbow_shimmer_texture()
	ResourceSaver.save(rainbow_texture, base_path + "queer_rainbow_shimmer.tres")
	
	# Create aurora
	var aurora_texture = create_aurora_texture()
	ResourceSaver.save(aurora_texture, base_path + "queer_aurora.tres")
	
	print("🏳️‍🌈 Queer textures saved successfully!")
	print("Available textures:")
	print("  - queer_pride_gradient.tres (Classic 6-stripe pride)")
	print("  - queer_trans_gradient.tres (Trans pride colors)")
	print("  - queer_rainbow_shimmer.tres (Dynamic rainbow)")
	print("  - queer_aurora.tres (Aurora-like flowing colors)")
