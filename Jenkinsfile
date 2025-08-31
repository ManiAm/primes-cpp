pipeline {

  agent any

  options { skipDefaultCheckout(true) }

  stages {

    stage('Checkout') {
      steps {
        publishChecks name: 'Checkout', title: 'Checkout', status: 'IN_PROGRESS', summary: 'Starting…'
        echo 'Checking out the code...'
      }
      post {
        success { publishChecks name: 'Checkout', status: 'COMPLETED', conclusion: 'SUCCESS', summary: 'Checked out' }
        failure { publishChecks name: 'Checkout', status: 'COMPLETED', conclusion: 'FAILURE', summary: 'Checkout failed' }
      }
    }

    stage('Build') {
      steps {
        publishChecks name: 'Build', title: 'Build', status: 'IN_PROGRESS', summary: 'Compiling…'
        echo 'Building the project...'
      }
      post {
        success { publishChecks name: 'Build', status: 'COMPLETED', conclusion: 'SUCCESS', summary: 'Build ok' }
        failure { publishChecks name: 'Build', status: 'COMPLETED', conclusion: 'FAILURE', summary: 'Build failed' }
      }
    }

    stage('Test') {
      steps {
        publishChecks name: 'Tests', title: 'Unit Tests', status: 'IN_PROGRESS', summary: 'Running tests…'
        echo 'Running tests...'
      }
      post {
        success { publishChecks name: 'Tests', status: 'COMPLETED', conclusion: 'SUCCESS', summary: 'All tests passed' }
        unstable { publishChecks name: 'Tests', status: 'COMPLETED', conclusion: 'FAILURE', summary: 'Some tests failed' }
        failure { publishChecks name: 'Tests', status: 'COMPLETED', conclusion: 'FAILURE', summary: 'Tests failed' }
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
        publishChecks name: 'Deploy', title: 'Deployment', status: 'IN_PROGRESS', summary: 'Deploying…'
        echo 'Deploying application...'
      }
      post {
        success { publishChecks name: 'Deploy', status: 'COMPLETED', conclusion: 'SUCCESS', summary: 'Deployed' }
        failure { publishChecks name: 'Deploy', status: 'COMPLETED', conclusion: 'FAILURE', summary: 'Deployment failed' }
      }
    }
  }
  post {
    // Optional overall check
    success  { publishChecks name: 'CI', status: 'COMPLETED', conclusion: 'SUCCESS', summary: 'Pipeline green' }
    failure  { publishChecks name: 'CI', status: 'COMPLETED', conclusion: 'FAILURE', summary: 'Pipeline failed' }
    unstable { publishChecks name: 'CI', status: 'COMPLETED', conclusion: 'FAILURE', summary: 'Pipeline unstable' }
  }
}
