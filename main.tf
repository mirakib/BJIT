
resource "local_file" "plan" {
  filename = "${path.module}/plan.txt"

  content = <<-EOT
  Terraform Project Summary

  - Configured the Terraform local provider.
  - Defined name, ID, and topic as input variables.
  - Loaded variable values from terraform.tfvars.
  - Created plan.txt with a bullet-point summary.
  - Created a personalized text file using name and ID.
  - Used Terraform local_file resources to create both files.
  - Topic: ${var.topic}
  EOT
}

resource "local_file" "personal_info" {
  filename = "${path.module}/${replace(var.name, " ", "-")}-${var.id}.txt"

  content = <<-EOT
  Name: ${var.name}
  ID: ${var.id}
  Topic: ${var.topic}
  EOT
}
