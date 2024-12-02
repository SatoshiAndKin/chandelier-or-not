#!/bin/bash
set -eux -o pipefail

# Usage: ./post-to-chandelier-or-not.sh <path-to-image>
if [ -z "$1" ]; then
    echo "Usage: $0 <path-to-image> <vote-yes> <extra args for forge script>"
    exit 1
fi

IMAGE_PATH="$1"

if [ "$2" = "true" ]; then
    VOTE_YES=true
else
    VOTE_YES=false
fi

shift 2


source .env

# `ipfs add` the image and save the hash to a variable
IMAGE_CID=$(ipfs add -q "$IMAGE_PATH")
echo "IMAGE_CID: " $IMAGE_CID

# create a temporary directory to store the json files
TEMP_DIR=$(mktemp -d)

# TODO: trap to clean up the temp directory

cd "$TEMP_DIR"

# copy/link the image to the temp directory. this makes ipfs pins easier
ln "$IMAGE_PATH" .

# TODO: think about these files more? what else should we put in the metadata?
# create a yes.json file:
# TODO: put some sort of "yes"-specific border around the image?
echo "{
    \"name\": \"Chandelier or Not? Yes\",
    \"image\": \"ipfs:\/\/$IMAGE_CID\"
}" > yes.json

# create a no.json file:
# TODO: put some sort of "no"-specific border around the image?
echo "{
    \"name\": \"Chandelier or Not? No\",
    \"image\": \"ipfs:\/\/${IMAGE_CID}\"
}" > no.json

# `ipfs add --pin` the temp directory and save the hash to a variable
# the command gives us a CID for every file, but we only want the root dir
DIR_CID=$(ipfs add --pin -r -q . | tail -n 1)

echo "DIR_CID: " $DIR_CID

MY_MULTIHASH_QUIC="/ip4/157.131.203.141/udp/4003/quic-v1/p2p/12D3KooWDDpCF8n8xGoaZfhkuK81QkKJUGuoqTbLyAJDRzTMux6q"
MY_MULTIHASH_TCP="/ip4/157.131.203.141/tcp/4003/p2p/12D3KooWDDpCF8n8xGoaZfhkuK81QkKJUGuoqTbLyAJDRzTMux6q"

IMAGE_NAME=$(basename "$IMAGE_PATH")

# TODO: include "groupId": "chandelierOrNot"
curl --request POST \
  --url https://api.pinata.cloud/pinning/pinByHash \
  --header "Authorization: Bearer ${PINATA_API_JWT}" \
  --header "Content-Type: application/json" \
  --data '{
    "hashToPin": "'"${DIR_CID}"'",
    "pinataOptions": {
      "hostNodes": [
        "'"${MY_MULTIHASH_QUIC}"'",
        "'"${MY_MULTIHASH_TCP}"'"
      ]
    },
    "pinataMetadata": {
      "name": "Chandelier or Not directory for '"${IMAGE_NAME}"'",
      "keyvalues": {}
    }
  }'

# forge script to post the DIR_CID to the chandelier contract
export IMAGE_DIR_URI="ipfs://$DIR_CID"

# TODO: try to fetch the image from some public ipfs gateways

cd -

forge script script/PostAndVote.s.sol:PostAndVoteScript \
    --broadcast \
    "$@"

# TODO: make sure the frame server can handle this post

# TODO: create a farcaster post using neynar apis
