#!/bin/bash
mkdir -p bin && swiftc -o bin/apple-brightness apple-brightness.swift -framework CoreGraphics -F /System/Library/PrivateFrameworks -framework DisplayServices;