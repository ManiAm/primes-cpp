
def checks
def CORES = '4'  // fallback

pipeline {
  agent any

  options {
    skipDefaultCheckout(true)
    timestamps()
  }

  environment {
    DEBIAN_FRONTEND = 'noninteractive'
    PATH = "${env.HOME}/.local/bin:${env.PATH}"
  }

  stages {

    stage('01. Init & Checkout') {
      steps {
        publishChecks name: '01. Checkout', title: 'Checkout', status: 'IN_PROGRESS', summary: 'Starting…'
        checkout scm
        script { checks = load 'jenkins/lib/Checks.groovy' }
      }
      post {
        success { publishChecks name: '01. Checkout', status: 'COMPLETED', conclusion: 'SUCCESS', summary: 'Checked out' }
        failure { publishChecks name: '01. Checkout', status: 'COMPLETED', conclusion: 'FAILURE', summary: 'Checkout failed' }
      }
    }

    stage('02. Prepare Environment') {
      steps {
        checks.start('02. Prepare', 'Prepare', 'Installing deps & Conan…')
        sh label: 'OS + Python deps', script: 'jenkins/scripts/prepare_env.sh'
      }
      post {
        success { checks.ok('02. Prepare', 'Deps ready') }
        failure { checks.fail('02. Prepare', 'Prepare failed') }
      }
    }

    stage('03. Conan Setup') {
      steps {
        checks.start('03. Conan', 'Conan', 'Detecting profile & installing…')
        sh label: 'Conan profile + install', script: 'jenkins/scripts/conan_setup.sh'
      }
      post {
        success { checks.ok('03. Conan', 'Conan configured') }
        failure { checks.fail('03. Conan', 'Conan failed') }
      }
    }

    stage('04. Lint') {
      steps {
        checks.start('04. Lint', 'Lint', 'clang-format / linters…')
        sh label: 'Lint', script: "jenkins/scripts/run_with_conan.sh 'make lint'"
      }
      post {
        success { checks.ok('04. Lint', 'Lint clean') }
        unstable { checks.fail('04. Lint', 'Lint issues found') }
        failure { checks.fail('04. Lint', 'Lint failed') }
      }
    }

    stage('05. Static Analysis') {
      steps {
        checks.start('05. Static', 'Static Analysis', 'cppcheck, etc.…')
        sh label: 'Static', script: "jenkins/scripts/run_with_conan.sh 'make static'"
      }
      post {
        success { checks.ok('05. Static', 'Static analysis ok') }
        unstable { checks.fail('05. Static', 'Static analysis issues') }
        failure { checks.fail('05. Static', 'Static analysis failed') }
      }
    }

    stage('06. Build') {
      steps {
        checks.start('06. Build', 'Build', 'Compiling…')
        script { CORES = sh(returnStdout: true, script: 'nproc || echo 4').trim() }
        sh label: 'Build', script: "jenkins/scripts/run_with_conan.sh 'make -j ${CORES} build'"
      }
      post {
        success { checks.ok('06. Build', 'Build ok') }
        failure { checks.fail('06. Build', 'Build failed') }
      }
    }

    stage('07. Test') {
      steps {
        checks.start('07. Test', 'Unit Tests', 'Running tests…')
        sh label: 'Test', script: "jenkins/scripts/run_with_conan.sh 'make -j ${CORES} test'"
      }
      post {
        success { checks.ok('07. Test', 'All tests passed') }
        unstable { checks.fail('07. Test', 'Some tests failed') }
        failure { checks.fail('07. Test', 'Tests failed') }
        always {
          catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
            junit allowEmptyResults: true, testResults: 'build/**/junit*.xml'
          }
          archiveArtifacts artifacts: 'build/**/test-logs/**', allowEmptyArchive: true
        }
      }
    }

    stage('08. Coverage') {
      steps {
        checks.start('08. Coverage', 'Coverage', 'gcovr…')
        sh label: 'Coverage', script: "jenkins/scripts/run_with_conan.sh 'make coverage'"
      }
      post {
        success { checks.ok('08. Coverage', 'Coverage generated') }
        failure { checks.fail('08. Coverage', 'Coverage failed') }
        always {
          archiveArtifacts artifacts: 'build/**/coverage*/**/*, coverage*/**/*', allowEmptyArchive: true
          // publishCoverage adapters: [gcovrAdapter('build/coverage/coverage.xml')], sourceFileResolver: sourceFiles('STORE_ALL_BUILD')
        }
      }
    }

    stage('09. Package') {
      steps {
        checks.start('09. Package', 'Package', 'Creating distributables…')
        sh label: 'Package', script: "jenkins/scripts/run_with_conan.sh 'make package'"
      }
      post {
        success { checks.ok('09. Package', 'Artifacts packaged') }
        failure { checks.fail('09. Package', 'Packaging failed') }
        always {
          archiveArtifacts artifacts: 'dist/**', allowEmptyArchive: true
        }
      }
    }

    stage('10. Deploy') {
      when {
        allOf {
          not { changeRequest() }
          anyOf { branch 'master'; branch 'main'; buildingTag() }
        }
      }
      steps {
        checks.start('10. Deploy', 'Deployment', 'Deploying…')
        echo 'Deploying application...'
      }
      post {
        success { checks.ok('10. Deploy', 'Deployed') }
        failure { checks.fail('10. Deploy', 'Deployment failed') }
      }
    }
  }

  post {
    success  { publishChecks name: 'CI Summary', status: 'COMPLETED', conclusion: 'SUCCESS', summary: 'Pipeline green' }
    failure  { publishChecks name: 'CI Summary', status: 'COMPLETED', conclusion: 'FAILURE', summary: 'Pipeline failed' }
    unstable { publishChecks name: 'CI Summary', status: 'COMPLETED', conclusion: 'FAILURE', summary: 'Pipeline unstable' }
    always {
      sh 'conan --version || true'
      sh 'git rev-parse --short HEAD || true'
    }
  }
}
