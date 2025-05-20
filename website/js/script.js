const iconList = [
    "icon_blue.png",
    "icon_brown.png",
    "icon_cyan.png",
    "icon_darkgray.png",
    "icon_green.png",
    "icon_orange.png",
    "icon_pink.png",
    "icon_purple.png",
    "icon_red.png"
];

let lastIndex = -1;

function randomizePlayerIcon() {
    let randomIndex;
    do {
        randomIndex = Math.floor(Math.random() * iconList.length);
    } while (randomIndex === lastIndex);
    
    lastIndex = randomIndex;
    const iconFile = iconList[randomIndex];
    const iconPath = `./assets/img/player_icons/${iconFile}`;

    const playerIcon = document.getElementById("playerIcon");
    
    // Ajout d'une classe d'animation temporaire
    playerIcon.classList.remove("spin-fade"); // reset si déjà présente
    void playerIcon.offsetWidth; // forcer le reflow pour relancer l'anim
    playerIcon.classList.add("spin-fade");

    playerIcon.src = iconPath;
}

window.onload = randomizePlayerIcon;
document.getElementById("playerIcon").addEventListener("click", randomizePlayerIcon);


function updateCountdown() {
    const endDate = new Date("May 21, 2025 00:00:00").getTime();
    const now = new Date().getTime();
    const timeLeft = endDate - now;

    if (timeLeft <= 0) {
        // Afficher le message et le bouton de lancement du jeu (nouvel onglet)
        document.getElementById("countdown").innerHTML = `
            <div class="back-img"></div>
            <div class="overlay">
                <h2>The game is now available..</h2>
                <div class="game-launch-btns">
                  <button id="launchGameBtn" class="launch-btn">Launch the Game</button>
                </div>
            </div>
        `;
        setTimeout(() => {
            const launchBtn = document.getElementById('launchGameBtn');
            if (launchBtn) {
                launchBtn.addEventListener('click', function() {
                    window.open('./game/index.html', '_blank');
                });
            }
        }, 100);
        clearInterval(timerInterval);
        return;
    }

    const days = Math.floor(timeLeft / (1000 * 60 * 60 * 24));
    const hours = Math.floor((timeLeft % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
    const minutes = Math.floor((timeLeft % (1000 * 60 * 60)) / (1000 * 60));
    const seconds = Math.floor((timeLeft % (1000 * 60)) / 1000);

    document.getElementById("days").textContent = days;
    document.getElementById("hours").textContent = hours;
    document.getElementById("minutes").textContent = minutes;
    document.getElementById("seconds").textContent = seconds;
}

// Mettre à jour toutes les secondes
const timerInterval = setInterval(updateCountdown, 1000);

// Mise à jour immédiate au chargement
updateCountdown();



// Sélectionne les boutons de type
document.querySelectorAll('.option').forEach(button => {
    button.addEventListener('click', function () {
        // Enlever la classe 'active' de tous les boutons
        document.querySelectorAll('.option').forEach(btn => btn.classList.remove('active'));
        // Ajouter la classe 'active' au bouton sélectionné
        this.classList.add('active');

        // Mettre à jour la valeur du champ caché 'type'
        const type = this.getAttribute('data-type');
        document.getElementById('type').value = type;
    });
});

// Animation du bouton Submit
const submitBtn = document.querySelector('.submit');
submitBtn.addEventListener('click', () => {
    // Ajoute une petite animation d'échelle
    submitBtn.style.transform = 'scale(0.95)';
    submitBtn.style.transition = 'transform 0.1s ease';

    setTimeout(() => {
        submitBtn.style.transform = 'scale(1)';
    }, 150);
});


// Changer la taille de body en fonction de l'addition de header + main + footer et actualiser quand la fenêtre est redimensionnée
function adjustBodyHeight() {
    const headerHeight = document.querySelector('header').offsetHeight;
    const mainHeight = document.querySelector('main').offsetHeight;
    const footerHeight = document.querySelector('footer').offsetHeight;

    const totalHeight = headerHeight + mainHeight + footerHeight;

    document.body.style.height = `${totalHeight}px`;
}
window.addEventListener('resize', adjustBodyHeight);
window.addEventListener('load', adjustBodyHeight);
adjustBodyHeight();



const images = document.querySelectorAll('.gallery-image');
const lightbox = document.getElementById('lightbox');
const lightboxImg = document.getElementById('lightbox-img');
const closeBtn = document.querySelector('.lightbox .close');

images.forEach(img => {
    img.addEventListener('click', () => {
        lightboxImg.src = img.src;
        lightbox.classList.add('active');
        // Overflow y hidden pour éviter le scroll de la page sur html
        document.documentElement.style.overflowY = 'hidden';
    });
});

const closeLightbox = () => {
    lightbox.classList.remove('active');
    // Réinitialiser l'overflow y pour permettre le scroll de la page
    document.documentElement.style.overflowY = 'initial';
};

closeBtn.addEventListener('click', closeLightbox);

lightbox.addEventListener('click', (e) => {
    if (e.target === lightbox) {
        closeLightbox();
    }
});

// Beta message
// Affiche un message lorsque le bouton "Beta" est cliqué
const betaButton = document.querySelector('.beta-button');
const toast = document.getElementById('beta-toast');

betaButton.addEventListener('click', (e) => {
    e.preventDefault();

    toast.classList.remove('hidden');
    toast.classList.add('show');

    // Cache le toast après 3 secondes
    setTimeout(() => {
        toast.classList.remove('show');
        // petit délai pour permettre la transition de sortie
        setTimeout(() => {
            toast.classList.add('hidden');
        }, 400);
    }, 3000);
});


// Formulaire via ajax
document.querySelector('.submit').addEventListener('click', async function () {
    const message = document.getElementById('message').value;
    const screenshot = document.getElementById('screenshot').files[0];
    const formBox = document.querySelector('.form-box');
    const spinner = document.getElementById('spinner'); // Le spinner
    const submitButton = document.querySelector('.submit'); // Le bouton d'envoi
    const type = document.getElementById('type').value;

    // Si aucun message, on affiche un message d'alerte
    if (!message) {
        alert("Please enter a message.");
        return;
    }

    // Si le message est trop long, on affiche un message d'alerte
    if (message.length > 500) {
        alert("Message too long. Please limit to 500 characters.");
        return;
    }

    // Si le message est trop court, on affiche un message d'alerte
    if (message.length < 10) {
        alert("Message too short. Please enter at least 10 characters.");
        return;
    }

    const name = document.getElementById('name').value;
    if (name) {
        alert("Error. Please try again.");
        return;
    }

    // Vérifier la taille de l'image si elle est fournie
    if (screenshot && screenshot.size > 2 * 1024 * 1024) { // 2 Mo max
        alert("Image too large. Please limit to 2MB.");
        return;
    }

    const formData = new FormData();
    formData.append('type', type);
    formData.append('message', message);
    if (screenshot) {
        formData.append('screenshot', screenshot);
    }

    try {
        spinner.style.display = 'block';
        spinner.classList.add('fade-in');

        // ➔ Désactivation du bouton "submit"
        submitButton.disabled = true;
        submitButton.style.display = 'none';

        const response = await fetch('../php/submit_feedback.php', {
            method: 'POST',
            body: formData
        });

        const result = await response.json();

        // ➔ Une fois la réponse, on cache le spinner avec animation
        spinner.classList.remove('fade-in');
        spinner.classList.add('fade-out');

        setTimeout(() => {
            spinner.style.display = 'none'; // Cacher le spinner après l'animation
        }, 500);

        // ➔ Réaction au résultat du serveur
        if (result.success) {
            // Reset le formulaire proprement AVANT
            document.getElementById('message').value = '';
            document.getElementById('screenshot').value = '';

            // Afficher le message de remerciement
            formBox.innerHTML = `
                <div class="thank-you-message">
                    <h2>Thank you for your feedback! 🎉</h2>
                    <p>We appreciate your help in making 6 Takes even better!</p>
                </div>
            `;
        } else {
            alert('Error: ' + result.error);
        }
    } catch (error) {
        // En cas d'erreur, cacher le spinner et afficher l'alerte
        spinner.style.display = 'none';
        alert('Error sending feedback.');
    } finally {
        // Réactiver le bouton "submit" à la fin
        submitButton.disabled = false;
        submitButton.style.display = 'block';
    }
});


document.addEventListener('DOMContentLoaded', () => {
    document.body.classList.add('loaded');
    document.getElementById('message').value = '';
    document.getElementById('screenshot').value = '';
    // Réinitialiser le type à suggestion par défaut
    document.getElementById('type').value = 'suggestion';
});
