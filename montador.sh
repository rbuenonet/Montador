#!/bin/bash

#limpa a tela
clear

#funcao que imprime o separador para facilitar a leitura
function separator(){
	echo -e "\n--------------------------------------------------------------------------------------------\n"
}

function nodejs(){
	#instalando o nodejs
	separator
	echo "Instalando o NODEJS"
	separator
	curl -sL http://deb.nodesource.com/setup_6.x | sudo -E bash -
	apt-get install -y nodejs

	#instalando o PM2
	separator
	echo "Instalando o PM2 para funcionar juntamente com o NODEJS"
	separator
	npm install pm2 -g
}

function php(){
	#instalando o php
	separator
	echo "Instalando o php"
	separator
	apt-get install php-fpm php-mysql

	echo -e "\nDescomente e mude o valor do parametro: 'cgi.fix_pathinfo' colocando o valor '1' (normalmente na linha 761). Tecle enter para continuar."
	read ok
	vim /etc/php/7.0/fpm/php.ini	

	/etc/init.d/php7.0-fpm restart
}

#mensagem de bem vindo
echo "Bem Vindo $(whoami)!"

echo -e "\nIniciando o script de montagem de servidor"

#escolha do tipo de servidor
echo -e "\nVoce deseja montar qual servidor?"
echo "(0) Nenhum"
echo "(1) Todos"
echo "(2) NodeJs"
echo "(3) PHP"
read servidor

#escolha do dominio
echo -e "\nQual dominio deseja?"
read dominio

#url do projeto no git
echo -e "\nDigite a url do projeto no git ou vazio para nao clonar o repositorio"
read projeto

#atualiza todos os pacotes ja instalados
separator
echo "Atualizando todos os pacotes:"
separator
apt-get update

#instala o VIM
separator
echo "Instalando o Editor Vim"
separator
apt-get install vim

#instalando o git
separator
echo "Instalando o GIT"
separator
apt-get install git

#instalando o MySQL
separator
echo "Instalando o MySQL"
separator
apt-get install mysql-server
service mysql restart

#instalando o UFW (firewall)
separator
echo "Instalando UFW"
separator
apt-get install ufw

#instala o nginx
separator
echo "Instalando o proxy NGINX"
separator
apt-get install nginx

#configurando nginx
separator
echo "Configurando o NGINX"
separator

#cria pasta do dominio -> arquivo/log
mkdir -p /var/www/$dominio/{public/,log}

texto=""
#texto+="worker_processes 1;"
#texto+="\nevents{\n\tworker_connections 1024; \n}"
#texto+="\nhttp{"
#texto+="\n\tinclude mine.types;\n\tdefault_type application/octet-stream;\n\tsendfile on;\n\tkeepalive_timeout 65;\n\tgzip on;"
texto+="\n\n\tserver{\n\t\tlisten 80;\n\n\t\t#configuracoes de dominios\n\t\tserver_name $dominio;\n\t\taccess_log /var/www/$dominio/log/access.log; #arquivo para log de acessos\n\t\troot /var/www/$dominio/public;\n\t\tindex index.html index.htm index.php;\n\n\t\tlocation / {"


texto+="\n\n\t\t\t#conteudo estatico\n\t\t\troot /var/www/$dominio/public;\n\t\t\texpires max;"
texto+="\n\n\t\t\t#conteudo node\n\t\t\tproxy_pass http://127.0.0.1:[YOUR_PORT];\n\t\t\tproxy_http_version 1.1;\n\t\t\tproxy_set_header Upgrade \$http_upgrade;\n\t\t\tproxy_set_header Connection 'upgrade';\n\t\t\tproxy_set_header Host \$host;\n\t\t\tproxy_cache_bypass \$http_upgrade;"
texto+="\n\n\t\t\t#conteudo php\n\t\t\tinclude snippets/fastcgi-php.conf;\n\t\t\tfastcgi_pass unix:/run/php/php7.0-fpm.sock;"

texto+="\n\t\t}\n\t}";
#texto+="\n}"

if [ -e "/etc/nginx/sites-available/$dominio" ]; then
	rm /etc/nginx/sites-available/$dominio
	rm /etc/nginx/sites-enabled/$dominio
fi

echo -e "$texto" >> /etc/nginx/sites-available/$dominio
ln -s /etc/nginx/sites-available/$dominio /etc/nginx/sites-enabled

echo -e "\n\nDescomente a linha 23 'server_names_hash_bucket_size 64;'. Tecle enter para continuar."
read ok
vim /etc/nginx/nginx.conf

service nginx restart

#Instalar o servidor do backend escolhido
case "$servidor" in
	"1") 
		nodejs; php;;
	"2")
		nodejs;;
	"3")
		php;;
esac

#clona o repositorio o usuario quiser
if [ -n "$projeto" ];
then
	separator
	echo -e "Clonando repositorio"
	separator
	git clone $projeto /var/www/$dominio/
fi	


separator
echo "Fim do script de montagem de servidor"

