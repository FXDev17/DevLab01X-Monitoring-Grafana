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
                    echo 'Starting Security Tests...'

                    // Checkov: Static code analysis
                    echo 'Running CheckOV Scan...'
                    try {
                        sh  '''
                            source /opt/security-tools-env/bin/activate
                            checkov -d . --soft-fail
                            deactivate
                            ''' // to use when checkov is created in an venv
                        // sh 'sudo /home/ec2-user/.local/bin/checkov -d . --soft-fail'
                        echo 'Checkov scan completed successfully.'
                    } catch (Exception e) {
                        echo "Checkov scan failed: ${e.getMessage()}"
                    }

                    // Trivy: Filesystem scan
                    echo 'Running Trivy filesystem scan...'
                    try {
                        sh 'trivy fs --exit-code 1 --severity HIGH,CRITICAL .'
                        echo 'Trivy scan completed successfully.'
                    } catch (Exception e) {
                        echo "Trivy scan failed: ${e.getMessage()}"
                        error 'Stopping pipeline due to critical security issues'
                    }

                    echo 'Running Snyk vulnerability test...'
                    sh 'ls -la .'  // Debug
                    try {
                        withCredentials([string(credentialsId: 'snyk-token', variable: 'SNYK_TOKEN')]) {
                            sh 'snyk auth $SNYK_TOKEN && echo "Snyk authenticated successfully"'
                            sh 'snyk iac test . --severity-threshold=high -d || true'
                        }
                        echo 'Snyk test completed successfully.'
                    } catch (Exception e) {
                        echo "Snyk test failed: ${e.getMessage()}"
                    }

                    // Gitleaks: Secrets detection
                    echo 'Running Gitleaks secrets detection...'
                    try {
                        sh 'gitleaks detect --source . --exit-code 1'
                        echo 'Gitleaks scan completed successfully.'
                    } catch (Exception e) {
                        echo "Gitleaks failed: ${e.getMessage()}"
                        error 'Stopping pipeline due to secrets detected'
                    }

                    echo 'All security tests completed.'
                }
            }
        }

        // Pipeline Check Terraform Plan With SSHKeys
        stage('Terraform Plan') {
            steps { 
                script {
                    try {
                        echo 'Generating Terraform Plan...'
                        
                        // Change to the env/dev directory before running terraform commands
                        dir('env/dev') {
                            // Securely pass the SSH key using withCredentials
                            withCredentials([string(credentialsId: 'jenkins_ssh_public_key', variable: 'SSH_KEY')]) {
                                // Initialize Terraform
                                sh 'terraform init'
                                
                                // Run terraform plan from the correct directory and securely pass the SSH key
                                sh "terraform plan -var 'ssh_public_key=${SSH_KEY}' -out=tfplan"
                            }
                        }
                    } catch (Exception e) {
                        echo "Terraform Plan failed: ${e.getMessage()}"
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
                    def userInput = input(
                        id: 'approvePlan',
                        message: 'Approve Terraform Plan?',
                        ok: 'Approve',
                        submitter: 'admin',  // Optional: restrict to admins
                        parameters: [choice(name: 'ACTION', choices: ['Approve', 'Reject'], description: 'Approve or Reject the plan')]
                    )
                    if (userInput == 'Reject') {
                        echo 'Plan rejected by user.'
                        error 'Pipeline stopped due to rejection.'
                    }
                    echo 'Plan approved. Proceeding...'
                }
            }
        }
        // Pipeline Check Terraform Apply
        stage('Terraform Apply') {
            steps {
                script {
                    try {
                        echo 'Applying Terraform changes...'
                        dir('env/dev') {
                            
                            sh 'terraform apply -auto-approve tfplan'
                        }
                    } catch (Exception e) {
                        echo "Terraform Apply failed: ${e.getMessage()}"
                        error 'Stopping pipeline due to Terraform Apply failure'
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline finished. Cleaning up...'
            sh 'rm -f tfplan'
        }
        success {
            echo 'Terraform changes applied successfully!'
        }
        failure {
            echo 'Pipeline failed. Review the logs for details.'
        }
    }
}