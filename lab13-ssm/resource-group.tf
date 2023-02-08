resource "aws_resourcegroups_group" "test_servers" {
  name = "test_servers"

  resource_query {
    query = <<JSON
{
  "ResourceTypeFilters": [
    "AWS::EC2::Instance"
  ],
  "TagFilters": [
    {
      "Key": "Environment",
      "Values": ["test"]
    }
  ]
}
JSON
  }
}

resource "aws_resourcegroups_group" "prod_servers" {
  name = "prod_servers"

  resource_query {
    query = <<JSON
{
  "ResourceTypeFilters": [
    "AWS::EC2::Instance"
  ],
  "TagFilters": [
    {
      "Key": "Environment",
      "Values": ["prod"]
    }
  ]
}
JSON
  }
}
