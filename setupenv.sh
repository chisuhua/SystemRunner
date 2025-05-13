PROJECT_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") >/dev/null && pwd)
source sc_tools/setenv.sh
source venv/bin/activate
export LD_LIBRARY_PATH=$PROJECT_DIR/venv/lib:$LD_LIBRARY_PATH
