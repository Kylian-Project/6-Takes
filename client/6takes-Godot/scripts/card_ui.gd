extends Control

# Méthode pour assigner les données de la carte
func set_card_data(image_path):
	# Je Charge l’image depuis le chemin
	var texture = load(image_path)  
	if texture:
		# jaAssigne la texture au TextureRect enfant
		$TextureRect.texture = texture  
	else:
		print("❌ Erreur : Impossible de charger l'image", image_path)
