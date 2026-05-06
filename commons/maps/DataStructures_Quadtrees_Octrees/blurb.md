Four quadrants. Void boundaries mark the divisions — a cross cut through the center of the room, splitting space into equal quarters. Some quadrants are dense with platforms. Others are nearly empty. The subdivision is uniform, but the contents are not.

A quadtree divides 2D space into four equal regions. If a region contains too many objects, subdivide it into four more. Empty regions stay as single large cells. Dense regions split recursively until each leaf holds a manageable count. Octrees extend this to 3D — eight children instead of four. The structure adapts its resolution to the data.

Adaptive spatial triage. The quadtree does not treat all space equally — it allocates detail where detail exists and ignores the rest. The same total area, but the structure's attention is unevenly distributed. Resolution is not a property of the space. It is a response to what the space contains.
