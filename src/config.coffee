# REPLACE_ENV_* is replaced at run-time with * environment variable when
# starting production server. This is necessary to avoid re-building at run-time

HOST = process.env.HYPERPLANE_DASHBOARD_HOST or
  REPLACE_ENV_HYPERPLANE_DASHBOARD_HOST? and
    REPLACE_ENV_HYPERPLANE_DASHBOARD_HOST or
  'localhost'

hostToHostname = (host) ->
  host.split(':')[0]

module.exports =
  AUTH_COOKIE: 'accessToken'
  HYPERPLANE_ADMIN_PASSWORD: process.env.HYPERPLANE_ADMIN_PASSWORD or
          REPLACE_ENV_HYPERPLANE_ADMIN_PASSWORD? and
            REPLACE_ENV_HYPERPLANE_ADMIN_PASSWORD or
          'insecurepassword'
  HYPERPLANE_API_URL: process.env.PUBLIC_HYPERPLANE_API_URL or
          REPLACE_ENV_PUBLIC_HYPERPLANE_API_URL? and
            REPLACE_ENV_PUBLIC_HYPERPLANE_API_URL or
          'http://localhost:50180'

  ENV: process.env.NODE_ENV or
       REPLACE_ENV_NODE_ENV? and REPLACE_ENV_NODE_ENV or
       'production'
  ENVS:
    DEV: 'development'
    PROD: 'production'
    TEST: 'test'
  HOSTNAME: hostToHostname(HOST)

  # Server only
  PORT: process.env.PORT or 3000
