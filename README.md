#FIRST :

    run postgres (sh startdb.sh);
    create users for postgres instance (sh createdbs.sh);
    make migrations to db (sh migrate.sh);

#SECOND :

    build all containers and let running them (sh start_services.sh) 