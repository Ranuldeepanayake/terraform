aws ec2 describe-internet-gateways --query 'InternetGateways[*].{ID:InternetGatewayId,State:Attachments[0].State,VPC:Attachments[0].VpcId,Tags:Tags}' \
--output table