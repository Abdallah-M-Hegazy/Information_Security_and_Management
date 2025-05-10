#!/bin/bash

# Check if log file is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <log_file>"
    exit 1
fi

LOG_FILE=$1

# Verify it's an Apache log file
if ! head -n 1 "$LOG_FILE" | grep -qE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'; then
    echo "Error: This doesn't appear to be an Apache access log file"
    echo "Make sure you're using a file with entries like:"
    echo '192.168.1.1 - - [10/Oct/2023:14:30:01 +0000] "GET /index.html HTTP/1.1" 200 1234'
    exit 1
fi

# Output file
OUTPUT_FILE="complete_log_analysis_$(date +%Y%m%d_%H%M%S).txt"

# Analysis functions
analyze_requests() {
    echo "==============================================" >> "$OUTPUT_FILE"
    echo "1. REQUEST COUNTS" >> "$OUTPUT_FILE"
    echo "==============================================" >> "$OUTPUT_FILE"
    total_requests=$(wc -l < "$LOG_FILE")
    echo "Total requests: $total_requests" >> "$OUTPUT_FILE"
    
    get_requests=$(grep -c '"GET ' "$LOG_FILE")
    post_requests=$(grep -c '"POST ' "$LOG_FILE")
    echo "GET requests: $get_requests" >> "$OUTPUT_FILE"
    echo "POST requests: $post_requests" >> "$OUTPUT_FILE"
}

analyze_ips() {
    echo "==============================================" >> "$OUTPUT_FILE"
    echo "2. UNIQUE IP ADDRESSES" >> "$OUTPUT_FILE"
    echo "==============================================" >> "$OUTPUT_FILE"
    unique_ips=$(awk '{print $1}' "$LOG_FILE" | sort -u | wc -l)
    echo "Total unique IP addresses: $unique_ips" >> "$OUTPUT_FILE"
    
    echo "" >> "$OUTPUT_FILE"
    echo "Requests per IP (GET and POST):" >> "$OUTPUT_FILE"
    awk '{print $1, $6}' "$LOG_FILE" | sed 's/"//g' | sort | uniq -c | sort -nr >> "$OUTPUT_FILE"
}

analyze_failures() {
    echo "==============================================" >> "$OUTPUT_FILE"
    echo "3. FAILURE REQUESTS" >> "$OUTPUT_FILE"
    echo "==============================================" >> "$OUTPUT_FILE"
    failed_requests=$(grep -E 'HTTP/1.[01]" [45][0-9]{2}' "$LOG_FILE" | wc -l)
    echo "Total failed requests (4xx/5xx): $failed_requests" >> "$OUTPUT_FILE"
    
    failure_percentage=$(echo "scale=2; ($failed_requests / $total_requests) * 100" | bc)
    echo "Failure percentage: $failure_percentage%" >> "$OUTPUT_FILE"
    
    echo "" >> "$OUTPUT_FILE"
    echo "Common failure status codes:" >> "$OUTPUT_FILE"
    grep -E 'HTTP/1.[01]" [45][0-9]{2}' "$LOG_FILE" | awk '{print $9}' | sort | uniq -c | sort -nr >> "$OUTPUT_FILE"
}

analyze_top_user() {
    echo "==============================================" >> "$OUTPUT_FILE"
    echo "4. TOP USER" >> "$OUTPUT_FILE"
    echo "==============================================" >> "$OUTPUT_FILE"
    top_ip=$(awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -1 | awk '{print $2}')
    top_count=$(awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -1 | awk '{print $1}')
    echo "Most active IP: $top_ip with $top_count requests" >> "$OUTPUT_FILE"
}

analyze_daily_avg() {
    echo "==============================================" >> "$OUTPUT_FILE"
    echo "5. DAILY REQUEST AVERAGES" >> "$OUTPUT_FILE"
    echo "==============================================" >> "$OUTPUT_FILE"
    total_days=$(awk -F'[:[]' '{print $2}' "$LOG_FILE" | awk '{print $1}' | sort -u | wc -l)
    if [ "$total_days" -gt 0 ]; then
        daily_avg=$(echo "scale=2; $total_requests / $total_days" | bc)
        echo "Average requests per day: $daily_avg" >> "$OUTPUT_FILE"
    else
        echo "Could not calculate daily average (no dates found)" >> "$OUTPUT_FILE"
    fi
}

analyze_failure_days() {
    echo "==============================================" >> "$OUTPUT_FILE"
    echo "6. FAILURE ANALYSIS BY DAY" >> "$OUTPUT_FILE"
    echo "==============================================" >> "$OUTPUT_FILE"
    echo "Days with most failures:" >> "$OUTPUT_FILE"
    grep -E 'HTTP/1.[01]" [45][0-9]{2}' "$LOG_FILE" | awk -F'[:[]' '{print $2}' | awk '{print $1}' | sort | uniq -c | sort -nr >> "$OUTPUT_FILE"
}

analyze_hourly_requests() {
    echo "==============================================" >> "$OUTPUT_FILE"
    echo "7. HOURLY REQUEST PATTERNS" >> "$OUTPUT_FILE"
    echo "==============================================" >> "$OUTPUT_FILE"
    echo "Requests by hour of day:" >> "$OUTPUT_FILE"
    awk -F: '{print $2}' "$LOG_FILE" | sort | uniq -c >> "$OUTPUT_FILE"
}

analyze_status_codes() {
    echo "==============================================" >> "$OUTPUT_FILE"
    echo "8. STATUS CODE BREAKDOWN" >> "$OUTPUT_FILE"
    echo "==============================================" >> "$OUTPUT_FILE"
    echo "Status code frequencies:" >> "$OUTPUT_FILE"
    awk '{print $9}' "$LOG_FILE" | sort | uniq -c | sort -nr >> "$OUTPUT_FILE"
}

analyze_active_users_by_method() {
    echo "==============================================" >> "$OUTPUT_FILE"
    echo "9. MOST ACTIVE USERS BY REQUEST METHOD" >> "$OUTPUT_FILE"
    echo "==============================================" >> "$OUTPUT_FILE"
    echo "Top IPs for GET requests:" >> "$OUTPUT_FILE"
    grep '"GET ' "$LOG_FILE" | awk '{print $1}' | sort | uniq -c | sort -nr | head -5 >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "Top IPs for POST requests:" >> "$OUTPUT_FILE"
    grep '"POST ' "$LOG_FILE" | awk '{print $1}' | sort | uniq -c | sort -nr | head -5 >> "$OUTPUT_FILE"
}

analyze_failure_patterns() {
    echo "==============================================" >> "$OUTPUT_FILE"
    echo "10. FAILURE PATTERNS BY TIME" >> "$OUTPUT_FILE"
    echo "==============================================" >> "$OUTPUT_FILE"
    echo "Failures by hour of day:" >> "$OUTPUT_FILE"
    grep -E 'HTTP/1.[01]" [45][0-9]{2}' "$LOG_FILE" | awk -F: '{print $2}' | sort | uniq -c | sort -nr >> "$OUTPUT_FILE"
    
    echo "" >> "$OUTPUT_FILE"
    echo "Failures by day of week:" >> "$OUTPUT_FILE"
    grep -E 'HTTP/1.[01]" [45][0-9]{2}' "$LOG_FILE" | awk '{print $4}' | cut -d: -f1 | tr -d '[' | sort | uniq -c | sort -nr >> "$OUTPUT_FILE"
}

generate_suggestions() {
    echo "==============================================" >> "$OUTPUT_FILE"
    echo "ANALYSIS SUGGESTIONS" >> "$OUTPUT_FILE"
    echo "==============================================" >> "$OUTPUT_FILE"
    
    # Get top failure day
    top_failure_day=$(grep -E 'HTTP/1.[01]" [45][0-9]{2}' "$LOG_FILE" | awk -F'[:[]' '{print $2}' | awk '{print $1}' | sort | uniq -c | sort -nr | head -1)
    
    # Get top failure hour
    top_failure_hour=$(grep -E 'HTTP/1.[01]" [45][0-9]{2}' "$LOG_FILE" | awk -F: '{print $2}' | sort | uniq -c | sort -nr | head -1)
    
    # Get suspicious IPs (more than 100 requests)
    suspicious_ips=$(awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr | awk '$1 > 100')
    
    echo "1. Failure Reduction Suggestions:" >> "$OUTPUT_FILE"
    echo "   - Pay special attention to $top_failure_day as it had the most failures" >> "$OUTPUT_FILE"
    echo "   - The hour $top_failure_hour had the most failures - consider increasing monitoring during this time" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    echo "2. Security Considerations:" >> "$OUTPUT_FILE"
    if [ -n "$suspicious_ips" ]; then
        echo "   - The following IPs made an unusually high number of requests and should be investigated:" >> "$OUTPUT_FILE"
        echo "$suspicious_ips" | while read -r line; do
            echo "     $line" >> "$OUTPUT_FILE"
        done
    else
        echo "   - No IPs made an unusually high number of requests" >> "$OUTPUT_FILE"
    fi
    echo "" >> "$OUTPUT_FILE"
    
    echo "3. Performance Optimization:" >> "$OUTPUT_FILE"
    echo "   - Consider scaling resources during peak hours identified in the hourly analysis" >> "$OUTPUT_FILE"
    echo "   - Review the most common error codes to identify specific issues that need addressing" >> "$OUTPUT_FILE"
}

# Main analysis
echo "Starting complete analysis of $LOG_FILE..."
echo "Complete Log Analysis Report - $(date)" > "$OUTPUT_FILE"

analyze_requests
analyze_ips
analyze_failures
analyze_top_user
analyze_daily_avg
analyze_failure_days
analyze_hourly_requests
analyze_status_codes
analyze_active_users_by_method
analyze_failure_patterns
generate_suggestions

echo "Analysis complete. Report saved to $OUTPUT_FILE"
