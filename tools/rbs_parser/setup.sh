#!/bin/bash

set -eu
SCRIPT_DIR=$(cd $(dirname $0); pwd)
TMP_DIR=`mktemp -d`

pushd $TMP_DIR > /dev/null

git clone https://github.com/Shopify/rbs_parser.git --depth 1 --no-tags

cd rbs_parser
make
mkdir -p $SCRIPT_DIR/bin
cp rbs2rbi* $SCRIPT_DIR/bin/

popd > /dev/null

rm -rf $TMP_DIR

echo "done."
