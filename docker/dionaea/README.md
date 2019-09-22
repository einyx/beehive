[![](https://images.microbadger.com/badges/version/blackhatch/dionaea:1811.svg)](https://microbadger.com/images/blackhatch/dionaea:1811 "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/blackhatch/dionaea:1811.svg)](https://microbadger.com/images/blackhatch/dionaea:1811 "Get your own image badge on microbadger.com")

# dionaea

[dionaea](https://github.com/DinoTools/dionaea) is a low interaction honeypot with focus on capturing malware.

This dockerized version is part of the **[T-Pot community honeypot](http://dtag-dev-sec.github.io/)** of Deutsche Telekom AG.

The `Dockerfile` contains the blueprint for the dockerized dionaea and will be used to setup the docker image.

The `docker-compose.yml` contains the necessary settings to test dionaea using `docker-compose`. This will ensure to start the docker container with the appropriate permissions and port mappings.

# Dionaea Dashboard

![Dionaea Dashboard](doc/dashboard.png)
