package tests

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestVnetModuleValidation validates the VNet module configuration
func TestVnetModuleValidation(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/vnet",
		Vars: map[string]interface{}{
			"resource_group_name": "rg-test",
			"location":           "eastus",
			"vnet_name":          "vnet-test",
			"address_space":      []string{"10.0.0.0/16"},
			"subnets": map[string]interface{}{
				"app": map[string]interface{}{
					"address_prefixes":  []string{"10.0.1.0/24"},
					"service_endpoints": []string{"Microsoft.Sql"},
				},
				"db": map[string]interface{}{
					"address_prefixes": []string{"10.0.2.0/24"},
				},
			},
			"tags": map[string]string{
				"Environment": "Test",
			},
		},
		NoColor: true,
	})

	// Validate the configuration compiles
	output := terraform.InitAndValidate(t, terraformOptions)
	assert.Contains(t, output, "Success")
}

// TestVnetModuleFormat checks Terraform formatting
func TestVnetModuleFormat(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../modules/vnet",
	}

	output := terraform.RunTerraformCommand(t, terraformOptions, "fmt", "-check", "-diff")
	assert.Empty(t, output, "Terraform files should be properly formatted")
}
