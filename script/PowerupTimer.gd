extends Node2D

var powerupNum:int

var time:float # Set by parent. Time, in seconds, that the powerup lasts for

var color:Color # Set by parent. Color of the progress bar

var sizeList = [100, 124, 154]
var posList  = [-50, -62, -77]

func _ready():
	$Progress.modulate = color
	$Progress.modulate.a = 0.5 # Make it transparent-ish
	
	$Progress.max_value = time
	
	# When the powerupNum is 0, the scale will be 1, and when it's 
	# more than that, it will be increased by increments of 0.1
	var n = powerupNum
	$Progress.size     = Vector2(sizeList[n], sizeList[n])
	$Progress.position = Vector2(posList[n], posList[n])
	
	$Timer.wait_time = time
	$Timer.start()

func properScale(n:int) -> float:
	var num:float = 10
	
	for i in range(0, n):
		num *= 1.2
	
	return num

func _process(_delta):
	# Update the progress bar
	$Progress.value = $Timer.time_left
	
	# Ensure that the timer is always right-side-up
	self.global_rotation = 0

# Wait until the timer is over, then delete it
func timerEnded():
	self.queue_free()
