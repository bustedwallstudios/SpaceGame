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
func _process(delta): 
	self.position += moveVector
	
	if self.position.length() > 2000: # If the bullet is really far away
		self.queue_free()

func collision(area):
	var areaIsMeteor = String(area.get_parent().name).count("Meteor")
	if areaIsMeteor:
		self.queue_free()
