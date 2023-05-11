extends Node2D

var screenSize = GlobalLoad.screenSize

@onready var graceDist = self.get_parent().get_parent().graceDist

var amountToRotate:float # Randomly rotate a little bit
var directionToMove:Vector2 # Set by parent
var thisMeteorSpeed = randf_range(0.25, 2)

var avgRadiusOfThisMeteor:float # Set in the generateMeteorShape() function
var customSize = -1 # Set by whatever creates this meteor

var destroyed:bool = false # Set true when shot
var shouldDespawn:bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	amountToRotate = randf_range(-1.5, 1.5)
	
	var shapePolygon = generateMeteorShape()
	
	$Shape.polygon = shapePolygon
	$CollisionArea/Collision.set_deferred("polygon", shapePolygon)

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
	
	return PackedVector2Array(pointLocations)	

# Returns true if the meteor is out of the screen and should be despawned
func isOffscreen():
	var isOutOfBoundsX:bool = self.position.x < -graceDist*2 or self.position.x > screenSize.x + graceDist*2
	
	var isOutOfBoundsY:bool = self.position.y < -graceDist*2 or self.position.y > screenSize.y + graceDist*2
	
	return isOutOfBoundsX or isOutOfBoundsY

func collision(area):
	var areaIsBullet = String(area.get_parent().name).count("Bullet") > 0
	if areaIsBullet and not self.destroyed:
		hit()

# Called when shot with a bullet
func hit():
	# If the meteor is big enough, break apart into smaller ones
	if self.avgRadiusOfThisMeteor > 70: 
		for i in range(0, 2):
			var direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
			var size      = self.avgRadiusOfThisMeteor - 20
			self.get_parent().get_parent().createMeteor(size, self.position, direction)
	
	$DestroyedAudio.play()
	
	destroyThisMeteor()

func checkForDespawn():
	var shouldDeleteMeteor = self.isOffscreen() or self.shouldDespawn
	
	if shouldDeleteMeteor:
		self.queue_free() # Delete the meteor from the universe

func destroyThisMeteor():
	self.destroyed = true
	self.hide()
	$CollisionArea.queue_free()
	
	await get_tree().create_timer(1).timeout # Wait one second before actually disappearing, just for the sound to play
	
	self.shouldDespawn = true
