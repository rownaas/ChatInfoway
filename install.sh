#!/bin/bash

LOG_FILE="install_log.txt"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

log "Início da configuração do ambiente"

# Diretórios
ROOT_DIR=$(pwd)
FRONTEND_DIR="$ROOT_DIR/frontend"
BACKEND_DIR="$ROOT_DIR/backend"

# Verificar e instalar nvm se não estiver instalado
if ! command -v nvm &> /dev/null; then
    log "Instalando NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
    source ~/.nvm/nvm.sh
else
    log "NVM já está instalado"
fi

# Função para instalar Node.js e npm usando nvm
install_node_version() {
    local version=$1
    log "Instalando Node.js versão $version..."
    nvm install $version
    nvm use $version
    log "Node.js versão $version instalado"
}

# Configurar fuso horário e atualizar o sistema
log "Configurando fuso horário e atualizando o sistema..."
sudo apt update && sudo apt upgrade -y

# Instalar e configurar Redis
log "Instalando Redis..."
sudo apt install -y redis-server
sudo sed -i 's/^# requirepass .*/requirepass senhainformada/' /etc/redis/redis.conf
sudo systemctl restart redis-server

# Adicionar repositório RabbitMQ e instalar RabbitMQ
log "Instalando RabbitMQ..."
sudo add-apt-repository -y ppa:rabbitmq/rabbitmq-erlang
wget -qO - https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.deb.sh | sudo bash
sudo apt install -y rabbitmq-server
sudo rabbitmq-plugins enable rabbitmq_management

# Configurar usuário RabbitMQ
log "Configurando RabbitMQ..."
sudo rabbitmqctl add_user admin 123456
sudo rabbitmqctl set_user_tags admin administrator
sudo rabbitmqctl set_permissions -p / admin "." "." ".*"

# Instalar Google Chrome
log "Instalando Google Chrome..."
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install -y ./google-chrome-stable_current_amd64.deb
rm -rf google-chrome-stable_current_amd64.deb

# Perguntar qual ambiente configurar
read -p "Qual ambiente deseja configurar? (frontend, backend, banco ou tudo): " ENVIRONMENT

configure_frontend() {
    log "Configurando Frontend..."
    if [ -d "$FRONTEND_DIR" ]; then
        cd "$FRONTEND_DIR"
        
        # Instalar e usar Node.js 16 para o frontend
        install_node_version 16

        # Criar arquivo .env
        log "Criando arquivo .env para o frontend..."
        cat <<EOL > .env
VUE_URL_API='http://localhost:3100'
VUE_FACEBOOK_APP_ID='23156312477653241'
EOL
    
        # Instalar dependências
        log "Instalando dependências do npm para o frontend..."
        npm install || { log 'Falha ao instalar dependências'; exit 1; }
    
        # Build do PWA
        log "Build do PWA..."
        npx quasar build -m pwa || { log 'Falha ao construir PWA'; exit 1; }
    
        log "Frontend configurado com sucesso!"
    else
        log "Diretório frontend não encontrado!"
    fi
}

configure_backend() {
    log "Configurando Backend..."
    if [ -d "$BACKEND_DIR" ]; then
        cd "$BACKEND_DIR"
        
        # Instalar e usar Node.js 18 para o backend
        install_node_version 18
    
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
        log "Criando arquivo .env para o backend..."
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
        log "Instalando dependências do npm para o backend..."
        sudo chmod +x $(which node)
        npm install || { log 'Falha ao instalar dependências'; exit 1; }
    
        # Build do backend
        log "Build do backend..."
        npm run build || { log 'Falha ao construir o backend'; exit 1; }
    
        # Rodar migrações e seeders do sequelize
        log "Rodando migrações e seeders do sequelize..."
        npx sequelize db:migrate || { log 'Falha ao rodar migrações'; exit 1; }
        npx sequelize db:seed:all || { log 'Falha ao rodar seeders'; exit 1; }
    
        # Instalar PM2 e configurar para rodar o backend
        log "Instalando PM2..."
        npm install -g pm2 || { log 'Falha ao instalar PM2'; exit 1; }
    
        log "Configurando PM2 para rodar o backend..."
        pm2 start dist/server.js --name izing-api
    
        log "Backend configurado com sucesso!"
    else
        log "Diretório backend não encontrado!"
    fi
}

configure_database() {
    log "Configurando Banco de Dados..."
    sudo apt install -y postgresql-14
    
    # Configurar PostgreSQL
    log "Configurando PostgreSQL..."
    sudo -u postgres psql <<EOL
CREATE USER postgres WITH PASSWORD 'postgres';
CREATE DATABASE izing;
GRANT ALL PRIVILEGES ON DATABASE izing TO postgres;
ALTER USER postgres WITH SUPERUSER;
EOL
    
    # Permitir acesso de qualquer IP
    log "Permitindo acesso de qualquer IP..."
    sudo bash -c 'echo "host all all 0.0.0.0/0 md5" >> /etc/postgresql/14/main/pg_hba.conf'
    sudo bash -c 'echo "listen_addresses = '*'\" >> /etc/postgresql/14/main/postgresql.conf'
    
    # Reiniciar PostgreSQL
    log "Reiniciando PostgreSQL..."
    sudo systemctl restart postgresql
    
    log "Banco de Dados configurado com sucesso!"
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
    log "Ambiente inválido. Saindo."
fi

log "Configuração do ambiente concluída"
