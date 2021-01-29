# Terrafile 

Terrafile is a binary written in Go to systematically manage external modules from Github for use in Terraform. 

## How to use

Terrafile expects a file named `Terrafile` which will contain your terraform module dependencies in a yaml like format.

An example Terrafile:

```yaml
tf-aws-vpc:
    source:  "git@github.com:terraform-aws-modules/terraform-aws-vpc"
    version: "v1.46.0"
tf-aws-vpc-experimental:
    source:  "git@github.com:terraform-aws-modules/terraform-aws-vpc"
    version: "master"
```

Terrafile config file in current directory and modules exported to ./vendor/modules

```sh
$ terrafile
INFO[0000] [*] Checking out v1.46.0 of git@github.com:terraform-aws-modules/terraform-aws-vpc  
INFO[0000] [*] Checking out master of git@github.com:terraform-aws-modules/terraform-aws-vpc  
```

Terrafile config file in custom directory

```sh
$ terrafile -f config/Terrafile
INFO[0000] [*] Checking out v1.46.0 of git@github.com:terraform-aws-modules/terraform-aws-vpc  
INFO[0000] [*] Checking out master of git@github.com:terraform-aws-modules/terraform-aws-vpc  
```

Terraform modules exported to custom directory

```sh
$ terrafile -p custom_directory
INFO[0000] [*] Checking out master of git@github.com:terraform-aws-modules/terraform-aws-vpc  
INFO[0001] [*] Checking out v1.46.0 of git@github.com:terraform-aws-modules/terraform-aws-vpc  
```

Invoking a wait time of 1 second between each git clone (defaults to 2)

```sh
$ terrafile -w 0
INFO[0000] [*] Checking out master of git@github.com:terraform-aws-modules/terraform-aws-vpc  
INFO[0001] [*] Checking out v1.46.0 of git@github.com:terraform-aws-modules/terraform-aws-vpc  
```

Invoking with a maximum of 3 retry attempts per git clone (defaults to 5)

```sh
$ terrafile -m 3
INFO[0000] [*] Checking out master of git@github.com:terraform-aws-modules/terraform-aws-vpc  
INFO[0001] [*] Checking out v1.46.0 of git@github.com:terraform-aws-modules/terraform-aws-vpc  
```

Example Terraform 12 project.tf file

```hcl
module "vpc_1" {
  source = "./vendor/modules/tf-aws-vpc"
}

module "vpc_2" {
  source = "./vendor/modules/tf-aws-vpc-experimental"
}
```
