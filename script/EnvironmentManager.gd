extends Node2D

var frame = 0

var screenSize = GlobalLoad.screenSize

@export var MeteorScene:PackedScene

@export var PowerupScene:PackedScene

@export var MineScene:PackedScene

# The distance OUTSIDE the screen that each meteor will spawn, so they cannot
# be seen spawning in
var meteorGraceDist = 121 # 120px is the max meteor size

# Called every frameww'delta' is the elapsed time since the previous frame.
func _process(_delta):
	frame += 1

# Called by the timer every second and a bit
func tryCreateMeteor():
	if $Meteors.get_child_count() < 10: # If there are less than 10 meteors on the screen right now
		createMeteor()

func createMine():
	# Make it so that the next mine will spawn with a random interval
	$MineSpawnTimer.wait_time = randf_range(4, 20)
	
	# Create the mine and add it to the scene. The mine handles its own initial
	# position and stuff.
	var newMine = MineScene.instantiate()
	$Items.call_deferred("add_child", newMine)

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
		edgeY = -meteorGraceDist
	
	# The right side of the screen
	elif edge == 1:
		edgeX = intX + meteorGraceDist
		edgeY = randi() % intY
	
	# The bottom of the screen
	elif edge == 2:
		edgeX = randi() % intX
		edgeY = intY + meteorGraceDist
	
	# The left side of the screen
	else:
		edgeX = -meteorGraceDist
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

func spawnPowerupAt(newPowerupPos:Vector2):
	var newPowerup = PowerupScene.instantiate()
	newPowerup.position = newPowerupPos
	$Items.call_deferred("add_child", newPowerup)
