#!/bin/bash

# Port Usage Killer Tool
# View port usage and optionally kill occupying processes

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Show help
show_help() {
    echo "🔌 Port Usage Killer Tool"
    echo ""
    echo "Usage: $0 [options] [port]"
    echo ""
    echo "Options:"
    echo "  -l, --list       List all listening ports"
    echo "  -c, --common     Show common port usage"
    echo "  -k, --kill PORT  Kill process using specified port"
    echo "  -h, --help       Show help"
    echo ""
    echo "Examples:"
    echo "  $0 3000          Check port 3000 usage"
    echo "  $0 -k 8080       Kill process using port 8080"
    echo "  $0 -l            List all listening ports"
    echo "  $0 -c            Show common dev ports"
    echo ""
}

# Get port usage info
get_port_info() {
    local port=$1
    
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS
        lsof -i ":$port" 2>/dev/null
    else
        # Linux
        lsof -i ":$port" 2>/dev/null || netstat -tlnp 2>/dev/null | grep ":$port"
    fi
}

# Get process details
get_process_details() {
    local pid=$1
    
    echo -e "${CYAN}Process Details:${NC}"
    echo "   PID: $pid"
    
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS
        PROC_NAME=$(ps -p "$pid" -o comm= 2>/dev/null)
        PROC_USER=$(ps -p "$pid" -o user= 2>/dev/null)
        PROC_CMD=$(ps -p "$pid" -o command= 2>/dev/null)
        PROC_START=$(ps -p "$pid" -o lstart= 2>/dev/null)
        PROC_CPU=$(ps -p "$pid" -o %cpu= 2>/dev/null)
        PROC_MEM=$(ps -p "$pid" -o %mem= 2>/dev/null)
    else
        # Linux
        PROC_NAME=$(ps -p "$pid" -o comm= 2>/dev/null)
        PROC_USER=$(ps -p "$pid" -o user= 2>/dev/null)
        PROC_CMD=$(ps -p "$pid" -o cmd= 2>/dev/null)
        PROC_START=$(ps -p "$pid" -o lstart= 2>/dev/null)
        PROC_CPU=$(ps -p "$pid" -o %cpu= 2>/dev/null)
        PROC_MEM=$(ps -p "$pid" -o %mem= 2>/dev/null)
    fi
    
    echo "   Name:    $PROC_NAME"
    echo "   User:    $PROC_USER"
    echo "   CPU:     ${PROC_CPU}%"
    echo "   Memory:  ${PROC_MEM}%"
    echo "   Started: $PROC_START"
    echo "   Command: $PROC_CMD"
}

# Kill process
kill_process() {
    local pid=$1
    local force=$2
    
    if [ "$force" == "force" ]; then
        kill -9 "$pid" 2>/dev/null
    else
        kill "$pid" 2>/dev/null
    fi
    
    return $?
}

# Check single port
check_port() {
    local port=$1
    local auto_kill=$2
    
    echo -e "${BLUE}🔍 Checking port $port${NC}"
    echo ""
    
    # Get usage info
    PORT_INFO=$(get_port_info "$port")
    
    if [ -z "$PORT_INFO" ]; then
        echo -e "${GREEN}✓ Port $port is not in use${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}⚠ Port $port is in use${NC}"
    echo ""
    echo "$PORT_INFO" | head -1
    echo "$PORT_INFO" | tail -n +2
    echo ""
    
    # Get PIDs
    PIDS=$(echo "$PORT_INFO" | tail -n +2 | awk '{print $2}' | sort -u)
    
    for pid in $PIDS; do
        if [ -n "$pid" ] && [ "$pid" != "PID" ]; then
            echo ""
            get_process_details "$pid"
            
            if [ "$auto_kill" == "auto" ]; then
                echo ""
                echo -e "${RED}→ Killing process $pid...${NC}"
                if kill_process "$pid"; then
                    sleep 0.5
                    if ps -p "$pid" &>/dev/null; then
                        echo "   Normal termination failed, trying force kill..."
                        kill_process "$pid" "force"
                    fi
                    echo -e "${GREEN}✓ Process terminated${NC}"
                else
                    echo -e "${RED}✗ Termination failed, may need sudo${NC}"
                fi
            else
                echo ""
                read -p "Kill this process? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    echo -e "${RED}→ Killing process $pid...${NC}"
                    if kill_process "$pid"; then
                        sleep 0.5
                        if ps -p "$pid" &>/dev/null; then
                            read -p "Process still running, force kill? (y/N): " -n 1 -r
                            echo
                            if [[ $REPLY =~ ^[Yy]$ ]]; then
                                kill_process "$pid" "force"
                            fi
                        fi
                        
                        if ! ps -p "$pid" &>/dev/null; then
                            echo -e "${GREEN}✓ Process terminated${NC}"
                        fi
                    else
                        echo -e "${RED}✗ Termination failed${NC}"
                        echo "   Try: sudo kill -9 $pid"
                    fi
                fi
            fi
        fi
    done
}

# List all listening ports
list_all_ports() {
    echo -e "${BLUE}📋 All Listening Ports${NC}"
    echo ""
    
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS
        echo -e "${CYAN}COMMAND          PID   USER   PORT${NC}"
        lsof -iTCP -sTCP:LISTEN -P -n 2>/dev/null | tail -n +2 | \
            awk '{split($9,a,":"); printf "%-16s %-5s %-6s %s\n", $1, $2, $3, a[length(a)]}' | \
            sort -t' ' -k4 -n | uniq
    else
        # Linux
        netstat -tlnp 2>/dev/null || ss -tlnp 2>/dev/null
    fi
}

# Show common ports
show_common_ports() {
    echo -e "${BLUE}🔌 Common Development Ports Check${NC}"
    echo ""
    
    declare -A PORTS
    PORTS=(
        [22]="SSH"
        [80]="HTTP"
        [443]="HTTPS"
        [3000]="React/Node Dev"
        [3306]="MySQL"
        [4200]="Angular Dev"
        [5000]="Flask"
        [5173]="Vite Dev"
        [5432]="PostgreSQL"
        [5500]="Live Server"
        [6379]="Redis"
        [8000]="Django"
        [8080]="Alt HTTP/Tomcat"
        [8888]="Jupyter"
        [9000]="PHP-FPM"
        [27017]="MongoDB"
    )
    
    printf "${CYAN}%-8s %-18s %-10s %s${NC}\n" "Port" "Service" "Status" "Process"
    echo "─────────────────────────────────────────────────"
    
    for port in $(echo "${!PORTS[@]}" | tr ' ' '\n' | sort -n); do
        service="${PORTS[$port]}"
        
        # Check port
        if [[ "$(uname)" == "Darwin" ]]; then
            PROC=$(lsof -i ":$port" -sTCP:LISTEN 2>/dev/null | tail -n +2 | head -1 | awk '{print $1}')
        else
            PROC=$(lsof -i ":$port" 2>/dev/null | tail -n +2 | head -1 | awk '{print $1}')
        fi
        
        if [ -n "$PROC" ]; then
            printf "%-8s %-18s ${YELLOW}%-10s${NC} %s\n" "$port" "$service" "IN USE" "$PROC"
        else
            printf "%-8s %-18s ${GREEN}%-10s${NC}\n" "$port" "$service" "FREE"
        fi
    done
}

# Interactive mode
interactive_mode() {
    echo -e "${BLUE}🔌 Port Usage Killer Tool${NC}"
    echo ""
    echo "Enter port number to check, or:"
    echo "  l - List all listening ports"
    echo "  c - Show common ports"
    echo "  q - Quit"
    echo ""
    
    while true; do
        read -p "Enter port number: " input
        
        case "$input" in
            l|L)
                echo ""
                list_all_ports
                echo ""
                ;;
            c|C)
                echo ""
                show_common_ports
                echo ""
                ;;
            q|Q)
                echo "Bye!"
                exit 0
                ;;
            ''|*[!0-9]*)
                echo "Please enter a valid port number"
                ;;
            *)
                echo ""
                check_port "$input"
                echo ""
                ;;
        esac
    done
}

# Main logic
case "$1" in
    -h|--help)
        show_help
        ;;
    -l|--list)
        list_all_ports
        ;;
    -c|--common)
        show_common_ports
        ;;
    -k|--kill)
        if [ -z "$2" ]; then
            echo "Error: Please specify port number"
            echo "Usage: $0 -k <port>"
            exit 1
        fi
        check_port "$2" "auto"
        ;;
    '')
        interactive_mode
        ;;
    *)
        if [[ "$1" =~ ^[0-9]+$ ]]; then
            check_port "$1"
        else
            echo "Error: Invalid option '$1'"
            show_help
            exit 1
        fi
        ;;
esac
