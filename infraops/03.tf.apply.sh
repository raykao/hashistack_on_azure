#!/bin/bash

terraform apply \
  -input=false \
  -auto-approve "tfplan" \
  ./terraform