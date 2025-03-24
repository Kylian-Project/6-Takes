extends Control
class_name CardVbox  # ou class_name CardUI selon le fichier

func set_card_data(image_path):
	var texture = load(image_path)  
	if texture:
		$TextureRect.texture = texture  
	else:
		print("❌ Erreur : Impossible de charger l'image", image_path)
