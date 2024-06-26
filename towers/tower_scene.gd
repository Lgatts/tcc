extends Area2D

signal tower_clicked


@onready var projectile_lines = $ProjectileLines
@onready var attack_timer:Timer = $Timer
@onready var range_indicator = $RangeIndicator
@onready var tower_actions = %TowerActions
@onready var change_attack_button = $TowerSprite/TowerActions/ChangeAttackButton
@onready var up_attack_button = $TowerSprite/TowerActions/UpAttackButton
@onready var laser_audio = $LaserAudio
@onready var power_up_audio = $PowerUpAudio
@onready var placed_timer = $PlacedTimer

var _damage: int = 1
var _element: Enums.Elements = Enums.Elements.NEUTRAL
var targets: Array[Area2D]
var base_atack: Marker2D
var placed: bool = false
var can_be_placed = false
var current_tower_pad: TowerPad

var _texture: Texture2D
var _aura: Texture2D
var _parent_icon: Texture2D
var _parent: Enums.Elements
var _override_element: bool = true
var _override_attack: bool = false
var _cost: int
var _up_damage_cost: int = 50

var attack_colors = {
	Enums.Elements.FIRE: Color.html("#ff8691"),
	Enums.Elements.WATER: Color.html("75e2ef"),
	Enums.Elements.EARTH: Color.html("#b3805c"),
	Enums.Elements.WIND: Color.html("#75ff6e"),
	Enums.Elements.NEUTRAL: Color.html("#d0d0d0"),
}

var attacks = {
	Enums.Elements.FIRE: explosiveAttack,
	Enums.Elements.WATER: tripleAttack,
	Enums.Elements.EARTH: pauseAttack,
	Enums.Elements.WIND: fastAttack,
	Enums.Elements.NEUTRAL: boldAttack
}

func construct(element: Enums.Elements, texture:Texture2D, damage:int, parent:Enums.Elements, aura:Texture2D, 
override_element: bool, parent_icon: Texture2D, cost: int):
	_element = element
	_texture = texture
	_damage = damage
	_parent = parent
	_aura = aura
	_override_element = override_element
	_parent_icon = parent_icon
	_cost = cost
	
func _ready():
	_create_attack_lines()
	base_atack = $TowerSprite/Marker2D
	$AnimationPlayer.play("float")
	_load_aura_if_possible()
	$TowerSprite.texture = _texture
	range_indicator.visible = true

func _load_aura_if_possible():
	if(_parent != Enums.Elements.UNDEFINED):
		$TowerSprite/Aura.texture = _aura
		$AnimationPlayer2.play("aura")

func _create_attack_lines():
	for projectile_line in projectile_lines.get_children():
		_set_color_by_element(projectile_line)
		projectile_line.position = Vector2.ZERO
		projectile_line.clear_points()
		projectile_line.add_point(Vector2.ZERO)
		projectile_line.add_point(Vector2.ZERO)

func _set_color_by_element(projectile_line):
	if !_override_element and _parent != Enums.Elements.UNDEFINED:
		projectile_line.default_color = attack_colors[_parent]
	else:
		projectile_line.default_color = attack_colors[_element]

func _on_area_2d_area_entered(area):
	if(placed):
		targets.append(area)		
		_attack()

func _process(_delta):
	if(targets.is_empty() and placed):
		attack_timer.stop()
		for projectile_line in projectile_lines.get_children():
			projectile_line.visible = false
	else:
		if(placed):
			_update_attack_line_position()
	_set_up_attack_visbility()

func _set_up_attack_visbility():
	if(Globals.player.gold < _up_damage_cost):
		up_attack_button.visible = false
	else:
		up_attack_button.visible = true

func _update_attack_line_position():
	var counter = 0
	var base_position = (base_atack.global_position - self.global_position)
	for projectile_line in projectile_lines.get_children():
		projectile_line.points[0] = base_position
		projectile_line.points[1] = _calc_relative_position(counter)
		counter += 1

func _attack():
	laser_audio.play()
	if _override_attack:
		attacks[_parent].call()
	else:
		attacks[_element].call()
	attack_timer.start()
	
func boldAttack():
	attack_timer.wait_time = 0.6
	_set_line_visible(30)
	targets[0].get_parent().take_damage(_damage * 2, _get_element())

func pauseAttack():
	attack_timer.wait_time = 0.5
	_set_line_visible(10)
	targets[0].get_parent().take_damage(_damage, _get_element(), true)

func explosiveAttack():
	attack_timer.wait_time = 0.7
	_set_line_visible(15)
	for enemie in targets:
		enemie.get_parent().take_damage(_damage, _get_element())
	
func fastAttack():
	attack_timer.wait_time = 0.1
	_set_line_visible(15)
	targets[0].get_parent().take_damage(_damage, _get_element())

func _set_line_visible(width:int):	
	var projectileLine:Line2D = projectile_lines.get_children()[0]
	projectileLine.width = width	
	projectileLine.visible = true

func tripleAttack():
	attack_timer.wait_time = 0.4
	var counter = 0
	for projectile_line in projectile_lines.get_children():
		projectile_line.width = 10
		projectile_line.visible = true
		if(self.targets.size() > counter):
			targets[counter].get_parent().take_damage(_damage, _get_element())
		counter += 1

func _get_element() -> Enums.Elements:
	if(_override_element):
		return _element
	else:
		return _parent

func _on_area_2d_area_exited(area):
	targets.erase(area)

func _calc_relative_position(targetId: int) -> Vector2:
	if(self.targets.size() > targetId):
		return self.targets[targetId].global_position - self.global_position
	else:
		return Vector2.ZERO

func _do_damage():
	_attack()

func place():	
	placed_timer.start()
	Globals.player.gold -= _cost	
	self.can_be_placed = false
	self.current_tower_pad.has_turret = true
	self.range_indicator.visible = false
	self.global_position = current_tower_pad.global_position
	self.range_indicator.update_color(Color(0.1,0.7,1,0.4))
	if(current_tower_pad._element == _parent):
		_override_attack = true
		change_attack_button.visible = false
	else:
		change_attack_button.visible = true
		
	if(_parent == Enums.Elements.UNDEFINED):
		change_attack_button.visible = false
	else:
		change_attack_button.texture = _parent_icon
		change_attack_button.tooltip_text = "Usar ataque da classe mãe"	
	tower_actions.visible = true	

func _on_mouse_entered():
	if(placed and Globals.ui_state == Enums.States.DEFAULT):
		self.range_indicator.visible = true

func _on_mouse_exited():
	if(placed):
		self.range_indicator.visible = false

func _isLeftClickMouse(event) -> bool:
	return (event is InputEventMouseButton 
		and event.button_index == MOUSE_BUTTON_LEFT 
		and event.is_pressed()
		and placed)

func _on_input_event(_viewport, event, _shape_idx):	
	if _isLeftClickMouse(event):
		if(tower_actions.visible):
			tower_actions.visible = false
		else:
			tower_actions.visible = true
			
func delete_tower():
	Globals.player.gold += 75
	current_tower_pad.has_turret = false
	queue_free()

func _on_recycle_button_clicked():
	delete_tower()

func _on_change_attack_button_clicked():
	if(_override_attack):
		_override_attack = false
		change_attack_button.texture = _parent_icon
		change_attack_button.tooltip_text = "Usar ataque da classe mãe"
	else:
		_override_attack = true
		change_attack_button.texture = _texture
		change_attack_button.tooltip_text = "Usar ataque original"

func _on_up_attack_button_clicked():
	power_up_audio.play()
	Globals.player.gold -= _up_damage_cost
	_up_damage_cost += 50
	up_attack_button.tooltip_text = "Aumentar dano\n" + "Custo: " + str(_up_damage_cost)
	_damage += 1

func _on_placed_timer_timeout():
	self.placed = true
