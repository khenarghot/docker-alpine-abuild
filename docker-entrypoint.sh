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

adduser -G abuild -g "Alpine Package Builder" -s /bin/ash -D \
	-u $RUID -h /home/builder builder

sudo chown builder:abuild /home/builder

if [ "$1" = 'abuilder' ]; then
	# we need to set the permissiosn here because docker mounts volumes as root
	sudo chown -R builder:abuild \
	     /packages

	sudo chmod -R 0770 \
	     /packages

fi

exec sudo -u builder "$@"
