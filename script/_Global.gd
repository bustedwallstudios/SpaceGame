extends Node

const screenSize = Vector2(1280*2, 720*2)

var score:int = 0

# The distance OUTSIDE the screen that each meteor will spawn, so they cannot
# be seen spawning in
const meteorGraceDist = 121 # 120px is the max meteor size

# Used all over the place to detect collision types.
func inGroup(areaNode, groupName:String):
	return areaNode.get_parent().is_in_group(groupName)
