#!/bin/bash
sudo apt-get install -y ec2-instance-connect make openssl wget curl gcc build-essential 
curl -o aws-replication-installer-init https://aws-elastic-disaster-recovery-us-west-1.s3.us-west-1.amazonaws.com/latest/linux/aws-replication-installer-init
chmod +x aws-replication-installer-init
sudo ./aws-replication-installer-init --account-id 718147145862 --region us-west-1 --no-prompt
