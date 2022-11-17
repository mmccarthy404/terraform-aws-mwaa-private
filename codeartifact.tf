resource "aws_codeartifact_domain" "mwaa_ca_domain" {
  domain = var.ca_domain_name
}

resource "aws_codeartifact_repository" "mwaa_ca_repo" {
  repository  = var.ca_repo_name
  domain      = aws_codeartifact_domain.mwaa_ca_domain.domain
  description = "MWAA repo"

  external_connections {
    external_connection_name = "public:pypi"
  }
}