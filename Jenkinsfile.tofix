pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'eu-west-2'  // Set your region
    }

    tools {
        terraform 'Terraform'  // Must match Jenkins tool config
    }

    stages {
        // Pipeline Check Security Testing: CheckOV, TRIVY, SNYK, GITLEAKS
        stage('Security Testing') {
            steps {
                script {
                    def RED = '\u001b[31m'
                    def GREEN = '\u001b[32m'
                    def RESET = '\u001b[0m'

                    try {
                        // Checkov: Static code analysis
                        sh '''
                            source /opt/security-tools-env/bin/activate
                            checkov -d . --soft-fail
                            deactivate
                        '''
                        // sh 'sudo /home/ec2-user/.local/bin/checkov -d . --soft-fail'

                        // Trivy: Filesystem scan
                        sh 'trivy fs --exit-code 1 --severity HIGH,CRITICAL .'

                        // Snyk
                        sh 'ls -la .'  // Debug
                        withCredentials([string(credentialsId: 'snyk-token', variable: 'SNYK_TOKEN')]) {
                            sh 'snyk auth $SNYK_TOKEN && echo "Snyk authenticated successfully"'
                            sh 'snyk iac test . --severity-threshold=high -d || true'
                        }

                        // Gitleaks: Secrets detection
                        sh 'gitleaks detect --source . --exit-code 1'

                        echo -e "${GREEN}✔ Pass${RESET}"
                    } catch (Exception e) {
                        echo -e "${RED}✖ Security Testing failed: ${e.getMessage()}${RESET}"
                        if (e.getMessage().contains('trivy') || e.getMessage().contains('gitleaks')) {
                            error 'Stopping pipeline due to critical security issues'
                        }
                    }
                }
            }
        }

        // Pipeline Check Terraform Plan With SSHKeys Config
        stage('Terraform Plan') {
            steps {
                script {
                    def RED = '\u001b[31m'
                    def GREEN = '\u001b[32m'
                    def RESET = '\u001b[0m'

                    try {
                        dir('env/dev') {
                            // Securely pass the SSH key using withCredentials
                            withCredentials([string(credentialsId: 'jenkins_ssh_public_key', variable: 'SSH_KEY')]) {
                                // Initialize Terraform
                                sh 'terraform init'
                                
                                // Run terraform plan from the correct directory and securely pass the SSH key
                                sh "terraform plan -var 'ssh_public_key=${SSH_KEY}' -out=tfplan"
                            }
                        }
                        echo -e "${GREEN}✔ Pass${RESET}"
                    } catch (Exception e) {
                        echo -e "${RED}✖ Terraform Plan failed: ${e.getMessage()}${RESET}"
                        error 'Stopping pipeline due to Terraform Plan failure'
                    }
                }
            }
        }

        // stage('Terraform Plan') {
        //     steps { 
        //         script {
        //             try {
        //                 echo 'Generating Terraform Plan...'
                        
        //                 // Change to the env/dev directory before running terraform commands
        //                 dir('env/dev') {
        //                     // Securely pass the SSH key using withCredentials
        //                         // Initialize Terraform
        //                         sh 'terraform init'
                                
        //                         // Run terraform plan from the correct directory and securely pass the SSH key
        //                         sh "terraform plan -out=tfplan"
        //                 }
        //             } catch (Exception e) {
        //                 echo "Terraform Plan failed: ${e.getMessage()}"
        //                 error 'Stopping pipeline due to Terraform Plan failure'
        //             }
        //         }
        //     }
        // }

        // Pipeline Check Terraform Approval
        stage('Approval') {
            steps {
                script {
                    def RED = '\u001b[31m'
                    def GREEN = '\u001b[32m'
                    def RESET = '\u001b[0m'

                    try {
                        def userInput = input(
                            id: 'approvePlan',
                            message: 'Approve Terraform Plan?',
                            ok: 'Approve',
                            submitter: 'admin',  // Optional: restrict to admins
                            parameters: [choice(name: 'ACTION', choices: ['Approve', 'Reject'], description: 'Approve or Reject the plan')]
                        )
                        if (userInput == 'Reject') {
                            echo -e "${RED}✖ Plan rejected by user${RESET}"
                            error 'Pipeline stopped due to rejection.'
                        }
                        echo -e "${GREEN}✔ Pass${RESET}"
                    } catch (Exception e) {
                        echo -e "${RED}✖ Approval failed: ${e.getMessage()}${RESET}"
                        error 'Stopping pipeline due to approval failure'
                    }
                }
            }
        }

        // Pipeline Check Terraform Apply
        stage('Terraform Apply') {
            steps {
                script {
                    def RED = '\u001b[31m'
                    def GREEN = '\u001b[32m'
                    def RESET = '\u001b[0m'

                    try {
                        dir('env/dev') {
                            sh 'terraform apply -auto-approve tfplan'
                        }
                        echo -e "${GREEN}✔ Pass${RESET}"
                    } catch (Exception e) {
                        echo -e "${RED}✖ Terraform Apply failed: ${e.getMessage()}${RESET}"
                        error 'Stopping pipeline due to Terraform Apply failure'
                    }
                }
            }
        }
    }

    post {
        always {
            def YELLOW = '\u001b[33m'
            def RESET = '\u001b[0m'
            echo -e "${YELLOW}🧹 Cleaning up...${RESET}"
            sh 'rm -f env/dev/tfplan || true'
        }
        success {
            def GREEN = '\u001b[32m'
            def RESET = '\u001b[0m'
            echo -e "${GREEN}🎉 Pipeline completed successfully!${RESET}"
        }
        failure {
            def RED = '\u001b[31m'
            def RESET = '\u001b[0m'
            echo -e "${RED}❌ Pipeline failed - Check logs${RESET}"
        }
    }
}