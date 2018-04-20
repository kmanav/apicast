# APIcast parameters

APIcast v2 has a number of parameters configured as [environment variables](#environment-variables) that can modify the behavior of the gateway. The following reference provides descriptions of these parameters.

Note that when deploying APIcast v2 with OpenShift, some of these parameters can be configured via OpenShift template parameters. The latter can be consulted directly in the [template](https://raw.githubusercontent.com/3scale/apicast/master/openshift/apicast-template.yml).

## Environment variables

### `APICAST_BACKEND_CACHE_HANDLER`

**Values:** strict | resilient  
**Default:** strict

Defines how the authorization cache behaves when backend is unavailable.
Strict will remove cached application when backend is unavailable.
Resilient will do so only on getting authorization denied from backend.

### `APICAST_CONFIGURATION_CACHE`

**Values:** _a number > 60_  
**Default:** 0

Specifies the interval (in seconds) that the configuration will be stored for. The value should be set to 0 (not compatible with boot value of `APICAST_CONFIGURATION_LOADER`) or more than 60. For example, if `APICAST_CONFIGURATION_CACHE` is set to 120, the gateway will reload the configuration from the API manager every 2 minutes (120 seconds).

### `APICAST_CONFIGURATION_LOADER`

**Values:** boot | lazy  
**Default:** lazy

Defines how to load the configuration.
Boot will request the configuration to the API manager when the gateway starts.
Lazy will load it on demand for each incoming request (to guarantee a complete refresh on each request `APICAST_CONFIGURATION_CACHE` should be 0).

### `APICAST_CUSTOM_CONFIG`

Defines the name of the Lua module that implements custom logic overriding the existing APIcast logic.

### `APICAST_ENVIRONMENT`

**Default:**  
**Value:** string\[:<string>\]  
**Example:** production:cloud-hosted

Double colon (`:`) separated list of environments (or paths) APIcast should load.
It can be used instead of `-e` or `---environment` parameter on the CLI and for example
stored in the container image as default environment. Any value passed on the CLI overrides this variable.

### `APICAST_LOG_FILE`

**Default:** _stderr_

Defines the file that will store the OpenResty error log. It is used by `bin/apicast` in the `error_log` directive. Refer to [NGINX documentation](http://nginx.org/en/docs/ngx_core_module.html#error_log) for more information. The file path can be either absolute, or relative to the prefix directory (`apicast` by default) 

### `APICAST_LOG_LEVEL`

**Values:** debug | info | notice | warn | error | crit | alert | emerg  
**Default:** warn

Specifies the log level for the OpenResty logs.

### `APICAST_MANAGEMENT_API`

**Values:**

- `disabled`: completely disabled, just listens on the port
- `status`: only the `/status/` endpoints enabled for health checks
- `debug`: full API is open

The [Management API](./management-api.md) is powerful and can control the APIcast configuration.
You should enable the debug level only for debugging.

### `APICAST_MODULE`

**Default:** apicast

Specifies the name of the main Lua module that implements the API gateway logic. Custom modules can override the functionality of the default `apicast.lua` module. See [an example](../examples/custom-module) of how to use modules.

### `APICAST_OAUTH_TOKENS_TTL`

**Values:** _a number_  
**Default:** 604800

When configured to authenticate using OAuth, this param specifies the TTL (in seconds) of the tokens created.

### `APICAST_PATH_ROUTING`

**Values:**
- `true` or `1` for _true_
- `false`, `0` or empty for _false_

When this parameter is set to _true_, the gateway will use path-based routing in addition to the default host-based routing. The API request will be routed to the first service that has a matching mapping rule, from the list of services for which the value of the `Host` header of the request matches the _Public Base URL_.

### `APICAST_POLICY_LOAD_PATH`

**Default**: `APICAST_DIR/policies`  
**Value:**: string\[:<string>\]
**Example**: ~/apicast/policies:$PWD/policies

Double colon (`:`) separated list of paths where APIcast should look for policies.
It can be used to first load policies from a development directory or to load examples.

### `APICAST_PROXY_HTTPS_CERTIFICATE_KEY`

**Default:**  
**Value:** string
**Example:** /home/apicast/my_certificate.key

The path to the key of the client SSL certificate.

### `APICAST_PROXY_HTTPS_CERTIFICATE`

**Default:**  
**Value:** string  
**Example:** /home/apicast/my_certificate.crt

The path to the client SSL certificate that APIcast will use when connecting
with the upstream. Notice that this certificate will be used for all the
services in the configuration.

### `APICAST_PROXY_HTTPS_PASSWORD_FILE`

**Default:**  
**Value:** string  
**Example:** /home/apicast/passwords.txt

Path to a file with passphrases for the SSL cert keys specified with
`APICAST_PROXY_HTTPS_CERTIFICATE_KEY`.

### `APICAST_PROXY_HTTPS_SESSION_REUSE`

**Default:** on  
**Values:**
- `on`: reuses SSL sessions.
- `off`: does not reuse SSL sessions.

### `APICAST_REPORTING_THREADS`

**Default**: 0  
**Value:** integer >= 0

Value greater than 0 is going to enable out-of-band reporting to backend.
This is a new **experimental** feature for increasing performance. Client
won't see the backend latency and everything will be processed asynchronously.
This value determines how many asynchronous reports can be running simultaneously
before the client is throttled by adding latency.

### `APICAST_RESPONSE_CODES`

**Values:**
- `true` or `1` for _true_
- `false`, `0` or empty for _false_

**Default:** \<empty\> (_false_)

When set to _true_, APIcast will log the response code of the response returned by the API backend in 3scale. In some plans this information can later be consulted from the 3scale admin portal.
Find more information about the Response Codes feature on the [3scale support site](https://access.redhat.com/documentation/en-us/red_hat_3scale/2.saas/html/analytics/response-codes-tracking).

### `APICAST_SERVICES_LIST`
**Value:** a comma-separated list of service IDs

Used to filter the services configured in the 3scale API Manager, and only use the configuration for specific services in the gateway, discarding those services' IDs that are not specified in the list.
Service IDs can be found on the **Dashboard > APIs** page, tagged as _ID for API calls_.

### `APICAST_SERVICE_${ID}_CONFIGURATION_VERSION`

Replace `${ID}` with the actual Service ID. The value should be the configuration version you can see in the configuration history on the Admin Portal.

Setting it to a particular version will prevent it from auto-updating and will always use that version.

### `APICAST_WORKERS`

**Default:** auto  
**Values:** _number_ | auto

This is the value that will be used in the nginx `worker_processes` [directive](http://nginx.org/en/docs/ngx_core_module.html#worker_processes). By default, APIcast uses `auto`, except for the development environment where `1` is used.

### `BACKEND_ENDPOINT_OVERRIDE`

URI that overrides backend endpoint from the configuration. Useful when deploying outside OpenShift deployed AMP.

**Example**: `https://backend.example.com`.

### `OPENSSL_VERIFY`

**Values:**
- `0`, `false`: disable peer verification
- `1`, `true`: enable peer verification

Controls the OpenSSL Peer Verification. It is off by default, because OpenSSL can't use system certificate store.
It requires custom certificate bundle and adding it to trusted certificates.

It is recommended to use https://github.com/openresty/lua-nginx-module#lua_ssl_trusted_certificate and point to to
certificate bundle generated by [export-builtin-trusted-certs](https://github.com/openresty/openresty-devel-utils/blob/master/export-builtin-trusted-certs).

### `REDIS_HOST`

**Default:** `127.0.0.1`

APIcast requires a running Redis instance for OAuth 2.0 Authorization code flow. `REDIS_HOST` parameter is used to set the hostname of the IP of the Redis instance.

### `REDIS_PORT`

**Default:** 6379

APIcast requires a running Redis instance for OAuth 2.0 Authorization code flow. `REDIS_PORT` parameter can be used to set the port of the Redis instance.

### `REDIS_URL`

**Default:** no value

APIcast requires a running Redis instance for OAuth 2.0 Authorization code flow. `REDIS_URL` parameter can be used to set the full URI as DSN format like: `redis://PASSWORD@HOST:PORT/DB`. Takes precedence over `REDIS_PORT` and `REDIS_HOST`.

### `RESOLVER`

Allows to specify a custom DNS resolver that will be used by OpenResty. If the `RESOLVER` parameter is empty, the DNS resolver will be autodiscovered.

### `THREESCALE_CONFIG_FILE`

Path to the JSON file with the configuration for the gateway. The configuration can be downloaded from the 3scale admin portal using the URL: `<schema>://<admin-portal-domain>/admin/api/nginx/spec.json` (**Example**: `https://account-admin.3scale.net/admin/api/nginx/spec.json`).

When the gateway is deployed using Docker, the file has to be injected to the docker image as a read only volume, and the path should indicate where the volume is mounted, i.e. path local to the docker container.

You can find sample configuration files in [examples](https://github.com/3scale/apicast/tree/master/examples/configuration) folder.

It is **required** to provide either `THREESCALE_PORTAL_ENDPOINT` or `THREESCALE_CONFIG_FILE` (takes precedence) for the gateway to run successfully.

### `THREESCALE_DEPLOYMENT_ENV`

**Values:** staging | production  
**Default:** production

The value of this environment variable will be used to define the environment for which the configuration will be downloaded from 3scale (Staging or Production), when using new APIcast.

The value will also be used in the header `X-3scale-User-Agent` in the authorize/report requests made to 3scale Service Management API. It is used by 3scale just for statistics.

### `THREESCALE_PORTAL_ENDPOINT`

URI that includes your password and portal endpoint in the following format: `<schema>://<password>@<admin-portal-domain>`. The `<password>` can be either the [provider key](https://support.3scale.net/docs/terminology#apikey) or an [access token](https://support.3scale.net/docs/terminology#tokens) for the 3scale Account Management API. `<admin-portal-domain>` is the URL used to log into the admin portal.

**Example**: `https://access-token@account-admin.3scale.net`.

When `THREESCALE_PORTAL_ENDPOINT` environment variable is provided, the gateway will download the configuration from 3scale on initializing. The configuration includes all the settings provided on the Integration page of the API(s).

It is **required** to provide either `THREESCALE_PORTAL_ENDPOINT` or `THREESCALE_CONFIG_FILE` (takes precedence) for the gateway to run successfully.


### `OPENTRACING_TRACER`

**Example** `jaeger`

This environment variable controls which tracing library will be loaded, right now, there's only one opentracing tracer available, `jaeger`.

If empty, opentracing support will be disabled.


### `OPENTRACING_CONFIG`

This environment variable is used to determine the config file for the opentracing tracer, if `OPENTRACING_TRACER` is not set, this variable will be ignored.

Each tracer has a default configuration file:
    * `jaeger`: `conf.d/opentracing/jaeger.example.json`

You can choose to mount a different configuration than the provided by default by setting the file path using this variable.

**Example**: `/tmp/jaeger/jaeger.json`

### `OPENTRACING_HEADER_FORWARD`

**Defaul** `uber-trace-id`

This environment variable controls the HTTP header used for forwarding opentracing information, this HTTP header will be forwarded to upstream servers.

