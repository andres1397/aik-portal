--- 
include:
  - nodejs
  - git

aik-ui: 
  git.latest: 
    - 
      name: "https://github.com/andres1397/aik-portal"
    - 
      target: /srv/aik-portal

install_npm_dependencies: 
  npm.bootstrap: 
    - 
      name: /srv/aik-portal/aik-app-ui

run_aik_portal:
  cmd.run:
    - name: "nohup node /srv/aik-portal/aik-app-ui/server.js > /dev/null 2>&1 &"
