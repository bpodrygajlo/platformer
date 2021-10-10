extends CanvasLayer


func _ready():
  $Coins/Label.text = str(0)
  $HealthBar/Bar.value = 0

func set_coins(coins):
  $Coins/Label.text = str(coins)
  
func set_health(health):
  $HealthBar/Bar.value = health
  var fg = $HealthBar/Bar.get("custom_styles/fg")
  if health == 3:
    fg.border_width_right = 2
  else:
    fg.border_width_right = 0
