#!/bin/bash
swift build -c release
cp .build/release/WindowNemo ./WindowNemo
echo "Build completed. Run ./WindowNemo to start the application."