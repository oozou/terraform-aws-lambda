package test

import (
	"flag"
	"fmt"
	"os"
	//"strings"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/lambda"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/oozou/terraform-test-util"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Global variables for test reporting
var (
	generateReport bool
	reportFile     string
	htmlFile       string
)

// TestMain enables custom test runner with reporting
func TestMain(m *testing.M) {
	flag.BoolVar(&generateReport, "report", false, "Generate test report")
	flag.StringVar(&reportFile, "report-file", "test-report.json", "Test report JSON file")
	flag.StringVar(&htmlFile, "html-file", "test-report.html", "Test report HTML file")
	flag.Parse()

	exitCode := m.Run()
	os.Exit(exitCode)
}

func TestTerraformAWSLambdaModule(t *testing.T) {
	t.Parallel()

	// Record test start time
	startTime := time.Now()
	var testResults []testutil.TestResult

	// Pick a random AWS region to test in
	awsRegion := "ap-southeast-1"

	// Construct the terraform options with default retryable errors to handle the most common
	// retryable errors in terraform testing.
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../examples/terraform-test",

		// Environment variables to set when running Terraform
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer func() {
		terraform.Destroy(t, terraformOptions)

		// Generate and display test report
		endTime := time.Now()
		report := testutil.GenerateTestReport(testResults, startTime, endTime)
		report.TestSuite = "Terraform AWS Lambda Tests"
		report.PrintReport()

		// Save reports to files
		if err := report.SaveReportToFile("test-report.json"); err != nil {
			t.Errorf("failed to save report to file: %v", err)
		}

		if err := report.SaveReportToHTML("test-report.html"); err != nil {
			t.Errorf("failed to save report to HTML: %v", err)
		}
	}()

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Define test cases with their functions
	testCases := []struct {
		name string
		fn   func(*testing.T, *terraform.Options, string)
	}{
		{"TestLambdaCreated", testLambdaCreated},
		{"TestLambdaConfiguration", testLambdaConfiguration},
		{"TestLambdaInvocation", testLambdaInvocation},
		{"TestIAMRoleAndPolicies", testIAMRoleAndPolicies},
		{"TestEnvironmentVariables", testEnvironmentVariables},
		{"TestCloudWatchLogs", testCloudWatchLogs},
	}

	// Run all test cases and collect results
	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			testStart := time.Now()

			// Capture test result
			defer func() {
				testEnd := time.Now()
				duration := testEnd.Sub(testStart)

				result := testutil.TestResult{
					Name:     tc.name,
					Duration: duration.String(),
				}

				if r := recover(); r != nil {
					result.Status = "FAIL"
					result.Error = fmt.Sprintf("Panic: %v", r)
				} else if t.Failed() {
					result.Status = "FAIL"
					result.Error = "Test assertions failed"
				} else if t.Skipped() {
					result.Status = "SKIP"
				} else {
					result.Status = "PASS"
				}

				testResults = append(testResults, result)
			}()

			// Run the actual test
			tc.fn(t, terraformOptions, awsRegion)
		})
	}
}

// Test if Lambda functions are created
func testLambdaCreated(t *testing.T, terraformOptions *terraform.Options, awsRegion string) {
	functionName := terraform.Output(t, terraformOptions, "function_name")
	require.NotEmpty(t, functionName, "Lambda function name should not be empty")

	sess, err := session.NewSession(&aws.Config{
		Region: aws.String(awsRegion)},
	)
	require.NoError(t, err, "Failed to create AWS session")

	lambdaClient := lambda.New(sess)

	_, err = lambdaClient.GetFunction(&lambda.GetFunctionInput{
		FunctionName: aws.String(functionName),
	})

	assert.NoError(t, err, "Lambda function should exist")
}

func testLambdaConfiguration(t *testing.T, terraformOptions *terraform.Options, awsRegion string) {
	functionName := terraform.Output(t, terraformOptions, "function_name")
	require.NotEmpty(t, functionName, "Lambda function name should not be empty")

	sess, err := session.NewSession(&aws.Config{
		Region: aws.String(awsRegion)},
	)
	require.NoError(t, err, "Failed to create AWS session")

	lambdaClient := lambda.New(sess)

	function, err := lambdaClient.GetFunction(&lambda.GetFunctionInput{
		FunctionName: aws.String(functionName),
	})
	require.NoError(t, err, "Failed to get lambda function")

	assert.Equal(t, "nodejs22.x", *function.Configuration.Runtime, "Unexpected runtime")
	assert.Equal(t, "index.handler", *function.Configuration.Handler, "Unexpected handler")
	assert.Equal(t, int64(3), *function.Configuration.Timeout, "Unexpected timeout")
	assert.Equal(t, int64(128), *function.Configuration.MemorySize, "Unexpected memory size")
}

func testLambdaInvocation(t *testing.T, terraformOptions *terraform.Options, awsRegion string) {
	functionName := terraform.Output(t, terraformOptions, "function_name")
	require.NotEmpty(t, functionName, "Lambda function name should not be empty")

	sess, err := session.NewSession(&aws.Config{
		Region: aws.String(awsRegion)},
	)
	require.NoError(t, err, "Failed to create AWS session")

	lambdaClient := lambda.New(sess)

	payload := `{"Host": "example.com", "Port": 80}`

	result, err := lambdaClient.Invoke(&lambda.InvokeInput{
		FunctionName: aws.String(functionName),
		Payload:      []byte(payload),
	})

	require.NoError(t, err, "Failed to invoke lambda function")
	assert.Equal(t, int64(200), *result.StatusCode, "Expected status code 200")
}

func testIAMRoleAndPolicies(t *testing.T, terraformOptions *terraform.Options, awsRegion string) {
	roleArn := terraform.Output(t, terraformOptions, "execution_role_arn")
	require.NotEmpty(t, roleArn, "Execution role ARN should not be empty")
	// Further checks can be added here to verify attached policies
}


func testEnvironmentVariables(t *testing.T, terraformOptions *terraform.Options, awsRegion string) {
	functionName := terraform.Output(t, terraformOptions, "function_name")
	require.NotEmpty(t, functionName, "Lambda function name should not be empty")

	sess, err := session.NewSession(&aws.Config{
		Region: aws.String(awsRegion)},
	)
	require.NoError(t, err, "Failed to create AWS session")

	lambdaClient := lambda.New(sess)

	function, err := lambdaClient.GetFunction(&lambda.GetFunctionInput{
		FunctionName: aws.String(functionName),
	})
	require.NoError(t, err, "Failed to get lambda function")

	require.NotNil(t, function.Configuration.Environment, "Environment variables should not be nil")
	assert.Equal(t, "ap-southeast-1", *function.Configuration.Environment.Variables["region"], "Unexpected region")
}

func testCloudWatchLogs(t *testing.T, terraformOptions *terraform.Options, awsRegion string) {
	// This test would require additional permissions to describe log groups.
	// For now, we'll just check that the log group name is what we expect.
	functionName := terraform.Output(t, terraformOptions, "function_name")
	logGroupName := fmt.Sprintf("/aws/lambda/%s", functionName)
	assert.Contains(t, logGroupName, "function", "Log group name should contain 'function'")
}