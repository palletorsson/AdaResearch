extends Node
class_name DiagramProvider

# Integrates DiagramGenerator with RichTextLabel
# Intercepts diagram:// URLs and generates textures

static func setup_rich_text_label(rtl: RichTextLabel):
    """Call this to enable procedural diagrams in a RichTextLabel"""
    rtl.meta_clicked.connect(_on_meta_clicked)


static func process_text_with_diagrams(text: String, rtl: RichTextLabel) -> String:
    """
    Process BBCode text and replace diagram:// references with actual textures

    Usage in tutorial text:
    [img=400x300]diagram://bloom_filter_bits[/img]
    """

    # Find all diagram:// references
    var regex = RegEx.new()
    regex.compile(r'\[img(?:=(\d+)(?:x(\d+))?)?\]diagram://([a-z_]+)\[/img\]')

    var matches = regex.search_all(text)
    var processed_text = text

    for match in matches:
        var full_match = match.get_string()
        var width_str = match.get_string(1) if match.get_string(1) else "400"
        var height_str = match.get_string(2) if match.get_string(2) else "300"
        var diagram_name = match.get_string(3)

        var width = int(width_str)
        var height = int(height_str) if height_str else width

        # Generate diagram
        var texture = DiagramGenerator.generate(diagram_name, width, height)

        # Add to RichTextLabel
        if rtl:
            rtl.add_image(texture, width, height)

            # Replace with placeholder that RichTextLabel will fill
            # Note: This is a simplified approach
            # You might need to use a different method depending on exact BBCode handling

    return processed_text


static func _on_meta_clicked(meta):
    """Handle clicks on diagram metadata"""
    if meta is String and meta.begins_with("diagram://"):
        print("Diagram clicked: %s" % meta)
