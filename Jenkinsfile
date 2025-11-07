pipeline {
    agent any

    environment {
        // Example environment variable
        APP_ENV = "test"
    }

    stages {
        stage('Init') {
            steps {
                echo "🚀 Starting pipeline for branch: ${env.BRANCH_NAME}"
                echo "🧭 Change ID (if PR): ${env.CHANGE_ID ?: 'N/A'}"
                echo "🔧 Running on node: ${env.NODE_NAME}"
            }
        }

        stage('Build') {
            when {
                expression {
                    // Skip this stage if it's a PR build
                    return !env.BRANCH_NAME.startsWith("PR-")
                }
            }
            steps {
                echo "🏗️ Building branch: ${env.BRANCH_NAME}"
                sh 'echo "Simulating build step..."'
            }
        }

        stage('PR Check') {
            when {
                expression {
                    // Run only for PRs
                    return env.BRANCH_NAME.startsWith("PR-")
                }
            }
            steps {
                echo "🧩 This is a Pull Request build!"
                echo "🔀 PR ID: ${env.CHANGE_ID}, Target: ${env.CHANGE_TARGET}"
            }
        }

        stage('Test') {
            steps {
                echo "🧪 Running tests for branch: ${env.BRANCH_NAME}"
                sh 'echo "Running unit tests..."'
            }
        }

        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                echo "🚢 Deploying main branch to production..."
                sh 'echo "Deployment successful!"'
            }
        }
    }

    post {
        always {
            echo "✅ Pipeline completed for branch: ${env.BRANCH_NAME}"
        }
        success {
            echo "🎉 Build succeeded!"
        }
        failure {
            echo "❌ Build failed!"
        }
    }
}
