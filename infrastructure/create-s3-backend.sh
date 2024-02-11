#! /usr/bin/bash

read -p "Enter the name of the s3 bucket: " BUCKET_NAME

aws s3api create-bucket --bucket $BUCKET_NAME --create-bucket-configuration LocationConstraint=eu-central-1

echo "Bucket $BUCKET_NAME created successfully!"
