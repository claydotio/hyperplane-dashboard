# REPLACE_ENV_* is replaced at run-time with * environment variable when
# starting production server. This is necessary to avoid re-building at run-time

HOST = process.env.HYPERPLANE_DASHBOARD_HOST or
  REPLACE_ENV_HYPERPLANE_DASHBOARD_HOST? and
    REPLACE_ENV_HYPERPLANE_DASHBOARD_HOST or
  'localhost'

hostToHostname = (host) ->
  host.split(':')[0]

module.exports =
  ALLOWED_APPS: [
    'kitten-cards', 'puppy-cards', 'indecency',
    'trivia', 'hangman', 'tic-tac-toe', 'clay', 'clay-bot'
  ]

  AUTH_COOKIE: 'accessToken'
  HYPERPLANE_ADMIN_PASSWORD: process.env.HYPERPLANE_ADMIN_PASSWORD or
          REPLACE_ENV_HYPERPLANE_ADMIN_PASSWORD? and
            REPLACE_ENV_HYPERPLANE_ADMIN_PASSWORD or
          'insecurepassword'
  MITTENS_ADMIN_PASSWORD: process.env.MITTENS_ADMIN_PASSWORD or
          REPLACE_ENV_MITTENS_ADMIN_PASSWORD? and
            REPLACE_ENV_MITTENS_ADMIN_PASSWORD or
          'insecurepassword'
  PAWS_ADMIN_PASSWORD: process.env.PAWS_ADMIN_PASSWORD or
          REPLACE_ENV_PAWS_ADMIN_PASSWORD? and
            REPLACE_ENV_PAWS_ADMIN_PASSWORD or
          'insecurepassword'
  DONALD_ADMIN_PASSWORD: process.env.DONALD_ADMIN_PASSWORD or
          REPLACE_ENV_DONALD_ADMIN_PASSWORD? and
            REPLACE_ENV_DONALD_ADMIN_PASSWORD or
          'insecurepassword'
  PULSAR_ADMIN_PASSWORD: process.env.PULSAR_ADMIN_PASSWORD or
          REPLACE_ENV_PULSAR_ADMIN_PASSWORD? and
            REPLACE_ENV_PULSAR_ADMIN_PASSWORD or
          'insecurepassword'
  HYPERPLANE_API_URL: process.env.HYPERPLANE_API_URL or
          REPLACE_ENV_PUBLIC_HYPERPLANE_API_URL? and
            REPLACE_ENV_PUBLIC_HYPERPLANE_API_URL or
          'http://localhost:50180'
  MITTENS_API_URL: process.env.MITTENS_API_URL or
          REPLACE_ENV_PUBLIC_MITTENS_API_URL? and
            REPLACE_ENV_PUBLIC_MITTENS_API_URL or
          'http://localhost:50230'
  PAWS_API_URL: process.env.PAWS_API_URL or
          REPLACE_ENV_PUBLIC_PAWS_API_URL? and
            REPLACE_ENV_PUBLIC_PAWS_API_URL or
          'http://localhost:50230'
  DONALD_API_URL: process.env.DONALD_API_URL or
          REPLACE_ENV_PUBLIC_DONALD_API_URL? and
            REPLACE_ENV_PUBLIC_DONALD_API_URL or
          'http://localhost:50290'
  PULSAR_API_URL: process.env.PULSAR_API_URL or
          REPLACE_ENV_PUBLIC_PULSAR_API_URL? and
            REPLACE_ENV_PUBLIC_PULSAR_API_URL or
          'http://localhost:50260'

  ENV: process.env.NODE_ENV or
       REPLACE_ENV_NODE_ENV? and REPLACE_ENV_NODE_ENV or
       'production'
  ENVS:
    DEV: 'development'
    PROD: 'production'
    TEST: 'test'
  HOSTNAME: hostToHostname(HOST)

  # Server only
  PORT: process.env.HYPERPLANE_DASHBOARD_PORT or 50190
