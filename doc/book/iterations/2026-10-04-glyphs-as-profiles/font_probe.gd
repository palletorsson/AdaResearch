extends SceneTree
func _initialize() -> void:
    var report: Array = []
    for path in ["C:/Windows/Fonts/wingding.ttf","C:/Windows/Fonts/seguisym.ttf"]:
        var font := FontFile.new()
        if font.load_dynamic_font(path)!=OK:
            continue
        print("CHARS ",font.get_supported_chars().substr(0,150))
        var chars := ["B","O","*","&",String.chr(0x2605)] if not "wingding" in path else [String.chr(0xf04a),"J"]
        for text in chars:
            print("PROBE ",path," ",text.unicode_at(0))
            var mesh := TextMesh.new()
            mesh.font = font
            mesh.text = text
            mesh.font_size = 48
            mesh.pixel_size = .04
            mesh.curve_step = .2
            mesh.depth = 0.0
            var a := mesh.surface_get_arrays(0)
            var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
            var ix: PackedInt32Array = a[Mesh.ARRAY_INDEX]
            report.append({"font":path,"cp":text.unicode_at(0),"verts":v.size(),"indices":ix.size()})
    print(JSON.stringify(report))
    var font := FontFile.new()
    font.load_dynamic_font("res://JetBrainsMono-Medium.ttf")
    var made: ArrayMesh = load("res://glyph_solid.gd").make(font,"B",.42)
    var verts: PackedVector3Array = made.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
    var values: Array = []
    for p in verts:
        values.append([p.x,p.y,p.z])
    FileAccess.open("res://geometry-probe.json",FileAccess.WRITE).store_string(JSON.stringify(values))
    quit()
