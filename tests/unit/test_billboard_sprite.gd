extends GutTest


func test_billboard_face_picks_row() -> void:
	var s := BillboardSprite.new()
	var img := Image.create(144, 256, false, Image.FORMAT_RGBA8)
	s.set_sheet(ImageTexture.create_from_image(img))
	var cases := {Vector2(0, 1): 0, Vector2(-1, 0): 1, Vector2(1, 0): 2, Vector2(0, -1): 3}
	for dir in cases:
		s.face(dir)
		assert_eq(s.row, cases[dir], str(dir))
		assert_eq(s.frame / s.hframes, cases[dir])
	s.free()


func test_diagonal_prefers_horizontal() -> void:
	var s := BillboardSprite.new()
	s.face(Vector2(0.8, 0.6))
	assert_eq(s.row, 2)
	s.free()


func test_zero_dir_keeps_row() -> void:
	var s := BillboardSprite.new()
	s.face(Vector2(-1, 0))
	s.face(Vector2.ZERO)
	assert_eq(s.row, 1)
	s.free()


func test_billboard_settings() -> void:
	var s := BillboardSprite.new()
	assert_eq(s.billboard, BaseMaterial3D.BILLBOARD_FIXED_Y)
	assert_eq(s.texture_filter, BaseMaterial3D.TEXTURE_FILTER_NEAREST)
	assert_eq(s.alpha_cut, SpriteBase3D.ALPHA_CUT_DISCARD)
	assert_true(s.shaded)
	s.free()
