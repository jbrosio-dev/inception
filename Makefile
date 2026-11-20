LOGIN = jbrosio
DATA_DIR = /home/$(LOGIN)/data

all:
	@echo "Creating directories for the physical volumes..."
	@if [ ! -d secrets ]; then \
		mkdir -p secrets; \
		openssl rand -base64 16 > secrets/sql_password.txt; \
		openssl rand -base64 16 > secrets/sql_root_password.txt; \
		openssl rand -base64 16 > secrets/user_password_ftp.txt; \
		openssl rand -base64 16 > secrets/wp_admin_password.txt; \
		openssl rand -base64 16 > secrets/wp_user_password.txt; \
	fi
	@mkdir -p $(DATA_DIR)/mariadb
	@mkdir -p $(DATA_DIR)/wordpress
	@echo "Spinning up the Inception infrastructure..."
	@docker-compose -f srcs/docker-compose.yml up -d --build

down:
	@echo "Stopping containers..."
	@docker-compose -f srcs/docker-compose.yml down

clean: down
	@echo "Removing unused containers and images..."
	@docker system prune -a --force

fclean: clean
	@echo "Removing all persistence (Volumes and local data)..."
	@rm -rf secrets/*
	@rm -rf secrets
	@sudo rm -rf $(DATA_DIR)/mariadb/*
	@sudo rm -rf $(DATA_DIR)/wordpress/*
	@docker volume rm $(docker volume ls -q) 2>/dev/null || true

re: fclean all

.PHONY: all down clean fclean re
