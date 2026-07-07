using Sandbox;
using System;
using System.Linq;

/// <summary>
/// The `t` utility from map_data.json. Proximity-based (no physics dependency):
/// when the player's head enters the pad column, flash and return the player to
/// spawn. In the full Ada curriculum this would advance to the next map in the
/// sequence ("action": "next_in_sequence") — a single test scene loops instead.
/// </summary>
public sealed class AdaTeleporter : Component
{
	public AdaMapBuilder Builder { get; set; }
	public float TriggerRadius { get; set; } = 24f;

	private ModelRenderer _renderer;
	private TimeSince _sinceTriggered = 10f;

	protected override void OnStart()
	{
		_renderer = Components.Get<ModelRenderer>();
	}

	protected override void OnUpdate()
	{
		// gentle pulse so the pad reads as "alive"
		if ( _renderer != null )
		{
			var pulse = 0.75f + 0.25f * MathF.Sin( Time.Now * 3f );
			_renderer.Tint = new Color( 0.2f * pulse, 0.9f * pulse, 0.4f * pulse );
		}

		if ( _sinceTriggered < 2f ) return;

		var camera = Scene.GetAllComponents<CameraComponent>().FirstOrDefault( c => c.IsMainCamera );
		if ( camera == null || Builder == null ) return;

		var head = camera.WorldPosition;
		var flatDistance = (head - WorldPosition).WithZ( 0 ).Length;
		var heightAbove = head.z - WorldPosition.z;

		if ( flatDistance < TriggerRadius && heightAbove > 0f && heightAbove < 2.5f * AdaMapBuilder.MetersToUnits )
		{
			_sinceTriggered = 0f;
			Log.Info( "AdaTeleporter: next_in_sequence → looping back to spawn (single test scene)" );

			var player = Scene.GetAllComponents<AdaVRPlayer>().FirstOrDefault()?.GameObject;
			if ( player != null )
				player.WorldPosition = Builder.SpawnPosition;
		}
	}
}
