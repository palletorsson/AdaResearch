extends SceneTree
const Record = preload("res://commons/artifacts/camera_glitch_study/saved_record.gd")
var checks:Array=[]
func check(label:String,ok:bool)->void:
	checks.append({"name":label,"passed":ok});print("RECORD ",label," ",ok)
func _initialize()->void:
	var data=Record.new();data.fixture()
	var bytes:PackedByteArray=data.bytes();var original:String=data.digest()
	check("fixture is 192 bytes",bytes.size()==192)
	check("first and last triplets known",bytes.slice(0,3)==PackedByteArray([0,0,0]) and bytes.slice(189)==PackedByteArray([255,0,255]))
	var unsigned:Dictionary=Record.decode(bytes,8,8,false)
	var signed_values:Dictionary=Record.decode(bytes,8,8,true)
	check("both declared readings accepted",unsigned.valid and signed_values.valid)
	for pair in [[0,0],[1,1],[63,63],[127,127],[128,-128],[192,-64],[254,-2],[255,-1]]:
		var at:int=[0,1,63,127,128,192,254,255].find(pair[0])*3
		check("unsigned byte "+str(pair[0]),unsigned.values[at]==pair[0])
		check("signed byte "+str(pair[0]),signed_values.values[at]==pair[1])
	var raw:Image=data.colour_image();var swapped:Image=data.colour_image(true)
	check("RGB receiver preserves exact bytes",raw.get_data()==bytes)
	var expected:=bytes.duplicate()
	for i in range(0,bytes.size(),3):expected[i]=bytes[i+2];expected[i+2]=bytes[i]
	check("BGR receiver permutes every triplet",swapped.get_data()==expected)
	var reversed=Record.new();reversed.load_bytes(swapped.get_data())
	check("same exchange reverses itself",reversed.colour_image(true).get_data()==bytes)
	var heights:PackedFloat32Array=data.heights(0,false,1)
	var signed_heights:PackedFloat32Array=data.heights(0,true,1)
	check("unsigned endpoints 0 and 1.2 metres",is_zero_approx(heights[0]) and is_equal_approx(heights[7],1.2))
	check("signed 128 crosses below zero",is_equal_approx(signed_heights[4],-1.2))
	check("signed 255 means minus one",is_equal_approx(signed_heights[7],-1.2/128))
	check("zero gain flattens every receiver value",all_zero(data.heights(2,true,0)))
	check("blue selects a different axis",is_zero_approx(data.heights(2,false,1)[7]) and is_equal_approx(data.heights(2,false,1)[56],1.2))
	check("bad width is explicit invalid result",not Record.decode(bytes,7,8).valid)
	check("truncated and negative layouts refused",not Record.decode(bytes.slice(0,191),8,8).valid and not Record.decode(bytes,-8,8).valid)
	check("invalid input retains previous record",not data.load_bytes(bytes.slice(0,2)) and data.digest()==original)
	var changed:=data.bytes();changed[0]=201
	check("returned bytes are not an alias",data.bytes()[0]==0 and data.digest()==original)
	var all_reads_unchanged:=data.digest()==original
	check("all interpretation operations preserve source",all_reads_unchanged)
	var input:=Image.create(16,16,false,Image.FORMAT_RGB8)
	for y in 16:
		for x in 16:input.set_pixel(x,y,Color(float(x)/15,float(y)/15,0))
	var capture=Record.new();check("image capture accepted",capture.capture(input))
	var sampled:=capture.bytes()
	check("cell centres sampled without averaging",sampled[0]==17 and sampled[1]==17 and sampled[189]==255 and sampled[190]==255)
	input.fill(Color.BLUE)
	check("camera changes do not change saved record",capture.bytes()==sampled)
	check("null capture retains record",not capture.capture(null) and capture.bytes()==sampled)
	var again=Record.new();again.fixture()
	check("fixture replays exactly",again.bytes()==bytes and again.digest()==original)
	var passed:=true
	for c in checks:passed=passed and c.passed
	var f:=FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE)
	f.store_string(JSON.stringify({"passed":passed,"checks":checks,"hash":original},"\t"));f.close();quit(0 if passed else 1)
func all_zero(values:PackedFloat32Array)->bool:
	if values.size()!=64:return false
	for value in values:
		if not is_zero_approx(value):return false
	return true
