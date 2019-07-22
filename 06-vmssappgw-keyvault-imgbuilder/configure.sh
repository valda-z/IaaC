#!/bin/bash

# configure myappservice

echo "#!/bin/bash
KVTOKEN=\$(curl \"http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-04-02&client_id=\${CLIENTID}&resource=https%3A%2F%2Fvault.azure.net\" -H Metadata:true | jq -r .access_token)
POSTGRESPWD=\$(curl \"https://\${KEYVAULT_NAME}.vault.azure.net/secrets/\${KEYVAULT_SECRET}?api-version=2016-10-01\" -H \"Authorization: Bearer \${KVTOKEN}\" | jq -r .value)
POSTGRESPWD=\${POSTGRESPWD//+/%2B}
POSTGRESPWD=\${POSTGRESPWD////%2F}
POSTGRESPWD=\${POSTGRESPWD//=/%3D}
export POSTGRESQL_URL=\"\${POSTGRESQL}&password=\${POSTGRESPWD}\"
/usr/bin/java -jar /usr/local/mysimpleapp/app.jar
" > /usr/local/mysimpleapp/run.sh
chmod +x /usr/local/mysimpleapp/run.sh
chown mysimpleapp:mysimpleapp /usr/local/mysimpleapp/run.sh

echo "[Unit]
Description=MySimpleApp
After=network-online.target

[Service]
EnvironmentFile=/etc/mysimpleapp.env
Type=simple
WorkingDirectory=/var/opt/mysimpleapp
ExecStart=/bin/bash /usr/local/mysimpleapp/run.sh
RemainAfterExit=no
Restart=always
RestartSec=5s
User=mysimpleapp
Group=mysimpleapp

[Install]
WantedBy=multi-user.target
" > /usr/lib/systemd/system/mysimpleapp.service

systemctl daemon-reload
