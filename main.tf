###########################################################################################################################
# API Gateway
###########################################################################################################################
module "api_gateway" {
  source  = "cloudposse/api-gateway/aws"
  version = "v0.7.0"

  name       = "shortener"
  stage_name = "prod"

  openapi_config = {
    openapi = "3.0.1"

    info = {
      title       = "shortener"
      description = "URL shortener"
      version     = "1.0"
    }

    paths = {
      "/" = {
        description = "Serve the entrypoint of the frontend"

        get = {
          responses = { "200" = {
            description = "200 response"
            content     = {}
            headers     = { "Content-Type" = { schema = { type = "string" } } }
          } }

          x-amazon-apigateway-integration = {
            type                = "aws"
            uri                 = "arn:aws:apigateway:${data.aws_region.current.name}:s3:path/${"shortener-web-${random_string.bucket_suffix.id}"}/index.html"
            httpMethod          = "GET"
            credentials         = module.iam_role.iam_role_arn
            passthroughBehavior = "when_no_templates"

            responses = { default = {
              statusCode         = "200"
              responseParameters = { "method.response.header.Content-Type" = "integration.response.header.Content-Type" }
            } }
          }
        }
      }

      "/web/{object}" = {
        description = "Serve frontend files"

        get = {
          parameters = [{
            name     = "object"
            in       = "path"
            required = true
            schema   = { type = "string" }
          }]

          responses = { "200" = {
            description = "200 response"
            content     = {}
            headers     = { "Content-Type" = { schema = { type = "string" } } }
          } }

          x-amazon-apigateway-integration = {
            type                = "aws"
            uri                 = "arn:aws:apigateway:${data.aws_region.current.name}:s3:path/${"shortener-web-${random_string.bucket_suffix.id}"}/{object}"
            httpMethod          = "GET"
            credentials         = module.iam_role.iam_role_arn
            passthroughBehavior = "when_no_templates"
            requestParameters   = { "integration.request.path.object" = "method.request.path.object" }

            responses = { default = {
              statusCode         = "200"
              responseParameters = { "method.response.header.Content-Type" = "integration.response.header.Content-Type" }
            } }
          }
        }
      }

      "/url" = {
        description = "Manage URLs"

        get = {
          responses = { "200" = {
            description = "200 response"
            content     = {}
          } }

          x-amazon-apigateway-integration = {
            type                = "aws"
            uri                 = "arn:aws:apigateway:${data.aws_region.current.name}:dynamodb:action/Scan"
            httpMethod          = "POST"
            credentials         = module.iam_role.iam_role_arn
            passthroughBehavior = "when_no_templates"
            timeoutInMillis     = 29000
            requestTemplates    = { "application/json" = jsonencode({ TableName = module.dynamodb_table.dynamodb_table_id }) }

            responses = { "200" = {
              statusCode = "200"

              responseTemplates = { "application/json" = <<-EOF
                #set($inputRoot = $input.path('$'))
                {
                  "urls": "$inputRoot.Items"
                }
                EOF
              }
            } }
          }
        }

        post = {
          responses = { "200" = {
            description = "200 response"
            content     = {}
          } }

          x-amazon-apigateway-integration = {
            type                = "aws"
            uri                 = "arn:aws:apigateway:${data.aws_region.current.name}:dynamodb:action/UpdateItem"
            httpMethod          = "POST"
            credentials         = module.iam_role.iam_role_arn
            passthroughBehavior = "when_no_templates"
            timeoutInMillis     = 29000

            responses = { "200" = {
              statusCode = "200"

              responseTemplates = { "application/json" = <<-EOF
                #set($inputRoot = $input.path('$'))
                {
                  "id": "$inputRoot.Attributes.id.S",
                  "url": "$inputRoot.Attributes.id.S",
                  "timestamp": "$inputRoot.Attributes.timestamp.S",
                }
                EOF
              }
            } }

            requestTemplates = { "application/json" = jsonencode({
              TableName           = module.dynamodb_table.dynamodb_table_id
              ConditionExpression = "attribute_not_exists(id)"
              UpdateExpression    = "SET #u = :u, #ts = :ts"
              ReturnValues        = "ALL_NEW"
              Key                 = { id = { S = "$input.json('$.id').replaceAll('\"', '')" } }

              ExpressionAttributeNames = {
                "#u"  = "url"
                "#ts" = "timestamp"
              }

              ExpressionAttributeValues = {
                ":u"  = { S = "$input.json('$.url').replaceAll('\"', '')" }
                ":ts" = { S = "$context.requestTime" }
              }
            }) }
          }
        }
      }

      "/{id}" = {
        description = "Use a redirect URL"

        get = {
          parameters = [{
            name     = "id"
            in       = "path"
            required = true
            schema   = { type = "string" }
          }]

          responses = { "301" = {
            description = "301 response"
            content     = {}
            headers     = { Location = { schema = { type = "string" } } }
          } }

          "x-amazon-apigateway-integration" = {
            type                = "aws"
            httpMethod          = "POST"
            uri                 = "arn:aws:apigateway:${data.aws_region.current.name}:dynamodb:action/GetItem"
            credentials         = module.iam_role.iam_role_arn
            timeoutInMillis     = 29000
            passthroughBehavior = "when_no_templates"

            requestTemplates = { "application/json" = jsonencode({
              Key       = { id = { S = "$util.escapeJavaScript($input.params().path.id)" } }
              TableName = module.dynamodb_table.dynamodb_table_id
            }) }

            responses = { "200" = {
              statusCode = "301"

              responseTemplates = { "application/json" = <<-EOF
                #set($inputRoot = $input.path('$'))
                #if ($inputRoot.toString().contains("Item"))
                  #set($context.responseOverride.header.Location = $inputRoot.Item.url.S)
                #end
                EOF
              }
            } }
          }
        }
      }
    }
  }
}

###########################################################################################################################
# DynamoDB table
###########################################################################################################################
module "dynamodb_table" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "v4.0.1"

  name     = "urls"
  hash_key = "id"

  attributes = [{
    name = "id"
    type = "S"
  }]
}

###########################################################################################################################
# IAM Roles
###########################################################################################################################
module "iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 5.39"

  create_role           = true
  role_requires_mfa     = false
  role_name             = "url-shortener-api"
  trusted_role_services = ["apigateway.amazonaws.com"]

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  ] # TODO: make this more granular
}

###########################################################################################################################
# S3 website
###########################################################################################################################
resource "random_string" "bucket_suffix" {
  length  = 5
  special = false
  upper   = false
}

module "s3_bucket_web" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.1"

  bucket        = "shortener-web-${random_string.bucket_suffix.id}"
  force_destroy = true
  attach_policy = true

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Sid       = "ApiGatewayAccess"
      Effect    = "Allow"
      Action    = "s3:GetObject"
      Resource  = "arn:aws:s3:::${"shortener-web-${random_string.bucket_suffix.id}"}/*"
      Principal = { Service = "apigateway.amazonaws.com" }
      Condition = { ArnLike = { "aws:SourceArn" = module.api_gateway.arn } }
    }]
  })
}

locals { mime_types = jsondecode(file("${path.module}/data/mime.json")) }

resource "aws_s3_object" "web" {
  for_each = fileset("${path.module}/web", "**/*")

  bucket       = module.s3_bucket_web.s3_bucket_id
  key          = each.key
  source       = "${path.module}/web/${each.key}"
  etag         = filemd5("${path.module}/web/${each.key}")
  content_type = lookup(local.mime_types, regex("\\.[^.]+$", each.value), null)
}
