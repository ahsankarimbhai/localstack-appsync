resource "aws_api_gateway_rest_api" "unifiedConnectorAPI" {
  name        = "${var.name_prefix}-mock-uc"
  description = "Mock API for UnifiedConnector used for E2E testing"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "business" {
  rest_api_id = aws_api_gateway_rest_api.unifiedConnectorAPI.id
  parent_id   = aws_api_gateway_rest_api.unifiedConnectorAPI.root_resource_id
  path_part   = "business"
}

resource "aws_api_gateway_resource" "businessGuid" {
  rest_api_id = aws_api_gateway_rest_api.unifiedConnectorAPI.id
  parent_id   = aws_api_gateway_resource.business.id
  path_part   = "{businessGuid}"
}

resource "aws_api_gateway_resource" "computer" {
  rest_api_id = aws_api_gateway_rest_api.unifiedConnectorAPI.id
  parent_id   = aws_api_gateway_resource.businessGuid.id
  path_part   = "computer"
}

resource "aws_api_gateway_resource" "ucid" {
  rest_api_id = aws_api_gateway_rest_api.unifiedConnectorAPI.id
  parent_id   = aws_api_gateway_resource.computer.id
  path_part   = "{ucid}"
}

resource "aws_api_gateway_method" "UnifiedConnectorMethod" {
  rest_api_id   = aws_api_gateway_rest_api.unifiedConnectorAPI.id
  resource_id   = aws_api_gateway_resource.ucid.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "UnifiedConnectorIntegration" {
  rest_api_id = aws_api_gateway_rest_api.unifiedConnectorAPI.id
  resource_id = aws_api_gateway_resource.ucid.id
  http_method = aws_api_gateway_method.UnifiedConnectorMethod.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = <<EOF
{
   "statusCode" : 200
}
EOF
  }
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id     = aws_api_gateway_rest_api.unifiedConnectorAPI.id
  resource_id     = aws_api_gateway_resource.ucid.id
  http_method     = aws_api_gateway_method.UnifiedConnectorMethod.http_method
  status_code     = "200"
  response_models = { "application/json" = "Empty" }
}

resource "aws_api_gateway_integration_response" "UnifiedConnectorIntegrationResponse" {
  depends_on = [
    aws_api_gateway_integration.UnifiedConnectorIntegration
  ]
  rest_api_id = aws_api_gateway_rest_api.unifiedConnectorAPI.id
  resource_id = aws_api_gateway_resource.ucid.id
  http_method = aws_api_gateway_method.UnifiedConnectorMethod.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code

  # Transforms the backend JSON response to XML
  response_templates = {
    "application/json" = <<EOF
{
    "adapters": [
        {
            "name": "Intel(R) 82574L Gigabit Network Connection",
            "mac": "00:50:56:a9:40:13",
            "ipv4": [
                "10.85.207.200"
            ],
            "ipv6": [
                "2001:420:2852:2011:c195:89b0:86f2:d2f0",
                "2001:420:2852:2011:f1ee:c38c:45f3:a96c",
                "fe80::c195:89b0:86f2:d2f0"
            ]
        }
    ],
    "arch": "unspecified",
    "bios_uuid": "f9a72942-0295-067c-474f-a9566564a8de",
    "boot_partition": "08a1e073-5907-42f7-aefd-714b8b17003d",
    "created": "2022-07-19T13:15:26.768088551Z",
    "disabled": false,
    "installations": [
        {
            "package": {
                "product": "cm-enterprise",
                "version": "99.0.1.400"
            },
            "configs": [
                {
                    "path": "<FOLDERID_ProgramFiles>/Cisco/Cisco Secure Client/CM/Configuration/cm_config.json",
                    "sha256": "2fc7ced8c1d09060fea8ad71d49b0e4e0d6d683e5020a36afe8efa8ba26692a6"
                }
            ]
        },
        {
            "package": {
                "product": "AMP",
                "version": "99.0.99.21144"
            },
            "configs": [
                {
                    "path": "<FOLDERID_ProgramData>/Cisco/AMP/bootstrap.xml",
                    "sha256": "5eb2001590dfce46f8ce0dd56c4314e73489a81370146d0c9f0661255615af2f"
                }
            ]
        },
        {
            "package": {
                "product": "ac-dart",
                "version": "5.0.00529"
            },
            "configs": []
        }
    ],
    "instance_key": "c7787f29-42dc-4946-b8ad-6a79318c61f7",
    "last_deployment_id": "e76f8547-9b1e-43b2-83b3-7dff21856f17",
    "last_domain": "WORKGROUP",
    "last_installer_id": "d6df277e-40e4-47c0-81bf-ccb8f9a56829",
    "last_hostname": "DESKTOP-EQ524I8",
    "last_os": "name Microsoft Windows 10 Enterprise - major: 10/minor 0/patch ",
    "serial": "VMware-42 29 a7 f9 95 02 7c 06-47 4f a9 56 65 64 a8 de",
    "ucid": "7db43731-feb9-4055-9ebe-66a9de465fd6",
    "updated": "2025-07-22T14:42:29.378997771Z",
    "wanted_deployment_id": "00000000-0000-0000-0000-000000000000"
} 
EOF
  }
}

output "api_gateway" {
  value = aws_api_gateway_rest_api.unifiedConnectorAPI
}
