FROM gm2bv/mddog:wheezy
MAINTAINER gm2bv <gm2bv2001@gmail.com>
CMD cd /home/www/mddog && git pull origin master
CMD chown -R www-data:www-data /home/www/mddog
ENTRYPOINT /root/startup.sh
