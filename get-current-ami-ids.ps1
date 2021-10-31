$regions = @("us-east-1","us-west-2","us-west-1","eu-west-1","eu-west-2","eu-west-3","eu-central-1","ap-northeast-1","ap-northeast-2","ap-northeast-3","ap-southeast-1","ap-southeast-2","ap-south-1","us-east-2","ca-central-1","sa-east-1")

Write-Host 'Update run-template.json with the following json snippet to set ami-ids'
Write-Host 'to the most current versions.'
Write-Host 'Test before publishing!'
Write-Host ''
Write-Host '        "AWSRegionArch2AMI": {'
for ($i=0; $i -lt $regions.length; $i++){
    $region = $regions[$i]
    Write-Host "            ""$region"": {" 
    $amiid = aws --region $region ec2 describe-images --filters Name=root-device-type,Values=ebs Name=architecture,Values=x86_64 Name=virtualization-type,Values=hvm Name=name,Values=amzn2-ami-hvm-2*gp2 Name=state,Values=available --owners amazon  --query "Images[?!contains(Name, '.rc-')]|sort_by(@, &CreationDate)[-1].[ImageId]" --output text
    Write-Host "                ""HVM64"": ""$amiid"""
    if ($i -eq $regions.length - 1){
        Write-Host "            }"
    } else {
        Write-Host "            },"
    }
}
Write-Host "        },"

# Output Format example:
# "us-east-1": {
#    "HVM64": "ami-0ff8a91507f77f867"
#},
