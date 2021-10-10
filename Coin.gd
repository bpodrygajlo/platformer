extends KinematicBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var velocity = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
  call_deferred("jump")

func jump():
  velocity += Vector2.UP.rotated(randf()/2.0 - 0.25) * (70 + randi() % 60)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
  velocity.y += 130 * delta
  velocity = move_and_slide(velocity, Vector2.UP)

func _on_Area2D_body_entered(body):
  body.collect_coin()
  self.queue_free()
