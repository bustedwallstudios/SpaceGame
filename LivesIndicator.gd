extends Node2D

# The indicators are stored in here, so that they can be
# found easily, and by their number.
var indicatorNodes = []

var startingPos:Vector2 = Vector2(30, 45)

func updateLives(count):	
	# If the correct amount of indicators already exist, do nothing
	# Or, if a negative amount is requested, obviously that makes no sense.
	if count == indicatorNodes.size() or count < 0:
		return
	
	elif count > indicatorNodes.size():
		# If more indicators are needed, then create new ones according to the missing number
		for i in range(0, count-indicatorNodes.size()):
			var newIndicator = $Sprite.duplicate()
			
			var xOffset = 40 * indicatorNodes.size()
			
			newIndicator.position = startingPos + Vector2(xOffset, 0)
			
			newIndicator.show()
			
			indicatorNodes.append(newIndicator)
			$Indicators.add_child(newIndicator)
	
	# If some amount needs to be deleted, then delete the right number
	elif count < indicatorNodes.size():
		for i in range(0, indicatorNodes.size()-count):
			var endIndicator = indicatorNodes.pop_back()
			
			endIndicator.queue_free()
