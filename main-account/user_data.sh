#!/bin/bash
sudo apt-get install -y ec2-instance-connect make openssl wget curl gcc build-essential 
curl -o ./aws-replication-installer-init.py https://aws-elastic-disaster-recovery-us-west-1.s3.us-west-1.amazonaws.com/latest/linux/aws-replication-installer-init.py
python3 aws-replication-installer-init.py --no-prompt --region us-west-1 --account-id