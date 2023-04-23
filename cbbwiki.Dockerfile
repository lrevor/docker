# syntax=docker/dockerfile:1
   
FROM mediawiki
RUN mkdir /var/www/html/TheWorldFamousCowboyBand1923
RUN ln -s /var/www/html /var/www/html/TheWorldFamousCowboyBand1923/wiki
