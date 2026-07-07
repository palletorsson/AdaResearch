/// <summary>
/// Embedded copy of commons/maps/Tutorial_Start/map_data.json — the fallback
/// when Assets/maps/*.json can't be read, so the scene always builds.
/// </summary>
public static class AdaMapData
{
	public const string TutorialStart = """
	{
	  "map_info": {
	    "name": "Tutorial_Start",
	    "description": "The absolute beginning - just one cube and an exit. Learn to exist in VR space.",
	    "dimensions": { "width": 3, "depth": 3, "max_height": 1 }
	  },
	  "lighting": {
	    "ambient_color": [0.4,0.4,0.5],
	    "ambient_energy": 0.8,
	    "directional_light": {
	      "enabled": true,
	      "direction": [-0.2,-0.8,-0.1],
	      "color": [1.0,1.0,1.0],
	      "energy": 1.2
	    }
	  },
	  "settings": {
	    "cube_size": 1.0,
	    "background": { "type": "sky", "color": [0.2,0.3,0.5] }
	  },
	  "layers": {
	    "structure": [
	      ["1","1","2"],
	      ["2","1","2"],
	      ["2","0","2"]
	    ],
	    "utilities": [
	      ["s"," "," "],
	      [" "," "," "],
	      [" ","t"," "]
	    ],
	    "interactables": [
	      [" "," "," "],
	      [" "," "," "],
	      ["rotating_cube","oscillation_cube","rotation_oscillation_cube"]
	    ]
	  }
	}
	""";
}
