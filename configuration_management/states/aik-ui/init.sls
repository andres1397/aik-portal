--- 
include: 
  - nodejs
  - git

aik-ui: 
  git.latest: 
    - 
      name: "https://github.com/RicNuva18/aik-portal-frontend"
    - 
      target: /srv/aik-portal

install_npm_dependencies: 
  npm.bootstrap: 
    - 
      name: /srv/aik-portal/aik-app-ui

run_aik_portal:
  cmd.run:
    - name: "node /srv/aik-portal/aik-app-ui/server.js"

