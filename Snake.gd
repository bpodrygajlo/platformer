extends KinematicBody2D

# Player controller. Basic 2d platforming
#
# - player is not supposed to be able to move when attacking

onready var _animation_player = $AnimationPlayer
onready var _sprite = $Flippable/Sprite
onready var time_since_last_attack = 1
onready var enemy = null
onready var forward_collider = $Flippable/FrontWallDetector
onready var forward_drop_collider = $Flippable/FrontHoleDetector
onready var moving_left = true
onready var enemy_detector = $Flippable/DangerZone

var is_attacking = false
onready var velocity = Vector2.ZERO
var health = 1
var is_dead = false
var direction = -1

func process_ai():
  # initialize - no decision
  var decision = {"attack": false, "forward": false }
  if is_attacking or not is_on_floor():
    return decision
  if enemy != null and not enemy.is_dead:
    if enemy_detector.overlaps_body(enemy):
      if is_on_floor() and not is_attacking and time_since_last_attack > 3:
        if enemy.position.x < position.x:
          direction = -1
        else:
          direction = 1
        is_attacking = true
        decision["attack"] = true
        time_since_last_attack = 0
        return decision
      return decision
  
  if is_on_floor() and forward_collider.is_colliding() or not forward_drop_collider.is_colliding():
    direction *= -1
  
  decision["forward"] = true
  return decision


func select_animation(attack):
  if attack:
    _animation_player.play("attack")
    return
  
  if is_attacking:
    return
    
  _animation_player.play("idle")
  
func set_enemy(player):
  enemy = player
  
func _physics_process(delta):
  velocity.y += 130 * delta
  velocity.x = lerp(velocity.x, 0, delta * 3)
  velocity = move_and_slide(velocity, Vector2.UP)
  if is_dead:
    return
    
  var decision = process_ai()
  
  if direction == 1:
    $Flippable.scale.x = -1
  elif direction == -1:
    $Flippable.scale.x = 1
    
  if decision["forward"]:
    velocity.x += direction * 15;
  elif decision["attack"]:
    velocity.x += direction * 30
    velocity.y -= 30
  velocity.x = clamp(velocity.x, -30, 30)
    
  select_animation(decision["attack"])  
  time_since_last_attack += delta

# when attack animation finished the player can jump or attack again
func _on_AnimationPlayer_animation_finished(anim_name):
  if anim_name == "attack":
    is_attacking = false
    _animation_player.stop()

func do_damage():
  if is_dead:
    return
  health -= 1
  var blood_scene = load("res://Blood.tscn")
  add_child(blood_scene.instance())
  if health <= 0:
    var coin_scene = load("res://Coin.tscn")
    for i in randi() % 3 + 1:
      call_deferred("add_child", coin_scene.instance())
    is_dead = true
    #$CollisionShape2D.set_deferred("disabled", true)
    _animation_player.play("death")

func _on_AttackArea_body_entered(body):
  var dir = 0
  if body.position.x > position.x:
    dir = 1
  else:
    dir = -1
  body.do_damage(dir)

func ressurect():
  is_dead = false
  is_attacking = false
  health = 1
