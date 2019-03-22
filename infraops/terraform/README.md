# Example Terraform Deployment Template

### Branch Build status
Master: ![Master Branch Build Status](https://dev.azure.com/osscanada/azure_devops_demo/_apis/build/status/TF%20Test%20Environment%20Build?branchName=master)

Test: ![Test Branch Build Status](https://dev.azure.com/osscanada/azure_devops_demo/_apis/build/status/TF%20Test%20Environment%20Build?branchName=test)

This example Terraform template is designed to demonstrate a simple Azure services deployment.  The goal is to iteratively update services (Adding/Removing/Updating) to declaratively modify the elastic scale of the services based on workload requirements/demands.  We will be using Git as the source of truth for our environment, which will give us an entry point as well as a simple and powerful access control model for sharing and collaboratively working on our infrastructure and required services (IaaS, PaaS and SaaS).  

Our Operations team can declaratively define the services that need to be provisioned and deployed via Terrafrom templates.  Each operator will be added to a team(s) in Github which will define the level of access they have to the repository to affect change.

The Azure DevOps (ADO) Pipelines will have all the critical and potentially sensitve information regarding each environment stored as either variables directly defined in the pipeline, or leverage variable groups that can be shared across pipelines depending on needs.  The second method of variable groups will help to reduce errors and save time by defining the `key:value` pairs for variable `names:values` for reuse in similar or related pipeline(s).

We can also leverage ADO's ability to pass in environment variables as secrets only when needed and store certain values inside Azure Key Vault for sensitive values.  This will allow us to reduce the expose of values to higher level operators who can replace/rotate the values in Azure Key Vault, or revoke rights accordingly outside of the ADO pipeline.  This is a good method to reduce the blast radius of compromised keys/secrets should it ever happen, and abstract the need to expose this inside ADO where you may have multiple pipeline owners who may not need or should have access to those values.  Similarly, since Developers using the infrastructure and the Operators who write the scripts to deploy the infrastructure are leveraging a Git/Source Control entry point into contributing/deploying infrastructure, they are never exposed to the values as they may not be given access to ADO (i.e. Git/GitHub/Source Control is their only access/entrypoint).

At each stage of a Build or a Release Pipeline, we can gate or place in additional conditions or triggers that will grant/allow the pipeline to continue onto the proceeding stage(s).  This allows for a code review, testing and other checks in place to ensure higher quality, lower defects are being passed along from stage to stage as well as release environment(s) (test->dev->canary->staging->prd etc).

Lastly we have a clear audit trail that we can review of who commited which changes, when, why and the outcome of each stage of a build/release.  We also have the ability to rollback to a previously known good point in time based on Git Commit, Build or Relase Number or other mechanisms to ensure we can repeatably and reliable redeploy a given point in time. 

## Terraform State File and Azure Backend

A Terraform State File is created to maintain and query the desired/presumed state of the services deployed.  It is generally saved locally, but in a distributed team you will want to leverage a Terraform [Backend](https://www.terraform.io/docs/backends/).  This allows the state to be saved in a central location and generate a lock/lease on the state to avoid collisions should anyone attempt to deploy new updates simultaneously.  We will be using the [AzureRM Backend](https://www.terraform.io/docs/backends/types/azurerm.html) which will save the state to an Azure Blob Storage Account.  Use the links provided above to find out more about this mechanism.

## Services being Deployed:

- Azure Resource Group
- Azure Container Registry
- Azure App Service Plan
    - Azure App Service: Web App for Containers (2)
      - (1) A Node.js/Express.js App serving up a backend RESTful API
      - (2) A Vue.js Web App serving as a Frontend JS MVC Single Page Web App (SPA)

## Required Variables

The deployment assumes that the following variables are set and available in the command line prior to running a ```terraform init | plan | apply``` command(s).  The naming of the variables are not all a requirement of Terraform, but the values are required and used inside Terraform templates and the Terraform Azure Provider.  You may rename them accordingly but ensure you update the ``variables.tf`` file and any other settings in the provided shell scripts.

```shell
export ARM_CLIENT_ID="<Azure Service Principal ID aka APP ID aka CLIENT ID>"
export ARM_CLIENT_SECRET="<Azure SP Password/Client Secret>"
export ARM_SUBSCRIPTION_ID="<Azure Subscription ID>"
export ARM_TENANT_ID="<Azure Active Directory ID>"
export TF_VAR_AZURE_RESOURCE_GROUP_NAME="<The Resource Group to deploy services into>"
export AZUREBLOBSTORAGEACCOUNTNAME="<Storage account name to save Terraform Backend state data>"
export AZUREBLOBSTOREACCESSKEY="<Azure Storage Account Storage Account Access Key>"
export AZUREBLOBSTORECONTAINERNAME="<Azure Storage container name to save the Terraform state file into"
export TFSTATEFILENAME="<name of the Terraform statefile e.g. test.env.tfstate>"
export TERRAFORMVERSION="<Terraform version number to install into Linux env e.g. 0.11.11>"
```

**NOTE:**
- Variables defined in a template file have the **lowest** level of precedence (i.e. they will be overwritten by values passed in via env vars or command line flags)
- You can set a script that passes in these values at run time by passing the ```-var 'key=value'``` flag/syntax to your `terraform init | plan | apply` command(s).  this is the **highest** level of precedence
- Azure DevOps will use/passin the Variables you define in a Pipeline into a Linux Environment.  However, the keys (names) you define in ADO will be uppercased automatically (i.e. ADO variable ```client_secret``` will be injected as ```CLIENT_SECRET``` in a linux shell environment)
- When using environment variables in a Terraform template, you will need to match the case as noted above, as well as include a ```TF_VAR_``` prefix to your variable name. See [Terraform Environment Variables](https://www.terraform.io/docs/configuration/variables.html#environment-variables) for more details

## Additional Resources

- Get some [hands on](https://learn.hashicorp.com/terraform) learning about [Terraform](https://www.terraform.io/docs/)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
- [Azure DevOps](https://dev.azure.com)
- [Azure App Services](https://docs.microsoft.com/en-us/azure/app-service/)
- [Web App for Containers](https://docs.microsoft.com/en-us/azure/app-service/containers/)
- [Azure Container Registry](https://docs.microsoft.com/en-us/azure/container-registry/)
- [GitOps](https://www.weave.works/blog/gitops-operations-by-pull-request)
- [Immutable Infrastructure](https://www.digitalocean.com/community/tutorials/what-is-immutable-infrastructure)