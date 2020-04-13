#!/bin/bash env

## https://docs.gitlab.com/charts/installation/cloud/gke.html
## https://docs.gitlab.com/charts/installation/deployment.html

export REGION='us-central1'
export CLUSTER_NAME='gitlab-cluster'
export EMAIL=''

# execute GitLab commands commands
# Using https://gitlab.com/gitlab-org/charts/gitlab/-/tree/master/scripts

./gitlab/gke_bootstrap_script.sh up

gcloud compute addresses create ${CLUSTER_NAME}-external-ip --region $REGION --project $PROJECT

export EXTERNAL_IP=$(gcloud compute addresses describe ${CLUSTER_NAME}-external-ip --region $REGION --project $PROJECT --format='value(address)')

export DOMAIN=$EXTERNAL_IP'.xip.io'

helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm upgrade --install gitlab gitlab/gitlab \
#  --timeout 600 \
  --set global.hosts.domain=$DOMAIN \
  --set global.hosts.externalIP=$EXTERNAL_IP \
  --set certmanager-issuer.email=$EMAIL

#export PASSWORD=$(kubectl get secret <name>-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode ; echo)

export PASSWORD=$(kubectl get secret gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode ; echo)

echo 'your password is ' $PASSWORD
echo 'your username is ' $EMAIL
echo 'Please visit https://'$DOMAIN 'in your browser'