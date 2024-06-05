extends Node

@onready var animation_player = $CanvasLayer/AnimationPlayer
@onready var continue_button = $CanvasLayer/VBoxContainer/ContinueButton

func _ready():
	continue_button.visible = Repository.has_save()
	animation_player.play("title")

func _on_new_game_button_pressed():
	Globals.player = Player.new()
	TransitionScene.change_scene("res://screens/create_char.tscn")

func _on_continue_button_pressed():
	Repository.load_game()
	TransitionScene.change_scene("res://levels/over_world.tscn")
	
