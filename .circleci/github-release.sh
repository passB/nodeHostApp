#!/usr/bin/env bash
TAG="$(git tag -l --points-at HEAD)"

if [ -n "${TAG}" ]; then
 PREFIX="passb_hostapp_${TAG}"

 yarn github-release upload -o passB -r nodeHostApp -t "${TAG}" artifacts/*
fi