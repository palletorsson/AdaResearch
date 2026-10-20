extends Node
## Each pass reads an immutable previous texture. The next group is scheduled
## only after frame_post_draw. No readback or CPU chemistry in the live path.
signal changed
const SIZE := 96
const PASSES := 8
const STEP = preload("./field_step.gdshader")
var views: Array[SubViewport] = []
var materials: Array[ShaderMaterial] = []
var state_texture: Texture2D
var initial_texture: ImageTexture
var running := false
var busy := false
var iterations := 0
var feed := .055
var kill := .062
var pending_steps := 0
var pending_reset := -1
var brush_queue: Array[Vector2] = []
var _group := 0
var _last := 0
var _count := 0
var _integrating := false
var _budget := 0.0

func _ready()->void:
    for i in range(PASSES*2):
        var view:=SubViewport.new();view.name="State_%02d"%i
        view.size=Vector2i(SIZE,SIZE);view.disable_3d=true;view.use_hdr_2d=false
        view.render_target_update_mode=SubViewport.UPDATE_DISABLED;add_child(view)
        var rect:=ColorRect.new();rect.size=Vector2(SIZE,SIZE)
        var mat:=ShaderMaterial.new();mat.shader=STEP;rect.material=mat;view.add_child(rect)
        views.append(view);materials.append(mat)
    RenderingServer.frame_post_draw.connect(_completed)
    _reset_now(true)

static func encode(a:float,b:float)->Color:
    var u:=roundi(clampf(a,0,1)*4095);var v:=roundi(clampf(b,0,1)*4095)
    return Color(float(u/16)/255.0,float(v/16)/255.0,float((u%16)*16+v%16)/255.0,1)

static func decode(c:Color)->Vector2:
    var packed:=roundi(c.b*255)
    return Vector2(roundi(c.r*255)*16+packed/16,roundi(c.g*255)*16+packed%16)/4095.0

func reset(seeded:bool=true)->void:
    running=false;pending_steps=0;brush_queue.clear();_budget=0
    if busy:pending_reset=int(seeded)
    else:_reset_now(seeded)

func _reset_now(seeded:bool)->void:
    var image:=Image.create(SIZE,SIZE,false,Image.FORMAT_RGB8);image.fill(encode(1,0))
    if seeded:
        for at in [Vector2(.32,.35),Vector2(.52,.49),Vector2(.67,.66)]:
            for y in range(SIZE):
                for x in range(SIZE):
                    if Vector2((x+.5)/SIZE,(y+.5)/SIZE).distance_to(at)<.055:image.set_pixel(x,y,encode(.5,1))
    initial_texture=ImageTexture.create_from_image(image);state_texture=initial_texture
    for mat in materials:mat.set_shader_parameter("previous_state",initial_texture)
    iterations=0;pending_reset=-1;changed.emit()

func mark(uv:Vector2)->void:
    if uv.x<0 or uv.y<0 or uv.x>1 or uv.y>1:return
    if brush_queue.size()<32:brush_queue.append(uv)

func step(count:int=1)->void:
    running=false;pending_steps+=clampi(count,1,20000)

func _process(delta:float)->void:
    if busy:return
    if pending_reset>=0:_reset_now(pending_reset==1)
    var count:=0
    if pending_steps>0:count=mini(PASSES,pending_steps);pending_steps-=count
    elif running:
        _budget=minf(_budget+delta*240.0,PASSES)
        count=int(_budget);_budget-=count
    if count==0 and brush_queue.is_empty():return
    _schedule(maxi(1,count),count>0)

func _schedule(count:int,integrating:bool)->void:
    busy=true;_count=count;_integrating=integrating
    # Break old dependencies: disabled targets keep their completed pixels.
    for mat in materials:mat.set_shader_parameter("previous_state",initial_texture)
    var source:Texture2D=initial_texture
    for i in range(count):
        var slot:=_group*PASSES+i;var mat:=materials[slot]
        mat.set_shader_parameter("previous_state",source)
        mat.set_shader_parameter("feed",feed);mat.set_shader_parameter("kill",kill)
        mat.set_shader_parameter("integrate",integrating)
        mat.set_shader_parameter("brush",brush_queue.pop_front() if not brush_queue.is_empty() else Vector2(-10,-10))
        views[slot].render_target_update_mode=SubViewport.UPDATE_ONCE
        source=views[slot].get_texture();_last=slot

func _completed()->void:
    if not busy:return
    state_texture=views[_last].get_texture()
    if _integrating:iterations+=_count
    _group=1-_group;busy=false;changed.emit()

func _exit_tree()->void:
    if RenderingServer.frame_post_draw.is_connected(_completed):RenderingServer.frame_post_draw.disconnect(_completed)
