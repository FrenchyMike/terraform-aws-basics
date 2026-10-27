# Terraform basics

## Terraform installation

* [Terraform installation page](https://developer.hashicorp.com/terraform/install)
* Linux installation:
  ```bash
  wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
  sudo apt update && sudo apt install terraform
  ```
* Installation check
  ```bash
  > $ terraform --version

  Terraform v1.10.5
  on linux_amd64
  ```

## AWS CLI installation

* [AWS CLI usage](https://docs.aws.amazon.com/cli/latest/)
* [AWS CLI installation doc](https://docs.aws.amazon.com/en_us/cli/)
  ```bash
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install
  ```
* AWS CLI configuration
  * [AWS CLI configuration doc](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-quickstart.html)
  * create an `admin` user through the console: IAM section
  * Connect using the admin user credentials:
    ```bash
    $ aws configure

    AWS Access Key ID [None]: accesskey
    AWS Secret Access Key [None]: secretkey
    Default region name [None]: us-west-2
    Default output format [None]:
    ```

## Terraform user

We can create a terraform through:
* AWS console, in the `IAM` section
* AWS CLI:
  ```bash
  # Create user
  aws iam create-user --user-name terraform-user

  # Create an access key, Terraform will use it to make API call to manage AWS resources(save the output securely as it shows only once)
  aws iam create-access-key --user-name terraform-user

  # Attach the AmazonEC2FullAccess policy
  aws iam attach-user-policy \
    --user-name terraform-user \
    --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess
  ```

By now we only use EC2 management, but policies will be updated as our needs will.

## Terraform configuration

> **If you using Visual studio code you may use the [terraform extension](terraform)**

### Terraform provider

Terraform is designed to use *providers* depending on resource you want to manage like public cloud, containers orchestrator and others... All providers are available [here](https://registry.terraform.io/browse/providers)

In our use case the provider is [AWS](https://registry.terraform.io/providers/hashicorp/aws/latest)

Let's configure it. Create and edit a `main.tf` file with the following code:

```tf
provider "aws" {
    region = "eu-west-3"
    access_key = "your access key"
    secret_key = "your secret key"
}
```

Declare credentials directly in the tf file is obviously a lack of security, it will be solved later.

### AWS Resource creation

Let's create our first resource:

When using terraform the general syntax is "

>```tf
>resource "<PROVIDER>_<TYPE>" "NAME" {
>  CONFIG_BLOC
>}
>```

Let's create a very basic EC2 instance, based on the [Terraform `aws_instance` documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)
* PROVIDER: `aws`
* TYPE: `instance`
* NAME: a id to use our resource within Terraform: `my_ec2_instance`
* CONFIG:
  * `ami`: stands for Amazon Machine Image, a unique ID refering to an OS on a specific region
    You can retrieve this id here: https://cloud-images.ubuntu.com/locator/ec2/, or in the AWS console
  * `instance_type`: an instance corresponds to a server with specific CPU, Memory and network capacity, here we chose `t3.micro` ([instance type doc](https://aws.amazon.com/ec2/instance-types/))

```tf
resource "aws_instance" "my_ec2_instance" {
    ami = "ami-06e02ae7bdac6b938"
    instance_type = "t3.micro"
    tags = {
        Name = "my_ec2_instance"
    }
}
```

Run terraform commad to create the resource:
```bash
> $ terraform init # Initate terraform based on provider

Initializing the backend...
Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Using previously-installed hashicorp/aws v5.84.0

Terraform has been successfully initialized!

> $ terraform plan # Describe desired state and actions

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_instance.my_ec2_instance will be created
  + resource "aws_instance" "my_ec2_instance" {
      + ami                                  = "ami-06e02ae7bdac6b938"
      + ...

> $ terraform apply # Create resources

...

aws_instance.my_ec2_instance: Creating...
aws_instance.my_ec2_instance: Still creating... [10s elapsed]
aws_instance.my_ec2_instance: Creation complete after 13s [id=i-0f3835eca43c80125]
```


### Add web server

Let's install apache a quick configure it using terraform, below basic commands to set up a web server:

```bash
#!/bin/bash
sudo apt-get update
sudo apt-get install -y apache2
sudo systemctl start apache2
sudo systemctl enable apache2
sudo echo "<h1>Hello devopssec</h1>" > /var/www/html/index.html
```

Let's add them into our `main.tf` file:

```tf
resource "aws_instance" "my_ec2_instance" {
    ami = "ami-06e02ae7bdac6b938"
    instance_type = "t3.micro"
    user_data = <<-EOF
        #!/bin/bash
        sudo apt-get update
        sudo apt-get install -y apache2
        sudo systemctl start apache2
        sudo systemctl enable apache2
        sudo echo "<h1>Hello devopssec</h1>" > /var/www/html/index.html
    EOF
    tags = {
        Name = "my_ec2_instance"
    }
}
```

To have access to our web site we need to configure security groups to allow connection from anywhere on port 80

```tf
resource "aws_security_group" "instance_sg" {
    name = "terraform-test-sg"

    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
```

The EC2 also need to be bind to this security group. Once the security group is created, variables from the terraform output are available, we can configure our EC2 to use the vpc ID from the security group creation by adding: `vpc_security_group_ids = [aws_security_group.instance_sg.id]`

```tf
resource "aws_instance" "my_ec2_instance" {
    ami = "ami-06e02ae7bdac6b938"
    instance_type = "t3.micro"
    vpc_security_group_ids = [aws_security_group.instance_sg.id]
    user_data = <<-EOF
        #!/bin/bash
        sudo apt-get update
        sudo apt-get install -y apache2
        sudo systemctl start apache2
        sudo systemctl enable apache2
        sudo echo "<h1>Hello devopssec</h1>" > /var/www/html/index.html
    EOF
    tags = {
        Name = "my_ec2_instance"
    }
}
```

### Cleaning the infra

To clean infrastructure based on main.tf, run the following command: `terraform destroy`

## Directory organization

For better visibility let's create and organize a dedicated directory for tf files:

```bash
mkdir tf
```

Split our `main.tf` into:
* [`provider.tf`](tf/provider.tf) file with the provider configuration
* [`ec2.tf`](tf/ec2.tf) file with the ec2 configuration
