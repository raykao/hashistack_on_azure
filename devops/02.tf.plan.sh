#!/bin/bash

terraform plan \
  -out=tfplan \
  -input=false \
  ./terraform