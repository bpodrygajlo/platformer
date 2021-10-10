extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
  $AnimationPlayer.play("idle")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#  pass


func _on_Button_pressed():
  var err = get_tree().change_scene("res://level.tscn")
  if err:
    print("Failed to load level")
