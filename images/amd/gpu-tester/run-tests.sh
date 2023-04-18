#!/bin/bash

set -x

# Check the kfd device and its permissions
ls -l /dev/kfd

# Check rocminfo
/opt/rocm/bin/rocminfo

# Prepare the test environment
cd /tests
source gpu-tests/bin/activate

# First test - Alexnet (suggested by AMD upstream)
python3 benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --model=alexnet
