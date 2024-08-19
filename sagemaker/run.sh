#!/bin/bash
set -e
source "${ARC_PATH}/toolbox/util.sh"

# find the arg --run_name and --task put the string values in the corresponding variables
for arg in "$@"; do
  # Check if the argument matches --run_name=value pattern
  if [[ $arg == --run_name=* ]]; then
    # Extract the value after the equals sign
    run_name="${arg#*=}"
    continue
  fi
  # Check if the argument matches --task=value pattern
  if [[ $arg == --task=* ]]; then
    # Extract the value after the equals sign
    task_name="${arg#*=}"
    # Exit the loop once the value is found
    continue
  fi
done

# Check if the values for run_name
if [ -z "$run_name" ]; then
  echo "Error: --run_name not provided."
  exit 1
fi

# Check if --run_name meets the naming constraints for aws
aws_pattern="^[a-zA-Z0-9](-*[a-zA-Z0-9]){0,62}$"

if ! [[ $run_name =~ $aws_pattern ]]; then
  LOG_ERROR "--run_name $run_name does not meet naming constraint where only letters, numbers and '-' are allowed (constraint: $aws_pattern)"
  exit 1
fi

registry="073089794243.dkr.ecr.eu-central-1.amazonaws.com/arc-gym"
timestamp=$(date +%s)  # Get the current timestamp in seconds since the Unix epoch
tag=$(date -d @"$timestamp" +"%Y-%m-%d.%H%M%S")  # Convert the timestamp to a human-readable format
image="${registry}:${tag}"

# Define the new Dockerfile path
new_dockerfile="/home/aanliker/Dockerfile"
context_dir="/home/aanliker"

# Build Docker with the new Dockerfile and context directory
echo "Building docker image: ${image} using Dockerfile: ${new_dockerfile}"
DOCKER_BUILDKIT=1 docker build \
  -f "${new_dockerfile}" \
  -t "${image}" \
  -t "${registry}:latest" \
  "${context_dir}" \

echo "Finished building docker"

# Push image to ECR
aws ecr get-login-password --region eu-central-1 --profile ascento-machine-learning | docker login --username AWS --password-stdin "${registry}"
docker push "${image}"
docker push "${registry}:latest"

# AWS allows us to use ml.g5.2xlarge and ml.g5.4xlarge
instance_type="ml.g5.2xlarge"

aws sagemaker create-training-job \
    --region eu-central-1 \
    --profile ascento-machine-learning \
    --training-job-name "${run_name}" \
    --algorithm-specification "TrainingInputMode=File,TrainingImage=${image}" \
    --role-arn "arn:aws:iam::073089794243:role/service-role/SageMaker-AscentoAutomation" \
    --checkpoint-config "S3Uri=s3://ascento-arc-gym/${task_name}" \
    --output-data-config "S3OutputPath=s3://ascento-arc-gym/${task_name}/exported" \
    --resource-config "InstanceType=${instance_type},InstanceCount=1,VolumeSizeInGB=50,KeepAlivePeriodInSeconds=0" \
    --stopping-condition "MaxRuntimeInSeconds=43200" \

echo "Started job: https://eu-central-1.console.aws.amazon.com/sagemaker/home?region=eu-central-1#/jobs/${run_name}"
