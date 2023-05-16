extends Node2D

var speed:int = 15

var velAdjustment:Vector2

# This is set in _ready(), because it is constant.
var moveVector:Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	# Create a vector for movement. It is based on the rotation of the bullet, and
	# the speed at which the bullet moves. each frame, this is added to the bullet's position.
	moveVector = Vector2(1, 0).rotated(rotation-PI/2) * speed
	
	moveVector += velAdjustment

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta): 
	self.position += moveVector
	
	if self.position.length() > 2000: # If the bullet is really far away
		self.queue_free()

func collision(area):
	var object = area.get_parent()
	
	if areaIs(area, "Meteor"):
		self.queue_free()
	if areaIs(area, "Mine"):
		# When the bullet hits a mine, randomly turn 60°
		self.rotation += randf_range(-PI/4, PI/4)
		moveVector *= 1.5 # Also move 1.5 times as fast afer the collision
		_ready()

# If the area that is passed in contains the string, it is that thing. A little messy.
func areaIs(areaNode, testString):
	return areaNode.get_parent().name.count(testString) > 0
