extends Node
class_name DiagramGenerator

# Generates procedural diagrams for tutorials
# Usage in tutorials: [img=400x300]diagram://bloom_filter_bits[/img]

static var _diagram_cache: Dictionary = {}

# Generate a diagram by name and return ImageTexture
static func generate(diagram_name: String, width: int = 400, height: int = 300) -> ImageTexture:
    var cache_key = "%s_%d_%d" % [diagram_name, width, height]

    # Return cached if available
    if _diagram_cache.has(cache_key):
        return _diagram_cache[cache_key]

    var img: Image = null

    # Route to specific generator
    match diagram_name:
        "bloom_filter_bits":
            img = generate_bloom_filter_bits(width, height)
        "skip_list_layers":
            img = generate_skip_list_layers(width, height)
        "hilbert_curve":
            img = generate_hilbert_curve(width, height)
        "dijkstra_graph":
            img = generate_dijkstra_graph(width, height)
        "binary_tree":
            img = generate_binary_tree(width, height)
        _:
            push_warning("Unknown diagram: %s" % diagram_name)
            img = generate_placeholder(width, height, diagram_name)

    var texture = ImageTexture.create_from_image(img)
    _diagram_cache[cache_key] = texture
    return texture


# ============================================================================
# DIAGRAM GENERATORS
# ============================================================================

static func generate_bloom_filter_bits(width: int, height: int) -> Image:
    var img = Image.create(width, height, false, Image.FORMAT_RGBA8)
    img.fill(Color(0.05, 0.05, 0.07, 1.0))

    var num_bits = 16
    var box_size = 25
    var total_width = num_bits * box_size
    var start_x = (width - total_width) / 2
    var y_top = height / 3
    var y_bottom = 2 * height / 3

    # Initial state (all zeros)
    for i in range(num_bits):
        var x = start_x + i * box_size
        draw_box(img, x, y_top, box_size, "0", Color(0.3, 0.3, 0.35))

    # After adding "cat" - bits 3, 7, 12 set
    var set_bits = [3, 7, 12]
    for i in range(num_bits):
        var x = start_x + i * box_size
        var is_set = i in set_bits
        var value = "1" if is_set else "0"
        var box_color = Color(0.8, 0.3, 0.3) if is_set else Color(0.3, 0.3, 0.35)
        draw_box(img, x, y_bottom, box_size, value, box_color)

    # Draw arrows to highlight set bits
    for bit_index in set_bits:
        var x = start_x + bit_index * box_size + box_size / 2
        draw_arrow_down(img, x, y_bottom - 35, Color(0.9, 0.6, 0.2))

    # Labels
    draw_text(img, width / 2, y_top - 30, "Initial: all bits = 0", Color.WHITE, true)
    draw_text(img, width / 2, y_bottom - 50, "After add('cat'): h1=3, h2=7, h3=12", Color(0.9, 0.9, 0.5), true)

    return img


static func generate_skip_list_layers(width: int, height: int) -> Image:
    var img = Image.create(width, height, false, Image.FORMAT_RGBA8)
    img.fill(Color(0.05, 0.05, 0.07, 1.0))

    var values = [1, 3, 4, 6, 9]
    var node_width = 40
    var node_height = 30
    var spacing = 20
    var start_x = 50
    var level_spacing = 60

    # Draw 4 levels
    for level in range(4):
        var y = height - 50 - (level * level_spacing)

        # Determine which nodes appear at this level (probabilistic)
        # Level 0: all nodes
        # Level 1: 1, 4, 9
        # Level 2: 1, 9
        # Level 3: 1

        var nodes_at_level = []
        match level:
            0: nodes_at_level = [0, 1, 2, 3, 4]  # All
            1: nodes_at_level = [0, 2, 4]        # Subset
            2: nodes_at_level = [0, 4]           # Fewer
            3: nodes_at_level = [0]              # Just head

        # Draw nodes at this level
        var prev_x = -1
        for idx in nodes_at_level:
            var x = start_x + idx * (node_width + spacing)
            draw_box(img, x, y, node_width, str(values[idx]), Color(0.3, 0.5, 0.7))

            # Draw horizontal line to next node
            if prev_x >= 0:
                draw_line_horizontal(img, prev_x + node_width, x, y + node_height / 2, Color(0.5, 0.7, 0.9))
            prev_x = x

        # Label
        draw_text(img, 20, y + node_height / 2, "L%d" % level, Color(0.6, 0.6, 0.7), false)

    draw_text(img, width / 2, 20, "Skip List: Express Lanes", Color.WHITE, true)

    return img


static func generate_hilbert_curve(width: int, height: int) -> Image:
    var img = Image.create(width, height, false, Image.FORMAT_RGBA8)
    img.fill(Color(0.05, 0.05, 0.07, 1.0))

    var order = 3  # Hilbert curve order
    var size = min(width, height) - 60
    var offset_x = (width - size) / 2
    var offset_y = (height - size) / 2

    # Generate Hilbert curve points
    var points = generate_hilbert_points(order)

    # Scale points to image size
    var max_coord = (1 << order) - 1  # 2^order - 1
    var scale = float(size) / float(max_coord)

    # Draw curve
    var prev_point = null
    for i in range(points.size()):
        var p = points[i]
        var x = offset_x + p.x * scale
        var y = offset_y + p.y * scale

        # Draw point
        var color = Color.from_hsv(float(i) / points.size(), 0.8, 0.9)
        draw_circle(img, x, y, 3, color)

        # Draw line from previous
        if prev_point:
            draw_line_smooth(img, prev_point.x, prev_point.y, x, y, color)

        prev_point = Vector2(x, y)

    draw_text(img, width / 2, 20, "Hilbert Curve (Order %d)" % order, Color.WHITE, true)

    return img


static func generate_dijkstra_graph(width: int, height: int) -> Image:
    var img = Image.create(width, height, false, Image.FORMAT_RGBA8)
    img.fill(Color(0.05, 0.05, 0.07, 1.0))

    # Define graph nodes positions
    var nodes = {
        "A": Vector2(100, height / 2),
        "B": Vector2(250, height / 3),
        "C": Vector2(250, 2 * height / 3),
        "D": Vector2(400, height / 2)
    }

    # Define edges with weights
    var edges = [
        {"from": "A", "to": "B", "weight": 4},
        {"from": "A", "to": "C", "weight": 2},
        {"from": "B", "to": "D", "weight": 3},
        {"from": "C", "to": "D", "weight": 1}
    ]

    # Draw edges
    for edge in edges:
        var from_pos = nodes[edge.from]
        var to_pos = nodes[edge.to]
        draw_line_smooth(img, from_pos.x, from_pos.y, to_pos.x, to_pos.y, Color(0.4, 0.4, 0.5))

        # Draw weight label
        var mid = (from_pos + to_pos) / 2
        draw_text(img, mid.x, mid.y - 10, str(edge.weight), Color(0.9, 0.7, 0.3), true)

    # Draw nodes
    for node_name in nodes:
        var pos = nodes[node_name]
        var color = Color(0.3, 0.6, 0.8) if node_name == "A" else Color(0.5, 0.5, 0.6)
        draw_circle(img, pos.x, pos.y, 20, color)
        draw_text(img, pos.x, pos.y, node_name, Color.WHITE, true)

    draw_text(img, width / 2, 20, "Weighted Graph", Color.WHITE, true)

    return img


static func generate_binary_tree(width: int, height: int) -> Image:
    var img = Image.create(width, height, false, Image.FORMAT_RGBA8)
    img.fill(Color(0.05, 0.05, 0.07, 1.0))

    # Simple binary tree: recursive drawing
    draw_tree_node(img, width / 2, 50, 80, 3, Color(0.4, 0.7, 0.5))

    draw_text(img, width / 2, height - 20, "Binary Tree (Depth 3)", Color.WHITE, true)

    return img


static func draw_tree_node(img: Image, x: float, y: float, spread: float, depth: int, color: Color):
    if depth <= 0:
        return

    # Draw node
    draw_circle(img, x, y, 12, color)

    # Draw children
    if depth > 1:
        var child_y = y + 60
        var left_x = x - spread
        var right_x = x + spread

        # Draw connecting lines
        draw_line_smooth(img, x, y + 12, left_x, child_y - 12, Color(0.5, 0.5, 0.6))
        draw_line_smooth(img, x, y + 12, right_x, child_y - 12, Color(0.5, 0.5, 0.6))

        # Recursive draw
        draw_tree_node(img, left_x, child_y, spread * 0.6, depth - 1, color)
        draw_tree_node(img, right_x, child_y, spread * 0.6, depth - 1, color)


static func generate_placeholder(width: int, height: int, name: String) -> Image:
    var img = Image.create(width, height, false, Image.FORMAT_RGBA8)
    img.fill(Color(0.1, 0.1, 0.15, 1.0))

    draw_text(img, width / 2, height / 2 - 10, "Diagram: %s" % name, Color(0.7, 0.7, 0.8), true)
    draw_text(img, width / 2, height / 2 + 20, "(Not implemented yet)", Color(0.5, 0.5, 0.6), true)

    return img


# ============================================================================
# DRAWING PRIMITIVES
# ============================================================================

static func draw_box(img: Image, x: int, y: int, size: int, text: String, fill_color: Color):
    # Fill
    for py in range(size):
        for px in range(size):
            if x + px < img.get_width() and y + py < img.get_height():
                img.set_pixel(x + px, y + py, fill_color)

    # Outline
    var outline_color = Color.WHITE
    for px in range(size):
        if x + px < img.get_width():
            if y < img.get_height():
                img.set_pixel(x + px, y, outline_color)
            if y + size - 1 < img.get_height():
                img.set_pixel(x + px, y + size - 1, outline_color)
    for py in range(size):
        if y + py < img.get_height():
            if x < img.get_width():
                img.set_pixel(x, y + py, outline_color)
            if x + size - 1 < img.get_width():
                img.set_pixel(x + size - 1, y + py, outline_color)


static func draw_circle(img: Image, cx: float, cy: float, radius: float, color: Color):
    var r_sq = radius * radius
    for py in range(int(-radius), int(radius) + 1):
        for px in range(int(-radius), int(radius) + 1):
            if px * px + py * py <= r_sq:
                var x = int(cx + px)
                var y = int(cy + py)
                if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
                    img.set_pixel(x, y, color)


static func draw_line_horizontal(img: Image, x1: int, x2: int, y: int, color: Color):
    for x in range(x1, x2 + 1):
        if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
            img.set_pixel(x, y, color)


static func draw_line_smooth(img: Image, x1: float, y1: float, x2: float, y2: float, color: Color):
    # Bresenham-style line
    var dx = abs(x2 - x1)
    var dy = abs(y2 - y1)
    var sx = 1 if x1 < x2 else -1
    var sy = 1 if y1 < y2 else -1
    var err = dx - dy

    var x = x1
    var y = y1

    for i in range(1000):  # Max iterations
        if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
            img.set_pixel(int(x), int(y), color)

        if abs(x - x2) < 1 and abs(y - y2) < 1:
            break

        var e2 = 2 * err
        if e2 > -dy:
            err -= dy
            x += sx
        if e2 < dx:
            err += dx
            y += sy


static func draw_arrow_down(img: Image, x: int, y: int, color: Color):
    # Simple down arrow
    for i in range(20):
        if y + i < img.get_height():
            img.set_pixel(x, y + i, color)

    # Arrowhead
    for dx in [-3, -2, -1, 0, 1, 2, 3]:
        var dy = abs(dx)
        if x + dx >= 0 and x + dx < img.get_width() and y + 20 - dy < img.get_height():
            img.set_pixel(x + dx, y + 20 - dy, color)


static func draw_text(img: Image, x: float, y: float, text: String, color: Color, centered: bool):
    # Note: Actual text rendering requires a font
    # This is a placeholder - you'd use a bitmap font or rasterize text
    # For now, we'll skip actual text rendering
    pass


# ============================================================================
# HILBERT CURVE GENERATION
# ============================================================================

static func generate_hilbert_points(order: int) -> Array[Vector2i]:
    var points: Array[Vector2i] = []
    var n = 1 << order  # 2^order

    for i in range(n * n):
        points.append(hilbert_index_to_xy(i, order))

    return points


static func hilbert_index_to_xy(index: int, order: int) -> Vector2i:
    var n = 1 << order
    var x = 0
    var y = 0

    for s in range(order):
        var rx = 1 & (index >> 1)
        var ry = 1 & (index ^ rx)

        if ry == 0:
            if rx == 1:
                x = n - 1 - x
                y = n - 1 - y
            var temp = x
            x = y
            y = temp

        x += rx * (n >> 1)
        y += ry * (n >> 1)
        index >>= 2
        n >>= 1

    return Vector2i(x, y)
