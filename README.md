# proxiable

Nice and easy intercepting, filtering and transforming of HTTP(S) requests

This program leverages [mitmproxy](https://mitmproxy.org/) and uses a simple
filesystem-based override system to intercept the requests and replace
resources in real time by the ones found locally.

## Usage

You can use the image directly from [Docker Hub](https://hub.docker.com/),
binding the ports from `mitmweb`:

```
docker run -n proxiable --rm -d \
     -p 8000:8000 -p 8001:8001 \
     -v "$PWD/sites:/var/proxiable/sites" \
     -v "$PWD/certs:/var/proxiable/certs" \
     diogenes1oliveira/proxiable
```

The intercepting certificate will be available in `certs/ca.pem`. You can also
put your own certificate bundle in the path above instead of letting `mitmproxy`
generate one.

The HTTP/HTTPS proxy will be available at `http://localhost:8000`.

## Directory Structure

First of all, you should create an overriding structure in a `sites` directory.
The overriding files are given by putting them in the same path structure as the
host / URL combination. For example, a structure such as below would map all
requests to http://nginx.org/nginx.png to serve from the filesystem instead:

```
sites/
└─── nginx.org/
     └─── nginx.png
```

You could also change the Google logo, served at https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png,
for Bing's logo using a structure such as the one below:

```
sites/
└─── www.google.com/
     └─── images/
          └─── branding/
               └─── googlelogo/
                    └─── 1x/
                         └─── googlelogo_color_272x92dp.png
```

## Configuration

| Variable               | Default   | Description                                      |
| ---------------------- | --------- | ------------------------------------------------ |
| `PROXIABLE_PROXY_HOST` | `0.0.0.0` | Host the proxy listens to                        |
| `PROXIABLE_PROXY_HOST` | `8000`    | Port the proxy listens on                        |
| `PROXIABLE_WEBUI_HOST` | `0.0.0.0` | Host the WebUI listens to                        |
| `PROXIABLE_WEBUI_HOST` | `8001`    | Port the WebUI listens on                        |
| `PROXIABLE_INDEX_FILE` | `INDEX`   | File to be looked up when the path ends with `/` |

