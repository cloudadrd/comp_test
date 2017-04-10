#!/usr/bin/env bash

rm -rf /data/competitor/*
mkdir /data/competitor/
/usr/local/bin/aws s3 sync s3://emr-gift-sin-bj/daily_competitor_user_id/sync/ /data/competitor/ --exclude *$