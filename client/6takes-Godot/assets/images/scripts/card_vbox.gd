extends Control
class_name CardVbox

# Méthode pour assigner les données de la carte
func set_card_data(image_path):
	# Je charge l’image depuis le chemin
	var texture = load(image_path)  
	if texture:
		# J'assigne la texture au TextureRect enfant
		$TextureRect.texture = texture  
	else:
		print("❌ Erreur : Impossible de charger l'image", image_path)
