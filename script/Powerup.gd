extends Node2D

const type = "Powerup"

# The type of powerup that it is.
# 0 is rapidfire
var powerupType = 0

var screenSize = GlobalLoad.screenSize

var t = 0 # The time passed. This is used in a sine function for visual effect

var drag = 0.015

# Set to true after 7 seconds, and then the powerup will flicker until it disappears
var shouldFlicker = false

# Set this so that I can change the scale of the icon at will, and it will
# automatically be the right numbers in the code.
@onready var originalScale  = $ShapePieces.scale.x

var vel = Vector2.ZERO

func _ready():
	vel = Vector2(3, 0) # Initialize the velocity pointing in a certain direction
	
	# Then, randomize the direction, but maintain a consistent intial velocity
	vel = vel.rotated(randf_range(0, 2*PI))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	t += delta*5
	
	# Sine the scale of the icon, so that it bobs in and out a little bit for visual effect
	var scaleSin  = originalScale + sin(t)/5
	var scaleSin2 = originalScale + sin(t*2)/5 # This one is twice as fast
	$ShapePieces.scale = Vector2(scaleSin, scaleSin)
	$ShapePieces/OutlineShape.scale = Vector2(scaleSin2, scaleSin2)
	
	self.position += vel
	vel *= 1-drag
	
	# If 7 seconds have elapsed, then begin to waver
	if shouldFlicker:
		$ShapePieces.modulate.a = ((sin(t*2) + 1) / 2) / 2 + 0.5
	
	screenWrap()

# When the player collects the powerup
func collected():
	disableCollision()
	$ShapePieces.hide()
	
	$CollectParticles.emitting = true
	
	$CollectAudio.play()
	
	# Stop the despawn timer, otherwise it will still play the despawn particles
	# if it has time to.
	$DespawnTimer.stop()
	
	# Wait 2 seconds for the particles to finish
	await get_tree().create_timer(2).timeout
	
	self.queue_free()

func screenWrap():
	# If the powerup has exceeded the screen bounds on the X, put it on the other side.
	if self.position.x  > screenSize.x:
		self.position.x = 0
	if self.position.x  < 0:
		self.position.x = screenSize.x
	
	# Same for the y.
	if self.position.y  > screenSize.y:
		self.position.y = 0
	if self.position.y  < 0:
		self.position.y = screenSize.y

func flicker():
	shouldFlicker = true

# When the time runs out
func despawn():
	disableCollision() # FIX THE BUG WHERE SOMETIMES THIS SAYS "CANNOT CALL METHOD ON A NULL VALUE"!!!!!!!!!!!!!!!
	
	$ShapePieces.hide()
	
	$DespawnParticles.emitting = true
	
	# Wait 2 seconds for the particles to finish
	await get_tree().create_timer(2).timeout
	
	self.queue_free()

func collision(area):
	if area.get_parent().name.count("Player") > 0:
		collected()

func disableCollision():
	$CollisionArea.set_deferred("monitorable", false)
	$CollisionArea.set_deferred("monitoring", false)
