#!/bin/bash

# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# For LICENSE information, plese check the source repository:
# https://github.com/lazize/aws-cli-helper
#
# The opinions expressed in this repository and code are my own and not necessarily those of my employer (past, present and future).

aws-whoami() {
    aws sts get-caller-identity --no-cli-pager --output json
}

aws-region() {
    if [[ "${1}" = "" ]]
    then
        export AWS_REGION=sa-east-1
    else
        export AWS_REGION=${1}
    fi
}

aws-profile() {
    export AWS_PROFILE=${1}
}

### Assume role
assume-role() {
    local -r ROLE_ARN="${1}"
    local ROLE_SESSION_NAME="${2}" # Optional
    local -r ROLE_EXTERNAL_ID="${3}" # Optional
    local -r SERIAL_NUMBER="${4}" # Optional
    local -r TOKEN_CODE="${5}" # Optional

    if [[ "${ROLE_ARN}" = "" ]]
    then
        echo "usage: assume-role ROLE_ARN [ROLE_SESSION_NAME] [ROLE_EXTERNAL_ID] [SERIAL_NUMBER] [TOKEN_CODE]"
        return 1
    fi

    # If exists old keys, save it
    [[ "${AWS_ACCESS_KEY_ID}" != "" ]] && export AWS_ACCESS_KEY_ID_ORIGINAL="${AWS_ACCESS_KEY_ID}"
    [[ "${AWS_SECRET_ACCESS_KEY}" != "" ]] && export AWS_SECRET_ACCESS_KEY_ORIGINAL="${AWS_SECRET_ACCESS_KEY}"
    [[ "${AWS_SESSION_TOKEN}" != "" ]] && export AWS_SESSION_TOKEN_ORIGINAL="${AWS_SESSION_TOKEN}"
    [[ "${AWS_PROFILE}" != "" ]] && export AWS_PROFILE_ORIGINAL="${AWS_PROFILE}"
    [[ "${AWS_DEFAULT_PROFILE}" != "" ]] && export AWS_DEFAULT_PROFILE_ORIGINAL="${AWS_DEFAULT_PROFILE}"
    
    [[ "${ROLE_SESSION_NAME}" = "" ]] && ROLE_SESSION_NAME="assume-role-script"

    if [[ "${ROLE_EXTERNAL_ID}" != "" && "${SERIAL_NUMBER}" != "" && "${TOKEN_CODE}" != "" ]]
    then
        local -r ASSUMED_ROLE=$(aws sts assume-role --role-arn "${ROLE_ARN}" --role-session-name "${ROLE_SESSION_NAME}" --external-id "${ROLE_EXTERNAL_ID}" --serial-number "${SERIAL_NUMBER}" --token-code "${TOKEN_CODE}" --no-cli-pager --output text --query 'Credentials.[AccessKeyId, SecretAccessKey, SessionToken]')
    elif [[ "${SERIAL_NUMBER}" != "" && "${TOKEN_CODE}" != "" ]]
    then
        local -r ASSUMED_ROLE=$(aws sts assume-role --role-arn "${ROLE_ARN}" --role-session-name "${ROLE_SESSION_NAME}" --serial-number "${SERIAL_NUMBER}" --token-code "${TOKEN_CODE}" --no-cli-pager --output text --query 'Credentials.[AccessKeyId, SecretAccessKey, SessionToken]')
    elif [[ "${ROLE_EXTERNAL_ID}" != "" ]]
    then
        local -r ASSUMED_ROLE=$(aws sts assume-role --role-arn "${ROLE_ARN}" --role-session-name "${ROLE_SESSION_NAME}" --external-id "${ROLE_EXTERNAL_ID}" --no-cli-pager --output text --query 'Credentials.[AccessKeyId, SecretAccessKey, SessionToken]')
    else
        local -r ASSUMED_ROLE=$(aws sts assume-role --role-arn "${ROLE_ARN}" --role-session-name "${ROLE_SESSION_NAME}" --no-cli-pager --output text --query 'Credentials.[AccessKeyId, SecretAccessKey, SessionToken]')
    fi

    if [[ "${ASSUMED_ROLE}" != "" ]]
    then
        AWS_ACCESS_KEY_ID=$(echo "${ASSUMED_ROLE}" | awk '{print $1}')
        AWS_SECRET_ACCESS_KEY=$(echo "${ASSUMED_ROLE}" | awk '{print $2}')
        AWS_SESSION_TOKEN=$(echo "${ASSUMED_ROLE}" | awk '{print $3}')
        export AWS_ACCESS_KEY_ID
        export AWS_SECRET_ACCESS_KEY
        export AWS_SESSION_TOKEN
        unset AWS_PROFILE
        unset AWS_DEFAULT_PROFILE
        return 0
    fi
    return 1
}

assume-role-clear() {
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
    unset AWS_REGION
    unset AWS_DEFAULT_REGION
    unset AWS_PROFILE
    unset AWS_DEFAULT_PROFILE
    # if exists original keys, put it back
    [[ "${AWS_ACCESS_KEY_ID_ORIGINAL}" != "" ]] && export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID_ORIGINAL}"
    [[ "${AWS_SECRET_ACCESS_KEY_ORIGINAL}" != "" ]] && export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY_ORIGINAL}"
    [[ "${AWS_SESSION_TOKEN_ORIGINAL}" != "" ]] && export AWS_SESSION_TOKEN="${AWS_SESSION_TOKEN_ORIGINAL}"
    [[ "${AWS_PROFILE_ORIGINAL}" != "" ]] && export AWS_PROFILE="${AWS_PROFILE_ORIGINAL}"
    [[ "${AWS_DEFAULT_PROFILE_ORIGINAL}" != "" ]] && export AWS_DEFAULT_PROFILE="${AWS_DEFAULT_PROFILE_ORIGINAL}"
    unset AWS_ACCESS_KEY_ID_ORIGINAL
    unset AWS_SECRET_ACCESS_KEY_ORIGINAL
    unset AWS_SESSION_TOKEN_ORIGINAL
    unset AWS_PROFILE_ORIGINAL
    unset AWS_DEFAULT_PROFILE_ORIGINAL
}

### Session Token
get-session-token() {
    local -r SERIAL_NUMBER="${1}"
    local -r TOKEN_CODE="${2}"
    if [[ "${SERIAL_NUMBER}" = "" || "${TOKEN_CODE}" = "" ]]
    then
        echo "usage: get-session-token SERIAL_NUMBER TOKEN_CODE"
        return 1
    fi

    # If exists old keys, save it
    [[ "${AWS_ACCESS_KEY_ID}" != "" ]] && export AWS_ACCESS_KEY_ID_ORIGINAL="${AWS_ACCESS_KEY_ID}"
    [[ "${AWS_SECRET_ACCESS_KEY}" != "" ]] && export AWS_SECRET_ACCESS_KEY_ORIGINAL="${AWS_SECRET_ACCESS_KEY}"
    [[ "${AWS_SESSION_TOKEN}" != "" ]] && export AWS_SESSION_TOKEN_ORIGINAL="${AWS_SESSION_TOKEN}"
    [[ "${AWS_PROFILE}" != "" ]] && export AWS_PROFILE_ORIGINAL="${AWS_PROFILE}"
    [[ "${AWS_DEFAULT_PROFILE}" != "" ]] && export AWS_DEFAULT_PROFILE_ORIGINAL="${AWS_DEFAULT_PROFILE}"

    local -r CREDENTIALS=$(aws sts get-session-token --serial-number "${SERIAL_NUMBER}" --token-code "${TOKEN_CODE}" --no-cli-pager --output text --query 'Credentials.[AccessKeyId, SecretAccessKey, SessionToken]')
    if [[ "${CREDENTIALS}" != "" ]]
    then
        AWS_ACCESS_KEY_ID=$(echo "${CREDENTIALS}" | awk '{print $1}')
        AWS_SECRET_ACCESS_KEY=$(echo "${CREDENTIALS}" | awk '{print $2}')
        AWS_SESSION_TOKEN=$(echo "${CREDENTIALS}" | awk '{print $3}')
        export AWS_ACCESS_KEY_ID
        export AWS_SECRET_ACCESS_KEY
        export AWS_SESSION_TOKEN
        unset AWS_PROFILE
        unset AWS_DEFAULT_PROFILE
        return 0
    fi
    return 1
}

### Stack
describe-stacks() {
    aws cloudformation describe-stacks --output table --query 'sort_by(Stacks, &to_string(LastUpdatedTime))[].[StackName, StackStatus, DriftInformation.StackDriftStatus, LastUpdatedTime]' --no-cli-page
}

describe-stack-events() {
    local -r STACK_NAME="${1}"

    if [[ "${STACK_NAME}" = "" ]]
    then
        echo "usage: describe-stack-events STACK_NAME"
        return 1
    fi

    aws cloudformation describe-stack-events --stack-name "${STACK_NAME}" --output table --query 'sort_by(StackEvents, &to_string(Timestamp))[].[Timestamp, LogicalResourceId, ResourceStatus, ResourceStatusReason]' --no-cli-page
}

create-stack() {
    # Create CloudFormation stack without any parameter, which means template doesn't have parameters or all parameters have already default value defined
    local -r STACK_NAME="${1}"
    local -r FILE_NAME="${2}"

    if [[ "${STACK_NAME}" = "" || "${FILE_NAME}" = "" ]]
    then
        echo "usage: create-stack STACK_NAME FILE_NAME"
        return 1
    fi

    aws cloudformation validate-template --template-body "file://${FILE_NAME}" --no-cli-pager &&
    aws cloudformation create-stack --stack-name "${STACK_NAME}" --template-body "file://${FILE_NAME}" --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM --no-cli-pager &&
    aws cloudformation wait stack-create-complete --stack-name "${STACK_NAME}" --no-cli-pager
}

update-stack() {
    # Update CloudFormation stack without any parameter, which means template doesn't have parameters or all parameters have already default value defined
    local -r STACK_NAME="${1}"
    local -r FILE_NAME="${2}"
    
    if [[ "${STACK_NAME}" = "" || "${FILE_NAME}" = "" ]]
    then
        echo "usage: update-stack STACK_NAME FILE_NAME"
        return 1
    fi
    
    aws cloudformation validate-template --template-body "file://${FILE_NAME}" --no-cli-pager &&
    aws cloudformation update-stack --stack-name "${STACK_NAME}" --template-body "file://${FILE_NAME}" --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM --no-cli-pager &&
    aws cloudformation wait stack-update-complete --stack-name "${STACK_NAME}" --no-cli-pager
}

delete-stack() {
    local -r STACK_NAME="${1}"

    if [[ "${STACK_NAME}" = "" ]]
    then
        echo "usage: delete-stack STACK_NAME"
        return 1
    fi

    aws cloudformation delete-stack --stack-name "${STACK_NAME}" --no-cli-pager &&
    aws cloudformation wait stack-delete-complete --stack-name "${STACK_NAME}" --no-cli-pager
}

### Stack-sets
list-stack-sets() {
    aws cloudformation list-stack-sets --output table --query 'sort_by(Summaries, &StackSetName)[].[StackSetName, Status, DriftStatus, AutoDeployment.Enabled, AutoDeployment.RetainStacksOnAccountRemoval]' --no-cli-pager
}

create-stack-set() {
    # Create CloudFormation stack-set without any parameter, which means template doesn't have parameters or all parameters have already default value defined
    local -r STACK_NAME="${1}"
    local -r FILE_NAME="${2}"
    local -r REGIONS="${3}" # One unique string separated by space
    local ORG_IDS="${4}" # One unique string separated by comma. Optional
                         # If not informed (or empty string), will use the root OU from Org

    if [[ "${STACK_NAME}" = "" || "${FILE_NAME}" = "" || "${REGIONS}" = "" ]]
    then
        echo "usage: create-stack-set STACK_NAME FILE_NAME [REGIONS] [ORG_IDS]"
        return 1
    fi

    if [[ "${ORG_IDS}" = "" ]]
    then
        ORG_IDS=$(aws organizations list-roots --output text --query 'Roots[0].Id')
        echo "--> Root OU: ${ORG_IDS}"
    fi
    
    aws cloudformation validate-template --template-body "file://${FILE_NAME}" --no-cli-pager &&
    aws cloudformation create-stack-set \
        --stack-set-name "${STACK_NAME}" \
        --template-body "file://${FILE_NAME}" \
        --capabilities "CAPABILITY_NAMED_IAM" "CAPABILITY_IAM" \
        --permission-model "SERVICE_MANAGED" \
        --auto-deployment "Enabled=true,RetainStacksOnAccountRemoval=false"

    local -r OPERATION_ID=$(aws cloudformation create-stack-instances \
                                --stack-set-name "${STACK_NAME}" \
                                --operation-preferences "RegionConcurrencyType=PARALLEL,FailureTolerancePercentage=10,MaxConcurrentPercentage=10" \
                                --deployment-targets "OrganizationalUnitIds=${ORG_IDS}" \
                                --regions ${REGIONS} --output text --query 'OperationId')
    echo "--> OperationId: ${OPERATION_ID}"
    
    echo "Sleeping for 60 seconds ..."
    sleep 60

    echo "Run: list-stack-set-operation \"${STACK_NAME}\" \"${OPERATION_ID}\""
    list-stack-set-operation "${STACK_NAME}" "${OPERATION_ID}"
}

update-stack-set() {
    # Update CloudFormation stack-set without any parameter, which means template doesn't have parameters or all parameters have already default value defined
    local -r STACK_NAME="${1}"
    local -r FILE_NAME="${2}"
    local -r REGIONS="${3}" # One unique string separated by space
    local ORG_IDS="${4}" # One unique string separated by comma

    if [[ "${STACK_NAME}" = "" || "${FILE_NAME}" = "" || "${REGIONS}" = "" || "${ORG_IDS}" = "" ]]
    then
        echo "usage: update-stack-set STACK_NAME FILE_NAME [REGIONS] [ORG_IDS]"
        return 1
    fi

    aws cloudformation validate-template --template-body "file://${FILE_NAME}" --no-cli-pager &&
    local -r OPERATION_ID=$(aws cloudformation update-stack-set \
                                --stack-set-name "${STACK_NAME}" \
                                --template-body "file://${FILE_NAME}" \
                                --capabilities "CAPABILITY_NAMED_IAM" "CAPABILITY_IAM" \
                                --operation-preferences "RegionConcurrencyType=PARALLEL,FailureTolerancePercentage=10,MaxConcurrentPercentage=10" \
                                --deployment-targets "OrganizationalUnitIds=${ORG_IDS}" \
                                --permission-model "SERVICE_MANAGED" \
                                --auto-deployment "Enabled=true,RetainStacksOnAccountRemoval=false" \
                                --regions ${REGIONS} --output text --query 'OperationId')
    echo "--> OperationId: ${OPERATION_ID}"
    
    echo "Sleeping for 60 seconds ..."
    sleep 60

    echo "Run: list-stack-set-operation \"${STACK_NAME}\" \"${OPERATION_ID}\""
    list-stack-set-operation "${STACK_NAME}" "${OPERATION_ID}"
}

list-stack-set-operation() {
    local -r STACK_SET_NAME="${1}"
    local OPERATION_ID="${2}" # Optional. If not informed will use the latest operation

    if [[ "${STACK_SET_NAME}" = "" ]]
    then
        echo "usage: list-stack-set-operation STACK_SET_NAME [OPERATION_ID]"
        return 1
    fi

    if [[ "${OPERATION_ID}" = "" ]]
    then
        # Get latest operation
        OPERATION_ID=$(aws cloudformation list-stack-set-operations --stack-set-name "${STACK_SET_NAME}" --no-cli-pager --output text --query 'sort_by(Summaries, &CreationTimestamp)[-1].OperationId')
    fi
    aws cloudformation describe-stack-set-operation --stack-set-name "${STACK_SET_NAME}" --operation-id "${OPERATION_ID}" --no-cli-pager &&
    aws cloudformation list-stack-set-operation-results --stack-set-name "${STACK_SET_NAME}" --operation-id "${OPERATION_ID}" --no-cli-pager --output table --query 'sort_by(Summaries, &Account)[].[Account, Region, Status]'
}

### Organizations
list-roots() {
    aws organizations list-roots --no-cli-pager --output json
}

create-policy() {
    local -r POLICY_NAME="${1}"
    local -r DESCRIPTION="${2}"
    local -r FILE_NAME="${3}"
    local -r TYPE="${4}"

    if [[ "${POLICY_NAME}" = "" || "${DESCRIPTION}" = "" || "${FILE_NAME}" = "" || "${TYPE}" = "" ]]
    then
        echo "usage: create-policy POLICY_NAME DESCRIPTION FILE_NAME TYPE"
        return 1
    fi

    aws organizations create-policy --name "${POLICY_NAME}" --description "${DESCRIPTION}" --content "file://${FILE_NAME}" --type "SERVICE_CONTROL_POLICY" --no-cli-pager --output json
}

create-policy-scp() {
    local -r POLICY_NAME="${1}"
    local -r DESCRIPTION="${2}"
    local -r FILE_NAME="${3}"
    local -r TYPE="SERVICE_CONTROL_POLICY"

    if [[ "${POLICY_NAME}" = "" || "${DESCRIPTION}" = "" || "${FILE_NAME}" = "" ]]
    then
        echo "usage: create-policy-scp POLICY_NAME DESCRIPTION FILE_NAME"
        return 1
    fi

    create-policy "${POLICY_NAME}" "${DESCRIPTION}" "${FILE_NAME}" "${TYPE}"
}

create-policy-tag() {
    local -r POLICY_NAME="${1}"
    local -r DESCRIPTION="${2}"
    local -r FILE_NAME="${3}"
    local -r TYPE="TAG_POLICY"

    if [[ "${POLICY_NAME}" = "" || "${DESCRIPTION}" = "" || "${FILE_NAME}" = "" ]]
    then
        echo "usage: create-policy-tag POLICY_NAME DESCRIPTION FILE_NAME"
        return 1
    fi

    create-policy "${POLICY_NAME}" "${DESCRIPTION}" "${FILE_NAME}" "${TYPE}"
}

create-policy-backup() {
    local -r POLICY_NAME="${1}"
    local -r DESCRIPTION="${2}"
    local -r FILE_NAME="${3}"
    local -r TYPE="BACKUP_POLICY"

    if [[ "${POLICY_NAME}" = "" || "${DESCRIPTION}" = "" || "${FILE_NAME}" = "" ]]
    then
        echo "usage: create-policy-backup POLICY_NAME DESCRIPTION FILE_NAME"
        return 1
    fi

    create-policy "${POLICY_NAME}" "${DESCRIPTION}" "${FILE_NAME}" "${TYPE}"
}

create-policy-aiservices() {
    local -r POLICY_NAME="${1}"
    local -r DESCRIPTION="${2}"
    local -r FILE_NAME="${3}"
    local -r TYPE="AISERVICES_OPT_OUT_POLICY"

    if [[ "${POLICY_NAME}" = "" || "${DESCRIPTION}" = "" || "${FILE_NAME}" = "" ]]
    then
        echo "usage: create-policy-aiservices POLICY_NAME DESCRIPTION FILE_NAME"
        return 1
    fi

    create-policy "${POLICY_NAME}" "${DESCRIPTION}" "${FILE_NAME}" "${TYPE}"
}

attach-policy() {
    local -r POLICY_ID="${1}"
    local TARGET_ID="${2}" # Optional. If not informed, will use the root OU from Org

    if [[ "${POLICY_ID}" = "" ]]
    then
        echo "usage: attach-policy POLICY_ID [TARGET_ID]"
        return 1
    fi

    if [[ "${TARGET_ID}" = "" ]]
    then
        TARGET_ID=$(aws organizations list-roots --output text --query 'Roots[0].Id')
        echo "--> Root OU: ${TARGET_ID}"
    fi

    aws organizations attach-policy --policy-id "${POLICY_ID}" --target-id "${TARGET_ID}" --no-cli-pager --output json &&
    aws organizations list-targets-for-policy --policy-id "${POLICY_ID}" --output table --query 'sort_by(Targets, &Name)[].[Name, TargetId, Type]'
}

list-policies() {
    local -r FILTER="${1}"
    aws organizations list-policies --filter "${FILTER}" --no-cli-pager --output json --query 'sort_by(Policies, &Name)[*]'
}

list-policies-scp() {
    local -r FILTER="SERVICE_CONTROL_POLICY"
    list-policies "${FILTER}"
}

list-policies-tag() {
    local -r FILTER="TAG_POLICY"
    list-policies "${FILTER}"
}

list-policies-backup() {
    local -r FILTER="BACKUP_POLICY"
    list-policies "${FILTER}"
}

list-policies-aiservices() {
    local -r FILTER="AISERVICES_OPT_OUT_POLICY"
    list-policies "${FILTER}"
}

list-accounts() {
    aws organizations list-accounts --no-cli-pager --output table --query 'sort_by(Accounts, &Id)[].[Id, Name, Email, Status]'
}

list-aws-service-access-for-organization() {
    aws organizations list-aws-service-access-for-organization --no-cli-pager --output table --query 'sort_by(EnabledServicePrincipals, &ServicePrincipal)[].[ServicePrincipal, DateEnabled]'
}

register-delegated-administrator-for-aws-config() {
    local -r ADMIN_ACCOUNT_ID="${1}"
    
    if [[ "${ADMIN_ACCOUNT_ID}" = "" ]]
    then
        echo "usage: register-delegated-administrator-for-aws-config ADMIN_ACCOUNT_ID"
        return 1
    fi

    aws organizations enable-aws-service-access --service-principal config-multiaccountsetup.amazonaws.com &&
    aws organizations enable-aws-service-access --service-principal config.amazonaws.com &&
    aws organizations register-delegated-administrator --account-id "${ADMIN_ACCOUNT_ID}" --service-principal config-multiaccountsetup.amazonaws.com &&
    aws organizations register-delegated-administrator --account-id "${ADMIN_ACCOUNT_ID}" --service-principal config.amazonaws.com &&
    aws organizations list-delegated-administrators --service-principal config-multiaccountsetup.amazonaws.com --no-cli-pager --output json &&
    aws organizations list-delegated-administrators --service-principal config.amazonaws.com --no-cli-pager --output json
}

### GuardDuty
register-delegated-administrator-for-guardduty() {
    local -r ADMIN_ACCOUNT_ID="${1}"
    
    if [[ "${ADMIN_ACCOUNT_ID}" = "" ]]
    then
        echo "usage: register-delegated-administrator-for-guardduty ADMIN_ACCOUNT_ID"
        return 1
    fi

    aws guardduty enable-organization-admin-account --admin-account-id "${ADMIN_ACCOUNT_ID}" &&
    aws guardduty list-organization-admin-accounts --no-cli-pager --output json &&
    aws organizations list-delegated-administrators --service-principal guardduty.amazonaws.com --no-cli-pager --output json
}

guardduty-admin() {
    local -r DETECTOR_ID=$(aws guardduty list-detectors --output text --query 'DetectorIds[0]')

    aws organizations list-delegated-administrators --service-principal guardduty.amazonaws.com --no-cli-pager --output json &&
    aws guardduty describe-organization-configuration --detector-id "${DETECTOR_ID}" --no-cli-pager --output json &&
    aws guardduty get-detector --detector-id "${DETECTOR_ID}" --no-cli-pager --output json &&
    aws guardduty list-members --detector-id "${DETECTOR_ID}" --output table --query 'sort_by(Members, &AccountId)[].[AccountId, RelationshipStatus]' --no-cli-pager
}

### Security Hub
register-delegated-administrator-for-securityhub() {
    local -r ADMIN_ACCOUNT_ID="${1}"
    
    if [[ "${ADMIN_ACCOUNT_ID}" = "" ]]
    then
        echo "usage: register-delegated-administrator-for-securityhub ADMIN_ACCOUNT_ID"
        return 1
    fi

    aws securityhub enable-organization-admin-account --admin-account-id "${ADMIN_ACCOUNT_ID}" &&
    aws securityhub list-organization-admin-accounts --no-cli-pager --output json &&
    aws organizations list-delegated-administrators --service-principal securityhub.amazonaws.com --no-cli-pager --output json
}

securityhub-admin() {
    aws organizations list-delegated-administrators --service-principal securityhub.amazonaws.com --no-cli-pager --output json &&
    aws securityhub describe-organization-configuration --no-cli-pager --output json &&
    aws securityhub describe-hub --no-cli-pager --output json &&
    aws securityhub list-members --output table --query 'sort_by(Members, &AccountId)[].[AccountId, MemberStatus]' --no-cli-pager
}

### CloudWatch
put-metric-alarm-for-ec2-reboot-at-check-failure() {
    # Follow the recommendations from:
    # https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/UsingAlarmActions.html#AddingRebootActions
    # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/viewing_metrics_with_cloudwatch.html#status-check-metrics
    
    local -r REGION_ID=$(aws ec2 describe-availability-zones --query 'AvailabilityZones[0].RegionName' --output text)
    local -r INSTANCE_IDS=$(aws ec2 describe-instances --query 'Reservations[].Instances[].InstanceId' --output text)
    for INSTANCE_ID in ${INSTANCE_IDS}
    do
        echo "Intance: ${INSTANCE_ID}"
        aws cloudwatch put-metric-alarm \
            --alarm-name "StatusCheckFailed_Instance-reboot-${INSTANCE_ID}" \
            --actions-enabled \
            --alarm-actions "arn:aws:automate:${REGION_ID}:ec2:reboot" \
            --metric-name 'StatusCheckFailed_Instance' \
            --namespace 'AWS/EC2' \
            --statistic 'Minimum' \
            --dimensions "[{\"Name\":\"InstanceId\",\"Value\":\"${INSTANCE_ID}\"}]" \
            --period 60 \
            --evaluation-periods 3 \
            --datapoints-to-alarm 3 \
            --threshold 0 \
            --comparison-operator 'GreaterThanThreshold' \
            --treat-missing-data 'missing'
    done
}

### IP Ranges
ip-ranges-services()
{
    echo "Run: curl -s 'https://ip-ranges.amazonaws.com/ip-ranges.json' | jq -r '.prefixes[] | .service' | sort -u" &&
    curl -s 'https://ip-ranges.amazonaws.com/ip-ranges.json' | jq -r '.prefixes[] | .service' | sort -u
}

ip-ranges-regions()
{
    echo "Run: curl -s 'https://ip-ranges.amazonaws.com/ip-ranges.json' | jq -r '.prefixes[] | .region' | sort -u" &&
    curl -s 'https://ip-ranges.amazonaws.com/ip-ranges.json' | jq -r '.prefixes[] | .region' | sort -u
}

ip-ranges-services-from-region()
{
    local -r REGION="${1}"
    if [[ "${REGION}" = "" ]]
    then
        echo "ERROR - Invalid 'REGION' argument"
        return 1
    fi
    echo "Run: curl -s 'https://ip-ranges.amazonaws.com/ip-ranges.json' | jq -r \".prefixes[] | select(.region | contains(\\\"${REGION}\\\"))? | .service\" | sort -u" &&
    curl -s 'https://ip-ranges.amazonaws.com/ip-ranges.json' | jq -r ".prefixes[] | select(.region | contains(\"${REGION}\"))? | .service" | sort -u
}

ip-ranges-prefix-from-service()
{
    local -r SERVICE="${1}"
    if [[ "${SERVICE}" = "" ]]
    then
        echo "ERROR - Invalid 'SERVICE' argument"
        return 1
    fi
    echo "Run: curl -s 'https://ip-ranges.amazonaws.com/ip-ranges.json' | jq -r \".prefixes[] | select(.service == \\\"${SERVICE}\\\")? | .ip_prefix\" | sort -V" &&
    curl -s 'https://ip-ranges.amazonaws.com/ip-ranges.json' | jq -r ".prefixes[] | select(.service == \"${SERVICE}\")? | .ip_prefix" | sort -V
}

ip-ranges-prefix-from-service-and-region()
{
    local -r SERVICE="${1}"
    local -r REGION="${2}"
    if [[ "${SERVICE}" = "" ]]
    then
        echo "ERROR - Invalid 'SERVICE' argument"
        return 1
    fi
    if [[ "${REGION}" = "" ]]
    then
        echo "ERROR - Invalid 'REGION' argument"
        return 1
    fi
    echo "Run: curl -s 'https://ip-ranges.amazonaws.com/ip-ranges.json' | jq -r \".prefixes[] | select(.service == \\\"${SERVICE}\\\")? | select(.region == \\\"${REGION}\\\")? | .ip_prefix\" | sort -V" &&
    curl -s 'https://ip-ranges.amazonaws.com/ip-ranges.json' | jq -r ".prefixes[] | select(.service == \"${SERVICE}\")? | select(.region == \"${REGION}\")? | .ip_prefix" | sort -V
}
