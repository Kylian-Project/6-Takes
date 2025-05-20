<!DOCTYPE html>
<html>
<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<title>6 Takes !</title>
    <link rel="stylesheet" href="./css/styles.css">
    <link rel="stylesheet" href="./css/medias.css">
    <!-- icon -->
    <link rel="icon" href="./assets/img/favicon.png" type="image/png" sizes="16x16">
</head>
<body>
    <header>
        <section class="logo-section">
            <img id="playerIcon" src="./assets/img/player_icons/icon_blue.png" alt="Player Icon" />
        </section>

        <section class="title-section">
            <!-- <h1 class="title">6 Takes !</h1> -->
            <img src="./assets/img/title.png" alt="Game Logo" class="title" />
        </section>

        <section class="navigation-section">
            <nav class="navigation">
                <ul class="nav-list">
                    <li><a href="#countdown">Countdown</a></li>
                    <li><a href="#features">Features</a></li>
                    <li><a href="#gallery">Gallery</a></li>
                    <li><a href="#beta">Beta</a></li>
                    <li><a href="#contact">Contact</a></li>
                </ul>
            </nav>
        </section>
    </header>

    <main>
        <section class="countdown-section" id="countdown">
            <div class="back-img"></div>
            <div class="overlay">
                <h2>The adventure begins in:</h2>

                <div class="cubes">
                    <div class="cube cube1"><span id="days"></span>d</div>
                    <div class="cube cube2"><span id="hours"></span>h</div>
                    <div class="cube cube3"><span id="minutes"></span>m</div>
                    <div class="cube cube4"><span id="seconds"></span>s</div>
                </div>
            </div>
        </section>
        
        <section class="game-features-section" id="features">
            <h2>Game Features</h2>
            <div class="features-list">
                <div class="feature-item">
                    <img src="./assets/img/feature1.png" alt="Feature 1" class="feature-icon" />
                    <h3 style="color: #549b57;">Strategic Gameplay</h3>
                    <p>Master the art of card placement and outsmart your opponents.</p>
                </div>
                <div class="feature-item">
                    <img src="./assets/img/feature2.png" alt="Feature 2" class="feature-icon" />
                    <h3 style="color: #004e98;">Multiplayer Fun</h3>
                    <p>Challenge friends or compete with players worldwide.</p>
                </div>
                <div class="feature-item">
                    <img src="./assets/img/feature3.png" alt="Feature 3" class="feature-icon" />
                    <h3 style="color: #ba3737;">Quick To Learn</h3>
                    <p>Simple rules, deep strategy, endless entertainment.</p>
                </div>
            </div>
        </section>

        <section class="gallery-section" id="gallery">
            <h2>Our Gallery</h2>
            <div class="gallery-grid">
                <img src="./assets/img/gallery/gallery-1.png" alt="Gallery Image 1" class="gallery-image" />
                <img src="./assets/img/gallery/gallery-2.png" alt="Gallery Image 2" class="gallery-image" />
                <img src="./assets/img/gallery/gallery-3.png" alt="Gallery Image 3" class="gallery-image" />
                <img src="./assets/img/gallery/gallery-4.png" alt="Gallery Image 4" class="gallery-image" />
                <img src="./assets/img/gallery/gallery-5.png" alt="Gallery Image 5" class="gallery-image" />
                <img src="./assets/img/gallery/gallery-6.png" alt="Gallery Image 6" class="gallery-image" />
                <img src="./assets/img/gallery/gallery-7.png" alt="Gallery Image 7" class="gallery-image" />
                <img src="./assets/img/gallery/gallery-8.png" alt="Gallery Image 8" class="gallery-image" />
            </div>
            <!-- Overlay -->
            <div id="lightbox" class="lightbox">
                <span class="close">&times;</span>
                <img class="lightbox-content" id="lightbox-img" src="" alt="Large View" />
            </div>
        </section>

        <section class="beta-section" id="beta">
            <div class="container-beta">
                <h2>Try The Beta Version</h2>
                <p>Join our community of early players and help shape the future of 6 Takes!</p>
                <button class="beta-button"><img src="./assets/img/download-icon.png" alt="Download" class="download-icon"/>Download Beta</button>                         
            </div>
        </section>

        <section class="contact-section" id="contact">
            <div class="container">
              <h1><span class="blue">Your Feedback</span> Shapes <span class="red">the Game</span></h1>
          
              <div class="form-box">
                <p class="label">What would you like to share?</p>
                <div class="button-group">
                    <button class="option active" data-type="suggestion">✨ Improvement</button>
                    <button class="option redback" data-type="bug">🐞 Bug Report</button>
                </div>
          
                <label for="message" class="label">Your Message</label>
                <textarea id="message" placeholder="Share your thoughts with us..."></textarea>

                <label for="screenshot" class="label">Attach a Screenshot (2MB max.)</label>
                <input type="file" id="screenshot" accept="image/*" class="file-input" />

                <input type="text" id="name" name="name" placeholder="Name" class="hidden" />
                
                <input type="hidden" id="type" name="type" value="suggestion" />

                <button class="submit">Submit Feedback</button>

                <div id="spinner" style="display: none; text-align: center; margin-top: 10px;">
                    <img src="./assets/img/spinner.gif" alt="Chargement..." width="50">
                </div>
                
              </div>
            </div>
        </section>

        <div id="beta-toast" class="beta-toast hidden">
            🚧 La version beta n'est pas encore disponible.
        </div>

    </main>

    <footer>
        <p>&copy; 2025 6 Takes! Game</p>
    </footer>

</body>
</html>
<script src="./js/script.js"></script>