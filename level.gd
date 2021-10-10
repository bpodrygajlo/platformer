extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var player
onready var spawn = $SpawnPoint

func _process(_delta):
  var snake_count = 0
  for snake in $Snakes.get_children():
    if snake.is_dead == false:
      snake_count += 1
  if snake_count == 0:
    var end_scene = load("res://end.tscn")
    var end = end_scene.instance()
    add_child(end)
  if Input.is_action_just_pressed("ui_down"):
    switch_to_next_level()
    

# Called when the node enters the scene tree for the first time.
func _ready():
  var gui_scene = load("res://Gui.tscn")
  var gui = gui_scene.instance()
  add_child(gui)
  
  var player_scene = load("res://Character.tscn")
  player = player_scene.instance()
  player.connect("player_died", self, "respawn")
  player.connect("set_coins", gui, "set_coins")
  player.connect("update_health", gui, "set_health")
  add_child(player)
  player.position = spawn.position
  
  var snake_scene = load("res://Snake.tscn")
  for snake_spawn in $SnakeSpawns.get_children():
    var snake = snake_scene.instance()
    snake.position = snake_spawn.position
    $Snakes.add_child(snake)
    snake.set_enemy(player)
  
  set_camera_limits()
  add_background()
  
func set_camera_limits():
  var map_limits = $TileMap.get_used_rect()
  var map_cellsize = $TileMap.cell_size
  $Character/Camera2D.limit_left = map_limits.position.x * map_cellsize.x
  $Character/Camera2D.limit_right = map_limits.end.x * map_cellsize.x
  $Character/Camera2D.limit_top = map_limits.position.y * map_cellsize.y
  $Character/Camera2D.limit_bottom = map_limits.end.y * map_cellsize.y


func add_background():
  var bg = load("res://background.tscn")
  add_child(bg.instance())
  

func _on_Area2D_body_exited(_body):
  respawn()

func respawn():
  player.respawn(spawn.position)
  for snake in $Snakes.get_children():
    snake.ressurect()

var level = 1
func switch_to_next_level():
  if level == 1:
    switch_levels($TileMap, $TileMap2)
    level = 2
  else:
    switch_levels($TileMap2, $TileMap)
    level = 1

func switch_levels(from : TileMap, to : TileMap):
  from.visible = false
  to.visible = true
  to.collision_layer = from.collision_layer
  to.collision_mask = from.collision_mask
  from.collision_layer = 0x0
  from.collision_mask = 0x0
