#!/usr/bin/env bash

export DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

[[ -f "${DIR}/env.sh" ]] && echo "Importing environment from ${DIR}/env.sh..." && . ${DIR}/env.sh

set +x; echo "Connect to cluster..."
set -x;
gcloud container clusters get-credentials gitlab-cluster --zone ${ZONE} --project ${PROJECT_ID}
set +x; echo

# Install Tekton Pipelines
set +x; echo "Install Tekton Pipelines..."
set -x
kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
set +x; echo

# Install Tekton Triggers
set +x; echo "Install Tekton Triggers..."
set -x
kubectl apply -f https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
kubectl apply -f https://storage.googleapis.com/tekton-releases/triggers/latest/interceptors.yaml
set +x; echo

# Install Tekton Dashboard
set +x; echo "Install Tekton Dashboard..."
set -x
kubectl apply --filename https://storage.googleapis.com/tekton-releases/dashboard/latest/tekton-dashboard-release.yaml
set +x; echo

sed -i "s/TEKTON_DOMAIN/${TEKTON_DOMAIN}/g" tekton/gitlab-base/gitlab-ingress.yaml
sed -i "s/TEKTON_DOMAIN/${TEKTON_DOMAIN}/g" tekton/resources/dashboard-ing.yaml

sleep 30


#Install TKN CLI tool
set +x; echo "Setting up external ip..."
mkdir ~/.tkncli
cd ~/.tkncli
if ! [ -x "$(command -v tkn)" ]; then
    echo "***** Installing TKN CLI v0.17.2 *****"
    if [[ "$OSTYPE"  == "linux-gnu" ]]; then
        set -x;
        curl -LO https://github.com/tektoncd/cli/releases/download/v0.17.2/tkn_17.2_Linux_x86_64.tar.gz
        sudo tar xvzf tkn_0.17.2_Linux_x86_64.tar.gz -C /usr/local/bin/ tkn
        set +x;


    elif [[ "$OSTYPE" == "darwin"* ]]; then
        set -x;
        curl -LO https://github.com/tektoncd/cli/releases/download/v0.17.2/tkn_0.17.2_Darwin_x86_64.tar.gz
        sudo tar xvzf tkn_0.17.2_Darwin_x86_64.tar.gz -C /usr/local/bin tkn
        set +x;
    else
        echo "unknown OS"
    fi
else
    echo "TKN is already installed. Let's move on"
fi
