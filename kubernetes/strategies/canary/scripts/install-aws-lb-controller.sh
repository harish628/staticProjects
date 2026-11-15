#!/usr/bin/env bash
# Installs AWS Load Balancer Controller on an existing EKS cluster.
# Requires: aws cli, eksctl, helm, kubectl (already pointed at your cluster)
set -euo pipefail

CLUSTER_NAME="<YOUR_EKS_CLUSTER_NAME>"
VPC_ID="<YOUR_VPC_ID>"
REGION="ap-southeast-2"
ACCOUNT_ID="430398381271"

# 1. OIDC provider (needed for IRSA)
eksctl utils associate-iam-oidc-provider --cluster "$CLUSTER_NAME" --region "$REGION" --approve

# 2. IAM policy for the controller
curl -sSLo iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://iam_policy.json || echo "Policy already exists, continuing"

# 3. Service account with IAM role (IRSA)
eksctl create iamserviceaccount \
  --cluster "$CLUSTER_NAME" --region "$REGION" \
  --namespace kube-system --name aws-load-balancer-controller \
  --attach-policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy" \
  --override-existing-serviceaccounts --approve

# 4. Install controller via Helm
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName="$CLUSTER_NAME" \
  --set region="$REGION" \
  --set vpcId="$VPC_ID" \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

# 5. Verify
kubectl rollout status deployment/aws-load-balancer-controller -n kube-system
