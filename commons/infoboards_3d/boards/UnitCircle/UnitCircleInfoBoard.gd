# UnitCircleInfoBoard.gd
# Info board for Unit Circle and Trigonometric Waves
extends AlgorithmInfoBoardBase

# Preload visualization
const UnitCircleVis = preload("res://commons/infoboards_3d/boards/UnitCircle/UnitCircleVisualization.gd")

func initialize_content() -> void:
	"""Set up content pages for Unit Circle"""
	board_title = "Unit Circle & Waves"
	category_color = Color(0.5, 0.8, 0.9, 1.0)  # Cyan for wave functions

	page_content = [
		{
			"title": "The Unit Circle",
			"text": [
				"The unit circle is a circle with a radius of 1 centered at the origin (0,0)",
				"in the Cartesian coordinate system.",
				"",
				"It provides a geometric model that helps visualize trigonometric functions.",
				"",
				"KEY CONCEPT:",
				"Any point on the unit circle can be represented by the coordinates (cos θ, sin θ),",
				"where θ is the angle measured counterclockwise from the positive x-axis.",
				"",
				"This relationship is the foundation of trigonometry and is essential for",
				"understanding wave patterns, rotations, and periodic motion.",
				"",
				"GEOMETRIC PROPERTIES:",
				"• Radius: Always 1 (unit length)",
				"• Circumference: 2π ≈ 6.28 units",
				"• Any point (x, y) satisfies: x² + y² = 1",
				"• Angle θ measured in radians (360° = 2π radians)",
				"",
				"COORDINATES ON THE CIRCLE:",
				"For any angle θ:",
				"• x-coordinate = cos(θ)",
				"• y-coordinate = sin(θ)",
				"• Distance from origin = 1 (always)",
				"",
				"The visualization shows how a point moves around the unit circle",
				"as the angle θ changes, with projections showing sine and cosine values."
			],
			"visualization": "unit_circle"
		},
		{
			"title": "Sine Function",
			"text": [
				"The sine function (sin θ) represents the y-coordinate of a point",
				"on the unit circle at angle θ.",
				"",
				"DEFINITION:",
				"sin(θ) = opposite / hypotenuse (in a right triangle)",
				"sin(θ) = y-coordinate (on the unit circle)",
				"",
				"PROPERTIES:",
				"• Range: Always between -1 and 1",
				"• Period: Repeats every 2π radians (360°)",
				"• Starts at 0 when θ = 0",
				"• Maximum at θ = π/2 (90°) where sin(π/2) = 1",
				"• Minimum at θ = 3π/2 (270°) where sin(3π/2) = -1",
				"",
				"WAVE CHARACTERISTICS:",
				"When we plot sin(θ) against θ, we get a smooth, periodic wave pattern.",
				"This wave is fundamental to understanding many natural phenomena:",
				"• Sound waves and audio signals",
				"• Light and electromagnetic waves",
				"• Ocean tides and water waves",
				"• Alternating current in electricity",
				"• Pendulum motion",
				"",
				"SYMMETRY:",
				"Sine is an odd function: sin(-θ) = -sin(θ)",
				"This means the wave is symmetric about the origin.",
				"",
				"The visualization shows how the y-coordinate of the rotating point",
				"traces out the sine wave over time."
			],
			"visualization": "sine_wave"
		},
		{
			"title": "Cosine Function",
			"text": [
				"The cosine function (cos θ) represents the x-coordinate of a point",
				"on the unit circle at angle θ.",
				"",
				"DEFINITION:",
				"cos(θ) = adjacent / hypotenuse (in a right triangle)",
				"cos(θ) = x-coordinate (on the unit circle)",
				"",
				"PROPERTIES:",
				"• Range: Always between -1 and 1",
				"• Period: Repeats every 2π radians (360°)",
				"• Starts at 1 when θ = 0",
				"• Zero at θ = π/2 (90°) and θ = 3π/2 (270°)",
				"• Minimum at θ = π (180°) where cos(π) = -1",
				"",
				"RELATIONSHIP TO SINE:",
				"The cosine wave has the same shape as the sine wave,",
				"but is shifted by π/2 radians (90 degrees):",
				"",
				"cos(θ) = sin(θ + π/2)",
				"sin(θ) = cos(θ - π/2)",
				"",
				"This phase shift relationship is crucial for:",
				"• Understanding wave interactions",
				"• Signal processing",
				"• Phase analysis in physics",
				"• Fourier transforms",
				"",
				"SYMMETRY:",
				"Cosine is an even function: cos(-θ) = cos(θ)",
				"This means the wave is symmetric about the y-axis.",
				"",
				"The visualization shows how the x-coordinate traces the cosine wave."
			],
			"visualization": "cosine_wave"
		},
		{
			"title": "Tangent Function",
			"text": [
				"The tangent function (tan θ) is defined as the ratio of sine to cosine:",
				"",
				"tan(θ) = sin(θ) / cos(θ)",
				"",
				"GEOMETRIC MEANING:",
				"On the unit circle, tangent represents:",
				"• The slope of the line from the origin to the point",
				"• The length of the tangent line segment",
				"• The ratio of vertical to horizontal displacement",
				"",
				"PROPERTIES:",
				"• Range: From negative infinity to positive infinity (-∞ to +∞)",
				"• Period: Repeats every π radians (180°) - half that of sine/cosine!",
				"• Crosses zero at: 0, π, 2π, ... (multiples of π)",
				"",
				"UNDEFINED VALUES:",
				"Tangent is undefined when cos(θ) = 0:",
				"• At θ = π/2, 3π/2, 5π/2, ... (odd multiples of π/2)",
				"• These create vertical asymptotes in the graph",
				"• The function approaches ±∞ near these points",
				"",
				"WHY TANGENT IS DIFFERENT:",
				"Unlike sine and cosine, tangent:",
				"• Is not bounded (can be any value)",
				"• Has vertical asymptotes (discontinuities)",
				"• Has a shorter period (π instead of 2π)",
				"• Increases monotonically between asymptotes",
				"",
				"APPLICATIONS:",
				"• Calculating slopes and angles",
				"• Navigation and surveying",
				"• Optics and refraction",
				"• Engineering stress analysis"
			],
			"visualization": "tangent_wave"
		},
		{
			"title": "Wave Combinations & Fourier Analysis",
			"text": [
				"Complex wave patterns can be created by combining",
				"sine and cosine waves with different properties.",
				"",
				"WAVE PARAMETERS:",
				"• Amplitude: Controls the height/intensity of the wave",
				"  Example: 2·sin(θ) has twice the height of sin(θ)",
				"",
				"• Frequency: Controls how many cycles occur",
				"  Example: sin(2θ) completes cycles twice as fast",
				"",
				"• Phase: Controls the horizontal shift",
				"  Example: sin(θ + π/2) starts shifted by 90°",
				"",
				"FOURIER'S THEOREM:",
				"Any periodic waveform can be represented as a sum of",
				"sine and cosine waves (Fourier series).",
				"",
				"f(θ) = a₀ + a₁·sin(θ) + a₂·sin(2θ) + a₃·sin(3θ) + ...",
				"          + b₁·cos(θ) + b₂·cos(2θ) + b₃·cos(3θ) + ...",
				"",
				"PRACTICAL APPLICATIONS:",
				"• Sound synthesis - musical instruments",
				"• Audio compression (MP3, AAC)",
				"• Image processing (JPEG compression)",
				"• Signal analysis and filtering",
				"• Solving differential equations",
				"• Quantum mechanics",
				"",
				"WAVE INTERFERENCE:",
				"When waves combine:",
				"• Constructive interference: waves align, amplitude increases",
				"• Destructive interference: waves cancel, amplitude decreases",
				"• Beats: periodic amplitude variations from close frequencies",
				"",
				"The visualization shows multiple waves combining to create",
				"complex patterns - the foundation of all wave phenomena!"
			],
			"visualization": "combined_waves"
		}
	]

func create_visualization(vis_type: String) -> Control:
	"""Create appropriate visualization for the given type"""
	var vis = Control.new()
	vis.set_script(UnitCircleVis)
	vis.visualization_type = vis_type
	vis.custom_minimum_size = Vector2(400, 400)
	return vis
