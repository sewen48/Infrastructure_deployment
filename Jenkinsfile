pipeline {
    agent any
    environment {
        AWS_ACCOUNT_ID = credentials('account_id')
        AWS_DEFAULT_REGION="us-east-1"     
    }
        
    stages {
        stage('Infrastructure Deployment') {
           environment {
             AWS_ACCESS_KEY_ID = credentials('aws_access_key_id')
             AWS_SECRET_ACCESS_KEY = credentials('aws_secret_access_key')
           }
           steps {
              script {
                  bash "terraform init"
                  bash "terraform validate"
                  bash "terraform plan"
                  bash "terraform ${action} --auto-approve"
            }
        }
               
     }
    }
    
}
