extends Node2D

const type:String = "Meteor"

var screenSize = GlobalLoad.screenSize

@export var healthMultiplier = 1

@onready var graceDist = GlobalLoad.meteorGraceDist

var amountToRotate:float # Randomly rotate a little bit
var directionToMove:Vector2 # Set by parent
var thisMeteorSpeed = randf_range(0.25, 2)

# Set in the generateMeteorShape() function
var avgRadiusOfThisMeteor:float
var maxHealth:float
var health:float

# Set by whatever creates this meteor, in case it wants a custom size
var customSize = -1

var destroyed:bool = false # Set true when shot
var shouldDespawn:bool = false

# Whether or not this meteor should have a powerup crystal thing on it
var thisMeteorHasPowerup = randf() < 0.1

# Called when the node enters the scene tree for the first time.
func _ready():
	clearCracks()
	amountToRotate = randf_range(-1.5, 1.5)
	
	# Generate the polygon for the meteor's collision and shape
	var shapePolygon = generateMeteorShape()
	
	maxHealth = avgRadiusOfThisMeteor
	health = avgRadiusOfThisMeteor
	
	$Shape.polygon = shapePolygon
	$CollisionArea/Collision.set_deferred("polygon", shapePolygon)
	
	# Randomly change the color a little bit
	var cRand = 0.2
	$Shape.color *= 1 - randf()*cRand
	$Shape.color.a = 1 # Set the alpha back to 1.
	
	if thisMeteorHasPowerup:
		$Shape/Crystal.show()
		$Shape/Crystal.position = Vector2(randf_range(-20, 20), randf_range(-20, 20))
		$Shape/Crystal.rotation = randf_range(0, TAU)

# There are no cracks when the meteor comes into being
func clearCracks():
	$Cracks/CrackLine.clear_points()
	$Cracks/CrackLine2.clear_points()
	$Cracks/CrackLine3.clear_points()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.rotation_degrees += amountToRotate
	
	self.position += (directionToMove * thisMeteorSpeed) * 60*delta
	
	checkForDespawn()

# Generates and returns a shape polygon for the meteor
func generateMeteorShape() -> PackedVector2Array:
	var angleOfThisPoint = 0
	
	# All the points will be ~roughly~ around this distance away from the center
	# of the meteor. It won't be a circle, but it will be shaped approximately
	# like one.
	if self.customSize == -1: avgRadiusOfThisMeteor = randf_range(60, 90)
	else: avgRadiusOfThisMeteor = customSize
	var maxOffset = avgRadiusOfThisMeteor * 0.4 # The max "bumpiness" is 20% of the full radius of the meteor
	
	# 6+0 is the minimum (when avgrad is 20), and 6+(90-60)/6=11 is the max (when avgrad is 90)
	var numberOfPoints:int = 7 + (avgRadiusOfThisMeteor-60)/6
	
	# This array of all the point locations will later be turned into a
	# PackedVector2Array, which will then be put into the polygons for the meteor.
	var pointLocations: Array[Vector2] = []
	
	# Create the correct number of points
	for i in range(0, numberOfPoints):
		
		# Find the random offset that this point will have.
		var thisPointRandOffset = randf_range(-maxOffset, maxOffset)
		var thisPointDist = avgRadiusOfThisMeteor + thisPointRandOffset
		
		var thisX = cos(angleOfThisPoint)
		var thisY = sin(angleOfThisPoint)
		
		var thisPointPos:Vector2 = Vector2(thisX, thisY)
		thisPointPos *= thisPointDist
		
		pointLocations.append(thisPointPos)
		
		# Move to the angle of the next point
		angleOfThisPoint += TAU / numberOfPoints
	
	# Also configure the particles to reflect the size of the meteor
	configureParticles(avgRadiusOfThisMeteor)
	
	return PackedVector2Array(pointLocations)

func configureParticles(meteorRadius):
	# Configure the size directly
	$DestroyParticles.process_material.emission_sphere_radius = meteorRadius * 1.2
	
	# Increase the number of particles if the meteor is bigger
	#$DestroyParticles.amount = 16 * (meteorRadius/20)
	
	# Increase the size of the particles if the meteor is bigger
	var particleScale = 4 * (meteorRadius/20)
	$DestroyParticles.process_material.scale_min = particleScale
	$DestroyParticles.process_material.scale_max = particleScale*2

# Returns true if the meteor is out of the screen and should be despawned
func isOffscreen():
	var isOutOfBoundsX:bool = self.position.x < -graceDist*2 or self.position.x > screenSize.x + graceDist*2
	
	var isOutOfBoundsY:bool = self.position.y < -graceDist*2 or self.position.y > screenSize.y + graceDist*2
	
	return isOutOfBoundsX or isOutOfBoundsY

func collision(area):
	# The object that was collided with (a bullet, meteor, player, etc)
	var object = area.get_parent()
	
	if GlobalLoad.inGroup(area, "Bullet") and not self.destroyed:
		hit(object.damage)
	
	elif GlobalLoad.inGroup(area, "Mine") and not self.destroyed:
		# If the mine has exploded, then it means that the meteor is touching
		# the explosion
		if object.hasDetonated:
			var distanceToMine = (object.position - self.position).length()
			
			var mineDamage = distanceToMine/2
			
			hit(mineDamage)

# Called when damaged by something
func hit(damage:float):
	if thisMeteorHasPowerup:
		GlobalLoad.score += 3
	else:
		GlobalLoad.score += 1
	
	health -= damage
	
	# If there is still health remaining, then just crack the meteor.
	if health > 0:
		crack()
	else:
		breakMeteor()

func crack():
	var crackCount = 3
	
	# For each of the cracks (there are 3)
#	for i in range(0, crackCount):
#		var crackAngle = (360.0/crackCount) * i
#
#		var crackLength = self.health

func breakMeteor():
	# If the meteor is big enough, break apart into smaller ones
	if self.avgRadiusOfThisMeteor > 70: 
		for i in range(0, 2):
			var direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
			var size      = self.avgRadiusOfThisMeteor - 20
			self.get_parent().get_parent().createMeteor(size, self.position, direction)
	
	$DestroyedAudio.play()
	
	destroyThisMeteor()

func destroyThisMeteor():
	# If the meteor has a powerup crystal thing on it, then create one when it disappears
	if thisMeteorHasPowerup:
		self.get_parent().get_parent().spawnPowerupAt(self.position)
	
	# Disable collision, hide the sprite, tell the despawner that this meteor
	# can be despawned, and show the particles.
	self.destroyed = true
	$Shape.hide()
	disableCollision()
	$DestroyParticles.emitting = true
	
	await get_tree().create_timer(1).timeout # Wait one second before actually disappearing, just for the sound to play
	
	self.shouldDespawn = true

func disableCollision():
	$CollisionArea.set_deferred("monitorable", false)
	$CollisionArea.set_deferred("monitoring", false)

func checkForDespawn():
	var shouldDeleteMeteor = self.isOffscreen() or self.shouldDespawn
	
	if shouldDeleteMeteor:
		self.queue_free() # Delete the meteor from the universe
