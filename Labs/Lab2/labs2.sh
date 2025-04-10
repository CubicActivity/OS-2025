#!/bin/bash

# Check if a file is provided as an argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <path_to_csv_file>"
    exit 1
fi

CSV_FILE="$1"

# Check if the file exists and is readable
if [ ! -f "$CSV_FILE" ] || [ ! -r "$CSV_FILE" ]; then
    echo "Error: File does not exist or is not readable."
    exit 1
fi

# Read the header (subject names)
IFS=',' read -r -a headers < "$CSV_FILE"

# Ensure the file has at least one student
total_students=$(($(wc -l < "$CSV_FILE") - 1))
if [ "$total_students" -le 0 ]; then
    echo "Error: No student data found in the file."
    exit 1
fi

echo "Exam Scores Analysis"
echo "-------------------"
echo "Total Number of Students: $total_students"
echo ""

# Extract subject names from the header (ignoring first two columns)
subjects=("${headers[@]:2}")

echo "Subject Averages:"

# Compute and print averages for each subject
for ((i = 2; i < ${#headers[@]}; i++)); do
    subject=${headers[$i]}
    
    avg=$(awk -F, -v col="$((i+1))" 'NR > 1 && $col ~ /^[0-9]+$/ {sum+=$col; count++} 
        END {if(count>0) printf "%.2f", sum/count; else print "N/A"}' "$CSV_FILE")

    echo "  $subject: $avg"
done

echo ""
echo "Subject Extreme Performers:"

# Find the highest and lowest scorer for each subject
for ((i = 2; i < ${#headers[@]}; i++)); do
    subject=${headers[$i]}

    awk -F, -v col="$((i+1))" -v subject="$subject" '
    NR > 1 && $col ~ /^[0-9]+$/ {
        if (NR == 2 || $col > max) {
            max = $col
            high_name = $2
        }
        if (NR == 2 || $col < min) {
            min = $col
            low_name = $2
        }
    }
    END {
        if (NR > 1)
            printf "  %s - Highest: %s (Score: %d), Lowest: %s (Score: %d)\n", subject, high_name, max, low_name, min
    }' "$CSV_FILE"
done
