extends RefCounted
class_name GameSprites
## Loads PNG textures via the Godot import pipeline (CompressedTexture2D).


static func load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	# Imported textures (after .import exists).
	if ResourceLoader.exists(path):
		var res: Resource = load(path)
		if res is Texture2D:
			return res as Texture2D
	# Fallback for files not yet imported (or broken import cache).
	var img := Image.new()
	var err := img.load(path)
	if err == OK:
		return ImageTexture.create_from_image(img)
	push_warning("GameSprites: cannot load %s (err %d)" % [path, err])
	return null


static func sheet_frame_rect(col: int, row: int, frame_size: int = 32) -> Rect2:
	return Rect2(col * frame_size, row * frame_size, frame_size, frame_size)
