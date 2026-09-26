extends Node2D



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$player.position.x = global.player_start_pos_x
	$player.position.y = global.player_start_pos_y

	$player.set_camera_limits(global.camera_limits[global.current_scene])
	$player/MainCamera.reset_smoothing()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	change_scenes()


func change_scenes():
	if global.transition_scene == true:
		if global.current_scene == "west_side":
			global.finish_change_scene()


func _on_world_teleport_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		global.transition_scene = true
		global.next_scene = "world"


func _on_world_teleport_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		global.transition_scene = false
