extends Node

signal enemies_change

var current_wave: int = 0:
	set(value):
		current_wave = value
		enemies_change.emit()
		
var total_waves: int = 0:
	set(value):
		total_waves = value
		enemies_change.emit()
		
var player: Player = Player.new()

var ui_state: Enums.States = Enums.States.DEFAULT