document.addEventListener('DOMContentLoaded', function() {
    const arenaMenu = document.getElementById('arenaMenu');
    const closeBtn = document.getElementById('closeBtn');
    const arenaCards = document.querySelectorAll('.arena-card');

    console.log('Script loaded, found', arenaCards.length, 'arena cards');

    // Fonction pour obtenir le nom de la ressource
    function GetParentResourceName() {
        return window.location.hostname;
    }

    // Écouter les messages de FiveM
    window.addEventListener('message', function(event) {
        const data = event.data;
        console.log('Received message:', data);
        
        if (data.action === 'openArenaMenu') {
            console.log('Opening arena menu');
            showMenu();
        } else if (data.action === 'closeArenaMenu') {
            console.log('Closing arena menu');
            hideMenu();
        }
    });

    // Afficher le menu
    function showMenu() {
        console.log('Showing menu');
        arenaMenu.classList.remove('hidden');
        document.body.style.overflow = 'hidden';
    }

    // Cacher le menu
    function hideMenu() {
        console.log('Hiding menu');
        arenaMenu.classList.add('hidden');
        document.body.style.overflow = 'auto';
        
        // Envoyer message à FiveM pour fermer
        fetch(`https://${GetParentResourceName()}/closeMenu`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({})
        }).catch(error => {
            console.error('Error closing menu:', error);
        });
    }

    // Sélectionner une arène
    function selectArena(arenaIndex) {
        console.log('Selecting arena:', arenaIndex);
        
        // Envoyer la sélection à FiveM
        fetch(`https://${GetParentResourceName()}/selectArena`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                index: arenaIndex
            })
        }).then(response => {
            console.log('Arena selection sent successfully');
            hideMenu();
        }).catch(error => {
            console.error('Error sending arena selection:', error);
        });
    }

    // Event listeners
    if (closeBtn) {
        closeBtn.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            hideMenu();
        });
    }

    // Ajouter les event listeners aux cartes d'arène
    arenaCards.forEach((card, index) => {
        console.log('Adding listener to card', index + 1);
        card.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            const arenaIndex = parseInt(this.dataset.arena);
            console.log('Card clicked, arena index:', arenaIndex);
            selectArena(arenaIndex);
        });
        
        // Ajouter aussi un listener sur le bouton play
        const playBtn = card.querySelector('.arena-play-btn');
        if (playBtn) {
            playBtn.addEventListener('click', function(e) {
                e.preventDefault();
                e.stopPropagation();
                const arenaIndex = parseInt(card.dataset.arena);
                console.log('Play button clicked, arena index:', arenaIndex);
                selectArena(arenaIndex);
            });
        }
    });

    // Fermer avec Échap
    document.addEventListener('keydown', function(event) {
        if (event.key === 'Escape') {
            hideMenu();
        }
    });

    // Empêcher la fermeture en cliquant sur le conteneur
    const menuContainer = document.querySelector('.menu-container');
    if (menuContainer) {
        menuContainer.addEventListener('click', function(event) {
            event.stopPropagation();
        });
    }

    // Fermer en cliquant sur l'arrière-plan
    arenaMenu.addEventListener('click', function(e) {
        if (e.target === arenaMenu) {
            hideMenu();
        }
    });

    console.log('All event listeners added');
});