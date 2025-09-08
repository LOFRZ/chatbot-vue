# Utiliser une image Node.js officielle
FROM node:18-alpine

# Définir le répertoire de travail
WORKDIR /app

# Copier les fichiers package.json et package-lock.json
COPY package*.json ./

# Installer les dépendances
RUN npm ci

# Copier le code de l'application
COPY . .

# Construire l'application pour la production
RUN npm run build

# Utiliser nginx pour servir l'application
FROM nginx:alpine
COPY --from=0 /app/dist /usr/share/nginx/html

# Copier la configuration nginx personnalisée (optionnel)
# COPY nginx.conf /etc/nginx/nginx.conf

# Exposer le port
EXPOSE 80

# Commande par défaut de nginx
CMD ["nginx", "-g", "daemon off;"]