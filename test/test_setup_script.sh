#!/bin/bash
################################################################################
# Test script for setup_ubuntu2404_cuda13.sh
################################################################################
# This script validates the setup script without actually running it
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SETUP_SCRIPT="$SCRIPT_DIR/setup_ubuntu2404_cuda13.sh"

echo "Testing setup script: $SETUP_SCRIPT"
echo ""

# Test 1: Check script exists
echo -n "Test 1: Script exists... "
if [ -f "$SETUP_SCRIPT" ]; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
    exit 1
fi

# Test 2: Check script is executable
echo -n "Test 2: Script is executable... "
if [ -x "$SETUP_SCRIPT" ]; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
    exit 1
fi

# Test 3: Check bash syntax
echo -n "Test 3: Bash syntax is valid... "
if bash -n "$SETUP_SCRIPT"; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
    exit 1
fi

# Test 4: Check for required functions
echo -n "Test 4: Required functions exist... "
REQUIRED_FUNCTIONS=(
    "check_privileges"
    "check_ubuntu_version"
    "check_cuda"
    "install_system_dependencies"
    "install_python"
    "install_protoc"
    "install_sglang"
    "verify_installation"
    "create_service"
)

for func in "${REQUIRED_FUNCTIONS[@]}"; do
    if ! grep -q "^${func}()" "$SETUP_SCRIPT"; then
        echo -e "${RED}FAIL${NC} - Missing function: $func"
        exit 1
    fi
done
echo -e "${GREEN}PASS${NC}"

# Test 5: Check for logging functions
echo -n "Test 5: Logging functions exist... "
if grep -q "^log_info()" "$SETUP_SCRIPT" && \
   grep -q "^log_warn()" "$SETUP_SCRIPT" && \
   grep -q "^log_error()" "$SETUP_SCRIPT"; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
    exit 1
fi

# Test 6: Check for error handling (set -e)
echo -n "Test 6: Error handling enabled... "
if grep -q "^set -e" "$SETUP_SCRIPT"; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
    exit 1
fi

# Test 7: Check for CUDA version handling
echo -n "Test 7: CUDA version check exists... "
if grep -q "nvcc --version" "$SETUP_SCRIPT"; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
    exit 1
fi

# Test 8: Check for systemd service creation
echo -n "Test 8: Systemd service creation exists... "
if grep -q "/etc/systemd/system/sglang.service" "$SETUP_SCRIPT"; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
    exit 1
fi

# Test 9: Check for CUDA 13 support
echo -n "Test 9: CUDA 13 configuration exists... "
if grep -q "cu130" "$SETUP_SCRIPT"; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
    exit 1
fi

# Test 10: Check for Python 3.12 installation
echo -n "Test 10: Python 3.12 setup exists... "
if grep -q "python3.12" "$SETUP_SCRIPT"; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
    exit 1
fi

# Test 11: Source functions and test them (non-destructive)
echo -n "Test 11: Functions can be sourced... "
# Extract functions only (not main execution)
grep -A 1000 '^log_info()' "$SETUP_SCRIPT" | grep -B 1000 '^# Main execution' > /tmp/test_functions.sh
if source /tmp/test_functions.sh 2>/dev/null; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
    exit 1
fi

# Test 12: Test logging functions work
echo -n "Test 12: Logging functions work... "
source /tmp/test_functions.sh
OUTPUT=$(log_info "test" 2>&1)
if [[ "$OUTPUT" == *"test"* ]]; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
    exit 1
fi

# Clean up
rm -f /tmp/test_functions.sh

echo ""
echo -e "${GREEN}All tests passed!${NC}"
echo ""
