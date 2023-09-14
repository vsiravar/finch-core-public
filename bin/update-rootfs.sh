#!/bin/bash
set -euxo pipefail

DEPENDENCY_CLOUDFRONT_URL="https://deps.runfinch.com/"
AARCH64_FILENAME_PATTERN="common/aarch64/finch-rootfs-production-arm64-[0-9].*\.tar.gz$"
AMD64_FILENAME_PATTERN="common/x86-64/finch-rootfs-production-amd64-[0-9].*\.tar.gz$"
PLATFORM="common"
AARCH64="aarch64"
X86_64="x86-64"

while getopts d: flag
do
        case "${flag}" in
            d) dependency_bucket=${OPTARG};;
         esac
done

[[ -z "$dependency_bucket" ]] && { echo "Error: Dependency bucket not set"; exit 1; }

aarch64Deps=$(aws s3 ls s3://${dependency_bucket}/${PLATFORM}/${AARCH64}/ --recursive | grep "$AARCH64_FILENAME_PATTERN" | sort | tail -n 1 | awk '{print $4}')

[[ -z "$aarch64Deps" ]] && { echo "Error: aarch64 dependency not found"; exit 1; }

amd64Deps=$(aws s3 ls s3://${dependency_bucket}/${PLATFORM}/${X86_64}/ --recursive | grep "$AMD64_FILENAME_PATTERN" | sort | tail -n 1 | awk '{print $4}')

[[ -z "$amd64Deps" ]] && { echo "Error: x86_64 dependency not found"; exit 1; }

sed -E  -i.bak  's|^([[:blank:]]*FINCH_ROOTFS_URL[[:blank:]]*\?=[[:blank:]]*'${DEPENDENCY_CLOUDFRONT_URL}')('${AARCH64_FILENAME_PATTERN}')|\1'$aarch64Deps'|' Makefile
sed -E  -i.bak  's|^([[:blank:]]*FINCH_ROOTFS_URL[[:blank:]]*\?=[[:blank:]]*'${DEPENDENCY_CLOUDFRONT_URL}')('${AMD64_FILENAME_PATTERN}')|\1'$amd64Deps'|'  Makefile
