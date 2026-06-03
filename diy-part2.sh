#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# Modify default IP
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate
# Modify default theme
#sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
# Modify hostname
#sed -i 's/OpenWrt/P3TERX-Router/g' package/base-files/files/bin/config_generate
###############以下是我的代码###############
# 替换DTS 16M闪存分区，保留USB
cd target/linux/ramips/dts
cat > mt7620a_zte_q7.dts <<-'EOF'
#include "mt7620a.dtsi"
#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>
#include <dt-bindings/leds/common.h>
/ {
	compatible = "zte,q7", "ralink,mt7620a-soc";
	model = "ZTE Q7";
	aliases {
		led-boot = &led_status_blue;
		led-failsafe = &led_status_blue;
		led-running = &led_status_blue;
		led-upgrade = &led_status_blue;
	};
	leds {
		compatible = "gpio-leds";
		statred {
			function = LED_FUNCTION_STATUS;
			color = <LED_COLOR_ID_RED>;
			gpios = <&gpio0 13 GPIO_ACTIVE_LOW>;
		};
		led_status_blue: statblue {
			function = LED_FUNCTION_STATUS;
			color = <LED_COLOR_ID_BLUE>;
			gpios = <&gpio0 9 GPIO_ACTIVE_LOW>;
		};
	};
	keys {
		compatible = "gpio-keys";
		reset {
			label = "reset";
			gpios = <&gpio1 2 GPIO_ACTIVE_LOW>;
			linux,code = <KEY_RESTART>;
		};
	};
};
&gpio1 {
	status = "okay";
};
&spi0 {
	status = "okay";
	flash@0 {
		compatible = "jedec,spi-nor";
		reg = <0>;
		spi-max-frequency = <10000000>;
		partitions {
			compatible = "fixed-partitions";
			#address-cells = <1>;
			#size-cells = <1>;
			partition@0 {
				label = "u-boot";
				reg = <0x0 0x30000>;
				read-only;
			};
			partition@30000 {
				label = "u-boot-env";
				reg = <0x30000 0x10000>;
				read-only;
			};
			partition@40000 {
				label = "factory";
				reg = <0x40000 0x10000>;
				read-only;
				nvmem-layout {
					compatible = "fixed-layout";
					#address-cells = <1>;
					#size-cells = <1>;
					eeprom_factory_0: eeprom@0 {
						reg = <0x0 0x200>;
					};
					macaddr_factory_4: macaddr@4 {
						reg = <0x4 0x6>;
					};
				};
			};
			partition@50000 {
				compatible = "denx,uimage";
				label = "firmware";
				reg = <0x50000 0xfb0000>;
			};
		};
	};
};
&state_default {
	gpio {
		groups = "i2c", "uartf", "rgmii1", "rgmii2", "ephy", "wled";
		function = "gpio";
	};
};
&ethernet {
	nvmem-cells = <&macaddr_factory_4>;
	nvmem-cell-names = "mac-address";
	mediatek,portmap = "wllll";
};
&wmac {
	nvmem-cells = <&eeprom_factory_0>;
	nvmem-cell-names = "eeprom";
};
&sdhci {
	status = "okay";
};
&ehci {
	status = "okay";
};
&ohci {
	status = "okay";
};
EOF
cd -

# 修改mk固件IMAGE_SIZE为15744K(匹配16M闪存)，保留原有USB驱动配置
MK_FILE="target/linux/ramips/image/mt7620.mk"
sed -i '/define Device\/zte_q7/,/endef/ {
    s/IMAGE_SIZE := .*/IMAGE_SIZE := 15744k/
}' "$MK_FILE"
