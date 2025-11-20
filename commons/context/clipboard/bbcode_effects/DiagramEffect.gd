extends RichTextEffect
class_name DiagramEffect

# Custom BBCode tag: [diagram type=bloom_filter width=400 height=300]
# Renders procedurally generated diagrams inline

var bbcode = "diagram"

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
    var diagram_type = char_fx.env.get("type", "")
    var width = int(char_fx.env.get("width", 400))
    var height = int(char_fx.env.get("height", 300))

    # This gets called per character, so we need to handle it carefully
    # You'd typically create the image once and cache it

    return true

# Helper to create diagram images
static func create_bloom_filter_diagram(width: int, height: int) -> Image:
    var img = Image.create(width, height, false, Image.FORMAT_RGBA8)
    img.fill(Color(0.05, 0.05, 0.07))

    # Draw bit array boxes
    var box_size = 30
    var num_bits = 16
    var start_x = (width - (num_bits * box_size)) / 2
    var y = height / 2 - box_size / 2

    for i in range(num_bits):
        var x = start_x + i * box_size
        # Draw box outline
        draw_rect_outline(img, x, y, box_size, box_size, Color.WHITE)

        # Draw bit value (0 or 1)
        # This is simplified - you'd use actual drawing functions

    return img

static func draw_rect_outline(img: Image, x: int, y: int, w: int, h: int, color: Color):
    # Draw rectangle outline pixel by pixel
    for px in range(w):
        img.set_pixel(x + px, y, color)          # Top
        img.set_pixel(x + px, y + h - 1, color)  # Bottom
    for py in range(h):
        img.set_pixel(x, y + py, color)          # Left
        img.set_pixel(x + w - 1, y + py, color)  # Right
