CREDS=dqsy5ivdbumcam7wjfyjaycdfy
TOKEN=6uvn2uwjorn4xcklsjmmwajhc4 
CREDENTIALS_FILE=1password-credentials.secret.json

helm repo add 1password https://1password.github.io/connect-helm-charts/

op document get $CREDS > $CREDENTIALS_FILE

helm upgrade --install connect 1password/connect  -n one-pass --create-namespace \
  --set-file connect.credentials=$CREDENTIALS_FILE \
  --set operator.create=true \
  --set operator.token.value="$(op item get $TOKEN --field credential --reveal)" 

rm $CREDENTIALS_FILE