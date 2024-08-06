# URL Shortner

This terraform module is an AWS implementation of a URL shortener app using serverless resources:

- All backend logic is implemented using AWS Rest API Gateway capabilities
- A small frontend is stored in S3
- A DynamoDB table is used for persistence

## TODOS:

- [ ] Add diagram to docs
- [ ] Add handler for errors in create url
- [ ] Add handler for errors in get url
- [ ] Add pagination to get url list endpoint
- [ ] Add pagination to frontend
