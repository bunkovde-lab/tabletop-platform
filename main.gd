extends Control

var current_player := 0
var positions := [0, 0]
var cash := [1500, 1500]
var owned := {}
var log_lines: Array[String] = []
var rolled := false
var rng := RandomNumberGenerator.new()

const SPACES = [
 {"name":"СТАРТ","price":0},
 {"name":"Старая улица","price":100},
 {"name":"Шанс","price":0},
 {"name":"Рыночная площадь","price":140},
 {"name":"Налог","price":0},
 {"name":"Вокзал","price":200},
 {"name":"Парк","price":180},
 {"name":"Шанс","price":0},
 {"name":"Башенная улица","price":220},
 {"name":"Тюрьма","price":0},
 {"name":"Набережная","price":260},
 {"name":"Электростанция","price":150}
]

func _ready() -> void:
 rng.randomize()
 show_catalog()

func clear_ui() -> void:
 for child in get_children():
  remove_child(child)
  child.queue_free()

func make_label(value: String, size: int = 24) -> Label:
 var label := Label.new()
 label.text = value
 label.add_theme_font_size_override("font_size", size)
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 return label

func make_button(value: String, callback: Callable) -> Button:
 var button := Button.new()
 button.text = value
 button.custom_minimum_size = Vector2(0, 65)
 button.pressed.connect(callback)
 return button

func make_root(heading: String) -> VBoxContainer:
 clear_ui()
 var background := ColorRect.new()
 background.color = Color("#152036")
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(background)
 var margin := MarginContainer.new()
 margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 margin.add_theme_constant_override("margin_left", 20)
 margin.add_theme_constant_override("margin_right", 20)
 margin.add_theme_constant_override("margin_top", 28)
 margin.add_theme_constant_override("margin_bottom", 20)
 add_child(margin)
 var column := VBoxContainer.new()
 column.add_theme_constant_override("separation", 12)
 margin.add_child(column)
 column.add_child(make_label(heading, 34))
 return column

func show_catalog() -> void:
 var column := make_root("TABLETOP")
 column.add_child(make_label("Платформа настольных игр", 24))
 column.add_child(make_label("Демо: Сделка — город", 28))
 column.add_child(make_label("Два игрока на одном устройстве. Покупайте участки, собирайте аренду и управляйте капиталом.", 20))
 column.add_child(make_button("Начать партию", start_game))
 column.add_child(make_label("QR-подключение и личные телефоны игроков будут добавлены в следующих версиях.", 17))

func start_game() -> void:
 current_player = 0
 positions = [0, 0]
 cash = [1500, 1500]
 owned.clear()
 rolled = false
 log_lines = ["Партия началась"]
 show_game()

func show_game() -> void:
 var column := make_root("СДЕЛКА: ГОРОД")
 column.add_child(make_label("Игрок 1: $%d    Игрок 2: $%d" % [cash[0], cash[1]], 20))
 var scroll := ScrollContainer.new()
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 var grid := GridContainer.new()
 grid.columns = 3
 grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 for i in range(SPACES.size()):
  var space: Dictionary = SPACES[i]
  var tile := PanelContainer.new()
  tile.custom_minimum_size = Vector2(200, 105)
  var style := StyleBoxFlat.new()
  style.bg_color = Color("#355075") if i % 2 == 0 else Color("#466382")
  style.set_corner_radius_all(8)
  tile.add_theme_stylebox_override("panel", style)
  var tile_text: String = str(space["name"])
  if int(space["price"]) > 0:
   tile_text += "\n$%d" % int(space["price"])
  if owned.has(i):
   tile_text += "\nВладелец: %d" % (int(owned[i]) + 1)
  if positions[0] == i:
   tile_text += "\n● Игрок 1"
  if positions[1] == i:
   tile_text += "\n● Игрок 2"
  var label := make_label(tile_text, 15)
  label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  tile.add_child(label)
  grid.add_child(tile)
 scroll.add_child(grid)
 column.add_child(scroll)
 column.add_child(make_label("Ход игрока %d" % (current_player + 1), 23))
 var actions := HBoxContainer.new()
 actions.add_child(make_button("Бросить кубики", roll_dice))
 actions.add_child(make_button("Купить", buy_property))
 column.add_child(actions)
 column.add_child(make_button("Передать ход", end_turn))
 column.add_child(make_label("\n".join(log_lines.slice(max(0, log_lines.size() - 3))), 16))
 column.add_child(make_button("В каталог", show_catalog))

func roll_dice() -> void:
 if rolled:
  log_lines.append("Вы уже бросали кубики. Передайте ход.")
  show_game()
  return
 rolled = true
 var dice: int = rng.randi_range(1, 6) + rng.randi_range(1, 6)
 var previous: int = positions[current_player]
 var next: int = (previous + dice) % SPACES.size()
 positions[current_player] = next
 if previous + dice >= SPACES.size():
  cash[current_player] += 200
  log_lines.append("Бонус за круг: $200")
 var space: Dictionary = SPACES[next]
 log_lines.append("Игрок %d: %d → %s" % [current_player + 1, dice, str(space["name"])])
 if owned.has(next) and int(owned[next]) != current_player:
  var rent: int = int(int(space["price"]) * 0.2)
  cash[current_player] -= rent
  cash[int(owned[next])] += rent
  log_lines.append("Аренда: $%d" % rent)
 elif str(space["name"]) == "Налог":
  cash[current_player] -= 100
  log_lines.append("Налог: $100")
 elif str(space["name"]) == "Шанс":
  var change: int = [-100, -50, 100, 150][rng.randi_range(0, 3)]
  cash[current_player] += change
  log_lines.append("Событие: $%d" % change)
 show_game()

func buy_property() -> void:
 if not rolled:
  log_lines.append("Сначала бросьте кубики.")
 else:
  var position: int = positions[current_player]
  var space: Dictionary = SPACES[position]
  var price: int = int(space["price"])
  if price == 0:
   log_lines.append("Эту клетку нельзя купить.")
  elif owned.has(position):
   log_lines.append("Участок уже продан.")
  elif cash[current_player] < price:
   log_lines.append("Недостаточно денег.")
  else:
   cash[current_player] -= price
   owned[position] = current_player
   log_lines.append("Куплено: %s за $%d" % [str(space["name"]), price])
 show_game()

func end_turn() -> void:
 if not rolled:
  log_lines.append("Сначала бросьте кубики.")
 else:
  current_player = 1 - current_player
  rolled = false
 show_game()
