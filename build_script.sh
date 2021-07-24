#! /bin/sh
set -e o pipefail
cd ~/
git clone --progress -j 32 --depth 1 --single-branch https://github.com/54b1d/kernel_xiaomi_rosy -b eleven-sabid kernel
cd kernel

KERNEL_DIR=$PWD
KERNEL_NAME="Tortiose_4.9"
TG_BOT_TOKEN='1751232733:AAEhNCOm0YJQvwjB9lcuq4lhVtdJnkzjk0A'
CHATID='-1001201173541'
PREFIX=`date +"%Y%m%d"`

exports() {
	export KBUILD_BUILD_USER="54b1d"
	export KBUILD_BUILD_HOST="Github"
	export ARCH=arm64
	export SUBARCH=arm64
	export CROSS_COMPILE=$KERNEL_DIR/gcc-arm64/bin/aarch64-elf-
	export BOT_MSG_URL="https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage"
	export BOT_BUILD_URL="https://api.telegram.org/bot$TG_BOT_TOKEN/sendDocument"
	export PROCS=$(nproc --all)
	DEFCONFIG=rosy_sabid_defconfig
}

clone() {
	echo " "
	echo "★★Cloning GCC Toolchain from GitHub .."
	git clone --progress -j 32 --depth 1 --single-branch https://github.com/mvaisakh/gcc-arm64/ -b gcc-master

	echo "★★GCC cloning done"
	echo ""
	git clone --depth 1 --single-branch https://github.com/54b1d/AnyKernel3 anykernel
	echo "★★Cloning Kinda Done..!!!"
}

tg_post_msg() {
	curl -s -X POST "$BOT_MSG_URL" -d chat_id="$2" \
	-d "disable_web_page_preview=true" \
	-d "parse_mode=html" \
	-d text="$1"

}

tg_post_build() {
	curl --progress-bar -F document=@"$1" $BOT_BUILD_URL \
	-F chat_id="$2"  \
	-F "disable_web_page_preview=true" \
	-F "parse_mode=html" \
	-F caption="$3"  
}

build_kernel() {
	make O=out $DEFCONFIG
	BUILD_START=$(date +"%s")
	tg_post_msg "<b>NEW CI $KERNEL_NAME-rosy Build Triggered</b>%0A<b>Date : </b><code>$(TZ=Asia/Dhaka date)</code>%0A<b>Device : </b><code>rosy</code>%0A<b>Pipeline Host : </b><code>Github Actions</code>%0A<b>Host Core Count : </b><code>$PROCS</code>%0A<b>Compiler Used : </b><code>$KBUILD_COMPILER_STRING</code>" "$CHATID"
	make -j$PROCS O=out \
		CROSS_COMPILE=$CROSS_COMPILE \
	BUILD_END=$(date +"%s")
	DIFF=$((BUILD_END - BUILD_START))
	check_img
}
check_img() {
	if [ -f $KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb ] 
	    then
		gen_zip
	else
		tg_post_build "error.log" "$CHATID" "<b>Build failed to compile after $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds</b>"
	fi
}
gen_zip() {
 	mv $KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb anykernel/Image.gz-dtb
	cd $KERNEL_DIR/anykernel
	zip -r9 $KERNEL_NAME-rosy-$PREFIX.zip * -x .git README.md
	MD5CHECK=$(md5sum $KERNEL_NAME-rosy-$PREFIX.zip | cut -d' ' -f1)
	tg_post_build $KERNEL_NAME-rosy-$PREFIX.zip "$CHATID" "Build took : $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s) | MD5 Checksum : <code>$MD5CHECK</code>"
	cd ..
}
exports
clone
build_kernel
