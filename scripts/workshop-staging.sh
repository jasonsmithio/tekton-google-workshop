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
  export CLUSTER_NAME='gitlab-cluster'
  export PROJECT_ID=$(gcloud config get-value project)
  export PROJECT_NUMBER=$(gcloud projects list --filter="${PROJECT_ID}" --format="value(PROJECT_NUMBER)")

  [[ -f "${DIR}/env.sh" ]] && echo "Importing environment from ${DIR}/env.sh..." && . ${DIR}/env.sh
  echo "Writing ${DIR}/env.sh..."
  cat > ${DIR}/env.sh << EOF
export REGION=${REGION}
export ZONE=${ZONE}
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
  gcloud services enable artifactregistry.googleapis.com
  gcloud services enable container.googleapis.com
  gcloud services enable run.googleapis.com
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

  set +x; echo "Setting up external ip for gitlab and tekton..."
  set -x
  gcloud compute addresses create gitlab-${CLUSTER_NAME}-external-ip --region ${REGION} --project ${PROJECT_ID}
  gcloud compute addresses create tekton-${CLUSTER_NAME}-external-ip --region ${REGION} --project ${PROJECT_ID}
  set +x; echo

# NGINX INGRESSS FOR GITLAB
  export EXTERNAL_IP=$(gcloud compute addresses describe gitlab-${CLUSTER_NAME}-external-ip --region ${REGION} --project ${PROJECT_ID} --format='value(address)')
  echo 'your EXTERNAL IP is '${EXTERNAL_IP}
  echo "export EXTERNAL_IP=${EXTERNAL_IP}" >> env.sh

  export GITLAB_DOMAIN=${EXTERNAL_IP}'.xip.io'
  echo 'your GITLAB DOMAIN is '${GITLAB_DOMAIN}
  echo "export DOMAIN=${GITLAB_DOMAIN}" >> env.sh

# NGINX INGRESSS FOR TEKTON
  export TEKTON_EXT_IP=$(gcloud compute addresses describe tekton-${CLUSTER_NAME}-external-ip --region ${REGION} --project ${PROJECT_ID} --format='value(address)')
  echo 'your TEKTON_EXT_IP (Tekton External IP) is '${TEKTON_EXT_IP}
  echo "export TEKTON_EXT_IP=${TEKTON_EXT_IP}" >> env.sh

  export TEKTON_DOMAIN=${TEKTON_EXT_IP}'.xip.io'
  echo 'your TEKTON_DOMAIN is '${TEKTON_DOMAIN}
  echo "export TEKTON_DOMAIN=${TEKTON_DOMAIN}" >> env.sh


  set +x; echo "Installing gitlab into cluster.."
  set -x
  helm repo add gitlab https://charts.gitlab.io/
  helm repo update
  helm upgrade --install gitlab gitlab/gitlab \
    --set global.hosts.domain=${GITLAB_DOMAIN} \
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
  set +x; echo "Install NGINX Ingress.."
  set -x
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.41.2/deploy/static/provider/cloud/deploy.yaml
  set +x; echo

#Install Patch Ingress
set +x; echo "Patch NGINX Ingress with Static IP ..."
set -x
kubectl patch svc ingress-nginx-controller -p '{"spec": {"loadBalancerIP": "'"$TEKTON_EXT_IP"'" }}' -n ingress-nginx


  set +x; echo "Set up bindings.."
  set -x
  kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole=cluster-admin \
  --user=$(gcloud config get-value core/account)
  #Give your compute service account IAM access to Secret Manager
  gcloud projects add-iam-policy-binding ${PROJECT_ID} --member serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com --role roles/secretmanager.admin

}

gcp_bindings () {
# Grant the Cloud Run Admin role to the Cloud Build service account
set +x; echo "Setting IAM Binding for Cloud Build and Cloud Run.."

set -x
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member "serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role roles/cloudbuild.builds.editor

# Grant the IAM Service Account User role to the Cloud Build service account on the Cloud Run runtime service account
set -x
gcloud iam service-accounts add-iam-policy-binding \
  ${PROJECT_NUMBER}-compute@developer.gserviceaccount.com \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"
set +x; echo
}


#Main
environment
gitlab_project_setup
gcp_bindings


set +x; clear
set +x; echo



echo 'your password is: ' $PASSWORD
echo 'your username is: root'
echo 'Please visit https://gitlab.'$GITLAB_DOMAIN 'in your browser'
