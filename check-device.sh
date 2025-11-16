#!/bin/bash

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}🔍 Checking Connected Devices...${NC}"
echo ""

# Run flutter devices
DEVICES_OUTPUT=$(flutter devices 2>&1)

# Check if iPhone is connected
if echo "$DEVICES_OUTPUT" | grep -q "Prithvi's iPhone"; then
    if echo "$DEVICES_OUTPUT" | grep -q "(wireless)"; then
        echo -e "${YELLOW}⚠️  Device is connected WIRELESSLY${NC}"
        echo ""
        echo "To switch to wired connection:"
        echo "1. Open Xcode → Window → Devices and Simulators"
        echo "2. Select your iPhone"
        echo "3. Uncheck 'Connect via network'"
        echo "4. Connect USB cable"
        echo ""
    else
        echo -e "${GREEN}✅ Device is connected via USB CABLE${NC}"
        echo ""
        echo "You can now run the app!"
        echo ""
        echo "VS Code: Press F5 after selecting 'BarterBrAIn (Debug - Prithvi's iPhone)'"
        echo "Terminal: flutter run -d 00008150-001C1DCE1102401C"
        echo ""
    fi
    
    # Show device details
    echo -e "${BLUE}Device Details:${NC}"
    echo "$DEVICES_OUTPUT" | grep "Prithvi's iPhone"
    echo ""
else
    echo -e "${RED}❌ Physical iPhone not detected${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "1. Connect your iPhone via USB cable"
    echo "2. Unlock your iPhone"
    echo "3. If prompted, tap 'Trust This Computer'"
    echo "4. Run this script again"
    echo ""
fi

# Show all devices
echo -e "${BLUE}All Connected Devices:${NC}"
echo "$DEVICES_OUTPUT" | grep -E "(mobile|simulator)" | grep -v "Checking"
echo ""

