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

```bash
curl -v \
-H 'X-GitLab-Token: '${SECRET}  \
-H 'X-Gitlab-Event: Push Hook' \
-H 'Content-Type: application/json' \
--data-binary "@tekton/gitlab/gitlab-push-event.json" \
http://$INGRESS
```
