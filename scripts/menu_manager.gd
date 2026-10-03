# menu_manager.gd
# Autoload "MenuManager": full-screen menus (quest log, inventory). Only
# one is open at a time, and the game is paused while one is open. A menu
# is any node with open_menu() and close_menu(); always open and close
# menus through here so the pause stays correct.
extends Node

var current_menu: Node = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

# Esc closes the open menu
func _unhandled_input(event):
	if current_menu and event.is_action_pressed("ui_cancel"):
		close_menu()
		get_viewport().set_input_as_handled()

func toggle_menu(menu: Node):
	if current_menu == menu:
		close_menu()
	else:
		open_menu(menu)

# Opening a menu closes whichever one was already open
func open_menu(menu: Node):
	if current_menu == menu:
		return
	if current_menu:
		current_menu.close_menu()
	current_menu = menu
	menu.open_menu()
	get_tree().paused = true

func close_menu():
	if current_menu == null:
		return
	current_menu.close_menu()
	current_menu = null
	get_tree().paused = false

func is_open(menu: Node) -> bool:
	return current_menu == menu
