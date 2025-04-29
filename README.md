# ForenStack (Work in progress)
Forensics Stack deployable with Terrafrom in AWS. 
Velociraptor, Timesketch, Plaso all in one.

The idea of this project is to create a forensics stack that can be deployed in AWS using Terraform.
Depending on the use case, you can deploy all the components or just some of them.
Working components:
- Timesketch
- Velociraptor
To be added:
- Plaso
- Custom parsing modules
- Test Windows agent
- Test Linux agent
- Bloodhound
- Maybe something more, propose :)

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed
- AWS credentials configured

## Modules

### Common Module
The `common` module provides shared resources and configurations used by other modules, such as:
- S3 configuration bucket
- RSA keys
- SSM instance profile

### Timesketch Module
The `timesketch` module deploys Timesketch, a forensic timeline analysis tool. It is conditionally created based on the `create_timesketch` variable.

### Velociraptor Module
The `velociraptor` module deploys Velociraptor, a digital forensic and incident response tool. It is conditionally created based on the `create_velociraptor` variable.

## Variables

- `create_timesketch`: Boolean to determine whether to create the Timesketch module.
- `create_velociraptor`: Boolean to determine whether to create the Velociraptor module.

## Outputs

- `velo_url`: The URL for accessing the Velociraptor instance, if created.

## Usage

1. Clone this repository.
2. Initialize Terraform:
   ```bash
   terraform init
    ```
3. Review and customize the variables in your terraform.tfvars file.
4. Apply the configuration:
    ```bash
    terraform apply
    ```
5. Access the Velociraptor/Timesketch instance using the provided URL in the output.

6. To destroy the resources, run:
    ```bash
    terraform destroy
    ```