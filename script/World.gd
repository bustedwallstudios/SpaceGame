extends Node2D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	$UI/Score.set_text(str(GlobalLoad.score))

func updateLivesIndicator(newLifeCount):
	$PlayerStuff/LivesIndicator.updateLives(newLifeCount)

func shakeCamera(magnitude, shakeAmount=5):
	pass
	$WorldCamera.addTrauma(magnitude, shakeAmount)
