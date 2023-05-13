extends Node2D

# The bullet scene, so that bullets can be easily created on the player
@export var BulletScene:PackedScene

# The locations at which the bullets appear (the ends of the cannons basically)
var bulletSpawnLocations = [
	Vector2(0, -20),
]

var screenSize = Vector2(1280, 720)

var vel:Vector2 = Vector2(0, 0)

var accel = 0.2
var maxAllowedSpeed = 10

var drag = 0.015

var canShoot:bool = true # Set to true whenever the ShootAgainTimer expires

var immune = true # Starts true, until the deathFlicker() is complete.

# Called when the node enters the scene tree for the first time.
func _ready():
	self.position = screenSize/2
	self.rotation = 0
	vel = Vector2.ZERO
	
	respawn()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	screenWrap()
	
	if Input.is_action_pressed("turnLeft"):
		self.rotation_degrees -= 3.5
	if Input.is_action_pressed("turnRight"):
		self.rotation_degrees += 3.5
	
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
	if not $EngineAudio.playing:
		$EngineAudio.playing = true
	
	# Quickly but gradually bring up the volume from -80dB when they start rocketing
	$EngineAudio.volume_db = lerp($EngineAudio.volume_db, -12.0, 0.15)

func dontThrust():
	vel *= 1 - drag
	
	# If they're NOT thrusting, DON'T emit particles
	$EngineParticles.emitting = false
	
	# Quickly but gradually put the volume to 0 when they stop rocketing
	$EngineAudio.volume_db = lerp($EngineAudio.volume_db, -80.0, 0.025)

# Shoots whatever bullets from whatever placed
func shoot():
	for i in range(0, len(bulletSpawnLocations)):
		var thisBullet = BulletScene.instantiate()
		
		thisBullet.rotation = self.rotation
		
		thisBullet.position = self.position + bulletSpawnLocations[i].rotated(self.rotation)
		
		thisBullet.velAdjustment = self.vel
		
		self.get_parent().add_child(thisBullet)
	
	$ShootAudio.play()
	
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
	if areaIs(area, "Meteor"):
		if immune: return
		die()
	elif areaIs(area, "Powerup"):
		powerup(area.get_parent().powerupType)

func powerup(type):
	match type:
		1:
			# Powerup type 1 grants rapidfire for 5 seconds.
			$ShootAgainTimer.wait_time *= 0.2
			await get_tree().create_timer(5).timeout
			$ShootAgainTimer.wait_time /= 0.2

func die():
	$DieAudio.play()
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
