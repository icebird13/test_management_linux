#!/bin/bash

# File containing user accounts
accounts_file="user_accounts.txt"
admin_accounts_file="admin_accounts.txt"
quiz_performance_file="quiz_performance_file.csv"  # Updated file extension

# Variable to store authentication status
authenticated=false
username=""
is_admin=false

# Function to authenticate the user or administrator
authenticate() {
  if [ "$authenticated" = true ]; then
    return 0
  fi

  username=$(zenity --entry --title="Authentication" --text="Enter your username:")
  [ -z "$username" ] && return 1

  password=$(zenity --password --title="Authentication" --text="Enter your password:")
  [ -z "$password" ] && return 1

  # Check if the user is an administrator
  if grep -q "^$username:$password" "$admin_accounts_file"; then
    is_admin=true
  fi

  # Check if the user account exists
  if grep -q "^$username:$password" "$accounts_file"; then
    authenticated=true
    return 0  # Authentication success
  else
    zenity --error --text="Authentication failed. User account not found or incorrect password."
    return 1  # Authentication failure
  fi
}

# Function to display available quizzes and let the user select one
select_quiz() {
  quiz_list=($(ls saved_quizzes/*.txt 2>/dev/null | xargs -n 1 basename))

  if [ ${#quiz_list[@]} -eq 0 ]; then
    zenity --info --text="No quizzes available. Please create a quiz using test_make.sh."
    exit 0
  fi

  selected_quiz=$(zenity --list --title="Select Quiz" --column="Quiz" "${quiz_list[@]}")
  [ -z "$selected_quiz" ] && exit 0
}

run_quiz() {
  if ! authenticate; then
    zenity --error --text="Access denied. Exiting."
    exit 1
  fi

  select_quiz

  if grep -q "^$username|$selected_quiz|" "$quiz_history_file"; then
    zenity --info --text="You have already attempted the selected quiz. Exiting."
    exit 0
  fi

  score=0
  total_questions=0
  quiz_date=$(date +"%Y-%m-%d %H:%M:%S")
  time_limit=10

  while IFS=':' read -r question_number question options_count options correct_option hints; do
    IFS='%' read -ra options_array <<< "$options"
    
    # Display the question, options, and hints using Yad
    if [ "$hints" != "no hints added" ]; then
      question_and_options=$(printf "%s\n%s" "$question" "${options_array[*]}")
      hints_array=($hints)  # Convert hints string to array

      # Construct the hints string with different color (blue in this case)
      hints_string="Hints: <span foreground='blue'>"
      for hint in "${hints_array[@]}"; do
        hints_string+=" $hint"
      done
      hints_string+="</span>"

      question_and_options+="\n$hints_string"
    else
      question_and_options=$(printf "%s\n%s" "$question" "${options_array[*]}")
    fi

    user_answer=$(yad --title="Question $question_number" --text="$question_and_options" --list --column="Options" "${options_array[@]}" --height=400 --width=600 --timeout=$time_limit --timeout-indicator=top --separator=":")

    # To check if the user selected an option
    user_answer_status=$?
    if [ "$user_answer_status" -eq 0 ] && [ -n "$user_answer" ]; then
      user_answer=$(echo "$user_answer" | awk -F ':' '{print $1}')

      if [ "$user_answer" == "$correct_option" ]; then
        score=$((score + 1))
      fi
    fi

    total_questions=$((total_questions + 1))
  done < "saved_quizzes/$selected_quiz"
 
  
  # Append the quiz performance data to the CSV file
  if [ ! -e "$quiz_performance_file" ]; then
    echo "Username,Selected Quiz,Quiz Date,Score/Total Questions" > "$quiz_performance_file"
  fi

  echo "$username,$selected_quiz,$quiz_date,$score/$total_questions" >> "$quiz_performance_file"

  zenity --info --title="Quiz Result" --text="You scored $score out of $total_questions!"
}

while true; do
  choice=$(zenity --list --title="Quiz System" --column="Options" "Run Quiz" "Exit")

  case $choice in
    "Run Quiz") run_quiz ;;
    "Exit") exit ;;
    *) zenity --error --text="Invalid option." ;;
  esac
done

