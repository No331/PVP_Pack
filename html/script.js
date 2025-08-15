document.addEventListener('DOMContentLoaded', function() {
    const arenaMenu = document.getElementById('arenaMenu');
    const closeBtn = document.getElementById('closeBtn');
    const arenaCards = document.querySelectorAll('.arena-card');

    console.log('PVP Script loaded, found', arenaCards.length, 'arena cards');

    // Fonction pour obtenir le nom de la ressource
    function GetParentResourceName() {
        return 'pvp_pack'; // Nom fixe de votre ressource
    }

    // Écouter les messages de FiveM
    window.addEventListener('message', function(event) {
        const data = event.data;
        console.log('Received message from FiveM:', data);
        
        if (data.action === 'openArenaMenu') {
            console.log('Opening arena menu with arenas:', data.arenas);
            showMenu();
        } else if (data.action === 'closeArenaMenu') {
            console.log('Closing arena menu');
            hideMenu();
        }
    });

    // Afficher le menu
    function showMenu() {
        console.log('Showing arena menu');
        arenaMenu.classList.remove('hidden');
        document.body.style.overflow = 'hidden';
    }

    // Cacher le menu
    function hideMenu() {
        console.log('Hiding arena menu');
        arenaMenu.classList.add('hidden');
        document.body.style.overflow = 'auto';
        
        // Envoyer message à FiveM pour fermer
        fetch(`https://${GetParentResourceName()}/closeMenu`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({})
        }).then(response => {
            console.log('Close menu response:', response);
        }).catch(error => {
            console.error('Error closing menu:', error);
        });
    }

    // Sélectionner une arène
    function selectArena(arenaIndex) {
        console.log('Attempting to select arena:', arenaIndex);
        
        // Validation de l'index
        if (!arenaIndex || arenaIndex < 1 || arenaIndex > 4) {
            console.error('Invalid arena index:', arenaIndex);
            return;
        }
        
        console.log('Sending arena selection to FiveM...');
        
        // Envoyer la sélection à FiveM
        fetch(`https://${GetParentResourceName()}/selectArena`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                index: parseInt(arenaIndex)
            })
        }).then(response => {
            console.log('Arena selection response status:', response.status);
            return response.text();
        }).then(data => {
            console.log('Arena selection response data:', data);
            hideMenu();
        }).catch(error => {
            console.error('Error sending arena selection:', error);
            // Essayer de fermer le menu même en cas d'erreur
            hideMenu();
        });
    }

    // Event listener pour le bouton fermer
    if (closeBtn) {
        closeBtn.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            console.log('Close button clicked');
            hideMenu();
        });
    }

    // Ajouter les event listeners aux cartes d'arène
    arenaCards.forEach((card, index) => {
        const arenaIndex = parseInt(card.dataset.arena);
        console.log('Setting up card', index, 'with arena index:', arenaIndex);
        
        // Event listener sur la carte entière
        card.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            console.log('Arena card clicked:', arenaIndex);
            selectArena(arenaIndex);
        });
        
        // Event listener spécifique sur le bouton rejoindre
        const joinBtn = card.querySelector('.join-btn');
        if (joinBtn) {
            joinBtn.addEventListener('click', function(e) {
                e.preventDefault();
                e.stopPropagation();
                console.log('Join button clicked for arena:', arenaIndex);
                selectArena(arenaIndex);
            });
        }
    });

    // Fermer avec Échap
    document.addEventListener('keydown', function(event) {
        if (event.key === 'Escape') {
            console.log('Escape key pressed');
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
            console.log('Background clicked');
            hideMenu();
        }
    });

    console.log('All event listeners added successfully');
});