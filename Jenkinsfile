pipeline {

  agent any

  options { skipDefaultCheckout(true) }

  stages {

    stage('Checkout') {
      steps {
        publishChecks name: '01. Checkout', title: 'Checkout', status: 'IN_PROGRESS', summary: 'Starting…'
        echo 'Checking out the code...'
      }
      post {
        success { publishChecks name: '01. Checkout', status: 'COMPLETED', conclusion: 'SUCCESS', summary: 'Checked out' }
        failure { publishChecks name: '01. Checkout', status: 'COMPLETED', conclusion: 'FAILURE', summary: 'Checkout failed' }
      }
    }

    stage('Build') {
      steps {
        publishChecks name: '02. Build', title: 'Build', status: 'IN_PROGRESS', summary: 'Compiling…'
        echo 'Building the project...'
      }
      post {
        success { publishChecks name: '02. Build', status: 'COMPLETED', conclusion: 'SUCCESS', summary: 'Build ok' }
        failure { publishChecks name: '02. Build', status: 'COMPLETED', conclusion: 'FAILURE', summary: 'Build failed' }
      }
    }

    stage('Test') {
      steps {
        publishChecks name: '03. Tests', title: 'Unit Tests', status: 'IN_PROGRESS', summary: 'Running tests…'
        echo 'Running tests...'
      }
      post {
        success { publishChecks name: '03. Tests', status: 'COMPLETED', conclusion: 'SUCCESS', summary: 'All tests passed' }
        unstable { publishChecks name: '03. Tests', status: 'COMPLETED', conclusion: 'FAILURE', summary: 'Some tests failed' }
        failure { publishChecks name: '03. Tests', status: 'COMPLETED', conclusion: 'FAILURE', summary: 'Tests failed' }
      }
    }

    stage('Deploy') {
      when {
        allOf {
          not { changeRequest() }          // block on PRs
          anyOf { branch 'master'; buildingTag() }
        }
      }
      steps {
        publishChecks name: '04. Deploy', title: 'Deployment', status: 'IN_PROGRESS', summary: 'Deploying…'
        echo 'Deploying application...'
      }
      post {
        success { publishChecks name: '04. Deploy', status: 'COMPLETED', conclusion: 'SUCCESS', summary: 'Deployed' }
        failure { publishChecks name: '04. Deploy', status: 'COMPLETED', conclusion: 'FAILURE', summary: 'Deployment failed' }
      }
    }
  }

  post {
    // overall check
    success  { publishChecks name: '05. CI', status: 'COMPLETED', conclusion: 'SUCCESS', summary: 'Pipeline green' }
    failure  { publishChecks name: '05. CI', status: 'COMPLETED', conclusion: 'FAILURE', summary: 'Pipeline failed' }
    unstable { publishChecks name: '05. CI', status: 'COMPLETED', conclusion: 'FAILURE', summary: 'Pipeline unstable' }
  }
}
