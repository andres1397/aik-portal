#!groovy

node {

    step([$class: 'WsCleanup'])

    stage "Checkout Git repo"
        checkout scm

    stage "Run test"
        sh "docker run -v \$(pwd)/aik-app-ui:/data --rm usemtech/nodejs-mocha npm install"
        sh "docker run -v \$(pwd)/aik-app-ui:/data --rm usemtech/nodejs-mocha npm install chai chai-http && npm install --save-dev http-status-codes && npm install --save superagent superagent-promise"
        sh "docker run -v \$(pwd)/aik-app-ui:/data --rm usemtech/nodejs-mocha npm test"
    stage "Build RPM"
        sh "[ -d ./rpm] || mkdir ./rpm"
        sh "docker run -v \$(pwd)/aik-app-ui:/data/aik-app -v \$(pwd)/aik-app-ui/rpm:/data/rpm --rm tenzer/fpm -s dir -t rpm -n aik-app -v \$(git rev-parse --short HEAD) --description \"Aik app\" --directories /var/www/aik-app --package /data/rpm/aik-app-\$(git rev-parse --short HEAD).rpm /data/aik-app=/var/www/"
    stage "Update YUM repo"
        sh "[ -d ~/repo/rpm/aik-app] || mkdir -p ~/repo/rpm/aik-app/"
        sh "sudo mv ./aik-app-ui/rpm/*.rpm ~/repo/rpm/aik-app/"
        sh "createrepo ~/repo/"
        sh "aws s3 sync ~/repo s3://artifacts-automatizacion/ --region us-east-1 --delete"
    stage "Check YUM repo"
        sh "sudo yum clean all"
        sh "sudo yum update -y"
        sh "sudo yum info aik-app-\$(git rev-parse --short HEAD)"
    stage "Trigger downstream"

        def versionApp = sh returnStdout: true, script:"printf \$(git rev-parse --short HEAD)"
        build job: "aik-cdelivery", parameters: [[$class: "StringParameterValue", name: "APP_VERSION", value: "${versionApp}-1"]], wait: false

}