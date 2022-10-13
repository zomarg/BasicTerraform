# Running locally

1. Download & Install Terraform 
2. Run commands in /script folder from your preferred shell

## With Docker or Podman

1. `docker build . -t basic_terraform`

2. `docker run -it --rm -v .:/usr/src --entrypoint=/bin/bash --env-file ./dev.config.env basic_terraform`

3. Run commands in /script folder inside of container

## Links

* [Infrastructure as Code](https://gramozk.gitbook.io/devops/infrastructure-as-code)
* [Terraform Download](https://www.terraform.io/downloads)
* [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
* [Offical All Terraform Providers](https://registry.terraform.io/search/providers)
* [TFLint](https://github.com/terraform-linters/tflint)
* [Checkov](https://github.com/bridgecrewio/checkov)
* [Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/)

