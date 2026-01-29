# Maze Generator with Collision

This maze generator now includes full collision detection for walls, allowing for proper physics interactions and navigation.

## ✅ **Collision Features**

### **Wall Collision**
- **StaticBody3D** collision bodies for all walls
- **BoxShape3D** collision shapes matching wall dimensions
- **Dynamic collision management** - colliders are removed when walls become paths
- **Proper positioning** - colliders match visual wall positions exactly

### **Floor Navigation**
- **Floor collision** on all path cells for walkable surfaces
- **Thin collision bodies** (0.1 units high) for ground contact
- **Dynamic updates** - floor collision is added as walls become paths
- **Entrance/exit** also have floor collision for easy navigation

## 🔧 **How It Works**

### **Collision Creation**
```gdscript
# Wall collision (blocks movement)
func create_wall_collider(x: int, y: int) -> StaticBody3D:
    var static_body = StaticBody3D.new()
    var collision_shape = CollisionShape3D.new()
    var box_shape = BoxShape3D.new()
    box_shape.size = Vector3(cell_size, wall_height, cell_size)
    # ... setup and positioning

# Floor collision (walkable surface)
func create_floor_collider(x: int, y: int) -> StaticBody3D:
    var static_body = StaticBody3D.new()
    var collision_shape = CollisionShape3D.new()
    var box_shape = BoxShape3D.new()
    box_shape.size = Vector3(cell_size, 0.1, cell_size)  # Thin floor
    # ... setup and positioning
```

### **Dynamic Collision Management**
- Wall collision bodies are created for initial walls
- Floor collision bodies are created for initial paths
- Wall collision is removed when walls become paths during generation
- Floor collision is added when walls become paths during generation
- Entrance/exit points have floor collision for walkable navigation

### **Collision Arrays**
- `wall_colliders[y][x]` - Stores wall collision bodies for each cell
- `floor_colliders[y][x]` - Stores floor collision bodies for each cell
- `null` entries indicate no collision of that type
- `StaticBody3D` entries indicate solid collision bodies

## 🎮 **Usage**

### **Basic Testing**
1. Open `maze_test_collision.tscn`
2. Run the scene
3. Watch the maze generate with collision
4. Use arrow keys to move around and test collision

### **Debug Functions**
- **Space key**: Debug collision at current position
- **Escape key**: Show maze collision statistics

### **Integration**
```gdscript
# Check if position has wall collision
var is_wall = maze_generator.is_wall_at_position(world_position)

# Check if position has floor collision
var is_floor = maze_generator.is_floor_at_position(world_position)

# Get wall collision body at position
var wall_collider = maze_generator.get_wall_collider_at_position(world_position)

# Get floor collision body at position
var floor_collider = maze_generator.get_floor_collider_at_position(world_position)

# Get collision statistics
var info = maze_generator.debug_collision_info()
```

## 📊 **Debug Information**

### **Position Debug**
- Shows if current position is a wall or floor
- Shows if wall/floor collision bodies exist
- Displays collider names for identification

### **Maze Statistics**
- Total number of walls with collision
- Total number of floors with collision
- Maze dimensions and cell size
- Wall height configuration

## ⚙️ **Configuration**

### **Collision Settings**
- **Cell Size**: Controls collision box size
- **Wall Height**: Controls collision box height
- **Maze Dimensions**: Controls total collision area

### **Visual vs Collision**
- **Walls**: Visual mesh and wall collision body (blocks movement)
- **Paths**: Visual mesh and floor collision body (walkable surface)
- **Entrance/Exit**: Visual mesh and floor collision body (walkable surface)

## 🔍 **Technical Details**

### **Collision Body Structure**
```
# Wall Collision (blocks movement)
StaticBody3D (WallCollider_x_y)
└── CollisionShape3D
    └── BoxShape3D (cell_size × wall_height × cell_size)

# Floor Collision (walkable surface)
StaticBody3D (FloorCollider_x_y)
└── CollisionShape3D
    └── BoxShape3D (cell_size × 0.1 × cell_size)
```

### **Positioning**
- **Wall collision**: `(x * cell_size, wall_height/2, y * cell_size)`
- **Floor collision**: `(x * cell_size, 0.05, y * cell_size)`
- Matches visual positioning exactly
- Proper Y-axis positioning for collision detection

### **Memory Management**
- Wall collision bodies are freed when walls become paths
- Floor collision bodies are created when walls become paths
- `queue_free()` and `null` assignment for clean memory management
- No memory leaks from orphaned collision bodies

## 🚀 **Performance Notes**

- **Collision bodies**: One per cell (wall or floor)
- **Dynamic updates**: Wall collision removed, floor collision added during generation
- **Memory efficient**: Proper collision management for all cells
- **Physics ready**: Full physics interaction support with walkable floors

This implementation provides a solid foundation for maze-based games, navigation systems, and physics simulations with proper collision detection and walkable floors!
