"""Source-read captions for the overlooked pattern families; gallery data only."""

def entries():
    result = []

    def add(token, title, section, fit, caption, scene, maps, caution='', config=None):
        result.append(dict(token=token, title=title, section=section, fit=fit,
                           caption=caption, scene=scene, source_maps=maps,
                           caution=caution, config=config))

    add('pink_tartan', 'Tartan · crossings choose the colour', 'principles', 'Tiling ↔ Shaders · borrow first',
        'The existing pinktartan shader combines horizontal and vertical band masks. Where one band crosses the ground it alternates colours in a fine checker; where two coincide it uses a solid colour. A useful surface-level connection to warp and weft.',
        'res://commons/resourses/shaders/pinktartan.gdshader', ['Shader library · review receiver'],
        'Rendered on a plain review quad with the existing right-edge fade retained. This represents crossings with colour; it does not simulate threads.')
    add('tartan_demo', 'Tartan · the crate installation', 'principles', 'Tiling ↔ Shaders · needs clearer display',
        'The existing crate installation repeats a one-dimensional stripe function along two UV axes, blends the colours, and adds cross-hatching. Seed and width settings vary the surface between objects.',
        'res://algorithms/misc/tartan_boxes_demo.tscn', ['One_Adapt_7'],
        'The current installation washes out in this capture. Its shader clamps each colour channel to at least 0.5 before further adjustments, so dark palettes become lighter. Named palette presets are not verified historical tartan setts. This is surface shading, not woven yarn.')
    add('tartan_crossed_bands', 'Crossed bands · the smaller rule', 'principles', 'Shaders · small comparison',
        'The existing tartan_pattern shader repeats a square domain with fract, adds horizontal and vertical bands, then overwrites selected regions with diagonal marks. Compare this short rule with the more elaborate crate shader.',
        'res://commons/resourses/shaders/tartan_pattern.gdshader', ['Shader library · review receiver'],
        'Rendered on a plain review quad. This receiver is not a new museum artifact; the shader is unchanged.')
    scene = 'res://commons/primitives/arrays/pattern_tile_puzzle.tscn'
    for token, title, motif, mode, caption, caution in [
        ('pattern_twill', 'Twill · a diagonal from counting', 'twill', 0,
         'The existing motif rule uses (x + y) % 4 < 2: two cells on, two off, shifted by a cell each row. The diagonal emerges from the rule. A strong bridge from the tile to the thread loom.',
         'This is a two-colour draft displayed by the tile editor, not a thread simulation.'),
        ('pattern_houndstooth', 'Houndstooth · a 4 × 4 source', 'houndstooth', 0,
         'A stored four-by-four motif repeats by address. This contrasts an explicit small bitmap with twill’s arithmetic rule while keeping the editor and palette the same.', ''),
        ('pattern_offset', 'Offset rows · change the arrangement', 'houndstooth', 6,
         'The same houndstooth source is sampled with alternate tile rows shifted by half a tile. Keep the source fixed and compare the larger result with the previous card.', ''),
        ('pattern_transpose', 'Alternating tiles · exchange x and y', 'houndstooth', 8,
         'The existing HERRINGBONE mode exchanges the source x and y addresses on alternating tiles. The same source reveals how a different sampling rule changes the field.',
         'The implementation transposes alternate square tiles. It does not construct an interlocking rectangular herringbone floor.'),
    ]:
        add(token, title, 'principles', 'Tiling · existing rule', caption, scene,
            ['Array_Patterns · configured review specimen'], caution,
            dict(motif=motif, dyelot='mono', tile_size=4, repeat_mode=mode))

    atlas = [
        ('atlas_kente', 'Kente study · strips within a field', 'Tiling',
         'Divide the field into strips, offset blocks within each strip, then select horizontal bars, vertical bars or rectangles per block.'),
        ('atlas_ikat', 'Ikat study · displaced rows', 'Shaders',
         'Repeated diamond masks use a horizontal offset chosen for each thin row. The sampling address produces the broken edge; the motif remains simple.'),
        ('atlas_bingata', 'Bingata study · offset flowers', 'Tiling',
         'Five circular petals form a motif. Alternate rows shift half a cell, while a hash selects each cell’s palette.'),
        ('atlas_kanga', 'Kanga study · border and centre', 'Tiling',
         'A conditional separates the border from the central field. Dots occupy the border; a radial motif occupies the centre.'),
        ('atlas_shibori', 'Shibori study · irregular rings', 'Shaders',
         'A radial sine makes repeated rings. A small angular perturbation breaks their regular contour before the colour threshold is applied.'),
        ('atlas_tiger', 'Tiger-rug study · bilateral stripes', 'Shaders',
         'Distance from a central axis mirrors each stripe. Row-dependent length and waviness vary the repeated marks.'),
        ('atlas_iznik', 'Iznik study · centre and corner symmetry', 'Tiling ↔ Shaders',
         'Polar coordinates make a central rosette. Absolute and folded coordinates repeat corner motifs around the tile.'),
        ('atlas_zellige', 'Zellige study · two squares make a star', 'Tiling ↔ Shaders',
         'Take the union of a square distance field and its rotated copy, then apply inset thresholds to make coloured borders and an inner star.'),
        ('atlas_meander', 'Meander · a repeated turning band', 'Tiling',
         'Horizontal bands contain repeated right-angle masks. Several simple coordinate intervals assemble one turning motif.'),
        ('atlas_albers', 'Albers study · diagonal choices', 'Tiling',
         'Each cell chooses one of two diagonal splits. Hashes select the colours of the resulting triangular regions.'),
        ('atlas_delaunay', 'Delaunay study · rings and half-turns', 'Shaders',
         'Distance from a cell centre selects a ring. The upper and lower halves alternate colour order, giving a family of split circular motifs.'),
        ('atlas_vasarely', 'Vasarely study · a bulging grid', 'Shaders',
         'A radial function changes the sampling coordinates before the checker is calculated. The plane stays flat; its apparent depth comes from the image.'),
        ('atlas_riley', 'Riley study · bend the stripe domain', 'Shaders',
         'A sine displacement, concentrated by a Gaussian envelope, bends the coordinates used to generate regular stripes.'),
        ('atlas2_wang', 'Wang study · shared edge addresses', 'Tiling · later bridge',
         'Each tile colours four triangular regions from hashes of its edge addresses. Neighbours use the same address at a shared edge, so their colours agree.'),
        ('atlas2_batik', 'Batik study · motif and crackle', 'Shaders',
         'Four rotated ellipse masks make a motif. A narrow band around a noise threshold adds crackle-like marks to selected regions.'),
        ('atlas2_kuba', 'Kuba / Shoowa study · local rule changes', 'Tiling',
         'A coarse grid chooses among four rules: diagonal bands, opposite diagonals, crosses or diamonds. Different local fields form one composition.'),
        ('atlas2_hitomezashi', 'Hitomezashi · one bit per row and column', 'Tiling · borrow first',
         'A bit chosen for each row and column offsets alternating horizontal and vertical dashes. Small binary decisions produce connected stitch-like paths across the field.'),
        ('atlas2_sami', 'Sámi-band study · nested bands', 'Tiling',
         'Nested horizontal thresholds frame repeated diamond outlines. The motif and its border are controlled separately.'),
        ('atlas2_adinkra', 'Adinkra study · choose a stamp', 'Tiling',
         'Each grid cell selects among three constructed marks: rings, a lattice or broken circular arcs. Border lines organise the resulting stamped field.'),
    ]
    for token, title, fit, caption in atlas:
        caution = 'A shader interpretation from the existing Pattern Atlas; not a reconstruction of the named craft or a verified reproduction of an artwork.'
        if token == 'atlas2_wang':
            caution = 'This directly assigns matching edge colours. It is not a constraint solver and does not demonstrate an aperiodic tile set.'
        add(token, title, 'atlas', fit, caption,
            'res://commons/artifacts/pattern_atlas_gallery/pattern_atlas_gallery.tscn',
            ['Symmetry_Seventeen · Pattern Atlas'], caution,
            {'focus_child': token})

    family = [
        ('mm_varma_backen', 'Varma Backen · a winding line',
         'A sinusoidal stem repeats in lanes. Small motifs alternate by row and lane; noise warps the sampling field over time.'),
        ('mm_fjader', 'Fjäder · a reflected motif',
         'A central quill, tapered boundary and repeated angled bars form a feather-like mark. Alternate cells reverse its direction.'),
        ('mm_bonan', 'Bönan · repeat and turn',
         'Subtract one ellipse-like mask from another to make a bean shape. Each cell gives it a different rotation; alternating rows are offset.'),
        ('mm_mahjong_rand', 'Mah-Jong Rand · a colour sequence',
         'A band index cycles through five colours. Small coordinate displacements disturb the edges while a fine stripe adds a surface rhythm.'),
        ('mm_rutan_oscillerar', 'Rutan Oscillerar · two checks disagree',
         'Two checker fields differ in animated scale and offset. Where their values disagree, the shader introduces colour. The effect comes from comparing two familiar rules.'),
        ('mm_moders_drom', 'Moders Dröm · rules share a surface',
         'A noise field assigns regions to stripes, oval marks or checks. Repeated domain warping changes how those regions and patterns meet.'),
    ]
    for token, title, caption in family:
        add(token, title, 'mamma', 'Tiling ↔ Shaders · personal lineage', caption,
            'res://commons/artifacts/mamma_monster_gallery/mamma_monster_gallery.tscn',
            ['Mamma Mönster · Exhibition_PressedFromNamedHands'],
            'Existing shader study with the project’s maker labels retained. This is not a scan of an original textile. Animation is represented by one captured frame.' +
            (' The shader combines procedural rules; it does not run an image-generation model.' if token == 'mm_moders_drom' else ''),
            {'focus_child': token})
    return result
