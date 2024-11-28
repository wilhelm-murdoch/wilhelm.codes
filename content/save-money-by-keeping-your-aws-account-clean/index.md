At my current role, we manage just under 20 AWS accounts. Their uses vary from production workloads, to dedicated CI/CD environments, sandboxed areas for our engineers to experiment in, log aggregation, the list goes on. Needless to say, we like to isolate our concerns across our AWS org.

Because we have so many to manage and not a whole lot of people power ( it’s just 2 of us ), it gets easy for a lot of hidden costs to pop up here and there if we aren’t vigilant enough with housekeeping. 

We like to keep roughly 95% of *all* static infrastructure nicely tucked away in Terraform, but over the years you get so many small extant changes that the dirt begins to pile up and, along with it, costs. Just a little bit here and there, but the cumulative effect becomes more and more obvious as time moves on.

So, what do you do? Do you manually audit every account? Every *region* in every account? AWS doesn’t give you an easy way to view *all* resources across the entirety of your org outside of what you can glean from the billing console. So, we do what comes natural; find a way to make the glowing rectangle do the job for you.

The goal here isn't to find a solution that does _everything_, but just enough to make our jobs easier.

## Enter AWS Nuke

%[https://github.com/rebuy-de/aws-nuke]

I found [this utility](https://github.com/rebuy-de/aws-nuke) sometime last year when asked to find a way to trim some extra fat off our monthly bill. It is *excellent* and works precisely as advertised. It wound up only saving us a few hundred bucks per month, which is a drop in the bucket considering our total monthly spend, but saving money isn’t the only benefit.

### Added Security

Cleaning up unused resources is a low touch way to keeping up your security posture. Fewer forgotten things, means a smaller attack surface.

The longer you leave something unchecked, the harder it becomes to manage. Entropy affects everything and while code can be immutable, the world acting upon it is not. 

Think back and ask yourself how many times you’ve forgotten about a service with ageing dependencies, or an EC2 instance you haven’t patched in a while, or some critical, but undocumented, component stored away in some forgotten area of one of your accounts.

If you don’t need it, or don’t plan on actively maintaining it, find a way to get rid of it. 

### Soft-Dollar Cost

People tend to forget the hidden cost of maintaining lots of things; it requires human attention. Have a lot of random things you need to manage? Well, the more things there are the more time you spend on them. That literally translates to money spent at the end of the billing period and it won't be showing up on the invoice.

Wouldn’t you rather spend your time on more important things at work? Reduce hidden costs by cleaning up after yourself.

## Ok, Let's Nuke Some Stuff

First things first, determine the account id you're going to use. 

This is a highly-destructive operation, so make sure you're targeting the right account. Get yourself some credentials either through privileged IAM or an SSO user session. Assume from here on out that `11111111111` is your target account and ensure your user has administrative privileges. You'll need this level of authorization if you're going to be doing this kind of deep cleaning.

Ensure your credentials are associated with the proper account by doing something similar to the following. As a side note, if you're using a credentials sourced by SSO, you're going to need the `AWS_SESSION_TOKEN`, otherwise it's safe to ignore.

```bash
export AWS_ACCESS_KEY_ID="***"
export AWS_SECRET_ACCESS_KEY="***"
export AWS_SESSION_TOKEN="***"
aws sts get-caller-identity
{
    "UserId": "XXXXXXXXXXXXXXXX:DEADBEEF",
    "Account": "11111111111",
    "Arn": "arn:aws:sts::11111111111:assumed-role/AWSReservedSSO_AdministratorAccess/DEADBEEF"
}
```

## Configuration

There may be resources you wish to keep while cleaning your account. AWS Nuke exposes comprehensive filtering capabilities that allow you to ignore, or target, specific sets of resources. In our case, it would be stuff like GuardDuty, AWS Config, CloudTrail and S3 buckets dedicated to Terraform state storage. For resources we don't want to wipe, the following configuration provides a basic example of how you may bootstrap the cleaning process.

Ultimately, this will be highly specific to your unique use case, but it's a great way to demonstrate how it all works. Let's go through all the important sections:

```yaml
---
regions:
  - global
  - eu-north-1
  - ap-south-1
  - eu-west-3
  - eu-west-2
  - eu-west-1
  - ap-northeast-3
  - ap-northeast-2
  - ap-northeast-1
  - sa-east-1
  - ca-central-1
  - ap-southeast-1
  - ap-southeast-2
  - eu-central-1
  - us-east-1
  - us-east-2
  - us-west-1
  - us-west-2

account-blocklist:
- 12345678910

resource-types:
  excludes:
    - CloudWatchAlarm
    - Route53ResolverRule
    - Route53HostedZone
    - S3Object
    - S3Bucket
    - GuardDutyDetector
    - SNSSubscription
    - IAMSAMLProvider
    - CloudTrailTrail

accounts:
  11111111111:
    filters:
      IAMPolicy:
        - type: contains
          value: AWS-Chatbot-NotificationsOnly-Policy
      IAMRolePolicy:
        - type: contains
          value: CloudTrailCloudWatchLogsRole
        - type: contains
          value: OrganizationAccountAccessRole
      IAMRole:
        - type: contains
          value: AWSReservedSSO
        - type: contains
          value: CloudWatchAlarmToSlackRole
        - CloudTrailCloudWatchLogsRole
        - OrganizationAccountAccessRole
      IAMRolePolicyAttachment:
        - type: contains
          value: AWSReservedSSO
        - type: contains
          value: CloudWatchAlarmToSlackRole
      SNSTopic:
        - type: contains
          value: CloudWatchAlarms
      CloudWatchLogsLogGroup:
        - CloudTrail/DefaultLogGroup
```

#### `regions`

Lists the AWS regions to screen for resources. By default, we allow the tool to cycle through all supported regions. Unfortunately, there is no support for "all regions", so this is a list that will have to be manually maintained. Also, depending on the amount of resources, or use-case for this tool, you may not want to scan all regions. Trim this list to suit your purposes. 

`global` refers to _services_ which are considered global and not tied to any specific region. For example, IAM users, policies and roles.

#### `account-blocklist`

A list of AWS accounts to completely avoid. If you're not confident in your account selections, this is a great place to put accounts that run production workloads as an added failsafe. Remember, be explicit in your selections and use this tool _only_ in accounts you wish to clean. 

#### `resource-types.excludes` 

A list of AWS resources we wish to ignore. For us, these are typically associated with the resources we've primed using Terraform. In this case, we just skip them completely. Trim this list to suit your purposes, or just manually delete these resources in the AWS console if you're unsure.

#### `accounts`

Contains the id of the account you wish to clean. Within this block, you will see filters used to skip certain resources. In our case, the filter almost always contains a list of things we wish to keep in all accounts. Resources like CloudWatch alarms, GuardDuty and AWS Config settings, etc... 

You can read more about configuring `aws-nuke` in the associated repository's [README](https://github.com/rebuy-de/aws-nuke/blob/main/README.md). Feel free to customise this file locally to suit your own needs. There are a number of ways to filter and target resources with a high degree of precision.

## Using the Tool
By default, `aws-nuke` does not perform any destructive operations. You must explicitly add the `--no-dry-run` flag with a subsequent run after performing the initial scan of the target account.

You can install the tool locally on your machine, but I prefer using Docker to invoke the tool:

```bash
docker run --rm -it \
    -v ~/aws-nuke-config.yml:/home/aws-nuke/config.yml \
    -e AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY \
    -e AWS_SESSION_TOKEN \
    quay.io/rebuy/aws-nuke:main \
    --config /home/aws-nuke/config.yml
```

You will be asked to manually type the alias of the target account for confirmation. For our purposes, the alias for account `11111111111` is `aws-nuke-account`:

```
aws-nuke version v2.19.0.15.gb46fbe0 - Wed Oct  5 10:01:13 UTC 2022 - b46fbe0e9f63266f56b5afd9635b4e4d5a3108d4

Do you really want to nuke the account with the ID 11111111111 and the alias 'aws-nuke-account'?
Do you want to continue? Enter account alias to continue.
> aws-nuke-account
```

You will then see a list of AWS resources as `aws-nuke` cycles through each region:

```
global - IAMRole - RDSBucketAccessRole - [Name: "RDSBucketAccessRole", Path: "/service-role/"] - filtered by config
global - IAMRole - S3BucketAccessRole - [Name: "S3BucketAccessRole", Path: "/"] - would remove
global - IAMRole - EBSSnapshotReplicationRole - [Name: "EBSSnapshotReplicationRole", Path: "/"] - would remove
global - IAMRole - VPCFlowLogsRole - [Name: "VPCFlowLogsRole", Path: "/"] - would remove
global - IAMRole - OrganizationAccountAccessRole - [Name: "OrganizationAccountAccessRole", Path: "/"] - filtered by config
us-west-2 - EC2RouteTable - rtb-0000000000 - [tag:ManagedBy: "terraform", tag:Name: "VPCRouteTablePublic", tag:Purpose: "vpc-route-table"] - would remove
us-west-2 - EC2RouteTable - rtb-1111111111 - [tag:ManagedBy: "terraform", tag:Name: "VPCRouteTablePrivate", tag:Purpose: "vpc-route-table"] - would remove
Scan complete: 161 total, 83 nukeable, 78 filtered.

The above resources would be deleted with the supplied configuration. Provide --no-dry-run to actually destroy resources.
```

It is important during the dry run that you closely-examine each resource that has been flagged for removal. Here are some common flags you should be paying attention to:

1. `would remove`: these resources will be removed by AWS Nuke on a subsequent run with `--no-dry-run`.
2. `filtered by config`: these are resources that have been skipped as a result of your filtering configurations.
3. `cannot delete *`: marks AWS-managed resources that simply cannot be deleted.
  
If you notice something is marked as `would remove`, but should be kept, add a filter for it to the configuration file. Take an iterative approach until you're satisfied with the scanning results.

Once you have scanned the list and updated any relevant filters, you can execute the nuking process by passing the `--no-dry-run` flag. You will be presented with the same steps as above as well as a final confirmation message similar to the initial dry run scan.

## In Conclusion ...

This is a very destructive process that will permanently remove selected resources. Always make sure you have backups of selected data sources and they are properly-filtered within your configuration file. 

There may also be times when resources just aren't deleted as expected. That's ok as this process isn't 100% perfect. AWS Nuke is still under heavy development and AWS updates APIs around various services constantly. The point isn't for this tool to do 100% of the heavy lifting, but to get you mostly there.

90% complete still means you've successfully avoided 90% of the work. 😊

## 100% Completion Speed-Run

Just stop paying the bill. Seriously. Just stop paying for the account. Cancel the card. Delete those billing alerts and just walk away. If you stop paying, AWS will eventually just tear down your account with everything in it. All of it. The entire account. Credit score be damned!

_obviously, do not do this... Or, go nuts! After all, don't you sometimes wish you could burn it all down and just walk away? j/k_

![burn-koala.gif](https://cdn.hashnode.com/res/hashnode/image/upload/v1664982128441/xnlblxy1F.gif align="center")

Hope you've learned something useful!

Behave! (mostly) 🙉🙈🙊
