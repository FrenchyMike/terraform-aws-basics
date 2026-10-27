# Create a ssh key pair
resource "tls_private_key" "terraform_ssh_key" {
    algorithm = "RSA"
    rsa_bits = "4096"
}

# Save pair in two dedicated files
resource "local_file" "public_key" {
    content = tls_private_key.terraform_ssh_key.public_key_openssh
    filename = "./terraform_ssh_dir/id_rsa.pub"
    file_permission = "0422"
}

resource "local_file" "private_key" {
    content = tls_private_key.terraform_ssh_key.private_key_openssh
    filename = "./terraform_ssh_dir/id_rsa"
    file_permission = "0400"
}

# Upload key into AWS for EC2 usage
resource "aws_key_pair" "my_ec2" {
    key_name   = "terraform-key"
    public_key = tls_private_key.terraform_ssh_key.public_key_openssh
}

