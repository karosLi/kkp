#!/bin/zsh

#manual compile set path
PROJECT_DIR="../"

###stdlib
# Compiles the kkp stdlib into one file
./lua "$PROJECT_DIR/build-scripts/luac.lua" kkp kkp.dat "$PROJECT_DIR/stdlib/" "$PROJECT_DIR/stdlib/init.lua" -L "$PROJECT_DIR/stdlib"/**/*.lua

### 把字节码转成字节数组，方便放入代码里
luaByte=$(hexdump -v -e '1/1 "%d,"' kkp.dat)
# Dumps the compiled file into a byte array, then it places this into the source code
# cat > "$PROJECT_DIR/kkp_stdlib64.h" <<EOF
# // DO NOT MODIFY
# // This is auto generated, it contains a compiled version of the kkp stdlib
# #define KKP_STDLIB {$lua64Byte}
# EOF

# clean up
rm kkp.dat

var=`date "+%Y-%m-%d %H:%M:%S"`
# // ${var}

# cat > "$PROJECT_DIR/kkp_stdlib.h" <<EOF
# // DO NOT MODIFY
# // ${var}
# // This is auto generated, it contains a compiled version of the kkp stdlib
# #if __LP64__ || (TARGET_OS_EMBEDDED && !TARGET_OS_IPHONE) || TARGET_OS_WIN32 || NS_BUILD_32_LIKE_64
# #warning @"64 bit arm"
# #define KKP_STDLIB {$luaByte}
# #endif
# EOF

### 把内容写入到 目标文件，目前已经决定不支持 iPhone5s 之前的机型了，所以可以去掉宏判断了
cat > "$PROJECT_DIR/kkp_stdlib.h" <<EOF
// DO NOT MODIFY
// This is auto generated, it contains a compiled version of the kkp stdlib
#define KKP_STDLIB {$luaByte}
EOF


