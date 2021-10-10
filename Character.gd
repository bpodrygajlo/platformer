extends KinematicBody2D

# Player controller. Basic 2d platforming

onready var _animation_player = $AnimationPlayer
onready var _sprite = $Flippable/Sprite

signal player_died
signal set_coins(coins)
signal update_health(health)

export var acceleration = 350
export var max_health = 3
export var max_run_speed = 130
export var jump_force = 130
export var gravity_strength = 250
export(Curve) var jump_curve

var velocity = Vector2(0, 0)
var is_attacking
var health
var is_dead
var is_hurt
var time_since_last_jump
var coins

var is_jump_held = false
var time_since_grounded = 1

func reset():
  health = max_health
  is_dead = false
  is_hurt = false
  is_attacking = false
  time_since_last_jump = 3000
  velocity = Vector2.ZERO
  coins = 0
  emit_signal("update_health", health)
  
func _ready():
  reset()

func can_attack():
  return is_on_floor() and not is_attacking and not is_hurt and not is_dead
  
func can_jump():
  return (is_on_floor() or time_since_grounded < 0.1) and not is_attacking and not is_hurt and not is_dead
  
func interrupt_attack():
  is_attacking = false
  $Flippable/Area2D/CollisionShape2D.set_deferred("disabled", true)

func process_input():
  # initialize - no input
  var result = {"attack": false, "dir": 0, "jump": false, "end_jump": false }
  
  # player can attack only if hes on the floor and is not already attacking
  if can_attack() and Input.is_action_just_pressed("attack"):
    is_attacking = true
    result["attack"] = true
    
  if Input.is_action_pressed("ui_left"):
    result["dir"] = -1
  elif Input.is_action_pressed("ui_right"):
    result["dir"] = 1

  
  # player cannot jump when attacking
  if can_jump():    
    if Input.is_action_just_pressed("ui_up"):
      time_since_last_jump = 0
      is_jump_held = true
      
  if Input.is_action_just_released("ui_up") or time_since_last_jump > 0.5: 
    is_jump_held = false
    
  return result

# - player has to wait until the attack animation is finished to start another
#   attack
# - attacking right after the last attack is finished should queue another
#   attack of different type/animation
# - If player starts falling or is pushed upwards it should break all animation
#   and start the falling/jumping animation
func select_animation(input):
  if is_hurt:
    return
  if input["dir"] != 0:
    $Flippable.scale.x = input["dir"]
  # if player is in the air switch animation to fall/jump
  if velocity.y < -10:
    _animation_player.play("jump")
    _sprite.frame = int(min(abs(velocity.y)/30.0, 2))
    return
  if velocity.y > 10:
    _animation_player.play("jump")
    _animation_player.advance(0)
    _sprite.frame = 3 + int(min(velocity.y/30.0, 2))
    interrupt_attack()
    return
  
  # if player is attacking in this frame start attack animation
  if input["attack"]:
    _animation_player.play("attack")
    return
  
  if is_attacking:
    return
    
  # if player is not attacking just animate idle/walk/run
  if abs(velocity.x) > 50:
    _animation_player.play("run")
  elif abs(velocity.x) > 0.2:
    _animation_player.play("walk")
  else:
    _animation_player.play("idle")


func _physics_process(delta):
  # get input
  velocity.y += gravity_strength * delta
  var input
  if not is_dead:
      # if on floor its easier to control the direction
    var acc = acceleration if is_on_floor() else acceleration / 2
    input = process_input()
    
    var mult = 1
    if input["dir"] != sign(velocity.x):
      mult = 2
    velocity.x += input["dir"] * acc * delta * mult
    if input["dir"] == 0:
      velocity.x = lerp(velocity.x, 0, delta * 5)
    
    if is_jump_held:
      velocity.y = -jump_force
    else:
      if velocity.y < 0:
        velocity.y = 0
      
    velocity.x = clamp(velocity.x, -max_run_speed, max_run_speed)
    var gravity_clamp = 100 if $Flippable/RayCast2D.is_colliding() else 1000
    velocity.y = clamp(velocity.y, -1000, gravity_clamp)
    
  if is_dead:
    velocity.x = lerp(velocity.x, 0, delta * 5)

  
  velocity = move_and_slide(velocity, Vector2.UP)
  if not is_dead:
    select_animation(input)
  
  if is_on_floor():
    time_since_grounded = 0
  else:
    time_since_grounded += delta 
  time_since_last_jump += delta

# when attack animation finished the player can jump or attack again
func _on_AnimationPlayer_animation_finished(anim_name):
  if anim_name == "attack":
    is_attacking = false
  elif anim_name == "death":
    emit_signal("player_died")
  elif anim_name == "hurt":
    is_hurt = false
    is_attacking = false
    if health <= 0:
      is_dead = true
      _animation_player.play("death")

func do_damage(dir = 0):
  health -= 1
  emit_signal("update_health", health)
  is_hurt = true
  call_deferred("knockback", dir)
  _animation_player.play("hurt")
  interrupt_attack()
  
func knockback(dir):
  velocity.x += dir * 50
  velocity.y -= 20 * abs(dir)
  
func respawn(loc):
  reset()
  emit_signal("set_coins", 0)
  position = loc

func _on_Area2D_body_entered(body):
  body.do_damage()

func collect_coin():
  coins += 1
  emit_signal("set_coins", coins)
