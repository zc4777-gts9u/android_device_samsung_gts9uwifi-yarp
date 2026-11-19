$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)
$(call inherit-product, vendor/twrp/config/common.mk)

PRODUCT_NAME := twrp_gts9uwifi
PRODUCT_DEVICE := gts9uwifi
PRODUCT_RELEASE_NAME := gts9uwifi
PRODUCT_BRAND := Samsung
PRODUCT_MODEL := Galaxy Tab S9 Ultra
PRODUCT_MANUFACTURER := Samsung
PRODUCT_SHIPPING_API_LEVEL := 33
PRODUCT_TARGET_VNDK_VERSION := 33
PRODUCT_USE_DYNAMIC_PARTITIONS := true

PRODUCT_SYSTEM_PROPERTIES += \
    ro.hardware.gatekeeper=mdfpp \
    ro.twrp.touch.rotation=270 \
    ro.twrp.mtp.use_ffs=true \
    ro.product.first_api_level=33 \
    ro.crypto.dm_default_key.options_format.version=2 \
    ro.crypto.metadata_init_delete_all_keys.enabled=false
