STEPS=2
OVERRIDE=1
ARCH="x64"
SOURCE_PATH=$(dirname $0)
while getopts 'bdgips:' option
do
	case $option in
		b) STEPS=2 ;;
		d) STEPS=1 ;;
		g) STEPS=3 ;;
		i) STEPS=0 ;;
		p) OVERRIDE=0 ;;
		s) SOURCE_PATH=$OPTARG ;;
	esac
done
shift $((OPTIND-1))
BUILD_PATH=$SOURCE_PATH/build/release/"$ARCH"/Release/mame
INSTALL_PATH="${1:-/Applications}"

# Move to `mame` source tree
if [ ! -d $SOURCE_PATH ]
then
	echo "Source path '$SOURCE_PATH' not found. Please select an existing path and try again."
	exit 1
fi
echo "Moving to '$SOURCE_PATH'…"
cd $SOURCE_PATH

# Pull from git repository
if [ $STEPS -ge 3 ]
then
	echo "Pulling latest from GitHub…"
	if ! git fetch upstream || \
	! git merge upstream/master -m "Updating to latest from official" || \
	! git push
	then
		echo "Error while updating from official MAME repo. Please merge from the official repo manually and try again."
	fi
fi

# Build `mame`
if [ $STEPS -ge 2 ]
then
	echo "Building MAME…"
	if ! make REGENIE=1 TOOLS=1
	then
		echo "MAME source not found as '$SOURCE_PATH'. Please select mame source directory with '-s'."
		exit 1
	fi
fi

# Make release
if [ $STEPS -ge 1 ]
then
	echo "Packaging MAME…"
	if ! make -f dist.mak PTR64=1
	then
		echo "Failed running distribution script. Please check '$SOURCE_PATH/dist.mak' for errors and try again."
		exit 1
	fi
fi

# Move to install location
echo "Copying release build to \"$INSTALL_PATH\"…"
if [ ! -d $INSTALL_PATH ]
then
	echo "Install path not found. Creating path…"
	mkdir -p $INSTALL_PATH
fi
cp -R -p -v $(if [ $OVERRIDE -lt 1 ] ; then echo "-n"; fi) $BUILD_PATH $INSTALL_PATH

echo "MAME installation finished."
