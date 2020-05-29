#!/usr/bin/env bash

[[ -f "${DIR}/env.sh" ]] && echo "Importing environment from ${DIR}/env.sh..." && . ${DIR}/env.sh

set +x; echo "Connect to cluster.."
set -x;
gcloud container clusters get-credentials gitlab-cluster --zone ${ZONE} --project ${PROJECT_ID}
set +x; echo
  
# Install Tekton Pipelines
set +x; echo "Install Tekton Pipelines.."
set -x
kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
set +x; echo

# Install Tekton Triggers
set +x; echo "Install Tekton Triggers.."
set -x
kubectl apply --filename https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
set +x; echo


# Ingress NGINX Mandatory file
set +x; echo "Install Nginx Ingress Mandatory file.."
set -x
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/mandatory.yaml
set +x; echo

# Ingress NGINX GKE
set +x; echo "Install Nginx Ingress GKE.."
set -x
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/provider/cloud-generic.yaml
set +x; echo

sleep 30

#Install service accounts
#kubectl apply -f ../tekton/gitlab/role-resources/triggerbinding-roles
#kubectl apply -f ../tekton/gitlab/role-resources/secret.yaml
#kubectl apply -f ../tekton/gitlab/role-resources/serviceaccount.yaml

## Install Event Listener
#kubectl apply -f ../tekton/gitlab/gitlab-push-listener.yaml


# Install GitLab Ingress
#kubectl apply -f ../tekton/gitlab/gitlab-ingress.yaml

#Install TKN CLI tool
set +x; echo "Setting up external ip..."
mkdir ~/.tkncli
cd ~/.tkncli
if ! [ -x "$(command -v tkn)" ]; then
    echo "***** Installing TKN CLI v0.8.0 *****"
    if [[ "$OSTYPE"  == "linux-gnu" ]]; then
        set -x;
        curl -LO https://github.com/tektoncd/cli/releases/download/v0.8.0/tkn_0.8.0_Linux_x86_64.tar.gz
        sudo tar xvzf tkn_0.8.0_Linux_x86_64.tar.gz -C /usr/local/bin/ tkn
        set +x;


    elif [[ "$OSTYPE" == "darwin"* ]]; then
        set -x;
        curl -LO https://github.com/tektoncd/cli/releases/download/v0.8.0/tkn_0.8.0_Darwin_x86_64.tar.gz
        sudo tar xvzf tkn_0.8.0_Darwin_x86_64.tar.gz -C /usr/local/bin tkn
        set +x;
    else
        echo "unknown OS"
    fi
else 
    echo "TKN is already installed. Let's move on"
fi
