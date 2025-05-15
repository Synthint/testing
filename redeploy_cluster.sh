CREDS=dqsy5ivdbumcam7wjfyjaycdfy && \
TOKEN=6uvn2uwjorn4xcklsjmmwajhc4 && \
CREDENTIALS_FILE=1password-credentials.secret.json && \
OP_ARGO_GITHUB_TOKEN=tcl4726tkclhemkwc7epqchj5u && \
OP_ARGO_GITHUB_TOKEN_FILE="temp_argocd_github.key" && \
TUNNEL_CREDENTIALS=x6wrlnvszoncieq5bly3rnxxxu && \
TUNNEL_CREDENTIALS_FILE=tunnel-credentials.json && \
REPO="git@github.com:Synthint/testing.git" && \
CONTROL_PLANE="homelab"

touch $OP_ARGO_GITHUB_TOKEN_FILE  && \
chmod 777 $OP_ARGO_GITHUB_TOKEN_FILE  && \
op item get "$OP_ARGO_GITHUB_TOKEN" --field 'private key' --reveal | sed 's/^"//' | sed 's/"$//' > "$OP_ARGO_GITHUB_TOKEN_FILE"


helm repo add 1password https://1password.github.io/connect-helm-charts/

op document get $CREDS > $CREDENTIALS_FILE

helm upgrade --install connect 1password/connect  -n one-pass --create-namespace \
  --set-file connect.credentials=$CREDENTIALS_FILE \
  --set operator.create=true \
  --set operator.token.value="$(op item get $TOKEN --field credential --reveal)" 

rm $CREDENTIALS_FILE

op document get $TUNNEL_CREDENTIALS > $TUNNEL_CREDENTIALS_FILE


kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

ARGOCD_INITIAL_PASSWORD=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d)
ARGOCD_SERVICE_PORT=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')


argocd login $CONTROL_PLANE:$ARGOCD_SERVICE_PORT \
  --username admin \
  --password $ARGOCD_INITIAL_PASSWORD \
  --insecure

# argocd repo add git@git.example.com:repos/repo --insecure-ignore-host-key --ssh-private-key-path ~/id_rsa
argocd repo add $REPO \
  --type git \
  --name 'testing' \
  --ssh-private-key-path $OP_ARGO_GITHUB_TOKEN_FILE \
  --insecure-ignore-host-key

argocd app create app-of-apps \
  --repo $REPO \
  --path 'apps' \
  --dest-server 'https://kubernetes.default.svc' \
  --dest-namespace 'argocd' \
  --sync-policy 'automated' \


kubectl create ns cloudflared
kubectl create secret generic tunnel-credentials -n cloudflared \
--from-file=credentials.json=$TUNNEL_CREDENTIALS_FILE

kubectl label node rpi5 extra-hardware=rpi-gpio

rm $TUNNEL_CREDENTIALS_FILE
rm $OP_ARGO_GITHUB_TOKEN_FILE