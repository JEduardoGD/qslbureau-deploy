#!/bin/bash
DOMAIN="qslbureauqa.ddns.net"
USERSO="ubuntu"
#
#Update the apt package index and install packages to allow apt to use a repository over HTTPS
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
#
#Add Docker’s official GPG key:
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
#
#Use the following command to set up the repository:
echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
#
#add user to docker group and useit without sudo
echo '1'
sudo usermod -aG docker $USERSO
#
#reload docker group
echo '2'
#newgrp docker
#
#run hello-world docker
echo '3'
docker run hello-world
#
#install docker-compose
echo '4'
UNAMES=$(uname -s)
UNAMEM=$(uname -m)
echo '5'
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-${UNAMES}-${UNAMEM}" -o /usr/local/bin/docker-compose
echo '6'
sudo chmod +x /usr/local/bin/docker-compose
echo '7'
docker-compose --version
#
#intall others applications
echo '8'
sudo apt-get install -y git nginx build-essential software-properties-common
#
#unlink
echo '9'
sudo unlink /etc/nginx/sites-enabled/default
#
#create block directory
echo '10'
sudo mkdir -p "/var/www/${DOMAIN}/html"
sudo chown -R $USERSO:$USERSO "/var/www/${DOMAIN}/html"
sudo chmod -R 755 "/var/www/${DOMAIN}"
#
#create index block
echo "<html>"                                                             >> "/var/www/${DOMAIN}/html/index.html"
echo "    <head>"                                                         >> "/var/www/${DOMAIN}/html/index.html"
echo "        <title>Welcome to your_domain!</title>"                     >> "/var/www/${DOMAIN}/html/index.html"
echo "    </head>"                                                        >> "/var/www/${DOMAIN}/html/index.html"
echo "    <body>"                                                         >> "/var/www/${DOMAIN}/html/index.html"
echo "        <h1>Success! The your_domain server block is working!</h1>" >> "/var/www/${DOMAIN}/html/index.html"
echo "    </body>"                                                        >> "/var/www/${DOMAIN}/html/index.html"
echo "</html>"                                                            >> "/var/www/${DOMAIN}/html/index.html"
#
#create reverse-proxy.conf
echo "server {"                                                        >> reverse-proxy.conf.txt
echo "        listen 80;"                                              >> reverse-proxy.conf.txt
echo "        listen [::]:80;"                                         >> reverse-proxy.conf.txt
echo ""                                                                >> reverse-proxy.conf.txt
echo "        root /var/${DOMAIN}/html;"                               >> reverse-proxy.conf.txt
echo "        access_log /var/log/nginx/reverse-access.log;"           >> reverse-proxy.conf.txt
echo "        error_log /var/log/nginx/reverse-error.log;"             >> reverse-proxy.conf.txt
echo ""                                                                >> reverse-proxy.conf.txt
echo "        server_name ${DOMAIN};"                                  >> reverse-proxy.conf.txt
echo ""                                                                >> reverse-proxy.conf.txt
echo "        location ~/api/(.*)$ {"                                  >> reverse-proxy.conf.txt
echo "                proxy_set_header X-Real-IP  \$remote_addr;"      >> reverse-proxy.conf.txt
echo "                proxy_set_header X-Forwarded-For \$remote_addr;" >> reverse-proxy.conf.txt
echo "                proxy_set_header Host \$host;"                   >> reverse-proxy.conf.txt
echo "                #docker port of api container"                   >> reverse-proxy.conf.txt
echo "                proxy_pass http://127.0.0.1:8080/\$1;"           >> reverse-proxy.conf.txt
echo "        }"                                                       >> reverse-proxy.conf.txt
echo ""                                                                >> reverse-proxy.conf.txt
echo ""                                                                >> reverse-proxy.conf.txt
echo "        location / {"                                            >> reverse-proxy.conf.txt
echo "        #docker port of front container"                         >> reverse-proxy.conf.txt
echo "                    proxy_pass http://127.0.0.1:8082;"           >> reverse-proxy.conf.txt
echo "  }"                                                             >> reverse-proxy.conf.txt
echo "}"                                                               >> reverse-proxy.conf.txt
echo ""                                                                >> reverse-proxy.conf.txt
#
#
sudo cp reverse-proxy.conf.txt /etc/nginx/sites-available/reverse-proxy.conf
sudo ln -s /etc/nginx/sites-available/reverse-proxy.conf /etc/nginx/sites-enabled/reverse-proxy.conf
sudo nginx -t
sudo systemctl restart nginx
#
sudo apt install make gcc -y
cd /usr/local/src/
sudo wget http://www.noip.com/client/linux/noip-duc-linux.tar.gz
sudo tar xf noip-duc-linux.tar.gz
cd noip-2.1.9-1/
sudo make install
cd ~
echo "[Unit]"                         >> noip2.service
echo "Description=noip2 service"      >> noip2.service
echo ""                               >> noip2.service
echo "[Service]"                      >> noip2.service
echo "Type=forking"                   >> noip2.service
echo "ExecStart=/usr/local/bin/noip2" >> noip2.service
echo "Restart=always"                 >> noip2.service
echo ""                               >> noip2.service
echo "[Install]"                      >> noip2.service
echo "WantedBy=default.target"        >> noip2.service
sudo mv noip2.service /etc/systemd/system
sudo systemctl daemon-reload
sudo systemctl start noip2
sudo systemctl enable noip2
#
#installing certbot
sudo add-apt-repository -y ppa:certbot/certbot
sudo apt-get update
sudo apt-get install -y python3-certbot-nginx
sudo certbot --nginx -d $DOMAIN
