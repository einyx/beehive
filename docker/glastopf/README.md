[![](https://images.microbadger.com/badges/version/blackhatch/glastopf:1811.svg)](https://microbadger.com/images/blackhatch/glastopf:1811 "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/blackhatch/glastopf:1811.svg)](https://microbadger.com/images/blackhatch/glastopf:1811 "Get your own image badge on microbadger.com")

# glastopf

[glastopf](https://github.com/mushorg/glastopf) is a python web application honeypot.

This dockerized version is part of the **[T-Pot community honeypot](http://dtag-dev-sec.github.io/)** of Deutsche Telekom AG.

The `Dockerfile` contains the blueprint for the dockerized glastopf and will be used to setup the docker image.

The `docker-compose.yml` contains the necessary settings to test glastopf using `docker-compose`. This will ensure to start the docker container with the appropriate permissions and port mappings.  

# Glastopf Dashboard

![Glastopf Dashboard](doc/dashboard.png)
