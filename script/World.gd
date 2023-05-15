extends Node2D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	$Control/Label.set_text(str(GlobalLoad.score))

func updateLivesIndicator(newLifeCount):
	$PlayerStuff/LivesIndicator.updateLives(newLifeCount)
