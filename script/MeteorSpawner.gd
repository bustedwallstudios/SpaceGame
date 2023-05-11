extends Node2D

var frame = 0

var screenSize = GlobalLoad.screenSize

@export var MeteorScene:PackedScene

# The distance OUTSIDE the screen that each meteor will spawn, so they cannot
# be seen spawning in
var graceDist = 121 # 120px is the max meteor size

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	frame += 1

# Called by the timer every second and a bit
func tryCreateMeteor():
	if $Meteors.get_child_count() < 10: # If there are less than 10 meteors on the screen right now
		createMeteor()

func createMeteor(customSize = -1, location:Vector2=Vector2.ZERO, direction:Vector2=Vector2.ZERO):
	var thisMeteor = MeteorScene.instantiate()
	
	var startPos
	var startDirection
	
	if location == Vector2.ZERO:
		startPos = getStartPos()
	else:
		startPos = location
	
	if direction == Vector2.ZERO:
		startDirection = getStartDirection(startPos)
	else:
		startDirection = direction
	
	thisMeteor.position  = startPos
	thisMeteor.directionToMove = startDirection
	thisMeteor.customSize = customSize
	
	$Meteors.call_deferred("add_child", thisMeteor)

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
func getStartDirection(meteorPos:Vector2) -> Vector2:
	
	# The angle from the meteor to the center of the screen
	var angle = meteorPos.angle_to_point(screenSize / 2)
	
	# Randomly adjust it by 1/12 of a circle (15°)
	var angleRandom = randf() * PI/6
	
	# The final direction that the meteor will move in each frame (length 1)
	var direction:Vector2 = Vector2(cos(angle+angleRandom), sin(angle+angleRandom))
	
	return direction

