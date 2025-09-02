<template>
  <div>
    <!-- Overlay -->
    <div v-if="showChat" class="overlay" @click="toggleChat"></div>

    <!-- Conteneur principal -->
    <div class="chat-container">
      <button @click="toggleChat">{{ showChat ? '❌' : '' }} 🤖</button>

      <div v-if="showChat" class="chat-box">
        <div class="messages" ref="messages">
          <div v-for="(msg, index) in chatMessages" :key="index" :class="['msg', msg.sender]">
            {{ msg.text }}
          </div>
        </div>
        <input
          type="text"
          v-model="userInput"
          @keyup.enter="sendMessage"
          placeholder="Écris un message..."
        />
      </div>
    </div>
  </div>
</template>


<script>
export default {
  data() {
    return {
      showChat: false,
      userInput: '',
      chatMessages: [],
    };
  },
  methods: {
    toggleChat() {
      this.showChat = !this.showChat;
    },
    addMessage(sender, text) {
      this.chatMessages.push({ sender, text });
      this.$nextTick(() => {
        const container = this.$refs.messages;
        container.scrollTop = container.scrollHeight;
      });
    },
    async sendMessage() {
      const text = this.userInput.trim();
      if (!text) return;

      this.addMessage('user', text);
      this.userInput = '';

      try {
        const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${process.env.VUE_APP_GROQ_API_KEY}`
          },
          body: JSON.stringify({
            model: 'llama-3.3-70b-versatile',
            messages: [{ role: 'user', content: text }]
          })
        });

        const data = await response.json();
        const reply = data.choices?.[0]?.message?.content || '🤖 Je n’ai pas de réponse.';
        this.addMessage('bot', reply);
      } catch (error) {
        this.addMessage('bot', '❌ Erreur lors de la requête à l’API.');
        console.error(error);
      }
    }
  }
};
</script>

<style scoped>

.overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background: rgba(0, 0, 0, 0.6); /* noir semi-transparent */
  z-index: 999;
}

.chat-container {
  position: fixed;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  z-index: 1000; /* au-dessus de l'overlay */
}


.chat-container > button {
  width: 60px;
  height: 60px;
  padding: 0;
  font-size: 24px;
  background-color: #007bff;
  color: white;
  border: none;
  border-radius: 50%; /* bouton parfaitement rond */
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
}


.chat-box {
  margin-top: 20px; /* espace entre le bouton et la box */
  border-radius: 12px;
  width: 300px;
  height: 400px;
  border: 1px solid #ccc;
  padding: 10px;
  background: #d1d1d1;
  display: flex;
  flex-direction: column;
}

.messages {
  flex: 1;
  overflow-y: auto;
  margin-bottom: 10px;
  display: flex;
  flex-direction: column;
}


input[type="text"] {
  padding: 8px 15px;
  font-size: 14px;
  width: 90%;
  margin: 0 auto;
  display: block;
  border-radius: 25px;
  border: 1px solid #ccc;
  box-sizing: border-box;
  height: 36px;
  background-color: #f0f0f0; /* gris très clair */
  color: #333;               /* texte un peu plus foncé pour le contraste */
}


.msg {
  max-width: 70%;
  padding: 10px 15px;
  margin: 8px 0;
  border-radius: 20px;
  position: relative;
  word-wrap: break-word;
  font-size: 14px;
  line-height: 1.3;
}

.msg {
  max-width: 70%;
  padding: 10px 15px;
  margin: 8px 0;
  border-radius: 20px;
  position: relative;
  word-wrap: break-word;
  font-size: 14px;
  line-height: 1.3;
}

/* Bulles utilisateur (droite) */
.user {
  background-color: #0084ff; /* bleu Messenger */
  color: white;
  align-self: flex-end; /* aligné à droite */
  position: relative;
}

/* Triangle à droite avec la couleur actuelle */


/* Bulles bot (gauche) */
.bot {
  background-color: #e5e5ea; /* gris clair */
  color: black;
  align-self: flex-start; /* aligné à gauche */
  position: relative;
}

/* Triangle à gauche avec la couleur actuelle */



</style>

<style>
body {
  margin: 0;
  padding: 0;
  background-color: #6a0dad; /* Violet */
  font-family: sans-serif;
}
</style>
