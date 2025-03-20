#!/bin/bash

# Function to get total CPU usage
get_cpu_usage() {
    echo "--- CPU Usage ---"
    cpu_usage=$(top -bn1 | awk '/Cpu/ {print 100 - $8}')
    printf "Total CPU Usage: %.2f%%\n" "$cpu_usage"
}

# Function to get total memory usage correctly
get_memory_usage() {
    echo "--- Memory Usage ---"
    total_mem=$(awk '/MemTotal/ {print $2 / 1024}' /proc/meminfo)
    free_mem=$(awk '/MemFree/ {print $2 / 1024}' /proc/meminfo)
    buffers=$(awk '/Buffers/ {print $2 / 1024}' /proc/meminfo)
    cached=$(awk '/^Cached/ {print $2 / 1024}' /proc/meminfo)

    # Corrected memory calculation
    available_mem=$(awk -v free="$free_mem" -v buffers="$buffers" -v cached="$cached" 'BEGIN {print free + buffers + cached}')
    used_mem=$(awk -v total="$total_mem" -v available="$available_mem" 'BEGIN {print total - available}')
    percent_used=$(awk -v used="$used_mem" -v total="$total_mem" 'BEGIN {printf "%.2f", (used / total) * 100}')
    
    printf "Total Memory: %.0f MB\n" "$total_mem"
    printf "Used Memory: %.0f MB (%.2f%%)\n" "$used_mem" "$percent_used"
    printf "Available Memory (Free+Cache+Buffers): %.0f MB\n" "$available_mem"
}

# Function to get total disk usage
get_disk_usage() {
    echo "--- Disk Usage ---"
    df -h --output=size,used,avail,pcent / | awk 'NR==2 {printf "Total Disk: %s\nUsed Disk: %s (%s used)\nFree Disk: %s\n", $1, $2, $4, $3}'
}

# Function to get top 5 processes by CPU usage (Full Command)
get_top_cpu_processes() {
    echo "--- Top 5 Processes by CPU Usage ---"
    ps -eo pid,user,%cpu,cmd --sort=-%cpu | head -n 6 | awk 'NR>1 {printf "PID: %-6s User: %-8s CPU: %-5s CMD: %s\n", $1, $2, $3, substr($0, index($0, $4))}'
}

# Function to get top 5 processes by memory usage (Full Command)
get_top_memory_processes() {
    echo "--- Top 5 Processes by Memory Usage ---"
    ps -eo pid,user,%mem,cmd --sort=-%mem | head -n 6 | awk 'NR>1 {printf "PID: %-6s User: %-8s MEM: %-5s CMD: %s\n", $1, $2, $3, substr($0, index($0, $4))}'
}

# Function to get OS information correctly
get_os_info() {
    echo "--- OS Information ---"
    grep "PRETTY_NAME" /etc/os-release | cut -d= -f2 | tr -d '"'
    uname -r
}

# Function to get system uptime and load average in one clean line
get_uptime() {
    echo "--- Uptime and Load Average ---"
    uptime | awk -F'load average:' '{print $1 " | Load Average:" $2}'
}

# Function to get logged-in users with more details
get_logged_in_users() {
    echo "--- Logged in Users ---"
    who --ips
}

# Function to get failed login attempts in the last 24 hours
get_failed_logins() {
    echo "--- Failed Login Attempts (Last 24 Hours) ---"
    if command -v journalctl &>/dev/null; then
        failed_logins=$(journalctl --since "24 hours ago" | grep -c "Failed password")
    else
        failed_logins=$(lastb | awk -v date="$(date --date="yesterday" +"%b %e")" '$0 ~ date {count++} END {print count}')
    fi
    echo "$failed_logins"
}

# Main script execution
get_cpu_usage
get_memory_usage
get_disk_usage
get_top_cpu_processes
get_top_memory_processes
get_os_info
get_uptime
get_logged_in_users
get_failed_logins