LOCAL_PATH := $(call my-dir)


include $(CLEAR_VARS)
#LOCAL_MODULE := crypto-prebuilt
#LOCAL_SRC_FILES := libcrypto.a
#include $(PREBUILT_STATIC_LIBRARY)

LOCAL_MODULE    := tftpc
LOCAL_C_INCLUDES := $(LOCAL_PATH)/libzip/
LOCAL_STATIC_LIBRARIES := zip 
#PREBUILT_SHARED_LIBRARIES := crypto

LOCAL_CFLAGS := -DANDROID_NDK -Wno-psabi
LOCAL_SRC_FILES := tftpc.c

LOCAL_LDLIBS := -ldl -llog -lz

include $(BUILD_SHARED_LIBRARY)




