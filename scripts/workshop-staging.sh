#!/usr/bin/env bash

## https://docs.gitlab.com/charts/installation/cloud/gke.html
## https://docs.gitlab.com/charts/installation/deployment.html

environment () {
  HELMPATH=$(which helm)
  if [ "${HELMPATH}" == "" ]; then
    echo "You must have helm installed and have done a 'helm init' to run this script."
    exit 1
  fi

  # Set values that will be overwritten if env.sh exists
  echo "Setting up the environment..."
  export DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
  export REGION='us-central1'
  export ZONE='us-central1-f'
  export EMAIL='your@email.address'
  export CLUSTER_NAME='gitlab-cluster'
  export PROJECT_ID=$(gcloud config get-value project)
  export PROJECT_NUMBER=$(gcloud projects list --filter="${PROJECT_ID}" --format="value(PROJECT_NUMBER)")

  [[ -f "${DIR}/env.sh" ]] && echo "Importing environment from ${DIR}/env.sh..." && . ${DIR}/env.sh
  echo "Writing ${DIR}/env.sh..."
  cat > ${DIR}/env.sh << EOF
export REGION=${REGION}
export ZONE=${ZONE}
export EMAIL=${EMAIL}
export CLUSTER_NAME=${CLUSTER_NAME}
export PROJECT_ID=${PROJECT_ID}
export PROJECT_NUMBER=${PROJECT_NUMBER}
EOF
}

# execute GitLab commands commands
# Using https://gitlab.com/gitlab-org/charts/gitlab/-/tree/master/scripts

#./gitlab/gke_bootstrap_script.sh up

gitlab_project_setup () {

  set +x; echo "Enabling APIs..."
  set -x
  gcloud services enable compute.googleapis.com
  gcloud services enable containerregistry.googleapis.com
  gcloud services enable container.googleapis.com
  set +x; echo; set -x

  set +x; echo "Creating gitlab cluster..."
  set -x
  gcloud container clusters create gitlab-cluster \
      --zone ${ZONE} \
      --cluster-version latest --machine-type n1-standard-4 \
      --scopes cloud-platform \
      --num-nodes 3\
      --enable-ip-alias \
      --project ${PROJECT_ID}
  set +x; echo

  echo "Waiting for cluster bring up..."
  sleep 45

  set +x; echo "Setting up external ip..."
  set -x
  gcloud compute addresses create ${CLUSTER_NAME}-external-ip --region ${REGION} --project ${PROJECT_ID}
  set +x; echo

  export EXTERNAL_IP=$(gcloud compute addresses describe ${CLUSTER_NAME}-external-ip --region ${REGION} --project ${PROJECT_ID} --format='value(address)')
  echo 'your EXTERNAL IP is '${EXTERNAL_IP}
  echo "export EXTERNAL_IP=${EXTERNAL_IP}" >> env.sh

  export DOMAIN=${EXTERNAL_IP}'.xip.io'
  echo 'your DOMAIN is '${DOMAIN}
  echo "export DOMAIN=${DOMAIN}" >> env.sh


  set +x; echo "Installing gitlab into cluster.."
  set -x
  helm repo add gitlab https://charts.gitlab.io/
  helm repo update
  helm upgrade --install gitlab gitlab/gitlab \
    --set global.hosts.domain=${DOMAIN} \
    --set certmanager-issuer.email=${EMAIL} \
    --set global.hosts.externalIP=${EXTERNAL_IP}
  set +x; echo
    
  sleep 60

  export PASSWORD=$(kubectl get secret gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode ; echo)

  # Connect to cluster
  set +x; echo "Connect to cluster.."
  set -x;
  gcloud container clusters get-credentials gitlab-cluster --zone ${ZONE} --project ${PROJECT_ID}
  set +x; echo
  
  #Install Nginx Ingress
  set +x; echo "Install Nginx Ingress.."
  set -x
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-0.32.0/deploy/static/provider/cloud/deploy.yaml
  set +x; echo

  set +x; echo "Set up bindings.."
  set -x
  kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole=cluster-admin \
  --user=$(gcloud config get-value core/account)
  #Give your compute service account IAM access to Secret Manager
  gcloud projects add-iam-policy-binding ${PROJECT_ID} --member serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com --role roles/secretmanager.admin
  set +x; echo

  echo 'your password is: ' $PASSWORD
  echo 'your username is: root'
  echo 'Please visit https://gitlab.'$DOMAIN 'in your browser'
}

#Main
environment
gitlab_project_setup
