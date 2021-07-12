#Another approach is to create the secure password directly using AWS Console 
#and then fetch those values using data keyword
# https://medium.com/@whaleberry/tips-for-storing-secrets-with-aws-ssm-parameter-store-d70a4a42c64
# aws ssm put-parameter --name /database/mysql/password --value "testing" --type SecureString --key-id alias/finance
# Run the following command to verify the details of the parameter , use --region us-west-1 to be more precise
# aws ssm get-parameters --name "/database/mysql/password" --with-decryption

data "aws_ssm_parameter" "mysql_password" {
  name = "/database/mysql/password"
}


# https://aws.amazon.com/premiumsupport/knowledge-center/ecs-data-security-container-task/