extends RefCounted
## THE ACTIVITY IN THE SLOT (Palle, 2026-10-31: "in these slots we want to select specific artifacts and groups of
## artifacts; make the artifact parameterised and make them slot into the playground nicely"). A recipe's `activities`
## (place_builder.gd, from place.json "activity") name a registry artifact and a config carrying the slot - its floor
## footprint, its depth, the floor and rim heights. build() makes the artifact's scene with the config left as
## config_* metas (read in _ready) and stands it on the pool floor; fit() applies the config once it is in the tree.
## A surface that knows the slot (commons/context/walkgrids/TopologySpace.gd) fits and edge-secures itself.
const Items=preload("res://commons/player/inventory_items.gd")

static func build(item:Dictionary)->Node3D:
	var token:=str(item.get("artifact",""));var path:=Items.scene_for(token)
	if path=="" or not ResourceLoader.exists(path):push_warning("place_activity: no scene for artifact '%s'"%token);return null
	var node:Node=load(path).instantiate()
	if not node is Node3D:node.free();return null
	var cfg:Dictionary=item.get("config",{})
	for k in cfg:node.set_meta("config_%s"%str(k),cfg[k])
	node.name=str(item.get("id","activity"))
	var at:Array=item.get("position",[0,0,0]);(node as Node3D).position=Vector3(float(at[0]),float(at[1]),float(at[2]))
	node.set_meta("activity_artifact",token)
	return node

static func fit(node:Node3D,item:Dictionary)->void:
	if node!=null and node.has_method("apply_grid_config"):node.apply_grid_config(item.get("config",{}))
