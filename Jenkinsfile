pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'eu-west-2'
    }

    tools {
        terraform 'Terraform'  // Must match Jenkins tool config
    }

    stages {
        stage('Security Testing') {
            steps {
                script {
                    // Colors for console output
                    def RED = '\u001b[31m'
                    def GREEN = '\u001b[32m'
                    def YELLOW = '\u001b[33m'
                    def RESET = '\u001b[0m'

                    echo -e "${YELLOW}🔒 Starting Security Tests...${RESET}"

                    // Checkov
                    try {
                        sh '''
                            source /opt/security-tools-env/bin/activate
                            checkov -d . --soft-fail
                            deactivate
                        '''
                    } catch (Exception e) {
                        echo -e "${RED}✖ Checkov scan failed: ${e.getMessage()}${RESET}"
                    }

                    // Trivy
                    try {
                        sh 'trivy fs --exit-code 1 --severity HIGH,CRITICAL .'
                    } catch (Exception e) {
                        echo -e "${RED}✖ Trivy scan failed: ${e.getMessage()}${RESET}"
                        error 'Stopping pipeline due to critical security issues'
                    }

                    // Snyk
                    try {
                        withCredentials([string(credentialsId: 'snyk-token', variable: 'SNYK_TOKEN')]) {
                            sh '''
                                snyk auth $SNYK_TOKEN
                                snyk iac test . --severity-threshold=high -d || true
                            '''
                        }
                    } catch (Exception e) {
                        echo -e "${RED}✖ Snyk test failed: ${e.getMessage()}${RESET}"
                    }

                    // Gitleaks
                    try {
                        sh 'gitleaks detect --source . --exit-code 1'
                    } catch (Exception e) {
                        echo -e "${RED}✖ Gitleaks failed: ${e.getMessage()}${RESET}"
                        error 'Stopping pipeline due to secrets detected'
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                script {
                    def YELLOW = '\u001b[33m'
                    def RED = '\u001b[31m'
                    def RESET = '\u001b[0m'

                    echo -e "${YELLOW}📝 Generating Terraform Plan...${RESET}"
                    dir('env/dev') {
                        try {
                            sh 'terraform init'
                            sh 'terraform plan -out=tfplan'
                        } catch (Exception e) {
                            echo -e "${RED}✖ Terraform Plan failed: ${e.getMessage()}${RESET}"
                            error 'Stopping pipeline due to Terraform Plan failure'
                        }
                    }
                }
            }
        }

        stage('Approval') {
            steps {
                script {
                    def YELLOW = '\u001b[33m'
                    def GREEN = '\u001b[32m'
                    def RED = '\u001b[31m'
                    def RESET = '\u001b[0m'

                    echo -e "${YELLOW}⏳ Awaiting Approval...${RESET}"
                    def userInput = input(
                        id: 'approvePlan',
                        message: 'Approve Terraform Plan?',
                        ok: 'Approve',
                        submitter: 'admin',
                        parameters: [choice(name: 'ACTION', choices: ['Approve', 'Reject'], description: 'Approve or Reject the plan')]
                    )
                    if (userInput == 'Reject') {
                        echo -e "${RED}✖ Plan rejected by user.${RESET}"
                        error 'Pipeline stopped due to rejection.'
                    }
                    echo -e "${GREEN}✔ Plan approved. Proceeding...${RESET}"
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                script {
                    def YELLOW = '\u001b[33m'
                    def RED = '\u001b[31m'
                    def RESET = '\u001b[0m'

                    echo -e "${YELLOW}🚀 Applying Terraform Changes...${RESET}"
                    dir('env/dev') {
                        try {
                            sh 'terraform apply -auto-approve tfplan'
                        } catch (Exception e) {
                            echo -e "${RED}✖ Terraform Apply failed: ${e.getMessage()}${RESET}"
                            error 'Stopping pipeline due to Terraform Apply failure'
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            def YELLOW = '\u001b[33m'
            def RESET = '\u001b[0m'
            echo -e "${YELLOW}🧹 Pipeline finished. Cleaning up...${RESET}"
            sh 'rm -f env/dev/tfplan || true'
        }
        success {
            def GREEN = '\u001b[32m'
            def RESET = '\u001b[0m'
            echo -e "${GREEN}🎉 Terraform changes applied successfully!${RESET}"
        }
        failure {
            def RED = '\u001b[31m'
            def RESET = '\u001b[0m'
            echo -e "${RED}❌ Pipeline failed. Review logs for details.${RESET}"
        }
    }
}