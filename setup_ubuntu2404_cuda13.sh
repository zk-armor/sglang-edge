#!/bin/bash
################################################################################
# SGLang One-liner Setup Script for Ubuntu 24.04 with CUDA 13
################################################################################
# This script performs all necessary checks, downloads, and configurations
# to set up SGLang on Ubuntu 24.04 with CUDA 13.x
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/zk-armor/sglang-edge/main/setup_ubuntu2404_cuda13.sh | bash
#   or
#   bash setup_ubuntu2404_cuda13.sh
################################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Print banner
print_banner() {
    echo "================================================================================"
    echo "  SGLang Setup Script for Ubuntu 24.04 with CUDA 13"
    echo "================================================================================"
    echo ""
}

# Check if running as root or with sudo
check_privileges() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script requires root privileges. Please run with sudo."
        exit 1
    fi
}

# Check Ubuntu version
check_ubuntu_version() {
    log_info "Checking Ubuntu version..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        log_error "Cannot determine OS version"
        exit 1
    fi
    
    if [[ "$OS" != "Ubuntu" ]]; then
        log_error "This script is designed for Ubuntu. Detected: $OS"
        exit 1
    fi
    
    if [[ "$VER" != "24.04" ]]; then
        log_warn "This script is optimized for Ubuntu 24.04. Detected: $VER"
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        log_info "Ubuntu $VER detected ✓"
    fi
}

# Check CUDA installation
check_cuda() {
    log_info "Checking CUDA installation..."
    
    if command -v nvcc &> /dev/null; then
        CUDA_VERSION=$(nvcc --version | grep "release" | sed 's/.*release //' | sed 's/,.*//')
        log_info "CUDA version $CUDA_VERSION detected"
        
        # Check if CUDA 13.x is installed
        CUDA_MAJOR=$(echo $CUDA_VERSION | cut -d. -f1)
        if [[ "$CUDA_MAJOR" != "13" ]]; then
            log_warn "CUDA 13.x is recommended. Found CUDA $CUDA_VERSION"
            log_info "The script will continue but CUDA 13.x is preferred for optimal compatibility"
        else
            log_info "CUDA 13.x detected ✓"
        fi
        
        # Set CUDA_HOME if not already set
        if [ -z "$CUDA_HOME" ]; then
            export CUDA_HOME=/usr/local/cuda
            echo "export CUDA_HOME=/usr/local/cuda" >> ~/.bashrc
            log_info "CUDA_HOME set to $CUDA_HOME"
        fi
    else
        log_error "CUDA not found. Please install CUDA 13.x first."
        log_info "Visit: https://developer.nvidia.com/cuda-downloads"
        exit 1
    fi
    
    # Check for NVIDIA GPU
    if ! command -v nvidia-smi &> /dev/null; then
        log_error "nvidia-smi not found. Please install NVIDIA drivers."
        exit 1
    fi
    
    log_info "NVIDIA GPU detected:"
    nvidia-smi --query-gpu=name --format=csv,noheader | head -1
}

# Install system dependencies
install_system_dependencies() {
    log_info "Installing system dependencies..."
    
    # Update package lists
    apt-get update -qq
    
    # Install essential build tools
    apt-get install -y -qq \
        build-essential \
        cmake \
        git \
        wget \
        curl \
        software-properties-common \
        pkg-config \
        libssl-dev \
        libnuma-dev \
        unzip \
        gcc \
        g++ \
        perl \
        make
    
    log_info "System dependencies installed ✓"
}

# Install Python 3.12
install_python() {
    log_info "Installing Python 3.12..."
    
    # Add deadsnakes PPA for Python 3.12
    add-apt-repository -y ppa:deadsnakes/ppa > /dev/null 2>&1
    apt-get update -qq
    
    # Install Python 3.12 and dev packages
    apt-get install -y -qq \
        python3.12 \
        python3.12-full \
        python3.12-dev \
        python3.12-venv
    
    # Set Python 3.12 as default
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 2
    update-alternatives --set python3 /usr/bin/python3.12
    
    # Install pip
    if ! command -v pip3 &> /dev/null; then
        wget -q https://bootstrap.pypa.io/get-pip.py
        python3 get-pip.py
        rm get-pip.py
    fi
    
    log_info "Python 3.12 installed ✓"
    python3 --version
}

# Install Protocol Buffers compiler
install_protoc() {
    log_info "Installing Protocol Buffers compiler..."
    
    cd /tmp
    
    # Detect architecture
    ARCH=$(uname -m)
    if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
        PROTOC_ARCH="aarch_64"
    else
        PROTOC_ARCH="x86_64"
    fi
    
    if ! command -v protoc &> /dev/null; then
        PROTOC_ZIP="protoc-32.0-linux-${PROTOC_ARCH}.zip"
        wget -q https://github.com/protocolbuffers/protobuf/releases/download/v32.0/${PROTOC_ZIP}
        unzip -q -o ${PROTOC_ZIP} -d /usr/local
        rm ${PROTOC_ZIP}
        log_info "protoc installed ✓"
    else
        log_info "protoc already installed ✓"
    fi
    
    protoc --version
    cd -
}

# Install SGLang
install_sglang() {
    log_info "Installing SGLang..."
    
    # Upgrade pip
    pip3 install --upgrade pip -q
    
    # Install uv for faster installation
    log_info "Installing uv package manager..."
    pip3 install uv -q
    export UV_SYSTEM_PYTHON=true
    
    # Install SGLang with CUDA 13 dependencies
    log_info "Installing SGLang with CUDA 13.x support (this may take several minutes)..."
    CU_VERSION="cu130"
    
    # Install SGLang
    uv pip install "sglang" \
        --extra-index-url https://download.pytorch.org/whl/${CU_VERSION} \
        --prerelease=allow \
        --index-strategy unsafe-best-match
    
    log_info "SGLang installed ✓"
}

# Verify installation
verify_installation() {
    log_info "Verifying SGLang installation..."
    
    if python3 -c "import sglang" 2>/dev/null; then
        log_info "SGLang import successful ✓"
        SGLANG_VERSION=$(python3 -c "import sglang; print(sglang.__version__)" 2>/dev/null || echo "unknown")
        log_info "SGLang version: $SGLANG_VERSION"
    else
        log_error "SGLang installation verification failed"
        exit 1
    fi
    
    # Check torch and CUDA
    log_info "Verifying PyTorch CUDA support..."
    python3 -c "import torch; print(f'PyTorch version: {torch.__version__}'); print(f'CUDA available: {torch.cuda.is_available()}'); print(f'CUDA version: {torch.version.cuda if torch.cuda.is_available() else \"N/A\"}')"
    
    if python3 -c "import torch; exit(0 if torch.cuda.is_available() else 1)" 2>/dev/null; then
        log_info "PyTorch CUDA support verified ✓"
    else
        log_warn "PyTorch CUDA support not detected. Please check your CUDA installation."
    fi
}

# Create systemd service
create_service() {
    log_info "Creating SGLang systemd service..."
    
    # Create a directory for SGLang
    SGLANG_DIR="/opt/sglang"
    mkdir -p $SGLANG_DIR
    
    # Create a sample systemd service file
    cat > /etc/systemd/system/sglang.service <<EOF
[Unit]
Description=SGLang Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$SGLANG_DIR
Environment="CUDA_HOME=/usr/local/cuda"
Environment="PATH=/usr/local/cuda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ExecStart=/usr/bin/python3 -m sglang.launch_server --model-path meta-llama/Llama-3.1-8B-Instruct --host 0.0.0.0 --port 30000
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd
    systemctl daemon-reload
    
    log_info "SGLang systemd service created ✓"
    log_info "Service file: /etc/systemd/system/sglang.service"
    log_info ""
    log_info "To start the service:"
    log_info "  sudo systemctl start sglang"
    log_info ""
    log_info "To enable on boot:"
    log_info "  sudo systemctl enable sglang"
    log_info ""
    log_info "To check status:"
    log_info "  sudo systemctl status sglang"
}

# Print next steps
print_next_steps() {
    echo ""
    echo "================================================================================"
    log_info "SGLang installation completed successfully!"
    echo "================================================================================"
    echo ""
    log_info "Quick Start Guide:"
    echo ""
    echo "1. Test SGLang from command line:"
    echo "   python3 -m sglang.launch_server --model-path meta-llama/Llama-3.1-8B-Instruct --host 0.0.0.0 --port 30000"
    echo ""
    echo "2. Or use the systemd service:"
    echo "   sudo systemctl start sglang"
    echo "   sudo systemctl enable sglang  # Enable on boot"
    echo ""
    echo "3. Check the server status:"
    echo "   curl http://localhost:30000/health"
    echo ""
    echo "4. Documentation:"
    echo "   https://docs.sglang.ai/"
    echo ""
    echo "5. Example usage:"
    echo "   python3 -m sglang.bench_serving --model meta-llama/Llama-3.1-8B-Instruct"
    echo ""
    log_info "Note: Make sure to set your HuggingFace token for model downloads:"
    echo "   export HF_TOKEN=your_token_here"
    echo ""
    echo "================================================================================"
}

# Main execution
main() {
    print_banner
    check_privileges
    check_ubuntu_version
    check_cuda
    install_system_dependencies
    install_python
    install_protoc
    install_sglang
    verify_installation
    create_service
    print_next_steps
}

# Run main function
main
