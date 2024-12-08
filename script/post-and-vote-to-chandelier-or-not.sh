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
IMAGE_DIR_CID=$(ipfs add -q -w "$IMAGE_PATH" | tail -n1)
echo "IMAGE_DIR_CID: " $IMAGE_DIR_CID

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

# forge script to post the IMAGE_URI to the chandelier contract
export IMAGE_URI="ipfs://$IMAGE_CID/$IMAGE_NAME"
export VOTE_YES

# TODO: try to fetch the image from some public ipfs gateways

# forge script script/PostAndVote.s.sol:PostAndVoteScript \
#     --broadcast \
#     "$@"

# TODO: make sure the frame server can handle this post

# TODO: create a farcaster post using neynar apis
