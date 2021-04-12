# builds openssl and libcurl

automatically clone repos and builds openssl and libcurl (_static_) for different systems.

## android

> tested with Android NDK r21d

~~~bash
./build_android_openssl.sh -a android-arm64 && ./build_android_openssl.sh -a android-arm && \ 
./build_android_curl.sh -a android-arm64 -o ./build/openssl-android-arm64 && \
./build_android_curl.sh -a android-arm -o ./build/openssl-android-arm
~~~

generated includes and libs in ./build/_arch_
