FROM gm2bv/mddog
MAINTAINER gm2bv <gm2bv2001@gmail.com>
RUN apt-get update && apt-get upgrade -y
ENTRYPOINT /root/startup.sh
