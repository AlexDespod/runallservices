docker-compose -f docker-compose.store.yml up -d
sh createdbs.sh
sh migrate.sh