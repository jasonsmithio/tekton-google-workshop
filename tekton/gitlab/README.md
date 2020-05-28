<!-- https://github.com/tektoncd/triggers/tree/master/examples/gitlab -->
<!-- ttps://github.com/GoogleCloudPlatform/golang-samples/tree/master/getting-started/bookshelfh -->
<!-- https://cloud.google.com/go/getting-started/ -->

# Environment

```bash
export PROJECT='<project name>'
export EMAIL='<your email>'
```



```bash
chmod +x ./scripts/workshop-staging.sh
sh ./scripts/workshop-staging.sh
```

Install NGINX Ingress
```bash
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-0.32.0/deploy/static/provider/cloud/deploy.yaml
```

```bash
kubectl get el gitlab-listener -o=jsonpath='{.status.configuration.generatedName}'
```

Let's get our endpoint

```bash
export INGRESS=$(kubectl get ingress gitlab-tekton-ingress -o=jsonpath='{.status.loadBalancer.ingress[0].ip}{"\n"}')
```

To test, execute this command from the `tekton-google-workshop` directory:

```bash
curl -v \
-H 'X-GitLab-Token: '${SECRET}  \
-H 'X-Gitlab-Event: Push Hook' \
-H 'Content-Type: application/json' \
--data-binary "@tekton/gitlab/gitlab-push-event.json" \
http://$INGRESS
```

You should get a `201 CREATED`

## Setup GitLab

First we need our password. Execute this in your terminal.

```bash
kubectl get secret gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode ; echo
```

This will be your password while `root` is your username

Create a new project and name it *tekton-workshop*. For the sake of simplicity, set the **Visibility Level** to **Public**. In a real world scenario, you would want to lock this down more but for the sake of this demo, we will leave it more open.

Next

```bash
git clone https://gitlab.${DOMAIN}.xip.io/root/tekton-workshop.git
cd tekton-workshop
```

```bash
gcloud iam service-accounts create tekton-gcp \
  --display-name "Tekton Service Account for Google Cloud"
```

```bash
gcloud projects add-iam-policy-binding ${PROJECT_ID} --member serviceAccount:tekton-gcp@${PROJECT_ID}.iam.gserviceaccount.com --role roles/compute.storageAdmin
```

```bash
gcloud iam service-accounts keys create ~/key.json \
  --iam-account tekton-gcp@${PROJECT_ID}.iam.gserviceaccount.com
  ```

```bash
kubectl create secret generic kaniko-secret --from-file=$HOME/key.json
```
