resource "aws_iam_policy" "aws_load_balancer_controller" {
  name   = "${var.name_prefix}-aws-load-balancer-controller"
  policy = file("${path.module}/aws-load-balancer-controller-iam-policy.json")
}

data "aws_iam_policy_document" "aws_load_balancer_controller_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.compute_k8s.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "aws_iam_role" "aws_load_balancer_controller" {
  name               = "${var.name_prefix}-aws-load-balancer-controller"
  assume_role_policy = data.aws_iam_policy_document.aws_load_balancer_controller_assume_role.json
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  role       = aws_iam_role.aws_load_balancer_controller.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = module.compute_k8s.cluster_name
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = module.networking.vpc_id
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.aws_load_balancer_controller.arn
  }

  depends_on = [
    aws_iam_role_policy_attachment.aws_load_balancer_controller
  ]
}

resource "helm_release" "platform" {
  name      = "document-service"
  chart     = "../../../k8s/charts/platform"
  namespace = "default"

  lifecycle {
    precondition {
      condition     = !var.app_https_enabled || local.app_effective_certificate_arn != ""
      error_message = "app_https_enabled=true requires either app_acm_certificate_arn or app_acm_certificate_create=true."
    }
  }

  values = [
    yamlencode({
      image = {
        repository = var.document_service_image_repository
        tag        = var.document_service_image_tag
      }
      documentService = {
        dbSecret = {
          enabled = true
          name    = "document-service-db"
        }
        callbackSecret = {
          enabled = true
          name    = "document-service-callback"
        }
        env = {
          SPRING_DATASOURCE_URL                 = "jdbc:postgresql://${module.database_postgres.endpoint}:${module.database_postgres.port}/${module.database_postgres.db_name}"
          SPRING_DATASOURCE_DRIVER_CLASS_NAME   = "org.postgresql.Driver"
          SPRING_JPA_HIBERNATE_DDL_AUTO         = "validate"
          SPRING_FLYWAY_ENABLED                 = "true"
          APP_DOCUMENTS_QUEUE_CALLBACK_BASE_URL = var.document_service_callback_base_url
          APP_DOCUMENTS_QUEUE_REDIS_HOST        = module.cache_redis.endpoint
          APP_DOCUMENTS_QUEUE_REDIS_PORT        = tostring(module.cache_redis.port)
        }
      }
      frontend = {
        enabled = true
        image = {
          repository = var.frontend_image_repository
          tag        = var.frontend_image_tag
        }
      }
      tokenService = {
        enabled = true
        image = {
          repository = var.token_service_image_repository
          tag        = var.token_service_image_tag
        }
      }
      ingress = {
        enabled         = true
        className       = "alb"
        host            = var.app_hostname
        tlsSecretName   = ""
        tokenApiEnabled = true
        annotations     = local.app_ingress_annotations
      }
      job = {
        enabled = false
      }
    })
  ]

  depends_on = [
    helm_release.aws_load_balancer_controller
  ]
}
