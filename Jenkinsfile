pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'eu-west-2'
        ANSI_COLOR = "\033[34m"         // Blue
        ANSI_SUCCESS = "\033[32m"       // Green
        ANSI_WARNING = "\033[33m"       // Yellow
        ANSI_ERROR = "\033[31m"         // Red
        ANSI_RESET = "\033[0m"

        AWS_ACCESS_KEY_ID = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
    }

    tools {
        terraform 'Terraform'
    }

    stages {
        stage('Security Testing') {
            steps {
                script {
                    echo "${ANSI_COLOR}=== STARTING SECURITY TESTS ===${ANSI_RESET}"

                    echo "${ANSI_COLOR}🔍 Running CheckOV Scan...${ANSI_RESET}"
                    try {
                        sh '''
                            source /opt/security-tools-env/bin/activate
                            checkov -d . --soft-fail | sed "s/^/\\033[34m[CheckOV] \\033[0m/"
                            deactivate
                        '''
                        echo "${ANSI_SUCCESS}✅ CheckOV scan completed successfully${ANSI_RESET}"
                    } catch (Exception e) {
                        echo "${ANSI_WARNING}⚠️ CheckOV scan warnings: ${e.getMessage()}${ANSI_RESET}"
                    }

                    echo "${ANSI_COLOR}🔍 Running Trivy Filesystem Scan...${ANSI_RESET}"
                    try {
                        sh '''
                            trivy fs --exit-code 1 --severity HIGH,CRITICAL . | sed "s/^/\\033[34m[Trivy] \\033[0m/"
                        '''
                        echo "${ANSI_SUCCESS}✅ Trivy scan completed successfully${ANSI_RESET}"
                    } catch (Exception e) {
                        echo "${ANSI_ERROR}❌ Trivy scan failed: ${e.getMessage()}${ANSI_RESET}"
                        error 'Stopping pipeline due to critical security issues'
                    }

                    echo "${ANSI_COLOR}🔍 Running Snyk Vulnerability Test...${ANSI_RESET}"
                    try {
                        withCredentials([string(credentialsId: 'snyk-token', variable: 'SNYK_TOKEN')]) {
                            sh '''
                                snyk auth $SNYK_TOKEN
                                snyk iac test . --severity-threshold=high -d | sed "s/^/\\033[34m[Snyk] \\033[0m/" || true
                            '''
                        }
                        echo "${ANSI_SUCCESS}✅ Snyk test completed successfully${ANSI_RESET}"
                    } catch (Exception e) {
                        echo "${ANSI_WARNING}⚠️ Snyk test warnings: ${e.getMessage()}${ANSI_RESET}"
                    }

                    echo "${ANSI_COLOR}🔍 Running Gitleaks Secrets Detection...${ANSI_RESET}"
                    try {
                        sh '''
                            gitleaks detect --source . --exit-code 1 | sed "s/^/\\033[34m[Gitleaks] \\033[0m/"
                        '''
                        echo "${ANSI_SUCCESS}✅ Gitleaks scan completed successfully${ANSI_RESET}"
                    } catch (Exception e) {
                        echo "${ANSI_ERROR}❌ Gitleaks failed: ${e.getMessage()}${ANSI_RESET}"
                        error 'Stopping pipeline due to secrets detected'
                    }

                    echo "${ANSI_SUCCESS}✔️ All security tests completed${ANSI_RESET}"
                }
            }
        }

        stage('Terraform Plan & Apply') {
            steps {
                script {
                    echo "${ANSI_COLOR}📝 Generating Terraform Plan & Applying Changes...${ANSI_RESET}"
                    try {
                        dir('env/dev') {
                            sh '''
                                terraform init | sed "s/^/\\033[34m[TF Init] \\033[0m/"
                                terraform plan -out=tfplan | sed "s/^/\\033[34m[TF Plan] \\033[0m/"
                                terraform apply -auto-approve tfplan | sed "s/^/\\033[34m[TF Apply] \\033[0m/"
                            '''
                        }
                        echo "${ANSI_SUCCESS}✅ Terraform apply completed successfully${ANSI_RESET}"
                    } catch (Exception e) {
                        echo "${ANSI_ERROR}❌ Terraform failed: ${e.getMessage()}${ANSI_RESET}"
                        error 'Stopping pipeline due to Terraform failure'
                    }
                }
            }
        }

        /*
        stage('Manual Approval') {
            steps {
                script {
                    def userInput = input(
                        id: 'approvePlan',
                        message: 'Approve Terraform Plan?',
                        ok: 'Approve',
                        parameters: [
                            choice(name: 'ACTION', choices: ['Approve', 'Reject'], description: 'Choose an action')
                        ]
                    )
                    if (userInput == 'Reject') {
                        echo "${ANSI_ERROR}❌ Plan rejected by user${ANSI_RESET}"
                        error 'Pipeline stopped due to rejection'
                    } else {
                        echo "${ANSI_SUCCESS}👍 Plan approved${ANSI_RESET}"
                    }
                }
            }
        }
        */
    }

    post {
        always {
            echo "${ANSI_COLOR}🧹 Pipeline finished. Cleaning up...${ANSI_RESET}"
            sh 'rm -f tfplan || true'
        }
        success {
            echo "${ANSI_SUCCESS}✨ Pipeline succeeded!${ANSI_RESET}"
        }
        failure {
            echo "${ANSI_ERROR}💥 Pipeline failed. Review the logs above for details.${ANSI_RESET}"
        }
    }
}
