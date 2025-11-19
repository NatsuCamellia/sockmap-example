#!/bin/bash
PORT=1999
SERVER_IP="127.0.0.1"
TIME=30

function cleanup {
    echo "--- Cleaning up ---"
    sudo pkill sockperf
    sudo pkill loader
}
trap cleanup EXIT

if ! make; then
	echo "Build failed."
	exit 1
fi

echo ""
echo "=================================================="
echo "   PHASE A: BASELINE (TCP/IP Stack) "
echo "=================================================="
sockperf server -p $PORT --tcp --daemonize
sleep 1

echo "Running sockperf..."
BASELINE_OUTPUT=$(sockperf ping-pong -p $PORT --tcp --time $TIME) 
echo "$BASELINE_OUTPUT"
AVG_LATENCY_BASE=$(echo "$BASELINE_OUTPUT" | grep "Latency is" | awk '{print $5}')

sudo pkill sockperf
sleep 1


echo ""
echo "=================================================="
echo "   PHASE B: ACCELERATED (SOCKMAP) "
echo "=================================================="
echo "Starting BPF Loader..."
sudo ./loader $PORT > /dev/null 2>&1 &
sleep 2

echo "Starting sockperf server..."
sockperf server -p $PORT --tcp --daemonize
sleep 1

echo "Running sockperf..."
ACCEL_OUTPUT=$(sockperf ping-pong -p $PORT --tcp --time $TIME) 
echo "$ACCEL_OUTPUT"
AVG_LATENCY_ACCEL=$(echo "$ACCEL_OUTPUT" | grep "Latency is" | awk '{print $5}')

IMPROVEMENT=$(echo "$AVG_LATENCY_BASE - $AVG_LATENCY_ACCEL" | bc)
echo ""
echo "=================================================="
echo "   RESULTS "
echo "=================================================="
echo "Baseline:    $AVG_LATENCY_BASE usec"
echo "Accelerated: $AVG_LATENCY_ACCEL usec"
echo "Reduction:   $IMPROVEMENT usec"
echo "=================================================="
