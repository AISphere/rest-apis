#!/bin/bash

#-------------------------------------------------------------
# IBM Confidential
# OCO Source Materials
# (C) Copyright IBM Corp. 2016
# The source code for this program is not published or
# otherwise divested of its trade secrets, irrespective of
# what has been deposited with the U.S. Copyright Office.
#-------------------------------------------------------------

# Build a static Web site to serve the DLaaS Swagger.
# The site can be served locally, or deployed as a CloudFoundry app.

SCRIPTDIR="$(cd $(dirname "$0")/ && pwd)"

# Parse command line arguments
BUILDDIR=${1:-"$SCRIPTDIR"/build} # defaults to "build" if not specified


# Build the site

echo Building Swagger UI in directory: $BUILDDIR
SITEDIR="$BUILDDIR/dlaas-api"
mkdir -p "$BUILDDIR"
rm -rf "$SITEDIR"

id=$(docker create schickling/swagger-ui) # Get Swagger-ui files from container.
docker cp $id:/app/ "$SITEDIR"/
docker rm $id > /dev/null

cp -a "$SCRIPTDIR/manifest.yml" "$SITEDIR/"
cp -a "$SCRIPTDIR/../swagger/swagger.yml" "$SITEDIR/"
cat "$SITEDIR/index.html" |sed 's|http://petstore.swagger.io/v2/swagger.json|./swagger.yml|' > "$SITEDIR/index.html.$$"
mv "$SITEDIR/index.html.$$" "$SITEDIR/index.html"

# # Copy sample models
 for model in torch-mnist-model tf-model caffe-mnist-model caffe-inc-model keras-model mxnet-model; do
 	cp -a "$SCRIPTDIR/../../tests/testdata/$model" "$BUILDDIR/"
 	(cd "$BUILDDIR/$model" && zip -r ../$model.zip .)
 	cp -a "$BUILDDIR/$model.zip" "$SITEDIR/"
 done

# Print instructions

echo "To serve the site locally: (cd \"$SITEDIR\" && python -m SimpleHTTPServer)"

echo "To deploy as a Bluemix app: (cd \"$SITEDIR\" && cf api https://api.stage1.ng.bluemix.net && cf target -o dlaas -s dev && cf push)"
