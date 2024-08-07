# URL Shortner

This terraform module is an AWS implementation of a URL shortener app using serverless resources:

- All backend logic is implemented using AWS Rest API Gateway capabilities
- A small frontend is stored in S3
- A DynamoDB table is used for persistence


<!-- BEGIN_TF_DOCS -->


## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_api_gateway"></a> [api_gateway](#module_api_gateway) | cloudposse/api-gateway/aws | v0.7.0 |
| <a name="module_dynamodb_table"></a> [dynamodb_table](#module_dynamodb_table) | terraform-aws-modules/dynamodb-table/aws | v4.0.1 |
| <a name="module_iam_role"></a> [iam_role](#module_iam_role) | terraform-aws-modules/iam/aws//modules/iam-assumable-role | ~> 5.39 |
| <a name="module_s3_bucket_web"></a> [s3_bucket_web](#module_s3_bucket_web) | terraform-aws-modules/s3-bucket/aws | ~> 4.1 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input_name) | A name to use in all resources | `string` | `"shortener"` | no |
| <a name="input_tags"></a> [tags](#input_tags) | A mapping of tags to assign to resources | `map(string)` | `{}` | no |


<!-- END_TF_DOCS -->


## TODOS:

- [ ] Add diagram to docs
- [ ] Add handler for errors in create url
- [ ] Add handler for errors in get url
- [ ] Add pagination to get url list endpoint
- [ ] Add pagination to frontend
