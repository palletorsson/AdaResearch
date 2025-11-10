# Scene Structure Requirements

This document outlines the node structure required for each enhanced physics script.

## NewtonsLaws_Enhanced.gd

**Scene:** `newtonslaws.tscn`

Required node structure:
```
NewtonsLawsEnhanced (Node3D)
├── Objects (Node3D)
├── ForceVectors (Node3D)
└── Ground (Node3D)
```

The script creates all balls, force arrows, trails, and UI elements programmatically.

## Constraints_Interactive.gd

**Scene:** `constraints.tscn`

Required node structure:
```
ConstraintsInteractive (Node3D)
└── Demonstrations (Node3D)
    ├── PendulumChain (Node3D)
    ├── RopeBridge (Node3D)
    ├── Ragdoll (Node3D)
    ├── SliderRails (Node3D)
    ├── SwingingDoors (Node3D)
    └── SpringDamper (Node3D)
```

The script creates all physics bodies, joints, and interactive elements programmatically.

## How to Set Up Scene Structures

1. Open the scene in Godot editor
2. Add the required Node3D containers as children of the root node
3. Attach the corresponding script to the root node
4. Save the scene

Example for NewtonsLaws_Enhanced:
1. Open `newtonslaws.tscn`
2. Right-click root node → Add Child Node → Node3D, name it "Objects"
3. Repeat for "ForceVectors" and "Ground"
4. Select root node → In Inspector panel → Script → Load → select NewtonsLaws_Enhanced.gd
5. File → Save Scene

Example for Constraints_Interactive:
1. Open `constraints.tscn`
2. Right-click root node → Add Child Node → Node3D, name it "Demonstrations"
3. Right-click "Demonstrations" → Add Child Node → Node3D, name it "PendulumChain"
4. Repeat for other demonstration types (RopeBridge, Ragdoll, SliderRails, SwingingDoors, SpringDamper)
5. Select root node → Attach Constraints_Interactive.gd script
6. File → Save Scene

## Testing

After setting up the scene structure:
1. Press F6 to run the current scene
2. Verify no errors appear in the console
3. Check that physics objects appear and interact correctly
4. In VR mode, test grabbing objects with controllers

## Troubleshooting

**"Invalid get index 'add_child' on base null instance"**
- This means a required node is missing from the scene structure
- Check the error message to see which node path failed (e.g., `$Objects`, `$Demonstrations/Ragdoll`)
- Add the missing node as described above

**"Node not found: Objects"**
- Ensure node names match exactly (case-sensitive)
- Nodes should be direct children of the root node (except Demonstrations children)
