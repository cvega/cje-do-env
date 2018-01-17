pipeline {
  agent any
  stages {
    stage('build') {
      steps {
        sh 'echo "build"'
      }
    }
    stage('test') {
      parallel {
        stage('test') {
          steps {
            junit '*.junit.xml'
          }
        }
        stage('sonarqube') {
          steps {
            sh 'echo "sonar doing stuff"'
          }
        }
      }
    }
    stage('package') {
      steps {
        sh 'echo "whoa package is ready"'
        sh 'echo "2nd step"'
      }
    }
    stage('deploy') {
      steps {
        sh 'echo "deploy"'
      }
    }
  }
}