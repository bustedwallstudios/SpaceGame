extends Node2D

var speed:int = 20

var velAdjustment:Vector2

# This is set in _ready(), because it is constant.
var moveVector:Vector2

var trailPoints:Array = []

# Set wherever this bullet is created from, because different guns might have
# different damage amounts
var damage

# The ship/enemy/etc that shot this bullet. Set by the parent on creation. When
# the bullet collides, it checks if it collided with its owner, and if so, doesn't
# do anything.
var bulletOwner:Node

# Called when the node enters the scene tree for the first time.
func _ready():
	# Create a vector for movement. It is based on the rotation of the bullet, and
	# the speed at which the bullet moves. each frame, this is added to the bullet's position.
	moveVector = Vector2(1, 0).rotated(rotation-PI/2) * speed
	
	moveVector += velAdjustment

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta): 
	self.position += moveVector
	
	if self.position.length() > 5000: # If the bullet is really far away
		self.queue_free()
	
	trail()

func trail():
	if trailPoints.size() > 5:
		trailPoints.pop_front()
	
	trailPoints.append(self.position / self.scale)
	
	$TrailParticles.points = PackedVector2Array(trailPoints)
	
	$TrailParticles.global_position = Vector2.ZERO
	$TrailParticles.global_rotation = 0

func collision(area):
	var object = area.get_parent()
	
	if GlobalLoad.inGroup(area, "Meteor"):
		self.queue_free()
	
	if GlobalLoad.inGroup(area, "Mine"):
		if object.hasDetonated:
			turnAwayFrom(object.position, true)
		else:
			self.queue_free()

func turnAwayFrom(pos:Vector2, isBomb):
	var posToHere:Vector2 = self.position - pos
	
	# Get the relevant vectors for creating the final movement vector
	var initial:Vector2   = moveVector
	var forceDir:Vector2  = posToHere.normalized()
	var force:float       = 500 / posToHere.length()
	
	# Add the force vector and initial vector together to get the new movement
	# vec for the bullet
	var resultant:Vector2 = forceDir*force + (initial/2)
	
	# Point the bullet in its new direction of movement
	self.rotation = resultant.angle() + PI/2
	
	moveVector = resultant
