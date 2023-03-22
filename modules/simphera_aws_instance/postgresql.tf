resource "aws_db_instance" "simphera" {

  allocated_storage                   = var.postgresqlStorage
  max_allocated_storage               = var.postgresqlMaxStorage
  auto_minor_version_upgrade          = true # [RDS.13] RDS automatic minor version upgrades should be enabled
  engine                              = "postgres"
  engine_version                      = var.postgresqlVersion
  instance_class                      = var.db_instance_type_simphera
  identifier                          = local.db_simphera_id
  db_name                             = replace("${local.instancename}simphera", "/[^0-9a-zA-Z]/", "") # Use alphanumeric characters only
  username                            = local.secret_postgres_username
  password                            = local.secrets["postgresql_password"]
  multi_az                            = true # [RDS.5] RDS DB instances should be configured with multiple Availability Zones
  enabled_cloudwatch_logs_exports     = ["postgresql", "upgrade"]
  monitoring_interval                 = 60
  monitoring_role_arn                 = aws_iam_role.rds_enhanced_monitoring_role.arn # [RDS.9] Database logging should be enabled
  deletion_protection                 = true                                          # [RDS.7] RDS clusters should have deletion protection enabled
  skip_final_snapshot                 = false
  final_snapshot_identifier           = "${local.db_simphera_id}-final-snapshot"
  iam_database_authentication_enabled = true # [RDS.10] IAM authentication should be configured for RDS instances
  copy_tags_to_snapshot               = true
  storage_encrypted                   = true # [RDS.3] RDS DB instances should have encryption at rest enabled
  db_subnet_group_name                = var.database_subnet_group_name
  vpc_security_group_ids              = [var.postgresql_security_group_id]
  tags                                = var.tags
  depends_on = [
    aws_cloudwatch_log_group.db_simphera
  ]


}

resource "aws_db_instance" "keycloak" {
  allocated_storage                   = var.postgresqlStorage
  max_allocated_storage               = var.postgresqlMaxStorageKeycloak
  auto_minor_version_upgrade          = true # [RDS.13] RDS automatic minor version upgrades should be enabled
  engine                              = "postgres"
  engine_version                      = var.postgresqlVersion
  instance_class                      = var.db_instance_type_keycloak
  identifier                          = local.db_keycloak_id
  db_name                             = replace("${local.instancename}keycloak", "/[^0-9a-zA-Z]/", "")
  username                            = local.secret_postgres_username
  password                            = local.secrets["postgresql_password"]
  multi_az                            = true # [RDS.5] RDS DB instances should be configured with multiple Availability Zones
  enabled_cloudwatch_logs_exports     = ["postgresql", "upgrade"]
  monitoring_interval                 = 60
  monitoring_role_arn                 = aws_iam_role.rds_enhanced_monitoring_role.arn # [RDS.9] Database logging should be enabled
  deletion_protection                 = true                                          # [RDS.7] RDS clusters should have deletion protection enabled
  skip_final_snapshot                 = false
  final_snapshot_identifier           = "${local.db_keycloak_id}-final-snapshot"
  iam_database_authentication_enabled = true # [RDS.10] IAM authentication should be configured for RDS instances
  copy_tags_to_snapshot               = true
  storage_encrypted                   = true # [RDS.3] RDS DB instances should have encryption at rest enabled
  db_subnet_group_name                = var.database_subnet_group_name
  vpc_security_group_ids              = [var.postgresql_security_group_id]
  tags                                = var.tags
  depends_on = [
    aws_cloudwatch_log_group.db_keycloak
  ]
}


data "http" "aws_tls_certificate" {
  url = "https://truststore.pki.rds.amazonaws.com/${var.region}/${var.region}-bundle.pem"
}
resource "kubernetes_secret" "aws_tls_certificate" {
  metadata {
    name      = "customsslrootcertificate"
    namespace = kubernetes_namespace.k8s_namespace.metadata[0].name
  }
  data = {
    "databaseCertificates.pem" = data.http.aws_tls_certificate.response_body
  }
  type = "Opaque"
}


resource "aws_iam_role" "rds_enhanced_monitoring_role" {
  name = "${var.name}-rds-enhanced-monitoring"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "",
          "Effect" : "Allow",
          "Principal" : {
            "Service" : [
              "monitoring.rds.amazonaws.com"
            ]
          },
          "Action" : [
            "sts:AssumeRole"
          ]
        }
      ]
    }
  )

  tags = var.tags

}

# [RDS.6] Enhanced monitoring should be configured for RDS DB instances and clusters
resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring_policy" {
  role       = aws_iam_role.rds_enhanced_monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}


resource "aws_cloudwatch_log_group" "db_simphera" {
  name              = "/aws/rds/instance/${local.db_simphera_id}/postgresql" # CAUTION: the name is predetermined by AWS RDS. Do not change it. Otherwise AWS will create a new log group without retention and encryption.
  retention_in_days = var.cloudwatch_retention
  kms_key_id        = var.kms_key_cloudwatch
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "db_keycloak" {
  name              = "/aws/rds/instance/${local.db_keycloak_id}/postgresql" # CAUTION: the name is predetermined by AWS RDS. Do not change it. Otherwise AWS will create a new log group without retention and encryption.
  retention_in_days = var.cloudwatch_retention
  kms_key_id        = var.kms_key_cloudwatch
  tags              = var.tags
}
