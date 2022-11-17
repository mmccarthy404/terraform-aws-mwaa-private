resource "aws_codeartifact_domain" "mwaa_ca_domain" {
  domain = "mwaa"
}

resource "aws_codeartifact_repository" "mwaa_ca_repo" {
  repository  = "mwaa_repo"
  domain      = aws_codeartifact_domain.mwaa_ca_domain.domain
  description = "MWAA repo"

  external_connections {
    external_connection_name = "public:pypi"
  }
}