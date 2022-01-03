#!/bin/bash

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# For LICENSE information, plese check the source repository:
# https://github.com/lazize/aws-cli-helper

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

    if [[ "${ROLE_ARN}" = "" ]]
    then
        echo "usage: assume-role ROLE_ARN [ROLE_SESSION_NAME] [ROLE_EXTERNAL_ID]"
        return 1
    fi

    # If exists old keys, save it
    [[ "${AWS_ACCESS_KEY_ID}" != "" ]] && export AWS_ACCESS_KEY_ID_ORIGINAL="${AWS_ACCESS_KEY_ID}"
    [[ "${AWS_SECRET_ACCESS_KEY}" != "" ]] && export AWS_SECRET_ACCESS_KEY_ORIGINAL="${AWS_SECRET_ACCESS_KEY}"
    [[ "${AWS_SESSION_TOKEN}" != "" ]] && export AWS_SESSION_TOKEN_ORIGINAL="${AWS_SESSION_TOKEN}"
    [[ "${AWS_PROFILE}" != "" ]] && export AWS_PROFILE_ORIGINAL="${AWS_PROFILE}"
    [[ "${AWS_DEFAULT_PROFILE}" != "" ]] && export AWS_DEFAULT_PROFILE_ORIGINAL="${AWS_DEFAULT_PROFILE}"
    
    [[ "${ROLE_SESSION_NAME}" = "" ]] && ROLE_SESSION_NAME="assume-role-script"
    
    if [[ "${ROLE_EXTERNAL_ID}" = "" ]]
    then
        local -r ASSUMED_ROLE=$(aws sts assume-role --role-arn "${ROLE_ARN}" --role-session-name "${ROLE_SESSION_NAME}" --no-cli-pager --output text --query 'Credentials.[AccessKeyId, SecretAccessKey, SessionToken]')
    else
        local -r ASSUMED_ROLE=$(aws sts assume-role --role-arn "${ROLE_ARN}" --role-session-name "${ROLE_SESSION_NAME}" --external-id "${ROLE_EXTERNAL_ID}" --no-cli-pager --output text --query 'Credentials.[AccessKeyId, SecretAccessKey, SessionToken]')
    fi
    
    if [[ "${ASSUMED_ROLE}" != "" ]]
    then
        export AWS_ACCESS_KEY_ID=$(echo "${ASSUMED_ROLE}" | awk '{print $1}')
        export AWS_SECRET_ACCESS_KEY=$(echo "${ASSUMED_ROLE}" | awk '{print $2}')
        export AWS_SESSION_TOKEN=$(echo "${ASSUMED_ROLE}" | awk '{print $3}')
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
    # if exists original keys, put it back
    [[ "${AWS_ACCESS_KEY_ID_ORIGINAL}" != "" ]] && export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID_ORIGINAL}"
    [[ "${AWS_SECRET_ACCESS_KEY_ORIGINAL}" != "" ]] && export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY_ORIGINAL}"
    [[ "${AWS_SESSION_TOKEN_ORIGINAL}" != "" ]] && export AWS_SESSION_TOKEN="${AWS_SESSION_TOKEN_ORIGINAL}"
    [[ "${AWS_PROFILE_ORIGINAL}" != "" ]] && export AWS_PROFILE="${AWS_PROFILE_ORIGINAL}"
    [[ "${AWS_DEFAULT_PROFILE_ORIGINAL}" != "" ]] && export AWS_DEFAULT_PROFILE="${AWS_DEFAULT_PROFILE_ORIGINAL}"
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
                         # If not informed, will use the root OU from Org

    if [[ "${STACK_NAME}" = "" || "${FILE_NAME}" = "" ]]
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
    
    echo "Sleeping for 20 seconds ..."
    sleep 20

    list-stack-set-operation "${STACK_NAME}" "${OPERATION_ID}"
}

update-stack-set() {
    # Update CloudFormation stack-set without any parameter, which means template doesn't have parameters or all parameters have already default value defined
    local -r STACK_NAME="${1}"
    local -r FILE_NAME="${2}"
    local -r REGIONS="${3}" # One unique string separated by space
    local ORG_IDS="${4}" # One unique string separated by comma. Optional
                         # If not informed, will use the root OU from Org

    if [[ "${STACK_NAME}" = "" || "${FILE_NAME}" = "" ]]
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
    
    echo "Sleeping for 20 seconds ..."
    sleep 20

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
