extends Node

var player: Node = null


var player_current_attack = false

var current_scene = "world"  # world, cliff_side
var last_scene = "none" # none is first load, otherwise world, cliff_side, etc
var next_scene = "none"
var transition_scene = false

var camera_limits = {
	"world": {"left":0,"top":0,"right":464,"bottom":288},
	"cliff_side": {"left":0,"top":0,"right":351,"bottom":192},
	"west_side": {"left":0,"top":0,"right":400,"bottom":320},
	"east_side": {"left":-16,"top":-16,"right":528,"bottom":528},
}

var player_pos_data = {
	"world":{
		"cliff_side":{"x":169,"y":184}, # Start Coords when going from world to cliff_side
		"west_side":{"x":378,"y":250}, # Start Coords when going from world to west_side
		"east_side":{"x":-3,"y":279}, # Start Coords when going from world to west_side
	},
	"cliff_side":{
		"world":{"x":217,"y":20},  # Coords when going from cliff_side to world
	},
	
	"west_side":{
		"world":{"x":11,"y":42},  # Coords when going from cliff_side to world
	},
	"east_side":{
		"world":{"x":453, "y":227},
	},
}

var scene_paths = {
	"world": "res://scenes/World/world.tscn",
	"cliff_side": "res://scenes/World/cliff_side.tscn",
	"west_side": "res://scenes/World/west_side.tscn",
	"east_side": "res://scenes/World/east_side.tscn"
}

var player_start_pos_x = 64
var player_start_pos_y = 71

func finish_change_scene():
	if transition_scene:
		transition_scene = false
		player_start_pos_x = player_pos_data[current_scene][next_scene].x
		player_start_pos_y = player_pos_data[current_scene][next_scene].y
			
		last_scene=current_scene
		current_scene=next_scene
		next_scene="none"	
		get_tree().change_scene_to_file(scene_paths[current_scene])
	
