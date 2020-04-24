<!-- https://github.com/tektoncd/triggers/tree/master/examples/gitlab -->
<!-- ttps://github.com/GoogleCloudPlatform/golang-samples/tree/master/getting-started/bookshelfh -->
<!-- https://cloud.google.com/go/getting-started/ -->

# Environment

```bash
export PROJECT='<project name>'
export EMAIL='<your email>'
```

```bash
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/cloud-generic.yaml
```

```bash
chmod +x ./scripts/workshop-staging.sh
sh ./scripts/workshop-staging.sh
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