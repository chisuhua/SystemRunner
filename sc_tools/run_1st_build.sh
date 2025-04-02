export  ICSC_HOME=`pwd`
sed -i -e 's/X86/AArch64/g' icsc/sc_tool/CMakeLists.txt
./icsc/install.sh
