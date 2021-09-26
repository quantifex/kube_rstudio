# kube_rstudio

## Goals
1) Practice deployment of workloads to K8S (locally DockerDesktop hosted)
2) Learn terraform based K8S workload deployments
3) Create a reusable deployment solution for RStudio

### Pre-requisities
* WSL2 based Docker
    * Implement fix for https://github.com/microsoft/WSL/issues/4694
        ```
        kernelCommandLine = vsyscall=emulate
        ```
* DockerDesktop w/ K8S Cluster configured
    * Retrieve K8S configuration using kubectl in WSL2 Linux:
        ```bash
        kubectl config view --minify --flatten
        ```

### Implementation
* Terraform based docker execution
    * Utilizing terraform_exec image
* 



### Manual Testing
```bash
# Launch terraform_exec docker so that we can run the necessary terraform commands
docker run --rm -it -v $(pwd):/home terraform_exec bash

terraform plan -var-file=rstudio.tfvars -out=rstudio.tfplan
terraform apply rstudio.tfplan

# Store/retrieve terraform state/vars from S3 bucket (should not be stored in Git/version control)
aws s3 cp rstudio.tfvars s3://qfx-terraform-state/kube_rstudio/rstudio.tfvars
aws s3 cp terraform.tfstate s3://qfx-terraform-state/kube_rstudio/terraform.tfstate
aws s3 cp terraform.tfstate.backup s3://qfx-terraform-state/kube_rstudio/terraform.tfstate.backup
```