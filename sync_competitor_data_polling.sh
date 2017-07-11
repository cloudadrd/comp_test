#!/usr/bin/env bash

out_dir=/data/competitor
tmp_dir=/data/competitor_tmp
s3_path=s3://emr-gift-sin-bj/daily_competitor_user_id/sync/

rm -rf ${tmp_dir}
mkdir ${tmp_dir}
/usr/local/bin/aws s3 sync ${s3_path} ${tmp_dir} --exclude _*
mv -f ${tmp_dir}/* ${out_dir}