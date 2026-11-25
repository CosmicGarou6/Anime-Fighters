extends Node3D

const FIGHTER_SCRIPT = preload("res://scripts/fighter.gd")
const CHARACTERS = [
    {"name":"Garou", "color":Color(0.78,0.82,0.91), "accent":Color(0.16,0.20,0.30)},
    {"name":"Madara", "color":Color(0.55,0.12,0.18), "accent":Color(0.12,0.10,0.14)},
    {"name":"Aizen", "color":Color(0.82,0.82,0.88), "accent":Color(0.24,0.32,0.52)},
    {"name":"Guts", "color":Color(0.16,0.18,0.22), "accent":Color(0.52,0.54,0.60)},
    {"name":"Gojo", "color":Color(0.86,0.90,1.0), "accent":Color(0.18,0.28,0.62)},
    {"name":"Kokushibo", "color":Color(0.42,0.12,0.22), "accent":Color(0.86,0.55,0.28)}
]
const ARENAS = [
    {"name":"Valley of the End", "subtitle":"Final Naruto vs Sasuke battlefield", "floor":Color(0.16,0.24,0.28), "sky":Color(0.08,0.15,0.24)},
    {"name":"Sokyoku Hill", "subtitle":"Soul Society execution grounds", "floor":Color(0.34,0.31,0.29), "sky":Color(0.13,0.12,0.22)},
    {"name":"Monster Association", "subtitle":"Underground monster base", "floor":Color(0.19,0.16,0.20), "sky":Color(0.07,0.06,0.12)}
]

var selected_index := 0
var opponent_index := 1
var arena_index := 0
var player
var enemy
var player_health := 100.0
var enemy_health := 100.0
var round_number := 1
var match_started := false
var status_label: Label
var player_bar: ProgressBar
var enemy_bar: ProgressBar
var arena_root: Node3D
var ui: CanvasLayer
var buttons := {}

func _ready() -> void:
    _build_world()
    _build_ui()
    _show_selection()

func _build_world() -> void:
    var env := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_mat := ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = ARENAS[arena_index].sky
    sky_mat.sky_horizon_color = ARENAS[arena_index].sky.lightened(0.25)
    sky.sky_material = sky_mat
    environment.sky = sky
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.62,0.67,0.82)
    environment.ambient_light_energy = 0.7
    env.environment = environment
    add_child(env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -28, 0)
    sun.light_energy = 1.25
    add_child(sun)

    var camera := Camera3D.new()
    camera.position = Vector3(0, 7.5, 12.5)
    camera.look_at(Vector3(0, 1.0, 0), Vector3.UP)
    camera.fov = 48
    add_child(camera)

    arena_root = Node3D.new()
    arena_root.name = "Arena"
    add_child(arena_root)
    _create_arena_geometry()

func _create_arena_geometry() -> void:
    for child in arena_root.get_children():
        child.queue_free()
    var floor_mesh := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(22, 16)
    floor_mesh.mesh = plane
    floor_mesh.position.y = -0.08
    var floor_mat := StandardMaterial3D.new()
    floor_mat.albedo_color = ARENAS[arena_index].floor
    floor_mat.roughness = 0.92
    floor_mesh.material_override = floor_mat
    arena_root.add_child(floor_mesh)

    # Arena perimeter blocks create a distinct silhouette without heavy assets.
    for i in range(8):
        var pillar := MeshInstance3D.new()
        var box := BoxMesh.new()
        box.size = Vector3(1.0, randf_range(1.5, 4.0), 1.0)
        pillar.mesh = box
        var x := -9.0 + float(i) * 2.55
        pillar.position = Vector3(x, box.size.y * 0.5 - 0.05, -6.0)
        var mat := StandardMaterial3D.new()
        mat.albedo_color = ARENAS[arena_index].floor.darkened(0.25)
        pillar.material_override = mat
        arena_root.add_child(pillar)

    # Landmark structures vary by arena.
    if arena_index == 0:
        _add_landmark(Vector3(-7, 2.2, -4), Vector3(2.2, 4.4, 0.8), Color(0.32,0.43,0.48))
        _add_landmark(Vector3(7, 2.2, -4), Vector3(2.2, 4.4, 0.8), Color(0.32,0.43,0.48))
    elif arena_index == 1:
        _add_landmark(Vector3(0, 3.0, -5), Vector3(1.2, 6.0, 1.2), Color(0.55,0.46,0.36))
        _add_landmark(Vector3(-5, 1.3, -3), Vector3(3.0, 2.6, 1.0), Color(0.42,0.38,0.35))
    else:
        _add_landmark(Vector3(-6, 1.5, -4), Vector3(3.0, 3.0, 1.5), Color(0.30,0.24,0.34))
        _add_landmark(Vector3(6, 1.5, -4), Vector3(3.0, 3.0, 1.5), Color(0.30,0.24,0.34))

func _add_landmark(pos: Vector3, size: Vector3, color: Color) -> void:
    var item := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    item.mesh = mesh
    item.position = pos
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.8
    item.material_override = material
    arena_root.add_child(item)

func _build_ui() -> void:
    ui = CanvasLayer.new()
    add_child(ui)
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui.add_child(root)

    var title := Label.new()
    title.text = "ANIME FIGHTERS"
    title.position = Vector2(24, 12)
    title.add_theme_font_size_override("font_size", 28)
    root.add_child(title)

    status_label = Label.new()
    status_label.position = Vector2(24, 52)
    status_label.add_theme_font_size_override("font_size", 17)
    root.add_child(status_label)

    player_bar = _make_bar(root, Vector2(24, 92), Color(0.12,0.78,0.42))
    enemy_bar = _make_bar(root, Vector2(850, 92), Color(0.88,0.22,0.25))

    var select_panel := VBoxContainer.new()
    select_panel.name = "SelectPanel"
    select_panel.position = Vector2(24, 145)
    select_panel.custom_minimum_size = Vector2(330, 400)
    root.add_child(select_panel)
    var heading := Label.new()
    heading.text = "CHOOSE YOUR FIGHTER"
    heading.add_theme_font_size_override("font_size", 21)
    select_panel.add_child(heading)
    for i in range(CHARACTERS.size()):
        var b := Button.new()
        b.text = "%d. %s" % [i + 1, CHARACTERS[i].name]
        b.custom_minimum_size = Vector2(300, 44)
        b.pressed.connect(_choose_character.bind(i))
        select_panel.add_child(b)
    var arena_button := Button.new()
    arena_button.text = "CHANGE ARENA"
    arena_button.custom_minimum_size = Vector2(300, 42)
    arena_button.pressed.connect(_change_arena)
    select_panel.add_child(arena_button)
    var start_button := Button.new()
    start_button.text = "FIGHT!"
    start_button.custom_minimum_size = Vector2(300, 52)
    start_button.pressed.connect(_start_match)
    select_panel.add_child(start_button)

    _make_action_button(root, "MOVE LEFT", Vector2(24, 590), Vector2(125, 62), "left")
    _make_action_button(root, "MOVE RIGHT", Vector2(160, 590), Vector2(125, 62), "right")
    _make_action_button(root, "PUNCH", Vector2(860, 570), Vector2(110, 76), "punch")
    _make_action_button(root, "KICK", Vector2(980, 570), Vector2(110, 76), "kick")
    _make_action_button(root, "SPECIAL", Vector2(1100, 570), Vector2(150, 76), "special")
    _make_action_button(root, "GUARD", Vector2(980, 655), Vector2(110, 48), "guard")

func _make_bar(parent: Control, pos: Vector2, color: Color) -> ProgressBar:
    var bar := ProgressBar.new()
    bar.position = pos
    bar.size = Vector2(360, 24)
    bar.min_value = 0
    bar.max_value = 100
    bar.value = 100
    bar.show_percentage = false
    var fill := StyleBoxFlat.new()
    fill.bg_color = color
    bar.add_theme_stylebox_override("fill", fill)
    parent.add_child(bar)
    return bar

func _make_action_button(parent: Control, label: String, pos: Vector2, size: Vector2, action: String) -> void:
    var b := Button.new()
    b.text = label
    b.position = pos
    b.size = size
    b.add_theme_font_size_override("font_size", 16)
    b.pressed.connect(_action.bind(action))
    parent.add_child(b)
    buttons[action] = b

func _show_selection() -> void:
    status_label.text = "Select a character, choose one of 3 arenas, then start."
    _refresh_bars()

func _choose_character(index: int) -> void:
    selected_index = index
    status_label.text = "Selected: %s" % CHARACTERS[index].name

func _change_arena() -> void:
    arena_index = (arena_index + 1) % ARENAS.size()
    _create_arena_geometry()
    status_label.text = "Arena: %s" % ARENAS[arena_index].name

func _start_match() -> void:
    opponent_index = randi_range(0, CHARACTERS.size() - 1)
    while opponent_index == selected_index:
        opponent_index = randi_range(0, CHARACTERS.size() - 1)
    if is_instance_valid(player):
        player.queue_free()
    if is_instance_valid(enemy):
        enemy.queue_free()
    player = _spawn_fighter(CHARACTERS[selected_index], Vector3(-2.2, 0, 1.0), true)
    enemy = _spawn_fighter(CHARACTERS[opponent_index], Vector3(2.2, 0, -1.0), false)
    player_health = 100
    enemy_health = 100
    round_number = 1
    match_started = true
    status_label.text = "%s  VS  %s   |   %s" % [CHARACTERS[selected_index].name, CHARACTERS[opponent_index].name, ARENAS[arena_index].name]
    _refresh_bars()

func _spawn_fighter(data: Dictionary, pos: Vector3, is_player: bool):
    var f = FIGHTER_SCRIPT.new()
    f.setup(data.name, data.color, data.accent, is_player)
    add_child(f)
    f.position = pos
    return f

func _action(action: String) -> void:
    if not match_started:
        return
    if action == "left":
        player.position.x = clampf(player.position.x - 0.45, -7.0, 0.0)
    elif action == "right":
        player.position.x = clampf(player.position.x + 0.45, -0.5, 7.0)
    elif action == "guard":
        player.set_guard(true)
    else:
        var damage := 8.0
        if action == "kick":
            damage = 11.0
        elif action == "special":
            damage = 19.0
        enemy_health = maxf(0.0, enemy_health - damage)
        enemy.play_attack(action)
        if enemy_health <= 0:
            status_label.text = "%s WINS!" % CHARACTERS[selected_index].name
            match_started = false
        _refresh_bars()

func _refresh_bars() -> void:
    if is_instance_valid(player_bar):
        player_bar.value = player_health
        enemy_bar.value = enemy_health

func _process(delta: float) -> void:
    if not match_started:
        return
    if is_instance_valid(enemy) and is_instance_valid(player):
        var direction := signf(player.position.x - enemy.position.x)
        enemy.position.x += direction * delta * 0.7
        enemy.position.x = clampf(enemy.position.x, 0.5, 7.0)
        if randf() < delta * 0.35:
            player_health = maxf(0.0, player_health - randf_range(1.0, 3.0))
            _refresh_bars()
            if player_health <= 0:
                status_label.text = "%s WINS!" % CHARACTERS[opponent_index].name
                match_started = false

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_A or event.keycode == KEY_LEFT:
            _action("left")
        elif event.keycode == KEY_D or event.keycode == KEY_RIGHT:
            _action("right")
        elif event.keycode == KEY_J:
            _action("punch")
        elif event.keycode == KEY_K:
            _action("kick")
        elif event.keycode == KEY_L:
            _action("special")
