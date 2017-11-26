#!/usr/bin/env bash
TAG=$(git describe --tags) || true

if [ -n "${TAG}" ]; then
 PREFIX="passb_hostapp_${TAG}"

 yarn github-release upload -o passB -r nodeHostApp -t "${TAG}" artifacts/*
fi