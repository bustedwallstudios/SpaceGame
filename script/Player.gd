extends Node2D

# The bullet scene, so that bullets can be easily created on the player
@export var BulletScene:PackedScene

@export var PowerupProgressBarScene:PackedScene

@export var defaultShootDelay:float = 0.7

# The player starts with three lives
var currentLives = 3

@export var bodyIdx:int = 1
@onready var bodyShapes = [
	$CursorSprite,
	$GunshipSprite
]

# The locations at which the bullets appear (the ends of the cannons basically)
var bulletSpawnLocations = [
	[Vector2(0, -20)],
	[Vector2(11, -9), Vector2(-11, -9)]
]
var bulletN:int = 0 # This is used to determine, via modulus, which cannon should fire this time.

# The correct values based on the current ship that is being used.
@onready var bodySpriteNode = bodyShapes[bodyIdx]
@onready var bulletSpawns = bulletSpawnLocations[bodyIdx]

var screenSize = GlobalLoad.screenSize

var vel:Vector2 = Vector2(0, 0)

var accel = 0.2
var maxAllowedSpeed = 10
var rotationSpeed = 3.5

var drag = 0.015

var canShoot:bool = true # Set to true whenever the ShootAgainTimer expires

var shouldThrust:bool = false

var immune    = true # Starts true, until the deathFlicker() is complete.
var currentlyDead = false # If this is false, don't allow the player to control the ship

# If the player moved the mouse more recently than pressing A or D
var lastMovedMouse = false

func _ready():
	defaultShootDelay /= bulletSpawnLocations[bodyIdx].size()
	$ShootAgainTimer.wait_time = defaultShootDelay
	
	respawn()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not currentlyDead:
		screenWrap()
	
	if not currentlyDead:
		doControls()
	
	if shouldThrust:
		thrust() # Do all the shit relating to thrusting
	else:
		dontThrust() # Do all the shit relating to NOT thrusting
	
	limitVelocity()
	
	# Actually move
	self.position += vel

func doControls():
	
	if Input.is_action_pressed("turnLeft"):
		lastMovedMouse = false
		self.rotation_degrees -= rotationSpeed
	
	elif Input.is_action_pressed("turnRight"):
		lastMovedMouse = false
		self.rotation_degrees += rotationSpeed
	
	elif Input.get_last_mouse_velocity().length() > 0 or lastMovedMouse:
		# If the player moved the mouse last frame, or just more recently than
		# they pressed A or D
		lastMovedMouse = true
		
		var angleToMouse = (get_global_mouse_position() - global_position).angle() + PI/2
		
		# The supposed angle that the player will face in after the adjustment
		# towards the mouse cursor.
		var newAngle = lerp_angle(self.rotation, angleToMouse, 0.1)
		
		# The change in angle. This is found because if it is too high, it needs
		# to be limited.
		var angleDelta = newAngle - rotation
		
		# If the angle to turn is greater than the max allowed rotation speed,
		# then only turn the allowed amount.
		if abs(angleDelta) > deg_to_rad(rotationSpeed):
			angleDelta /= abs(angleDelta)
			angleDelta *= deg_to_rad(rotationSpeed)
		
		# Rotate by the angle change amount
		self.rotation += angleDelta
	
	if Input.is_action_pressed("thrust"):
		shouldThrust = true
	
	else: # If the player is not thrusting, gradually slow down
		# Do all the shit that needs to be done when the player is NOT thrusting
		shouldThrust = false
	
	# If the player is trying to shoot, and the timer dictates that they can,
	# shoot.
	if Input.is_action_pressed("shoot") and canShoot:
		canShoot = false
		$ShootAgainTimer.start()
		
		shoot()

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
	# Do not slow the player down due to drag if they are dead, because then
	# the particles will continue to fly away (Sivakumar)
	if not currentlyDead:
		vel *= 1 - drag
	
	# If they're NOT thrusting, DON'T emit particles
	$EngineParticles.emitting = false
	
	# Quickly but gradually put the volume to 0 when they stop rocketing
	$Audio/EngineAudio.volume_db = lerp($Audio/EngineAudio.volume_db, -80.0, 0.025)

# Shoots whatever bullets from whatever placed
func shoot():
	var thisBullet = BulletScene.instantiate()
	
	var turretCount = bulletSpawnLocations[bodyIdx].size()
	var turretPos   = bulletSpawns[bulletN%turretCount].rotated(self.rotation)
	
	# Set the values on the bullet for when it appears in the scene
	thisBullet.rotation = self.rotation
	thisBullet.position = self.position + turretPos
	thisBullet.velAdjustment = self.vel
	
	# The gunship has smaller bullets
	if bodyIdx == 1:
		thisBullet.scale *= 0.75
	
	self.get_parent().add_child(thisBullet)
	
	$Audio/ShootAudio.play()
	
	$ShootParticles.position = bulletSpawns[bulletN%turretCount]
	$ShootParticles.emitting = true
	
	bulletN += 1 # Go to the next turret next time

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
	
	# Don't handle any collisions if the player is dead
	if self.currentlyDead:
		return
	
	var object = area.get_parent()
	
	if areaIs(area, "Meteor"):
		if immune: return
		die()
	
	elif areaIs(area, "Powerup"):
		powerup(object.powerupType)
	
	elif areaIs(area, "Mine"):
		if immune: return
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
			
			# After the powerup is over, set the shoot time back.
			await get_tree().create_timer(seconds).timeout
			# Only reset this if the player currently has a powerup
			if $ShootAgainTimer.wait_time < defaultShootDelay:
				$ShootAgainTimer.wait_time /= 0.2

func createPowerupTimer(powerupType, time, color):
	var powerupTimer = PowerupProgressBarScene.instantiate()
	
	powerupTimer.powerupNum = powerupType
	powerupTimer.time  = time
	powerupTimer.color = color
	
	$PowerupTimers.add_child(powerupTimer)
	
	# The timer handles its own deletion

func die():
	currentlyDead = true # Don't allow the controls to be used until respawn
	
	# Play the death explosion audio
	$Audio/DieAudio.play()
	$ExplosionParticles.emitting = true
	
	# Subtract one life, and update the indicator
	currentLives -= 1
	self.get_parent().get_parent().updateLivesIndicator(currentLives)
	
	# Hide just the sprite
	bodySpriteNode.hide()
	
	# Stop doing anything in the thrust code
	shouldThrust = false
	
	resetPowerups()
	
	# Disable the collision until the player is back alive
	$Collision.set_deferred("monitorable", false)
	$Collision.set_deferred("monitoring",  false)
	
	self.get_parent().get_parent().shakeCamera(0.5, 3)
	
	# Wait 3 seconds to respawn
	await get_tree().create_timer(3).timeout
	
	respawn()

# Called when the node enters the scene tree for the first time.
func respawn():
	self.get_parent().get_parent().updateLivesIndicator(currentLives)
	
	# Enable the collision, now that the player is alive
	$Collision.monitorable = true
	$Collision.monitoring  = true
	
	self.show()
	
	# This makes it so that the ship will not immediately turn towards the mouse,
	# unless the player does actually move it when they respawn.
	lastMovedMouse = false
	
	currentlyDead = false
	
	# Put the player back in the middle of the screen, with no rotation and no speed
	self.position = screenSize/2
	self.rotation = 0
	vel = Vector2.ZERO
	
	respawnFlicker()

func respawnFlicker():
	
	immune = true
	
	var flickerDelay = 0.1
	for i in range(0, 20):
		bodySpriteNode.hide()
		await get_tree().create_timer(flickerDelay).timeout
		bodySpriteNode.show()
		await get_tree().create_timer(flickerDelay).timeout
		flickerDelay -= 0.005
	
	immune = false

func resetPowerups():
	for timer in $PowerupTimers.get_children():
		timer.call_deferred("queue_free")
	
	# Reset the effect of the shooting powerup
	$ShootAgainTimer.wait_time = defaultShootDelay

# If the area that is passed in contains the string, it is that thing. A little messy.
func areaIs(areaNode, testString):
	return areaNode.get_parent().name.count(testString) > 0
