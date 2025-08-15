document.addEventListener('DOMContentLoaded', function() {
    const arenaMenu = document.getElementById('arenaMenu');
    const closeBtn = document.getElementById('closeBtn');
    const arenaCards = document.querySelectorAll('.arena-card');

    // Écouter les messages de FiveM
    window.addEventListener('message', function(event) {
        const data = event.data;
        
        if (data.action === 'openArenaMenu') {
            showMenu();
        } else if (data.action === 'closeArenaMenu') {
            hideMenu();
        }
    });

    // Afficher le menu
    function showMenu() {
        arenaMenu.classList.remove('hidden');
        document.body.style.overflow = 'hidden';
    }

    // Cacher le menu
    function hideMenu() {
        arenaMenu.classList.add('hidden');
        document.body.style.overflow = 'auto';
        
        // Envoyer message à FiveM pour fermer
        fetch(`https://pvp_pack/closeMenu`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({})
        });
    }

    // Sélectionner une arène
    function selectArena(arenaIndex) {
        console.log('Selecting arena:', arenaIndex); // Debug
        // Envoyer la sélection à FiveM
        fetch(`https://pvp_pack/selectArena`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                index: arenaIndex
            })
        }).then(response => {
            console.log('Arena selection sent successfully');
        }).catch(error => {
            console.error('Error sending arena selection:', error);
        });
        
        hideMenu();
    }

    // Event listeners
    closeBtn.addEventListener('click', hideMenu);

    arenaCards.forEach(card => {
        card.addEventListener('click', function() {
            const arenaIndex = parseInt(this.dataset.arena);
            selectArena(arenaIndex);
        });
    });

    // Fermer avec Échap
    document.addEventListener('keydown', function(event) {
        if (event.key === 'Escape') {
            hideMenu();
        }
    });

    // Empêcher la fermeture en cliquant sur le conteneur
    document.querySelector('.menu-container').addEventListener('click', function(event) {
        event.stopPropagation();
    });

    // Fermer en cliquant sur l'arrière-plan
    arenaMenu.addEventListener('click', hideMenu);
});
