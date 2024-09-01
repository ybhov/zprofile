alias ll='ls -l'
alias ds='docker ps'

#
# List zprofile functions
#
function zprofile {
    grep -E 'function [a-zA-Z0-9_]+\s*\{' $HOME/.zprofile | awk '{print $2}'
}

#
# Login to AWS SSO and add credentials to AWS CLI
#
function awsl {
    [ -z "$1" ] && { echo "Usage: awsl <PROFILE>"; return 1; }
    aws sso login --profile $1
    eval "$(aws configure export-credentials --profile $1 --format env)"
}

#
# Login to local docker container
#
function de {
    [ -z "$1" ] && { echo "Usage: de <CONTAINER_ID>"; return 1; }
    docker exec -it $1 /bin/bash
}

#
# Login to ECS container in AWS
#
function ecs_container {
    [ -z "$2" ] && { echo "Example: ecs_command <AWS_PROFILE> <TASK_ARN> <OPTIONAL:COMMAND_TO_RUN>"; return 1; }
    region=$(echo $2 | awk -F":" '{print $4}')
    cluster=$(echo $2 | awk -F":" '{print $6}' | awk -F"/" '{print $2}')
    task=$(echo $2 | awk -F":" '{print $6}' | awk -F"/" '{print $3}')
    if [ -z "$3" ]; then
        command_to_run="/bin/bash"
    else
        command_to_run=$3
    fi
    aws --profile $1 --region $region ecs execute-command --cluster $cluster --task $task --container app-container --command $command_to_run --interactive
}

#
# List out matching EC2 Instances
#
function describe_ec2 {
    [ -z "$2" ] && { echo "Example: describe_ec2 <AWS_PROFILE> <AWS_REGION> <SEARCH_NAME>"; return 1; }
    PROFILE=$1
    REGION=$2
    SEARCH=$3
    aws ec2 --profile $PROFILE --region $REGION describe-instances --filters "Name=tag:Name,Values=*$SEARCH*" --query "Reservations[*].Instances[*].{Instance:InstanceId,IP:PrivateIpAddress,AZ:Placement.AvailabilityZone,Name:Tags[?Key=='Name']|[0].Value}" --output table
}

#
# Login and view ECR Repos
#
function ecr_login {
    [ -z "$2" ] && { echo "Usage: ecr_login <PROFILE> <REGION>"; return; }
    PROFILE=$1
    REGION=$2
    ACCOUNT=$(aws --profile $PROFILE sts get-caller-identity | jq -r .Account)
    aws --profile $PROFILE ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT.dkr.ecr.$REGION.amazonaws.com
}