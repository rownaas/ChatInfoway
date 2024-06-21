#!/bin/bash

echo "Configuração do ambiente"

# Perguntar qual ambiente configurar
read -p "Qual ambiente deseja configurar? (frontend, backend, banco ou tudo): " ENVIRONMENT

configure_frontend() {
    echo "Configurando Frontend..."
    cd ./frontend
    
    # Criar arquivo .env
    echo "Criando arquivo .env..."
    cat <<EOL > .env
VUE_URL_API='http://localhost:3100'
VUE_FACEBOOK_APP_ID='23156312477653241'
EOL
    
    # Instalar dependências
    echo "Instalando dependências do npm..."
    npm install
    
    # Instalar Quasar
    echo "Instalando Quasar..."
    npm install -g @quasar/cli
    
    # Build do PWA
    echo "Build do PWA..."
    quasar build -m pwa
    
    echo "Frontend configurado com sucesso!"
}

configure_backend() {
    echo "Configurando Backend..."
    cd ./backend
    
    # Perguntar pelos parâmetros do backend
    read -p "URL do Backend [https://api.chat.infowayti.com.br]: " BACKEND_URL
    BACKEND_URL=${BACKEND_URL:-https://api.chat.infowayti.com.br}
    
    read -p "URL do Frontend [https://chat.infowayti.com.br]: " FRONTEND_URL
    FRONTEND_URL=${FRONTEND_URL:-https://chat.infowayti.com.br}
    
    read -p "Porta do Proxy [443]: " PROXY_PORT
    PROXY_PORT=${PROXY_PORT:-443}
    
    read -p "Porta do Serviço Backend [8081]: " PORT
    PORT=${PORT:-8081}
    
    read -p "Host do PostgreSQL [localhost]: " POSTGRES_HOST
    POSTGRES_HOST=${POSTGRES_HOST:-localhost}
    
    read -p "Porta do PostgreSQL [5432]: " DB_PORT
    DB_PORT=${DB_PORT:-5432}
    
    read -p "Usuário do PostgreSQL [postgres]: " POSTGRES_USER
    POSTGRES_USER=${POSTGRES_USER:-postgres}
    
    read -p "Senha do PostgreSQL [postgres]: " POSTGRES_PASSWORD
    POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-postgres}
    
    read -p "Banco de dados PostgreSQL [izing]: " POSTGRES_DB
    POSTGRES_DB=${POSTGRES_DB:-izing}
    
    read -p "Host do Redis [127.0.0.1]: " IO_REDIS_SERVER
    IO_REDIS_SERVER=${IO_REDIS_SERVER:-127.0.0.1}
    
    read -p "Porta do Redis [6379]: " IO_REDIS_PORT
    IO_REDIS_PORT=${IO_REDIS_PORT:-6379}
    
    read -p "Senha do Redis [redis]: " IO_REDIS_PASSWORD
    IO_REDIS_PASSWORD=${IO_REDIS_PASSWORD:-redis}
    
    # Criar arquivo .env
    echo "Criando arquivo .env..."
    cat <<EOL > .env
#NODE_ENV=prod

# ambiente
NODE_ENV=dev

# URL do backend para construção dos hooks
BACKEND_URL=${BACKEND_URL}

# URL do front para liberação do cors
FRONTEND_URL=${FRONTEND_URL}

# Porta utilizada para proxy com o serviço do backend
PROXY_PORT=${PROXY_PORT}

# Porta que o serviço do backend deverá ouvir
PORT=${PORT}

# conexão com o banco de dados
DB_DIALECT=postgres
DB_PORT=${DB_PORT}
POSTGRES_HOST=${POSTGRES_HOST}
POSTGRES_USER=${POSTGRES_USER}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_DB=${POSTGRES_DB}

# Chaves para criptografia do token jwt
JWT_SECRET=DPHmNRZWZ4isLF9vXkMv1QabvpcA80Rc
JWT_REFRESH_SECRET=EMPehEbrAdi7s8fGSeYzqGQbV5wrjH4i

# Dados de conexão com o REDIS
IO_REDIS_SERVER=${IO_REDIS_SERVER}
IO_REDIS_PORT=${IO_REDIS_PORT}
IO_REDIS_DB_SESSION='2'
IO_REDIS_PASSWORD=${IO_REDIS_PASSWORD}

#CHROME_BIN=/usr/bin/google-chrome
CHROME_BIN=/usr/bin/google-chrome-stable
#CHROME_BIN=null

# tempo para randomização da mensagem de horário de funcionamento
MIN_SLEEP_BUSINESS_HOURS=1000
MAX_SLEEP_BUSINESS_HOURS=2000

# tempo para randomização das mensagens do bot
MIN_SLEEP_AUTO_REPLY=40
MAX_SLEEP_AUTO_REPLY=60

# tempo para randomização das mensagens gerais
MIN_SLEEP_INTERVAL=20
MAX_SLEEP_INTERVAL=50

# dados do RabbitMQ / Para não utilizar, basta comentar a var AMQP_URL
RABBITMQ_DEFAULT_USER=admin
RABBITMQ_DEFAULT_PASS=123456
AMQP_URL='amqp://admin:123456@localhost:5672?connection_attempts=5&retry_delay=5'

# api oficial (integração em desenvolvimento)
API_URL_360=https://waba-sandbox.360dialog.io

# usado para mostrar opções não disponíveis normalmente.
ADMIN_DOMAIN=izing.io

# Dados para utilização do canal do facebook
VUE_FACEBOOK_APP_ID=3237415623048660
FACEBOOK_APP_SECRET_KEY=3266214132b8c98ac59f3e957a5efeaaa13500

# Forçar utilizar versão definida via cache (https://wppconnect.io/pt-BR/whatsapp-versions/)
WEB_VERSION

# Customizar opções do pool de conexões DB
POSTGRES_POOL_MAX
POSTGRES_POOL_MIN
POSTGRES_POOL_ACQUIRE
POSTGRES_POOL_IDLE
EOL
    
    # Instalar dependências
    echo "Instalando dependências do npm..."
    npm install
    
    # Build do backend
    echo "Build do backend..."
    npm run build
    
    # Rodar migrações e seeders do sequelize
    echo "Rodando migrações e seeders do sequelize..."
    npx sequelize db:migrate
    npx sequelize db:seed:all
    
    # Configurar PM2
    echo "Configurando PM2..."
    pm2 start ./dist/server.js --name BackEnd --cwd ./backend
    
    echo "Backend configurado com sucesso!"
}

configure_database() {
    echo "Configurando Banco de Dados..."
    
    # Instalar PostgreSQL
    echo "Instalando PostgreSQL..."
    sudo apt-get update
    sudo apt-get install -y postgresql-14
    
    # Configurar PostgreSQL
    echo "Configurando PostgreSQL..."
    sudo -u postgres psql <<EOL
CREATE USER postgres WITH PASSWORD 'postgres';
CREATE DATABASE izing;
GRANT ALL PRIVILEGES ON DATABASE izing TO postgres;
ALTER USER postgres WITH SUPERUSER;
EOL
    
    # Permitir acesso de qualquer IP
    echo "Permitindo acesso de qualquer IP..."
    sudo bash -c 'echo "host all all 0.0.0.0/0 md5" >> /etc/postgresql/14/main/pg_hba.conf'
    sudo bash -c 'echo "listen_addresses = '*'" >> /etc/postgresql/14/main/postgresql.conf'
    
    # Reiniciar PostgreSQL
    echo "Reiniciando PostgreSQL..."
    sudo systemctl restart postgresql
    
    echo "Banco de Dados configurado com sucesso!"
}

if [ "$ENVIRONMENT" == "frontend" ]; then
    configure_frontend
elif [ "$ENVIRONMENT" == "backend" ]; then
    configure_backend
elif [ "$ENVIRONMENT" == "banco" ]; then
    configure_database
elif [ "$ENVIRONMENT" == "tudo" ]; then
    configure_frontend
    configure_backend
    configure_database
else
    echo "Ambiente inválido. Saindo."
fi
