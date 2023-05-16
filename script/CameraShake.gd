extends Camera2D

@export var decay = 0.1  # How quickly the shaking stops [0, 1].
@export var max_offset = Vector2(100, 75)  # Maximum hor/ver shake in pixels.
@export var max_roll = 0.1  # Maximum rotation in radians (use sparingly).

@onready var noise = FastNoiseLite.new()
var noise_y = 0

var trauma:float = 0  # Current shake strength.
var trauma_power = 2  # Trauma exponent. Use [2, 3].

var violence:float = 5

var max = 0.25

func _ready():
	randomize()
	noise.seed = randi()

func addTrauma(amount:float, shakeAmount=5):
	# Add trauma to the shaking, but limit it to 1.
	trauma = min(trauma + amount, 1.0)
	violence = shakeAmount

func _process(delta):
	if trauma:
		# Each frame, if there is trauma, decrease it by the decay amount,
		# and don't let it fall below 0.
		trauma = max(trauma - decay * delta, 0)
		shake()

func shake():
	var amount = pow(trauma, trauma_power)
	
	if amount > max:
		amount = max
	
	# Change the position that the camera is at. The more it is changed per frame,
	# the more violent the shaking will feel.
	noise_y += violence
	
	# The numbers here mean nothing, they're just supposed to be significantly different
	rotation = max_roll * amount * noise.get_noise_2d(-100, noise_y)
	offset.x = max_offset.x * amount * noise.get_noise_2d(0, noise_y)
	offset.y = max_offset.y * amount * noise.get_noise_2d(100, noise_y)
