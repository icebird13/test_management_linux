#!/bin/bash

USER_ACCOUNTS_FILE="user_accounts.txt"
ADMIN_ACCOUNTS_FILE="admin_accounts.txt"
QUIZ_PERFORMANCE_FILE="quiz_performance_file.csv"

authenticate_user() {
  username=$(zenity --entry --title "Login" --text "Enter administrator's username:")
  [ -z "$username" ] && exit 0

  password=$(zenity --entry --title "Login" --text "Enter administrator's password:" --hide-text)
  [ -z "$password" ] && exit 0

  if grep -q "^$username:$password" "$ADMIN_ACCOUNTS_FILE"; then
    return 0
  else
    zenity --error --text "Authentication failed. Invalid username or password."
    exit 1
  fi
}

generate_chart() {
  local usernames=("$@")
  local n=${#usernames[@]}

  data="\"All Users\" 0 0"  # Initialize total correct and incorrect values

  total_correct=0
  total_incorrect=0

  for ((i = 0; i < n; i++)); do
    username="${usernames[i]}"
    user_data=$(grep -i "^$username," "$QUIZ_PERFORMANCE_FILE" | grep ",$quiz_name," | awk -F',' '{print $4}' | sed 's/\// /')
    
    if [ -n "$user_data" ]; then
      correct=$(echo "$user_data" | awk '{print $1}')
      total=$(echo "$user_data" | awk '{print $2}')
      incorrect=$((total - correct))

      total_correct=$((total_correct + correct))
      total_incorrect=$((total_incorrect + incorrect))
      data+="\n\"$username\" $correct $incorrect"
    fi
  done
	#plotting the incorrect and correct answers on the graph
  gnuplot <<-GNUPLOT_SCRIPT
    set terminal pngcairo enhanced font "arial,10" size 800,400
    set output "quiz_chart.png"
    set title "Quiz Performance"
    set style data histograms
    set style fill pattern border
    set boxwidth 0.5
    set xlabel "Usernames"
    set ylabel "Answers"
    set yrange [0:$total_questions]  
    set xtics rotate by -45

    plot '< echo -e "$data"' using 2:xtic(1) lc rgb "green" title "Correct", \
         '' using 3:xtic(1) lc rgb "red" title "Incorrect"
GNUPLOT_SCRIPT
}

if ! authenticate_user; then
  zenity --error --text="Access denied. Only administrators are allowed to access the quiz review." --title="Access Denied"
  exit 0
fi

while true; do
  quiz_name=$(zenity --entry --title="Review Quiz" --text="Enter the quiz name (e.g., english.txt):")
  [ -z "$quiz_name" ] && exit 0

  quiz_data=$(grep -i ",$quiz_name," "$QUIZ_PERFORMANCE_FILE" | awk -F',' '{print $1, $4}' | sed 's/\// /')

  if [ -z "$quiz_data" ]; then
    zenity --info --text="No quiz performance data found for $quiz_name."
    exit 0
  fi

  usernames=()
  total_questions=0

  while read -r line; do
    username=$(echo "$line" | awk '{print $1}')
    total=$(echo "$line" | awk '{print $3}')
    usernames+=("$username")
    total_questions="$total"
  done <<< "$quiz_data"

  generate_chart "${usernames[@]}"

  xdg-open "quiz_chart.png" &
done

