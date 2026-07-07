using Sandbox;
using System;
using System.Linq;
using System.Text.Json.Nodes;

/// <summary>
/// Rebuilds an Ada Research map (map_data.json, 3 layers: structure / utilities /
/// interactables) as an s&box scene at runtime.
///
/// Coordinate mapping — Ada/Godot is Y-up, metres, grid row = +Z south:
///   grid col  -> s&box +X
///   grid row  -> s&box -Y
///   height    -> s&box +Z (Source 2 is Z-up, world units are inches)
/// </summary>
public sealed class AdaMapBuilder : Component
{
	/// <summary>Path inside Assets/ to an Ada map_data.json. Falls back to the embedded Tutorial_Start.</summary>
	[Property] public string MapFile { get; set; } = "maps/tutorial_start.map_data.json";

	/// <summary>1 Ada grid cell = 1 metre. s&box world units are inches.</summary>
	public const float MetersToUnits = 39.3701f;

	public Vector3 SpawnPosition { get; private set; }

	private Model _box;
	private Vector3 _boxSize;
	private float _cellSize = MetersToUnits;
	private float[,] _heights;

	protected override void OnStart()
	{
		_box = Model.Load( "models/dev/box.vmdl" );
		_boxSize = _box?.Bounds.Size ?? new Vector3( 50f );
		if ( _boxSize.x < 0.01f ) _boxSize = new Vector3( 50f );

		string json = null;
		try { json = FileSystem.Mounted.ReadAllText( MapFile ); }
		catch ( Exception ) { /* fall through to embedded copy */ }

		if ( string.IsNullOrWhiteSpace( json ) )
		{
			Log.Warning( $"AdaMapBuilder: could not read '{MapFile}', using embedded Tutorial_Start" );
			json = AdaMapData.TutorialStart;
		}

		var root = JsonNode.Parse( json );

		var cubeSize = root?["settings"]?["cube_size"]?.GetValue<float>() ?? 1.0f;
		_cellSize = cubeSize * MetersToUnits;

		BuildStructure( root );
		BuildLighting( root );
		BuildUtilities( root );
		BuildInteractables( root );
		PlacePlayer();

		Log.Info( $"AdaMapBuilder: built '{root?["map_info"]?["name"]}' — spawn at {SpawnPosition}" );
	}

	private Vector3 CellCenter( int row, int col, float z )
		=> new( (col + 0.5f) * _cellSize, -(row + 0.5f) * _cellSize, z );

	private void BuildStructure( JsonNode root )
	{
		var rows = root?["layers"]?["structure"]?.AsArray();
		if ( rows == null ) return;

		_heights = new float[rows.Count, rows.Max( r => r.AsArray().Count )];

		for ( int row = 0; row < rows.Count; row++ )
		{
			var cols = rows[row].AsArray();
			for ( int col = 0; col < cols.Count; col++ )
			{
				if ( !float.TryParse( cols[col]?.GetValue<string>(), out var h ) || h <= 0f )
					continue;

				_heights[row, col] = h;

				var go = new GameObject( true, $"floor_{row}_{col}" );
				go.Parent = GameObject;
				go.WorldPosition = CellCenter( row, col, h * _cellSize * 0.5f );
				go.WorldScale = new Vector3(
					_cellSize / _boxSize.x,
					_cellSize / _boxSize.y,
					h * _cellSize / _boxSize.z );

				var renderer = go.Components.Create<ModelRenderer>();
				renderer.Model = _box;
				// checkerboard greys, taller columns slightly darker — the grid IS the aesthetic (seqs 1-6)
				var shade = ((row + col) % 2 == 0 ? 0.55f : 0.45f) - (h - 1f) * 0.08f;
				renderer.Tint = new Color( shade, shade, shade * 1.05f );

				var collider = go.Components.Create<ModelCollider>();
				collider.Model = _box;
				collider.Static = true;
			}
		}
	}

	private void BuildLighting( JsonNode root )
	{
		var lighting = root?["lighting"];

		var go = new GameObject( true, "sun" );
		go.Parent = GameObject;

		var dirNode = lighting?["directional_light"]?["direction"]?.AsArray();
		// Godot (x, y-up, z) -> s&box (x, -z, y-up)
		var dir = dirNode is { Count: 3 }
			? new Vector3( dirNode[0].GetValue<float>(), -dirNode[2].GetValue<float>(), dirNode[1].GetValue<float>() )
			: new Vector3( -0.2f, 0.1f, -0.8f );
		go.WorldRotation = Rotation.LookAt( dir.Normal );

		var light = go.Components.Create<DirectionalLight>();
		var colNode = lighting?["directional_light"]?["color"]?.AsArray();
		var energy = lighting?["directional_light"]?["energy"]?.GetValue<float>() ?? 1.0f;
		light.LightColor = (colNode is { Count: 3 }
			? new Color( colNode[0].GetValue<float>(), colNode[1].GetValue<float>(), colNode[2].GetValue<float>() )
			: Color.White) * energy;
		light.Shadows = true;
	}

	private void BuildUtilities( JsonNode root )
	{
		var rows = root?["layers"]?["utilities"]?.AsArray();
		if ( rows == null ) return;

		for ( int row = 0; row < rows.Count; row++ )
		{
			var cols = rows[row].AsArray();
			for ( int col = 0; col < cols.Count; col++ )
			{
				var code = cols[col]?.GetValue<string>()?.Trim();
				if ( string.IsNullOrEmpty( code ) ) continue;

				var floorTop = FloorTop( row, col );
				var key = code.Split( ':' )[0];

				if ( key == "s" || key == "sp" )
				{
					SpawnPosition = CellCenter( row, col, floorTop + 1f );
					MakePad( row, col, floorTop, new Color( 0.3f, 0.5f, 0.9f ), "spawn_pad" );
				}
				else if ( key == "t" )
				{
					var pad = MakePad( row, col, floorTop, new Color( 0.2f, 0.9f, 0.4f ), "teleporter" );
					var tp = pad.Components.Create<AdaTeleporter>();
					tp.Builder = this;
					tp.TriggerRadius = _cellSize * 0.6f;
				}
				else
				{
					Log.Info( $"AdaMapBuilder: utility '{code}' at ({row},{col}) not implemented in this test scene" );
				}
			}
		}
	}

	private void BuildInteractables( JsonNode root )
	{
		var rows = root?["layers"]?["interactables"]?.AsArray();
		if ( rows == null ) return;

		for ( int row = 0; row < rows.Count; row++ )
		{
			var cols = rows[row].AsArray();
			for ( int col = 0; col < cols.Count; col++ )
			{
				var name = cols[col]?.GetValue<string>()?.Trim();
				if ( string.IsNullOrEmpty( name ) ) continue;

				// artifact token may carry :rotation:y_offset suffixes
				var token = name.Split( ':' )[0];
				var floorTop = FloorTop( row, col );

				var go = new GameObject( true, token );
				go.Parent = GameObject;
				var size = 0.5f * MetersToUnits;
				go.WorldPosition = CellCenter( row, col, floorTop + 0.8f * MetersToUnits );
				go.WorldScale = new Vector3( size / _boxSize.x, size / _boxSize.y, size / _boxSize.z );

				var renderer = go.Components.Create<ModelRenderer>();
				renderer.Model = _box;

				var cube = go.Components.Create<AdaAnimatedCube>();
				var rotates = token.Contains( "rotat" );
				var oscillates = token.Contains( "oscillation" );
				if ( rotates && oscillates ) cube.Mode = AdaAnimatedCube.MotionMode.Both;
				else if ( rotates ) cube.Mode = AdaAnimatedCube.MotionMode.Rotate;
				else if ( oscillates ) cube.Mode = AdaAnimatedCube.MotionMode.Oscillate;
				else
				{
					cube.Mode = AdaAnimatedCube.MotionMode.Placeholder;
					Log.Info( $"AdaMapBuilder: artifact '{token}' has no s&box port yet — magenta placeholder" );
				}

				renderer.Tint = cube.Mode switch
				{
					AdaAnimatedCube.MotionMode.Rotate => new Color( 0.9f, 0.6f, 0.2f ),
					AdaAnimatedCube.MotionMode.Oscillate => new Color( 0.3f, 0.7f, 0.9f ),
					AdaAnimatedCube.MotionMode.Both => new Color( 0.8f, 0.4f, 0.9f ),
					_ => Color.Magenta
				};
			}
		}
	}

	private GameObject MakePad( int row, int col, float floorTop, Color tint, string name )
	{
		var go = new GameObject( true, name );
		go.Parent = GameObject;
		var thickness = 0.05f * MetersToUnits;
		go.WorldPosition = CellCenter( row, col, floorTop + thickness * 0.5f );
		go.WorldScale = new Vector3(
			_cellSize * 0.9f / _boxSize.x,
			_cellSize * 0.9f / _boxSize.y,
			thickness / _boxSize.z );

		var renderer = go.Components.Create<ModelRenderer>();
		renderer.Model = _box;
		renderer.Tint = tint;
		return go;
	}

	private float FloorTop( int row, int col )
	{
		if ( _heights == null ) return 0f;
		if ( row < 0 || col < 0 || row >= _heights.GetLength( 0 ) || col >= _heights.GetLength( 1 ) ) return 0f;
		return _heights[row, col] * _cellSize;
	}

	private void PlacePlayer()
	{
		if ( SpawnPosition == Vector3.Zero )
			SpawnPosition = CellCenter( 0, 0, FloorTop( 0, 0 ) + 1f );

		var anchor = Scene.GetAllComponents<Sandbox.VR.VRAnchor>().FirstOrDefault();
		var player = anchor?.GameObject ?? Scene.GetAllComponents<AdaVRPlayer>().FirstOrDefault()?.GameObject;
		if ( player != null )
			player.WorldPosition = SpawnPosition;
	}
}
