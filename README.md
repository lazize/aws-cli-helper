# AWS CLI Helper

## Welcome

This repository contains a helper script to be used together with AWS CLI on Linux/Unix.


## Pre-requisites

* [Bash](https://www.gnu.org/software/bash/)
* [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)


## Usage

This is a helper script which contains shell functions. **It is not a script to be executed directly**. You need to `source` it first.

The file doesn't need to have execution permission for it to be sourced or for it to work.

1. Clone this repository
1. `source` file `aws-cli-helper.sh`

```shell
git clone https://github.com/lazize/aws-cli-helper.git
source ./aws-cli-helper/aws-cli-helper.sh
```

## Helper functions

### aws-whoami
Show you which user or role you are using at the moment with AWS CLI.

### aws-region
Set the `region` default environment variable used by AWS CLI.

### aws-profile
Set the `profile` default environment variable used by AWS CLI.

### assume-role
Assume role and export environment variables to be used by AWS CLI.  
If AWS credentials environment variables were already set, it will save it before overwrite.

**Parameters**

* ROLE_ARN  
Role ARN to be assumed. It is mandatory.

* ROLE_SESSION_NAME  
Role session name to use when assume new role. It is optional. Default value is `assume-role-script`.

* ROLE_EXTERNAL_ID  
Role external ID to be used when assume new role. It is optional.

### assume-role-clear
Clear all environment variables used by `assume-role`. It will restore saved previews AWS credentials environment variables if they exist.

### describe-stacks
List CloudFormation stacks in a table format ordered by `LastUpdatedTime`.

### describe-stack-events
Describe CloudFormation stack events in a table format ordered by `Timestamp`.

**Parameters**

* STACK_NAME  
Stack name. It is mandatory.

### create-stack
Create CloudFormation stack for some template file. It will validate the template before creates it and will wait for `stack-create-complete` status.  
Create CloudFormation stack without any parameter, which means template doesn't have parameters or all parameters have already default value defined.

**Parameters**

* STACK_NAME  
Stack name to create. It is mandatory.

* FILE_NAME  
File name with CloudFormation stack to create. It is mandatory.

### update-stack
Update CloudFormation stack for some template file. It will validate the template before updates it and will wait for `stack-update-complete` status.
Update CloudFormation stack without any parameter, which means template doesn't have parameters or all parameters have already default value defined.

**Parameters**

* STACK_NAME  
Stack name to update. It is mandatory.

* FILE_NAME  
File name with CloudFormation stack to update. It is mandatory.

### delete-stack
Delete CloudFormation stack. It will delete and wait for `stack-delete-complete` status.

**Parameters**

* STACK_NAME  
Stack name to delete. It is mandatory.

### list-stack-sets
List CloudFormation stack-sets in a table format ordered by `StackSetName`.

### create-stack-set
Create CloudFormation stack-set for some template file. It will validate the template before creates it.  
After creates the stack-set it will create stack instances for specified Organization ID's.  
Create CloudFormation stack-set without any parameter, which means template doesn't have parameters or all parameters have already default value defined.

> Can be used only from the organization's management account or by a member account that is a delegated administrator for CloudFormation.

**Parameters**

* STACK_NAME  
Stack-set name to create. It is mandatory.

* FILE_NAME  
File name with CloudFormation stack-set to create. It is mandatory.

* REGIONS  
Regions to apply this stack-set. One unique string separated by space. It is mandatory.  
Example: 'sa-east-1' or 'sa-east-1 eu-west-1'

* ORG_IDS  
Organization Unit ID's. One unique string separated by comma. It is optional.  
If not informed (or empty string), will use the root OU from AWS Organization.

### update-stack-set
Update CloudFormation stack-set for some template file. It will validate the template before updates it.  
Update CloudFormation stack-set without any parameter, which means template doesn't have parameters or all parameters have already default value defined.

> Can be used only from the organization's management account or by a member account that is a delegated administrator for CloudFormation.

**Parameters**

* STACK_NAME  
Stack-set name to update. It is mandatory.

* FILE_NAME  
File name with CloudFormation stack-set to update. It is mandatory.

* REGIONS  
Regions to apply this stack-set. One unique string separated by space. It is mandatory.  
Example: 'sa-east-1' or 'sa-east-1 eu-west-1'

* ORG_IDS  
Organization Unit ID's. One unique string separated by comma. It is mandatory.

### list-stack-set-operation
List CloudFormation stack-set operation for some specific stack-set and operation results in a table format ordered by `Account`.

> Can be used only from the organization's management account or by a member account that is a delegated administrator for CloudFormation.

**Parameters**

* STACK_SET_NAME  
Stack-set name to list. It is mandatory.

* OPERATION_ID  
Operation ID from this stack-set. It is optional.  
If not informed will use the latest operation based on `CreationTimestamp`.

### list-roots
Lists the roots that are defined in the current organization.

> Can be used only from the organization's management account or by a member account that is a delegated administrator for CloudFormation.

### create-policy
Creates an AWS Organization policy of a specified type that you can attach to a root, an organizational unit (OU), or an individual AWS account.  
This is an "internal" function, please use functions called `create-policy-scp`, `create-policy-tag`, `create-policy-backup` and `create-policy-aiservices`.

> Can be used only from the organization's management account or by a member account that is a delegated administrator for AWS Organization.

**Parameters**

* POLICY_NAME  
Policy name. It is mandatory.

* DESCRIPTION  
Policy description. It is mandatory.

* FILE_NAME  
File with policy template. It is mandatory.

* TYPE  
The type of policy to create. It is mandatory.  
Possible values:
  * SERVICE_CONTROL_POLICY
  * TAG_POLICY
  * BACKUP_POLICY
  * AISERVICES_OPT_OUT_POLICY

### create-policy-scp
Creates an AWS Organization service control policy (SCP) that you can attach to a root, an organizational unit (OU), or an individual AWS account.  

> Can be used only from the organization's management account or by a member account that is a delegated administrator for AWS Organization.

**Parameters**

* POLICY_NAME  
Policy name. It is mandatory.

* DESCRIPTION  
Policy description. It is mandatory.

* FILE_NAME  
File with policy template. It is mandatory.

### create-policy-tag
Creates an AWS Organization tag policy that you can attach to a root, an organizational unit (OU), or an individual AWS account.  

> Can be used only from the organization's management account or by a member account that is a delegated administrator for AWS Organization.

**Parameters**

* POLICY_NAME  
Policy name. It is mandatory.

* DESCRIPTION  
Policy description. It is mandatory.

* FILE_NAME  
File with policy template. It is mandatory.

### create-policy-backup
Creates an AWS Organization backup policy that you can attach to a root, an organizational unit (OU), or an individual AWS account.  

> Can be used only from the organization's management account or by a member account that is a delegated administrator for AWS Organization.

**Parameters**

* POLICY_NAME  
Policy name. It is mandatory.

* DESCRIPTION  
Policy description. It is mandatory.

* FILE_NAME  
File with policy template. It is mandatory.

### create-policy-aiservices
Creates an AWS Organization AI services policy that you can attach to a root, an organizational unit (OU), or an individual AWS account.  

> Can be used only from the organization's management account or by a member account that is a delegated administrator for AWS Organization.

**Parameters**

* POLICY_NAME  
Policy name. It is mandatory.

* DESCRIPTION  
Policy description. It is mandatory.

* FILE_NAME  
File with policy template. It is mandatory.

### attach-policy
Attaches an AWS Organization policy to a root, an organizational unit (OU), or an individual account.  
After attach will list all target for this specified policy.

> Can be used only from the organization's management account or by a member account that is a delegated administrator for AWS Organization.

**Parameters**

* POLICY_ID  
Policy ID. It is mandatory.

* TARGET_ID  
Target ID to attach the policy. It is optional.  
If not informed, will use the root OU from AWS Organization.

### list-policies
List all AWS Organization policies in an organization of a specified type sorted by `Name`.

This is an "internal" function, please use functions called `list-policies-scp`, `list-policies-tag`, `list-policies-backup` and `list-policies-aiservices`.

> Can be used only from the organization's management account or by a member account that is a delegated administrator for AWS Organization.

**Parameters**

* FILTER  
Type of policy that you want to include in the response. It is mandatory.  
Possible values:
  * SERVICE_CONTROL_POLICY
  * TAG_POLICY
  * BACKUP_POLICY
  * AISERVICES_OPT_OUT_POLICY


### list-policies-scp
List all AWS Organization service control policies (SCP) in an organization sorted by `Name`.

> Can be used only from the organization's management account or by a member account that is a delegated administrator for AWS Organization.

### list-policies-tag
List all AWS Organization tag policies in an organization sorted by `Name`.

> Can be used only from the organization's management account or by a member account that is a delegated administrator for AWS Organization.

### list-policies-backup
List all AWS Organization backup policies in an organization sorted by `Name`.

> Can be used only from the organization's management account or by a member account that is a delegated administrator for AWS Organization.

### list-policies-aiservices
List all AWS Organization AI services policies in an organization sorted by `Name`.

> Can be used only from the organization's management account or by a member account that is a delegated administrator for AWS Organization.

### list-accounts
Lists all the accounts in the AWS Organization in a table format sorted by `Account ID`.

> Can be used only from the organization's management account or by a member account that is a delegated administrator for AWS Organization.

### list-aws-service-access-for-organization
List of AWS services that you enabled to integrate with your AWS Organization in a table format sorted by `ServicePrincipal`.

> Can be used only from the organization's management account or by a member account that is a delegated administrator for AWS Organization.

### register-delegated-administrator-for-aws-config
Enable and register an individual AWS account as delegated administrator for AWS Config service.  
After that it will list all delegated administrator accounts for service principals related to AWS Config service.

> Can be used only from the organization's management account or by a member account that is a delegated administrator for AWS Organization.

**Parameters**

* ADMIN_ACCOUNT_ID  
AWS account ID. It is mandatory.

### register-delegated-administrator-for-guardduty
Enable and register an individual AWS account as delegated administrator for AWS GuardDuty service.  
After that it will list all delegated administrator accounts for service principals related to AWS GuardDuty service.

> Can be used only from the organization's management account or by a member account that is a delegated administrator for GuardDuty.

**Parameters**

* ADMIN_ACCOUNT_ID  
AWS account ID. It is mandatory.

### guardduty-admin
At AWS GuardDuty administrator account, list information's about delegated administrator, organization configuration, detector and member accounts.

### register-delegated-administrator-for-securityhub
Enable and register an individual AWS account as delegated administrator for AWS Security Hub service.  
After that it will list all delegated administrator accounts for service principals related to AWS Security Hub service.

> Can be used only from the organization's management account or by a member account that is a delegated administrator for Security Hub.

**Parameters**

* ADMIN_ACCOUNT_ID  
AWS account ID. It is mandatory.

### securityhub-admin
At AWS Security Hub administrator account, list information's about delegated administrator, organization configuration, hub and member accounts.

### put-metric-alarm-for-ec2-reboot-at-check-failure
Creates or updates an CloudWatch alarm for all EC2 instances with action to `reboot` when instance status check fail.


## Security

See [CONTRIBUTING](CONTRIBUTING.md) for more information.


## License

This library is licensed under the GPL-3.0 License. See the [LICENSE](LICENSE) file.


## Disclaimer

The opinions expressed in this repository and code are my own and not necessarily those of my employer (past, present and future).