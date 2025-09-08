<template>
  <div>
    <!-- Overlay -->
    <div v-if="showChat" class="overlay" @click="toggleChat"></div>

    <!-- Conteneur principal -->
    <div class="chat-container">
      <button @click="toggleChat">{{ showChat ? '❌' : '🤖' }} </button>

      <div v-if="showChat" class="chat-box">
        <div class="messages" ref="messages">
          <div
            v-for="(msg, index) in chatMessages"
            :key="index"
            :class="['msg', msg.sender]"
          >
            <div v-if="msg.type === 'text'" v-html="msg.text"></div>

            <div v-else-if="msg.type === 'image'">
              <img
                :src="msg.url"
                alt="Image générée"
                style="max-width: 100%; border-radius: 10px;"
              />
              <button
                class="download-btn"
                @click="downloadImage(msg.url, msg.prompt)"
              >
                📥 Télécharger l'image
              </button>
            </div>
          </div>
        </div>

        <div class="input-container">
          <input
            type="text"
            v-model="userInput"
            @keyup.enter="sendMessage"
            placeholder="Génération par mots-clés"
            :disabled="loading"
          />
          <button @click="sendMessage" :disabled="loading || !userInput.trim()">
            Générer
          </button>
        </div>

        <div v-if="loading" class="loading">⏳ Génération en cours...</div>
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
      loading: false,
    };
  },
  methods: {
    toggleChat() {
      this.showChat = !this.showChat;
    },
    addMessage(sender, content, type = 'text', prompt = '') {
      this.chatMessages.push({
        sender,
        text: content,
        type,
        url: content,
        prompt,
      });

      this.$nextTick(() => {
        const container = this.$refs.messages;
        if (container) container.scrollTop = container.scrollHeight;
      });
    },
    async sendMessage() {
      const text = this.userInput.trim();
      if (!text || this.loading) return;

      this.addMessage('user', text);
      this.userInput = '';
      this.loading = true;

      try {
        const apiKey = process.env.VUE_APP_HORDE_API_KEY;

        const submissionResponse = await fetch(
          'https://stablehorde.net/api/v2/generate/async',
          {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              apikey: apiKey,
              'Client-Agent': 'vue-image-bot/1.0',
            },
            body: JSON.stringify({
              prompt: text,
              params: {
                n: 1,
                width: 512,
                height: 512,
                steps: 25,
                sampler_name: 'k_euler',
              },
              nsfw: false,
              trusted_workers: false,
            }),
          }
        );

        const submissionData = await submissionResponse.json();
        const requestId = submissionData.id;

        let done = false;
        let imageUrl = '';

        while (!done) {
          await new Promise((r) => setTimeout(r, 3000));

          const checkResponse = await fetch(
            `https://stablehorde.net/api/v2/generate/status/${requestId}`,
            {
              headers: {
                apikey: '0000000000',
                'Client-Agent': 'vue-image-bot/1.0',
              },
            }
          );

          const checkData = await checkResponse.json();
          done = checkData.done;

          if (done) {
            const img = checkData.generations[0];
            imageUrl = img.img;
          }
        }

        this.addMessage('bot', imageUrl, 'image', text);
      } catch (error) {
        this.addMessage('bot', 'Erreur lors de la generation de l\'image.');
        console.error(error);
      } finally {
        this.loading = false;
      }
    },
    async downloadImage(url, prompt) {
      try {
        const response = await fetch(url);
        const blob = await response.blob();

        const safePrompt = prompt
          .toLowerCase()
          .replace(/[^a-z0-9\s]/gi, '')
          .trim()
          .replace(/\s+/g, '_')
          .slice(0, 40);

        const dateStr = new Date().toISOString().slice(0, 19).replace(/[:T]/g, '-');
        const filename = `image_${safePrompt}_${dateStr}.png`;

        if (window.showSaveFilePicker) {
          try {
            const fileHandle = await window.showSaveFilePicker({
              suggestedName: filename,
              types: [{
                description: 'Images PNG',
                accept: {'image/png': ['.png']}
              }]
            });
            const writable = await fileHandle.createWritable();
            await writable.write(blob);
            await writable.close();
            return;
          } catch (e) {
            // L'utilisateur a annulé ou erreur, continuer avec la méthode classique
          }
        }

        const blobUrl = window.URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.style.display = 'none';
        link.href = blobUrl;
        link.download = filename;
        link.rel = 'noopener';
        
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        
        setTimeout(() => {
          window.URL.revokeObjectURL(blobUrl);
        }, 1000);
        
      } catch (error) {
        console.error('Erreur lors du téléchargement de l\'image :', error);
        alert('Le téléchargement de l\'image a échoué.');
      }
    },
  },
};
</script>

<style scoped>
.overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background: rgba(0, 0, 0, 0.6);
  z-index: 999;
}

.chat-container {
  position: fixed;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  z-index: 1000;
  width: 350px;
}

.chat-container > button {
  width: 60px;
  height: 60px;
  padding: 0;
  font-size: 24px;
  background-color: #007bff;
  color: white;
  border: none;
  border-radius: 50%;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
}

.chat-box {
  margin-top: 20px;
  border-radius: 16px;
  width: 100%;
  height: 500px;
  border: none;
  padding: 20px;
  background: #f8fafc;
  display: flex;
  flex-direction: column;
  box-shadow: 0 4px 24px rgba(0, 0, 0, 0.1);
}

.messages {
  flex: 1;
  overflow-y: auto;
  margin-bottom: 10px;
  display: flex;
  flex-direction: column;
}

.input-container {
  display: flex;
  align-items: center;
  gap: 12px;
  width: 100%;
  background: #f1f5f9;
  padding: 8px;
  border-radius: 12px;
}

input[type='text'] {
  flex: 1;
  padding: 12px 16px;
  font-size: 16px;
  border: none;
  border-radius: 8px;
  background: transparent;
  color: #64748b;
  outline: none;
  font-weight: 400;
}

input[type='text']::placeholder {
  color: #94a3b8;
  font-weight: 400;
}

input[type='text']:disabled {
  color: #94a3b8;
  cursor: not-allowed;
}

button {
  padding: 12px 24px;
  font-size: 16px;
  font-weight: 500;
  border: none;
  border-radius: 12px;
  background: #8b5cf6;
  color: white;
  cursor: pointer;
  transition: all 0.2s ease;
  white-space: nowrap;
}

button:hover:not(:disabled) {
  background: #7c3aed;
}

button:disabled {
  background: #d1d5db;
  color: #9ca3af;
  cursor: not-allowed;
}

.download-btn {
  margin-top: 8px;
  padding: 6px 12px;
  background-color: #28a745;
  color: white;
  border-radius: 8px;
  border: none;
  cursor: pointer;
  font-size: 13px;
  transition: background-color 0.2s ease;
}

.download-btn:hover {
  background-color: #218838;
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
  display: flex;
  flex-direction: column;
}

.user {
  background-color: #0084ff;
  color: white;
  align-self: flex-end;
}

.bot {
  background-color: #e5e5ea;
  color: black;
  align-self: flex-start;
}

.loading {
  text-align: center;
  font-weight: bold;
  color: #333;
  margin-top: 8px;
}
</style>

<style>
body {
  margin: 0;
  padding: 0;
  background-color: #6a0dad;
  font-family: sans-serif;
}
</style>