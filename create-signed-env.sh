#!/bin/bash

# Prompt the user for each part of the subject line
# read -p "Enter country code 'US' (C): " country
# read -p "Enter state or province name 'California' (ST): " state
# read -p "Enter locality 'Los Angeles' (L): " locality
# read -p "Enter organization name 'crDroid' (O): " organization
# read -p "Enter organizational unit 'crDroid' (OU): " organizational_unit
# read -p "Enter common name 'crdroid' (CN): " common_name
# read -p "Enter email address 'android@android.com' (emailAddress): " email

country="DE"
state="Bavaria"
locality="Munich"
organization="Mi439"
organizational_unit="Mi439"
common_name="Mi439"
email="Mi439@Mi439.com"

# Construct the subject line
subject="/C=${country}/ST=${state}/L=${locality}/O=${organization}/OU=${organizational_unit}/CN=${common_name}/emailAddress=${email}"

# Print the subject line
echo "Using Subject Line:"
echo "$subject"

# Prompt the user to verify if the subject line is correct
# read -p "Is the subject line correct? (y/n): " confirmation

# Check the user's response
# if [[ $confirmation != "y" && $confirmation != "Y" ]]; then
#     echo "Exiting without changes."
#    exit 1
# fi
# clear

# https://wiki.lineageos.org/signing_builds
rm -rf ~/.android-certs

# Create Key
echo "Press ENTER TWICE to skip password (about 10-15 enter hits total). Cannot use a password for inline signing!"
mkdir ~/.android-certs

# Passwordless certificates

for x in bluetooth cyngn-app media networkstack nfc platform releasekey sdk_sandbox shared testcert testkey verity verifiedboot; do \
    printf "\n\n" | ./development/tools/make_key ~/.android-certs/$x "$subject"; \
done

#for x in bluetooth media networkstack nfc platform releasekey sdk_sandbox shared testkey verifiedboot; do \
#    ./development/tools/make_key ~/.android-certs/$x "$subject" > /dev/null 2>&1 && printf "\n\n" \
#done

cp ./development/tools/make_key ~/.android-certs/
sed -i 's|2048|4096|g' ~/.android-certs/make_key


for apex in com.android.adbd com.android.adservices com.android.adservices.api com.android.appsearch com.android.art com.android.bluetooth com.android.btservices com.android.cellbroadcast com.android.compos com.android.configinfrastructure com.android.connectivity.resources com.android.conscrypt com.android.devicelock com.android.extservices com.android.graphics.pdf com.android.hardware.biometrics.face.virtual com.android.hardware.biometrics.fingerprint.virtual com.android.hardware.boot com.android.hardware.cas com.android.hardware.wifi com.android.healthfitness com.android.hotspot2.osulogin com.android.i18n com.android.ipsec com.android.media com.android.media.swcodec com.android.mediaprovider com.android.nearby.halfsheet com.android.networkstack.tethering com.android.neuralnetworks com.android.ondevicepersonalization com.android.os.statsd com.android.permission com.android.resolv com.android.rkpd com.android.runtime com.android.safetycenter.resources com.android.scheduling com.android.sdkext com.android.support.apexer com.android.telephony com.android.telephonymodules com.android.tethering com.android.tzdata com.android.uwb com.android.uwb.resources com.android.virt com.android.vndk.current com.android.vndk.current.on_vendor com.android.wifi com.android.wifi.dialog com.android.wifi.resources com.google.pixel.camera.hal com.google.pixel.vibrator.hal com.qorvo.uwb; do \
    printf "\n\n" | ~/.android-certs/make_key ~/.android-certs/$apex "$subject"; \
    openssl pkcs8 -in ~/.android-certs/$apex.pk8 -inform DER -nocrypt -out ~/.android-certs/$apex.pem; \
done

## Create vendor for keys
mkdir -p vendor/lineage-priv
mv ~/.android-certs vendor/lineage-priv/keys
echo "PRODUCT_DEFAULT_DEV_CERTIFICATE := vendor/lineage-priv/keys/releasekey" > vendor/lineage-priv/keys/keys.mk
cat <<EOF > vendor/lineage-priv/keys/BUILD.bazel
filegroup(
    name = "android_certificate_directory",
    srcs = glob([
        "*.pk8",
        "*.pem",
    ]),
    visibility = ["//visibility:public"],
)
EOF

echo "Done! Now build as usual. If builds aren't being signed, add '-include vendor/lineage-priv/keys/keys.mk' to your device mk file"
echo "Make copies of your vendor/lineage-priv folder as it contains your keys!"
sleep 3
