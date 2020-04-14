#!/bin/bash env

## https://docs.gitlab.com/charts/installation/cloud/gke.html
## https://docs.gitlab.com/charts/installation/deployment.html

export REGION='us-central1'
export CLUSTER_NAME='gitlab-cluster'


# execute GitLab commands commands
# Using https://gitlab.com/gitlab-org/charts/gitlab/-/tree/master/scripts

./gitlab/gke_bootstrap_script.sh up

sleep 45

gcloud compute addresses create ${CLUSTER_NAME}-external-ip --region $REGION --project $PROJECT

export EXTERNAL_IP=$(gcloud compute addresses describe ${CLUSTER_NAME}-external-ip --region $REGION --project $PROJECT --format='value(address)')
echo 'your EXTERNAL IP is'$EXTERNAL_IP

export DOMAIN=$EXTERNAL_IP'.xip.io'
echo 'your DOMAIN is'$DOMAIN


helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm upgrade --install gitlab gitlab/gitlab \
  --set global.hosts.domain=${DOMAIN} \
  --set certmanager-issuer.email=${EMAIL} \
  --set global.hosts.externalIP=${EXTERNAL_IP}
  

#export PASSWORD=$(kubectl get secret <name>-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode ; echo)
sleep 60

export PASSWORD=$(kubectl get secret gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode ; echo)

echo 'your password is: ' $PASSWORD
echo 'your username is: root'
echo 'Please visit https://gitlab.'$DOMAIN 'in your browser'