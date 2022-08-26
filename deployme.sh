#!/bin/bash

#supervisorctl stop ScramFile
git pull
swift package update
swift build --configuration release
chown -R vapor:vapor .build
chmod -R 775 .build
#supervisorctl start ScramFile



# swift run Run --port 8081 --env production
