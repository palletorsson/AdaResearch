extends RefCounted
## Deliberate mappings, not hardware faults. Coordinates are metres; UV is 0..1.
const TITLES := ["01 / PULL THE SCANLINES","02 / BRIGHTNESS BECOMES RELIEF","03 / THREE COLOUR PLANES","04 / FOLD THE IMAGE","05 / CURL THE VIEW","06 / SHUFFLE THE ADDRESSES","07 / A STRIP STAYS BEHIND","08 / ROWS LOSE ALIGNMENT","09 / LET DARK PIXELS GO","10 / WRAP THE ROOM"]
const NOTES := ["Sixteen strips shift sideways and leave the image plane.","Sampled brightness changes vertex height; this is not camera depth.","Red, green and blue are read separately on three additive planes.","One continuous image folds along eight vertical creases.","The image bends into a curved surface; its UV addresses stay attached.","Twenty-four tiles exchange source addresses through a fixed permutation.","Alternate bands read a held frame while the others remain live.","Each row adds a different horizontal UV offset and wraps at the edge.","A luminance threshold discards pixels; the receiver has no collider.","A rectangle closes around a torus; its opposite image edges meet."]
const WIDTH := 3.2
const HEIGHT := 1.8

func location(mode: int,uv: Vector2,amount: float,tile:=0) -> Vector3:
	var x: float=(uv.x-.5)*WIDTH
	var y: float=(.5-uv.y)*HEIGHT
	match mode:
		0: return Vector3(x+amount*.45*sin(tile*2.7),y,amount*.35*cos(tile*1.6))
		3: return Vector3(x*(1-.3*amount),y,amount*.38*absf(sin(uv.x*8*PI)))
		4:
			var k:=amount*1.3
			if k<.0001:return Vector3(x,y,0)
			return Vector3(sin(x*k)/k,y,(1-cos(x*k))/k)
		5: return Vector3(x,y,amount*.10*(tile%4))
		6: return Vector3(x,y,amount*.24*(tile%2))
		9:
			var u:=uv.x*TAU;var v:=uv.y*TAU
			var torus:=Vector3((.95+.32*cos(v))*sin(u),.32*sin(v),(.95+.32*cos(v))*cos(u))
			return Vector3(x,y,0).lerp(torus,amount)
	return Vector3(x,y,0)

func source_uv(mode: int,uv: Vector2,amount: float,tile: int) -> Vector2:
	if mode!=5:return uv
	var col:=tile%6;var row:=floori(float(tile)/6.0)
	var target: int=(tile*7+5)%24
	var mapped:=uv+Vector2((target%6-col)/6.0,(floori(float(target)/6.0)-row)/4.0)
	return uv.lerp(mapped,amount)

func build(mode: int,amount: float) -> ArrayMesh:
	amount=clampf(amount,0,1)
	var cols:=64;var rows:=36
	if mode==0 or mode==6:cols=1;rows=16
	if mode==5:cols=6;rows=4
	if mode==2:cols=1;rows=1
	var vertices:=PackedVector3Array();var uvs:=PackedVector2Array();var normals:=PackedVector3Array()
	for row in rows:
		for col in cols:
			var tile:int=row*cols+col
			var corners: Array[Vector2]=[Vector2(float(col)/cols,float(row)/rows),Vector2(float(col+1)/cols,float(row)/rows),Vector2(float(col+1)/cols,float(row+1)/rows),Vector2(float(col)/cols,float(row+1)/rows)]
			for corner in [0,1,2,0,2,3]:
				var uv:=corners[corner]
				vertices.append(location(mode,uv,amount,tile));uvs.append(source_uv(mode,uv,amount,tile));normals.append(Vector3.BACK)
	var arrays:=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_TEX_UV]=uvs;arrays[Mesh.ARRAY_NORMAL]=normals
	var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);return mesh
