include:
    - nodejs

install_npm_dependencies:
    npm.bootstrap:
      - name: /srv/aik-portal/aik-app-ui

run_aik_portal:
    cmd.run:
      - name: "node /srv/aik-portal/aik-app-ui/server.js" 