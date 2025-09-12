aws ecr create-repository \
    --repository-name comfyui-wan \
    --region eu-west-1 \
    --image-scanning-configuration scanOnPush=true \
    --encryption-configuration encryptionType=AES256 \
    --profile warsztat-terraform