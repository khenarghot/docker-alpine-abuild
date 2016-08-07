#!/bin/bash
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

set -e

# sudo chown -R builder:abuild /home/builder/package
# sudo chmod -R 0770 /home/builder/package

# Get grup for given GID (awk required)
function get_group() {
    ID=$1
    shift
    
    awk -F: "{ if ( \$3 == $ID ) print \$1 }" /etc/group
}


GROUP=`get_group $RGID`

if [ "x$GROUP" = "x" ]; then
    GROUP=builder
    addgroup  -g $RGID $GROUP
fi
    

adduser -G $GROUP -g "Alpine Package Builder" -s /bin/ash -D \
	-u $RUID -h /home/builder builder

addgroup builder abuild

sudo chown builder:abuild /home/builder

exec sudo -E -u builder "$@"
