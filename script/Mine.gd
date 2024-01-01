extends Node2D

var screenSize = GlobalLoad.screenSize

# The distance OUTSIDE the screen that each meteor will spawn, so they cannot
# be seen spawning in
var graceDist = 60 # 50px is the mine radius

var vel:Vector2 = Vector2.ZERO
var angularVel:float

var drag = 0.025

var dimColor:Color    = Color("600000")
var brightColor:Color = Color("ce0000")
var lightIsOn:bool    = false

# This is used whenever something comes in contact with the mine. If it has
# detonated, then it must be contacting the explosion area, and if not, then
# it is merely contacting the mine itself.
var hasDetonated = false

# Set to true if the player shoots it, in order to determine whether they get points
# for its destruction
var playerDestroyed = false

# Called when the node enters the scene tree for the first time.
func _ready():
	self.position = getStartPos()
	
	# The starting velocity will be pointing roughly towards the center of the
	# screen, with a magnitude of 10-20.
	vel = getStartDirection(self.position) * randf_range(10, 22)
	
	angularVel = randf_range(-30, 30)

func getStartPos() -> Vector2:
	# Define the meteor's starting position
	var edge = randi() % 4  # 0 = top, 1 = right, 2 = bottom, 3 = left
	var edgeX = 0
	var edgeY = 0
	
	var intX = int(screenSize.x)
	var intY = int(screenSize.y)
	
	# The top of the screen
	if edge == 0:
		edgeX = randi() % intX
		edgeY = -graceDist
	
	# The right side of the screen
	elif edge == 1:
		edgeX = intX + graceDist
		edgeY = randi() % intY
	
	# The bottom of the screen
	elif edge == 2:
		edgeX = randi() % intX
		edgeY = intY + graceDist
	
	# The left side of the screen
	else:
		edgeX = -graceDist
		edgeY = randi() % intY

	var initialPos:Vector2 = Vector2(edgeX, edgeY)
	
	return initialPos

# Returns a Vector2 with X and Y components for movement, normalized.
func getStartDirection(pos:Vector2) -> Vector2:
	
	# The angle from the meteor to the center of the screen
	var angle = pos.angle_to_point(screenSize / 2)
	
	# Randomly adjust it by 1/20 of a circle
	var angleRandom = randf() * TAU/20
	
	# The final direction that the meteor will move in each frame (length 1)
	var direction:Vector2 = Vector2(cos(angle+angleRandom), sin(angle+angleRandom))
	
	return direction

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.position         += vel
	self.rotation_degrees += angularVel
	
	vel        *= 1-drag
	angularVel *= 1-drag
	
	screenWrap()

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

func flash():
	lightIsOn = !lightIsOn
	
	# If the flashes are coming really quickly, then keep the light on.
	if $FlashTimer.wait_time < 0.08:
		lightIsOn = true
	
	if lightIsOn: $Shape/BlinkingLight.color = brightColor
	else:         $Shape/BlinkingLight.color = dimColor
	
	$BeepAudio.play()
	
	$FlashTimer.wait_time *= 0.85

func detonate():
	if hasDetonated: return
	hasDetonated = true
	
	if playerDestroyed:
		GlobalLoad.score += 10 # When a mine is shot, increase the score by 10
	
	$FlashTimer.stop()
	$ExplodeTimer.stop()
	
	$Shape.hide()
	
	# Enable the collision on the explosion area, causing anything in this area
	# to die.
	$ExplosionArea.set_deferred("monitorable", true)
	$ExplosionArea.set_deferred("monitoring",  true)
	
	disableCollision()
	
	$ExplosionParticles.emitting = true
	$ExplosionAudio.play()
	
	self.get_parent().get_parent().get_parent().shakeCamera(0.5)
	
	despawn()

# Sets the time till detonation really low, and makes the bomb aggressively flash
# and beep until that time runs out. Used for being hit by bullets or other bombs.
func forcedDetonation(time:float = 0.5):
	# If the time remaining until detonation is less than the amount
	# that it will be after, don't even change it.
	time = min($ExplodeTimer.time_left, time)
		
	# Reset the delay, but make it very brief. That way it will immediately
	# take 0.3 seconds to explode, after being near its fallen comrade.
	$ExplodeTimer.wait_time = time
	$FlashTimer.wait_time   = 0.05 # Basically instant
	$ExplodeTimer.start()
	$FlashTimer.start()

func despawn():
	
	# Wait a split second before disabling the explosion collision again
	await get_tree().create_timer(0.1).timeout
	$ExplosionArea.set_deferred("monitorable", false)
	$ExplosionArea.set_deferred("monitoring",  false)
	
	# Wait 2 seconds for the audio and particles to finish
	await get_tree().create_timer(5).timeout
	
	self.queue_free()

func disableCollision():
	$CollisionArea.set_deferred("monitorable", false)
	$CollisionArea.set_deferred("monitoring", false)

func collision(area):
	var object = area.get_parent()
	
	if GlobalLoad.inGroup(area, "Bullet"):
		playerDestroyed = true
		
		# The bullet will push the mine
		self.vel += object.moveVector/5
		
		forcedDetonation()
	
	# If the mine collided with another mine
	if GlobalLoad.inGroup(area, "Mine"):
		# And the other mine has exploded (meaning that this mine is touching the
		# explosion)
		if object.hasDetonated:
			forcedDetonation()
