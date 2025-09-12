aws iam create-policy \
    --policy-name ECRComfyUIFullAccess \
    --policy-document file://ecr-policy.json \
    --profile warsztat-terraform

aws iam create-user --user-name github-actions-ecr \
    --profile warsztat-terraform


aws iam attach-user-policy \
    --user-name github-actions-ecr \
    --policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/ECRComfyUIFullAccess \
    --profile warsztat-terraform

aws iam create-access-key --user-name github-actions-ecr \
    --profile warsztat-terraform



aws iam create-policy \
    --policy-name ECRComfyUIReadOnly \
    --policy-document file://ecr-readonly-policy.json \
    --profile warsztat-terraform

aws iam create-user --user-name runpod-ecr-readonly \
    --profile warsztat-terraform

aws iam attach-user-policy \
    --user-name runpod-ecr-readonly \
    --policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/ECRComfyUIReadOnly \
    --profile warsztat-terraform

aws iam create-access-key --user-name runpod-ecr-readonly \
    --profile warsztat-terraform