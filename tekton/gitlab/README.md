<!-- https://github.com/tektoncd/triggers/tree/master/examples/gitlab -->
<!-- https://github.com/GoogleCloudPlatform/golang-samples/tree/master/getting-started/bookshelf -->
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
