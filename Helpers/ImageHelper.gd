# ImageHelper.gd
extends Node
class_name ImageHelper

# Creates a new image with the given width, height, and fill color
static func create_image(width: int, height: int, fill_color: Color = Color.BLACK) -> Image:
	var img = Image.create(width, height, false, Image.FORMAT_RGBA8)
	img.fill(fill_color)
	return img

# Converts an image into a texture
static func create_texture_from_image(img: Image) -> ImageTexture:
	var tex = ImageTexture.new()
	if img.get_data().size() != 0:
		tex.create_from_image(img)
	return tex

# Applies an outline effect to white pixels in an image
static func apply_outline(image: Image, outline_color: Color = Color(1, 0.2, 0.8, 1)):
	var width = image.get_width()
	var height = image.get_height()

	for y in range(height):
		for x in range(width):
			var color = image.get_pixel(x, y)
			if color == Color(1, 1, 1, 1):  # Check for white pixel
				# Add an outline around white pixels
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var nx = x + dx
						var ny = y + dy
						if nx >= 0 and ny >= 0 and nx < width and ny < height:
							var neighbor_color = image.get_pixel(nx, ny)
							if neighbor_color != Color(1, 1, 1, 1):  # Avoid overwriting white
								image.set_pixel(nx, ny, outline_color)
