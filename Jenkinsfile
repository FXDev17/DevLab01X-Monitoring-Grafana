pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'eu-west-2'
        ANSI_COLOR = "\033[34m" // Blue for info
        ANSI_SUCCESS = "\033[32m" // Green for success
        ANSI_WARNING = "\033[33m" // Yellow for warnings
        ANSI_ERROR = "\033[31m" // Red for errors
        ANSI_RESET = "\033[0m"

        // Set AWS credentials here directly from Jenkins' credentials manager
        AWS_ACCESS_KEY_ID = credentials('aws-access-key-id')  // Jenkins Credential ID
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')  // Jenkins Credential ID
    }

    tools {
        terraform 'Terraform'
    }

    stages {
        stage('Security Testing') {
            steps {
                script {
                    echo "${ANSI_COLOR}=== STARTING SECURITY TESTS ===${ANSI_RESET}"
                    
                    // CheckOV
                    echo "${ANSI_COLOR}🔍 Running CheckOV Scan...${ANSI_RESET}"
                    try {
                        sh '''
                            source /opt/security-tools-env/bin/activate
                            checkov -d . --soft-fail | sed "s/^/${ANSI_COLOR}[CheckOV] ${ANSI_RESET}/"
                            deactivate
                        '''
                        echo "${ANSI_SUCCESS}✅ CheckOV scan completed successfully${ANSI_RESET}"
                    } catch (Exception e) {
                        echo "${ANSI_WARNING}⚠️ CheckOV scan warnings: ${e.getMessage()}${ANSI_RESET}"
                    }

                    // Trivy
                    echo "${ANSI_COLOR}🔍 Running Trivy Filesystem Scan...${ANSI_RESET}"
                    try {
                        sh 'trivy fs --exit-code 1 --severity HIGH,CRITICAL . | sed "s/^/${ANSI_COLOR}[Trivy] ${ANSI_RESET}/"'
                        echo "${ANSI_SUCCESS}✅ Trivy scan completed successfully${ANSI_RESET}"
                    } catch (Exception e) {
                        echo "${ANSI_ERROR}❌ Trivy scan failed: ${e.getMessage()}${ANSI_RESET}"
                        error 'Stopping pipeline due to critical security issues'
                    }

                    // Snyk
                    echo "${ANSI_COLOR}🔍 Running Snyk Vulnerability Test...${ANSI_RESET}"
                    try {
                        withCredentials([string(credentialsId: 'snyk-token', variable: 'SNYK_TOKEN')]) {
                            sh 'snyk auth $SNYK_TOKEN'
                            sh 'snyk iac test . --severity-threshold=high -d | sed "s/^/${ANSI_COLOR}[Snyk] ${ANSI_RESET}/" || true'
                        }
                        echo "${ANSI_SUCCESS}✅ Snyk test completed successfully${ANSI_RESET}"
                    } catch (Exception e) {
                        echo "${ANSI_WARNING}⚠️ Snyk test warnings: ${e.getMessage()}${ANSI_RESET}"
                    }

                    // Gitleaks
                    echo "${ANSI_COLOR}🔍 Running Gitleaks Secrets Detection...${ANSI_RESET}"
                    try {
                        sh 'gitleaks detect --source . --exit-code 1 | sed "s/^/${ANSI_COLOR}[Gitleaks] ${ANSI_RESET}/"'
                        echo "${ANSI_SUCCESS}✅ Gitleaks scan completed successfully${ANSI_RESET}"
                    } catch (Exception e) {
                        echo "${ANSI_ERROR}❌ Gitleaks failed: ${e.getMessage()}${ANSI_RESET}"
                        error 'Stopping pipeline due to secrets detected'
                    }

                    echo "${ANSI_SUCCESS}✔️ All security tests completed${ANSI_RESET}"
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                script {
                    echo "${ANSI_COLOR}📝 Generating Terraform Plan...${ANSI_RESET}"
                    try {
                        dir('env/dev') {
                            // Use the AWS credentials directly from environment variables
                            sh '''
                                terraform init | sed "s/^/${ANSI_COLOR}[TF Init] ${ANSI_RESET}/"
                                terraform plan -out=tfplan | sed "s/^/${ANSI_COLOR}[TF Plan] ${ANSI_RESET}/"
                                terraform apply -auto-approve tfplan | sed "s/^/${ANSI_COLOR}[TF Apply] ${ANSI_RESET}/"

                            '''
                        }
                        echo "${ANSI_SUCCESS}✅ Terraform plan generated successfully${ANSI_RESET}"
                    } catch (Exception e) {
                        echo "${ANSI_ERROR}❌ Terraform Plan failed: ${e.getMessage()}${ANSI_RESET}"
                        error 'Stopping pipeline due to Terraform Plan failure'
                    }
                }
            }
        }

        // stage('Approval') {
        //     steps {
        //         script {
        //             echo "${ANSI_COLOR}🛑 Manual Approval Required${ANSI_RESET}"
        //             def userInput = input(
        //                 id: 'approvePlan',
        //                 message: 'Approve Terraform Plan?',
        //                 ok: 'Approve',
        //                 submitter: 'admin',
        //                 parameters: [choice(name: 'ACTION', choices: ['Approve', 'Reject'], description: 'Approve or Reject the plan')]
        //             )
        //             if (userInput == 'Reject') {
        //                 echo "${ANSI_ERROR}❌ Plan rejected by user${ANSI_RESET}"
        //                 error 'Pipeline stopped due to rejection'
        //             }
        //             echo "${ANSI_SUCCESS}👍 Plan approved${ANSI_RESET}"
        //         }
        //     }
        // }

        stage('Terraform Apply') {
            steps {
                script {
                    echo "${ANSI_COLOR}🚀 Applying Terraform Changes...${ANSI_RESET}"
                    try {
                        dir('env/dev') {
                            sh 'terraform apply -auto-approve tfplan | sed "s/^/${ANSI_COLOR}[TF Apply] ${ANSI_RESET}/"'
                        }
                        echo "${ANSI_SUCCESS}🎉 Terraform changes applied successfully!${ANSI_RESET}"
                    } catch (Exception e) {
                        echo "${ANSI_ERROR}❌ Terraform Apply failed: ${e.getMessage()}${ANSI_RESET}"
                        error 'Stopping pipeline due to Terraform Apply failure'
                    }
                }
            }
        }
    }

    post {
        always {
            echo "${ANSI_COLOR}🧹 Pipeline finished. Cleaning up...${ANSI_RESET}"
            sh 'rm -f tfplan'
        }
        success {
            echo "${ANSI_SUCCESS}✨ Pipeline succeeded!${ANSI_RESET}"
        }
        failure {
            echo "${ANSI_ERROR}💥 Pipeline failed. Review the logs above for details.${ANSI_RESET}"
        }
    }
}
