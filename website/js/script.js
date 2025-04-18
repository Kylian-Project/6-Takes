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
    const endDate = new Date("May 18, 2025 00:00:00").getTime();
    const now = new Date().getTime();
    const timeLeft = endDate - now;

    if (timeLeft <= 0) {
        document.getElementById("countdown").innerHTML = "🎉 Le jeu est sorti !";
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
const options = document.querySelectorAll('.option');

options.forEach(btn => {
    btn.addEventListener('click', () => {
        // Retire "active" de tous les boutons
        options.forEach(b => b.classList.remove('active'));
        // Ajoute "active" au bouton cliqué
        btn.classList.add('active');
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
