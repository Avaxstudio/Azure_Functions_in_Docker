# Baza: Azure Functions Node.js runtime (verzija 4, Node 20)
FROM mcr.microsoft.com/azure-functions/node:4-node20

# Instaliraj FFmpeg
RUN apt-get update && \
    apt-get install -y ffmpeg && \
    rm -rf /var/lib/apt/lists/*

# Postavi radni direktorijum
WORKDIR /home/site/wwwroot

# Kopiraj package.json i instaliraj zavisnosti
COPY package*.json ./
RUN npm install --only=production

# Kopiraj ostatak koda (index.js, function.json, itd.)
COPY . .

# Azure Functions runtime će automatski startovati funkciju
