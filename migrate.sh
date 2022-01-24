cat migrations/sbp/$(ls migrations/sbp) | docker exec -i store psql -U sbp -d sbp
cd migrations/pitboss && cat $(ls) | docker exec -i store psql -U pitboss -d pitboss && cd ../ && cd ../
cat migrations/speedwager/$(ls migrations/speedwager) | docker exec -i store psql -U speedwager -d speedwager