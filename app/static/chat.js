let chatOpen = false;

function toggleChat() {
    const chatWindow = document.getElementById('chat-window');
    chatWindow.classList.toggle('hidden');
    chatOpen = !chatOpen;
    if (chatOpen) {
        document.getElementById('chat-input').focus();
    }
}

function handleKeyPress(event) {
    if (event.key === 'Enter') {
        sendMessage();
    }
}

async function sendMessage() {
    const input = document.getElementById('chat-input');
    const message = input.value.trim();
    
    if (!message) return;
    
    // Afficher le message de l'utilisateur
    addMessage(message, 'user');
    input.value = '';
    
    // Désactiver l'input pendant l'envoi
    input.disabled = true;
    const button = input.nextElementSibling;
    button.disabled = true;
    
    // Afficher "typing..."
    const typingId = addMessage('Assistant tape...', 'assistant', true);
    
    try {
        const response = await fetch('/api/chat', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ message: message })
        });
        
        const data = await response.json();
        
        // Remplacer "typing..." par la réponse
        removeMessage(typingId);
        
        if (data.response) {
            // Si la réponse contient des sauts de ligne, les formater
            const formattedResponse = data.response.replace(/\n/g, '<br>');
            addMessageHTML(data.response, 'assistant');
        } else {
            addMessage('Erreur: Réponse invalide du serveur', 'assistant');
        }
    } catch (error) {
        removeMessage(typingId);
        addMessage('Erreur de connexion. Veuillez vérifier qu\'Ollama est démarré et réessayer.', 'assistant');
        console.error('Erreur:', error);
    } finally {
        // Réactiver l'input
        input.disabled = false;
        button.disabled = false;
        input.focus();
    }
}

function addMessage(text, sender, isTyping = false) {
    const messagesDiv = document.getElementById('chat-messages');
    const messageDiv = document.createElement('div');
    const id = 'msg-' + Date.now();
    messageDiv.id = id;
    messageDiv.className = `message ${sender}`;
    messageDiv.textContent = text;
    if (isTyping) {
        messageDiv.style.fontStyle = 'italic';
        messageDiv.style.opacity = '0.7';
    }
    messagesDiv.appendChild(messageDiv);
    messagesDiv.scrollTop = messagesDiv.scrollHeight;
    return id;
}

function addMessageHTML(html, sender) {
    const messagesDiv = document.getElementById('chat-messages');
    const messageDiv = document.createElement('div');
    const id = 'msg-' + Date.now();
    messageDiv.id = id;
    messageDiv.className = `message ${sender}`;
    // Utiliser innerHTML pour supporter les sauts de ligne
    messageDiv.innerHTML = html.replace(/\n/g, '<br>');
    messagesDiv.appendChild(messageDiv);
    messagesDiv.scrollTop = messagesDiv.scrollHeight;
    return id;
}

function removeMessage(id) {
    const msg = document.getElementById(id);
    if (msg) msg.remove();
}


