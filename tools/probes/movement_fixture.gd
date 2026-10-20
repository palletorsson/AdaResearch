extends RefCounted
## Test/capture fixture only. Never installed in the visitor's teaching session.
static func coordinates(t:float, variation:int=0) -> Array:
	var u:=clampf(t/4.0,0,1)
	var x:Array=[-0.5+0.25*sin(TAU*u),-0.5+u*0.9,-0.4-0.35*sin(PI*u),0.5-0.20*sin(TAU*u),0.4-u*0.7,-0.65+0.25*cos(PI*u)]
	for i in 6: x[i]+=sin(t*2.0+i*3.0+variation*7.0)*0.012
	return x
static func take(variation:int=0, reverse:bool=false) -> Array:
	var result:Array=[]
	for i in 81:
		var t:=i*0.05
		result.append({"t":t,"x":coordinates(4.0-t if reverse else t,variation)})
	return result
