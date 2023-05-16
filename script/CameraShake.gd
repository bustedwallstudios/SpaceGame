extends Camera2D

@export var decay = 0.8  # How quickly the shaking stops [0, 1].
@export var max_offset = Vector2(100, 75)  # Maximum hor/ver shake in pixels.
@export var max_roll = 0.1  # Maximum rotation in radians (use sparingly).

@onready var noise = FastNoiseLite.new()
var noise_y = 0

var trauma:float = 0  # Current shake strength.
var trauma_power = 2  # Trauma exponent. Use [2, 3].
	
func _ready():
	randomize()
	noise.seed = randi()
	noise.noise_type = 3
	noise.frequency = 4
	noise.fractal_octaves = 2

func addTrauma(amount:float):
	# Add trauma to the shaking, but limit it to 1.
	trauma = min(trauma + amount, 1.0)

func _process(delta):
	if trauma:
		trauma = max(trauma - decay * delta, 0)
		shake()

func shake():
	var amount = pow(trauma, trauma_power)
	noise_y += 1
	print(noise.get_noise_2d(noise.seed, noise_y))
	rotation = max_roll * amount * noise.get_noise_2d(noise.seed, noise_y)
	offset.x = max_offset.x * amount * noise.get_noise_2d(noise.seed*2, noise_y)
	offset.y = max_offset.y * amount * noise.get_noise_2d(noise.seed*3, noise_y)
