extends Node2D

# The bullet scene, so that bullets can be easily created on the player
@export var BulletScene:PackedScene

@export var PowerupProgressBarScene:PackedScene

# The player starts with three lives
var currentLives = 3

# The locations at which the bullets appear (the ends of the cannons basically)
var bulletSpawnLocations = [
	Vector2(0, -20),
]

var screenSize = GlobalLoad.screenSize

var vel:Vector2 = Vector2(0, 0)

var accel = 0.2
var maxAllowedSpeed = 10
var rotationSpeed = 3.5

var drag = 0.015

var canShoot:bool = true # Set to true whenever the ShootAgainTimer expires

var immune = true # Starts true, until the deathFlicker() is complete.

# If the player moved the mouse more recently than pressing A or D
var lastMovedMouse = false

# Called when the node enters the scene tree for the first time.
func _ready():
	self.position = screenSize/2
	self.rotation = 0
	vel = Vector2.ZERO
	
	self.get_parent().get_parent().updateLivesIndicator(currentLives)
	
	respawn()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	screenWrap()
	
	if Input.is_action_pressed("turnLeft"):
		lastMovedMouse = false
		self.rotation_degrees -= rotationSpeed
	elif Input.is_action_pressed("turnRight"):
		lastMovedMouse = false
		self.rotation_degrees += rotationSpeed
	
	# If the player moved the mouse last frame, or just more recently than
	# they pressed A or D
	elif Input.get_last_mouse_velocity().length() > 0 or lastMovedMouse:
		lastMovedMouse = true
		
		var angleToMouse = (get_global_mouse_position() - global_position).angle() + PI/2
		
		var newAngle = lerp_angle(self.rotation, angleToMouse, 0.1)
		
		var angleDelta = newAngle - rotation
		
		# If the angle to turn is greater than the max allowed rotation speed,
		# then only turn the allowed amount.
		if abs(angleDelta) > deg_to_rad(rotationSpeed):
			angleDelta /= abs(angleDelta)
			angleDelta *= deg_to_rad(rotationSpeed)
		
		# Use lerp_angle to rotate the player smoothly towards the target angle
		rotation += angleDelta
	
	if Input.is_action_pressed("thrust"):
		thrust() # Do all the shit relating to thrusting
	
	else: # If the player is not thrusting, gradually slow down
		# Do all the shit that needs to be done when the player is NOT thrusting
		dontThrust()
		
	if Input.is_action_pressed("shoot") and canShoot:
		canShoot = false
		$ShootAgainTimer.start()
		
		shoot()
	
	limitVelocity()
	
	# Actually move
	self.position += vel

# Do all the thrusting stuff
func thrust():
	vel.x += sin(self.rotation) * accel
	vel.y -= cos(self.rotation) * accel # Subtracted, because -y is up in the game engine
	
	$EngineParticles.emitting = true
	
	# If the audio isn't already playing, start playing it (if it is already playing
	# and it is told to play every frame, it will restart every frame...)
	if not $Audio/EngineAudio.playing:
		$Audio/EngineAudio.playing = true
	
	# Quickly but gradually bring up the volume from -80dB when they start rocketing
	$Audio/EngineAudio.volume_db = lerp($Audio/EngineAudio.volume_db, -12.0, 0.15)

func dontThrust():
	vel *= 1 - drag
	
	# If they're NOT thrusting, DON'T emit particles
	$EngineParticles.emitting = false
	
	# Quickly but gradually put the volume to 0 when they stop rocketing
	$Audio/EngineAudio.volume_db = lerp($Audio/EngineAudio.volume_db, -80.0, 0.025)

# Shoots whatever bullets from whatever placed
func shoot():
	for i in range(0, len(bulletSpawnLocations)):
		var thisBullet = BulletScene.instantiate()
		
		thisBullet.rotation = self.rotation
		
		thisBullet.position = self.position + bulletSpawnLocations[i].rotated(self.rotation)
		
		thisBullet.velAdjustment = self.vel
		
		self.get_parent().add_child(thisBullet)
	
	$Audio/ShootAudio.play()
	
	$ShootParticles.emitting = true

# Limits the velocity to a maximum speed, and it works diagonally too
func limitVelocity():
	
	# If they're going faster than max speed, then set the speed to the max speed.
	if vel.length() > maxAllowedSpeed:
		var speedNormalized:Vector2 = vel.normalized()
		
		var clampedSpeed:Vector2 = speedNormalized * maxAllowedSpeed
		
		vel = clampedSpeed

func screenWrap():
	# If the player has exceeded the screen bounds on the X, put it on the other side.
	if self.position.x  > screenSize.x:
		self.position.x = 0
	if self.position.x  < 0:
		self.position.x = screenSize.x
	
	# Same for the y.
	if self.position.y  > screenSize.y:
		self.position.y = 0
	if self.position.y  < 0:
		self.position.y = screenSize.y

func canShootAgain():
	canShoot = true

func collision(area):
	var object = area.get_parent()
	
	if areaIs(area, "Meteor"):
		if immune: return
		die()
	
	elif areaIs(area, "Powerup"):
		powerup(object.powerupType)
	
	elif areaIs(area, "Mine"):
		if object.hasDetonated:
			die()

func powerup(type):
	match type:
		0:
			var seconds = 5
			# Powerup type 1 grants rapidfire for 5 seconds.
			$ShootAgainTimer.wait_time *= 0.2
			
			# Reset the time left on the bullet shoot timer, so that
			# the powerup takes effect immediately
			$ShootAgainTimer.start()
			
			createPowerupTimer(type, seconds, Color(0, 1, 0, 0.5))
			
			await get_tree().create_timer(seconds).timeout
			$ShootAgainTimer.wait_time /= 0.2

func createPowerupTimer(powerupType, time, color):
	var powerupTimer = PowerupProgressBarScene.instantiate()
	
	powerupTimer.powerupNum = powerupType
	powerupTimer.time  = time
	powerupTimer.color = color
	
	self.add_child(powerupTimer)
	
	# The timer handles its own deletion

func die():
	$Audio/DieAudio.play()
	
	currentLives -= 1
	self.get_parent().get_parent().updateLivesIndicator(currentLives)
	
	_ready()
	respawn()

func respawn():
	immune = true
	
	var flickerDelay = 0.1
	for i in range(0, 20):
		$Sprite.hide()
		await get_tree().create_timer(flickerDelay).timeout
		$Sprite.show()
		await get_tree().create_timer(flickerDelay).timeout
		flickerDelay -= 0.005
	
	immune = false

# If the area that is passed in contains the string, it is that thing. A little messy.
func areaIs(areaNode, testString):
	return areaNode.get_parent().name.count(testString) > 0
