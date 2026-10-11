#!/usr/bin/env bash
set -e

# Thong tin PostgreSQL
DB_NAME="appdb"
DB_USER="appuser"
DB_PASSWORD="apppass"

# 1. Tao Custom Bridge Network
docker network inspect app-net >/dev/null 2>&1 || 
    docker network create --driver bridge app-net

# 2. Tao Named Volume
docker volume inspect db-data >/dev/null 2>&1 || 
    docker volume create db-data

# 3. Khoi chay PostgreSQL
docker rm -f db-server >/dev/null 2>&1 || true

docker run -d 
    --name db-server 
    --network app-net 
    --restart unless-stopped 
    -e POSTGRES_DB="$DB_NAME" 
    -e POSTGRES_USER="$DB_USER" 
    -e POSTGRES_PASSWORD="$DB_PASSWORD" 
    -v db-data:/var/lib/postgresql/data 
    postgres:15-alpine

# 4. Cho PostgreSQL san sang
until docker exec db-server pg_isready -U "$DB_USER" -d "$DB_NAME" >/dev/null 2>&1; do
    sleep 2
done

# 5. Khoi chay Backend container
docker rm -f app-container >/dev/null 2>&1 || true

docker run -d 
    --name app-container 
    --network app-net 
    --restart unless-stopped 
    -e DB_HOST=db-server 
    -e DB_PORT=5432 
    -e DB_NAME="$DB_NAME" 
    -e DB_USER="$DB_USER" 
    -e DB_PASSWORD="$DB_PASSWORD" 
    --entrypoint sh 
    node:18-alpine 
    -c "apk add --no-cache iputils postgresql-client >/dev/null && sleep infinity"

# 6. Kiem tra DNS va ket noi noi bo
docker exec app-container ping -c 2 db-server

docker exec app-container 
    pg_isready -h db-server -p 5432 -U "$DB_USER" -d "$DB_NAME"

# 7. Tao bang va them du lieu kiem chung
docker exec -i db-server 
    psql -U "$DB_USER" -d "$DB_NAME" <<'SQL'
CREATE TABLE IF NOT EXISTS persistence_test (
    id SERIAL PRIMARY KEY,
    message TEXT NOT NULL
);

INSERT INTO persistence_test (message)
VALUES ('Docker Named Volume persistence verified');
SQL

echo "Du lieu truoc khi xoa container:"
docker exec db-server 
    psql -U "$DB_USER" -d "$DB_NAME" 
    -c "SELECT * FROM persistence_test;"

# 8. Xoa cung container PostgreSQL
docker rm -f db-server

# 9. Tao lai container DB voi cung volume db-data
docker run -d 
    --name db-server 
    --network app-net 
    --restart unless-stopped 
    -e POSTGRES_DB="$DB_NAME" 
    -e POSTGRES_USER="$DB_USER" 
    -e POSTGRES_PASSWORD="$DB_PASSWORD" 
    -v db-data:/var/lib/postgresql/data 
    postgres:15-alpine

# 10. Cho DB san sang
until docker exec db-server pg_isready -U "$DB_USER" -d "$DB_NAME" >/dev/null 2>&1; do
    sleep 2
done

# 11. Xac minh du lieu van con
echo "Du lieu sau khi tao lai container:"
docker exec db-server 
    psql -U "$DB_USER" -d "$DB_NAME" 
    -c "SELECT * FROM persistence_test;"

# 12. Kiem tra lai DNS tu Backend
docker exec app-container ping -c 2 db-server

echo "Hoan tat: Network, Volume va Persistence da duoc kiem tra."