extends Node3D

var fighter_name := ""
var body_color := Color.WHITE
var accent_color := Color.BLACK
var is_player := false
var guard_active := false
var body_mesh: MeshInstance3D

func setup(name: String, main_color: Color, detail_color: Color, player_side: bool) -> void:
    fighter_name = name
    body_color = main_color
    accent_color = detail_color
    is_player = player_side
    _build_model()

func _build_model() -> void:
    var body := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.42
    capsule.height = 1.65
    body.mesh = capsule
    body.position.y = 1.0
    var material := StandardMaterial3D.new()
    material.albedo_color = body_color
    material.roughness = 0.72
    body.material_override = material
    add_child(body)
    body_mesh = body

    var head := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.34
    sphere.height = 0.68
    head.mesh = sphere
    head.position.y = 2.05
    var head_mat := StandardMaterial3D.new()
    head_mat.albedo_color = accent_color
    head.material_override = head_mat
    add_child(head)

    var belt := MeshInstance3D.new()
    var belt_mesh := BoxMesh.new()
    belt_mesh.size = Vector3(0.88, 0.18, 0.48)
    belt.mesh = belt_mesh
    belt.position.y = 0.85
    var belt_mat := StandardMaterial3D.new()
    belt_mat.albedo_color = accent_color
    belt.material_override = belt_mat
    add_child(belt)

    var label := Label3D.new()
    label.text = fighter_name
    label.position = Vector3(0, 2.65, 0)
    label.font_size = 32
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    add_child(label)

func set_guard(active: bool) -> void:
    guard_active = active
    if body_mesh:
        body_mesh.scale = Vector3(1.12, 1.0, 1.12) if active else Vector3.ONE

func play_attack(kind: String) -> void:
    if body_mesh:
        body_mesh.rotation.z = 0.22 if kind == "punch" else -0.22
        await get_tree().create_timer(0.18).timeout
        if is_instance_valid(body_mesh):
            body_mesh.rotation.z = 0.0
