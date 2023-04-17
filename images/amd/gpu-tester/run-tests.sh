#!/bin/bash

cd /tests
source gpu-tests/bin/activate
# First test - Alexnet (suggested by AMD upstream)
python3 benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --model=alexnet
