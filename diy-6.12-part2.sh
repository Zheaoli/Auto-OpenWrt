#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

########### 修改默认 IP ###########
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate
sed -i 's/192.168.1.1/192.168.40.1/g' package/base-files/files/bin/config_generate

########### 设置密码为空（可选） ###########
# sed -i 's@.*CYXluq4wUazHjmCDBCqXF*@#&@g' package/lean/default-settings/files/zzz-default-settings

########### 更改大雕源码（可选）###########
sed -i 's/KERNEL_PATCHVER:=6.12/KERNEL_PATCHVER:=6.18/g' target/linux/x86/Makefile

########### 更改默认主题（可选）###########
# 拉取 argon 原作者的源码
git clone https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
# 替换默认主题为 luci-theme-argon
sed -i 's/luci-theme-bootstrap/luci-theme-argon/' feeds/luci/collections/luci/Makefile
# make menuconfig时记得勾选LuCI ---> Applications ---> luci-app-argon-config


mkdir package/luci-app-openclash
cd package/luci-app-openclash
git init
git remote add -f origin https://github.com/vernesong/OpenClash.git
git config core.sparsecheckout true
echo "luci-app-openclash" >> .git/info/sparse-checkout
git pull --depth 1 origin master
git branch --set-upstream-to=origin/master master

# 编译 po2lmo (如果有po2lmo可跳过)
pushd luci-app-openclash/tools/po2lmo
make && sudo make install
popd

# Add luci-app-adguardhome
cd ~/actions-runner/_work/Auto-OpenWrt/Auto-OpenWrt/openwrt
git clone https://github.com/rufengsuixing/luci-app-adguardhome package/luci-app-adguardhome

# Workaround: savannah cgit returns 400 for gnulib snapshot
# Patch gnulib to use git clone (like immortalwrt) instead of tarball download
cat > tools/gnulib/Makefile << 'GNULIB_EOF'
include $(TOPDIR)/rules.mk

PKG_NAME:=gnulib
PKG_CPE_ID:=cpe:/a:gnu:$(PKG_NAME)

PKG_SOURCE_URL=git://git.git.savannah.gnu.org/$(PKG_NAME).git
PKG_SOURCE_DATE:=2025-07-01
PKG_SOURCE_VERSION:=a3151d456d6919c9066b54dc6f680452168165cf# # stable-202501
PKG_MIRROR_HASH:=b695d96e915ecd6c4551436f417cb2c0879aef4ef6318721c8d5cc86cb44ba9d

include $(INCLUDE_DIR)/host-build.mk

define Host/Configure
endef

define Host/Install
	$(call Host/Uninstall)
	$(INSTALL_DIR) $(1)/share/aclocal
	for m4 in $(HOST_BUILD_DIR)/m4/*.m4; do \
		$(INSTALL_DATA) $(HOST_BUILD_DIR)/m4/$$$$(basename $$$$m4) \
				$(1)/share/aclocal/gl_$$$$(basename $$$$m4); \
	done
	$(CP) $(HOST_BUILD_DIR)/ $(1)/share/gnulib/
	ln -sf ../share/gnulib/gnulib-tool $(STAGING_DIR_HOST)/bin/gnulib-tool
endef

define Host/Uninstall
	rm -rf $(STAGING_DIR_HOST)/bin/gnulib-tool $(STAGING_DIR_HOST)/share/gnulib
endef

$(eval $(call HostBuild))
GNULIB_EOF

# Modify default banner
rm -rf package/base-files/files/etc/banner
cp -f ~/actions-runner/_work/Auto-OpenWrt/Auto-OpenWrt/banner package/base-files/files/etc/banner


