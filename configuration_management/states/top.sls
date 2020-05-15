base:
  'roles:frontend':
    - match: grain
    - aik-ui
    - nodejs

  'roles:backend':
    - match: grain
    - aik-api
    - nodejs
