# SGLang Quick Start Guide - Ubuntu 24.04 with CUDA 13

This guide helps you get started with SGLang after running the setup script.

## Installation

Run the one-liner setup script:

```bash
curl -fsSL https://raw.githubusercontent.com/zk-armor/sglang-edge/main/setup_ubuntu2404_cuda13.sh | sudo bash
```

## Using SGLang

### 1. Set your HuggingFace Token

Before using SGLang, set your HuggingFace token to download models:

```bash
export HF_TOKEN=your_huggingface_token_here
```

To make it permanent, add it to your `~/.bashrc`:

```bash
echo 'export HF_TOKEN=your_huggingface_token_here' >> ~/.bashrc
source ~/.bashrc
```

### 2. Start SGLang Server

#### Option A: Using systemd service (recommended for production)

```bash
# Start the service
sudo systemctl start sglang

# Check status
sudo systemctl status sglang

# View logs
sudo journalctl -u sglang -f

# Enable on boot
sudo systemctl enable sglang

# Stop the service
sudo systemctl stop sglang
```

#### Option B: Run directly from command line

```bash
python3 -m sglang.launch_server \
  --model-path meta-llama/Llama-3.1-8B-Instruct \
  --host 0.0.0.0 \
  --port 30000
```

### 3. Test the Server

Check if the server is running:

```bash
curl http://localhost:30000/health
```

### 4. Send Requests

#### Using curl:

```bash
curl http://localhost:30000/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "meta-llama/Llama-3.1-8B-Instruct",
    "prompt": "What is the capital of France?",
    "max_tokens": 100
  }'
```

#### Using Python:

```python
import openai

client = openai.Client(
    base_url="http://localhost:30000/v1",
    api_key="EMPTY"
)

response = client.completions.create(
    model="meta-llama/Llama-3.1-8B-Instruct",
    prompt="What is the capital of France?",
    max_tokens=100
)

print(response.choices[0].text)
```

### 5. Advanced Configuration

#### Custom model:

Edit `/etc/systemd/system/sglang.service` and change the `ExecStart` line:

```bash
sudo nano /etc/systemd/system/sglang.service
```

Change:
```
ExecStart=/usr/bin/python3 -m sglang.launch_server --model-path YOUR_MODEL_PATH --host 0.0.0.0 --port 30000
```

Then reload and restart:
```bash
sudo systemctl daemon-reload
sudo systemctl restart sglang
```

#### Other options:

```bash
python3 -m sglang.launch_server \
  --model-path meta-llama/Llama-3.1-8B-Instruct \
  --host 0.0.0.0 \
  --port 30000 \
  --tp 2 \                    # Tensor parallelism (for multi-GPU)
  --mem-fraction-static 0.8   # GPU memory fraction
```

## Troubleshooting

### Check CUDA installation:

```bash
nvcc --version
nvidia-smi
```

### Check Python and SGLang:

```bash
python3 --version
python3 -c "import sglang; print(sglang.__version__)"
python3 -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')"
```

### View service logs:

```bash
sudo journalctl -u sglang -n 100 --no-pager
```

### Restart service:

```bash
sudo systemctl restart sglang
```

## Documentation

- Official Documentation: https://docs.sglang.ai/
- GitHub Repository: https://github.com/sgl-project/sglang
- Examples: https://github.com/sgl-project/sglang/tree/main/examples

## Support

- Slack: https://slack.sglang.ai/
- Issues: https://github.com/sgl-project/sglang/issues
