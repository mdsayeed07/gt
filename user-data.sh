#!/bin/bash

sudo apt update && sudo apt -y upgrade

sudo apt install -y apache2

sudo apt install -y mysql-server

sudo apt install -y php libapache2-mod-php php-mysql
