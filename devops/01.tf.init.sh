#!/bin/bash

## Following ENV VARs are injected into the pipeline via Build/Release Variables
## Each value will change based on the release pipeline environment this command is run in i.e. test/dev/staging/prod
#
# export AZUREBLOBSTORAGEACCOUNTNAME=""
# export AZUREBLOBSTORECONTAINERNAME=""
# export AZUREBLOBSTOREACCESSKEY=""
# export TFSTATEFILENAME=""

terraform init \
  -input=false \
  -backend-config="storage_account_name=$AZUREBLOBSTORAGEACCOUNTNAME" \
  -backend-config="container_name=$AZUREBLOBSTORECONTAINERNAME" \
  -backend-config="access_key=$AZUREBLOBSTOREACCESSKEY" \
  -backend-config="key=$TFSTATEFILENAME" \
  ./terraform