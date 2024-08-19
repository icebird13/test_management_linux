#!/bin/bash

quiz_directory="saved_quizzes"

# TO CREATE A NEW QUIZ DIRECTORY IF IT DOESN'T EXIST
create_quiz_directory() {
  if [ ! -d "$quiz_directory" ]; then
    mkdir "$quiz_directory"
  fi
}

# Variable to store authentication status
authenticated=false
admin_username=""
admin_password=""
quiz_file=""

# Function to authenticate the administrator
authenticate_administrator() {
  if [ "$authenticated" = true ]; then
    return 0
  fi

  admin_username=$(zenity --entry --title="Authentication" --text="Enter administrator username:")
  [ -z "$admin_username" ] && return 1

  admin_password=$(zenity --password --title="Authentication" --text="Enter administrator password:")
  [ -z "$admin_password" ] && return 1

  # Verify the administrator's credentials
  if grep -q "^$admin_username:$admin_password" "admin_accounts.txt"; then
    authenticated=true
    return 0  # Authentication success
  else
    zenity --error --text="Authentication failed."
    return 1  # Authentication failure
  fi
}

# Function to create a new quiz file
create_new_quiz() {
  # Ask the administrator if they want to create a new quiz only if the quiz file is not set
  if [ -z "$quiz_file" ]; then
    zenity --question --title="Create New Quiz" --text="Do you want to create a new quiz?"

    # Check the user's response
    if [ $? -eq 0 ]; then
      # Prompt the administrator for a new quiz file name
      new_quiz_name=$(zenity --entry --title="New Quiz Name" --text="Enter the name for the new quiz:")
      [ -z "$new_quiz_name" ] && return 1

      # Create the quiz directory if it doesn't exist
      create_quiz_directory

      # Create a new quiz file
      quiz_file="$quiz_directory/$new_quiz_name.txt"
      touch "$quiz_file"
      
      # Check if the administrator created or modified the quiz
      if [ -s "$quiz_file" ]; then
        # Quiz file is not empty, update the quiz details
        echo "# Quiz Details" > "$quiz_file"
        echo "Quiz '$new_quiz_name' Created/Modified on: $(date)" >> "$quiz_file"
        echo >> "$quiz_file"
      else
      zenity --info --text="No questions added to the quiz. The quiz is empty."
      fi
    fi
  fi
}

# Function to add a question to the current quiz with optional hints
add_question() {
  if [ -z "$quiz_file" ]; then
    zenity --info --text="Please create a new quiz first."
    return
  fi

  if ! $authenticated; then
    authenticate_administrator
    [ $? -eq 1 ] && return
  fi

  question=$(zenity --entry --title="Add Question" --text="Enter the question:" --width=500 --height=200)
  [ -z "$question" ] && return

  options_count=$(zenity --entry --title="Options Count" --text="Enter the number of options:")
  [ -z "$options_count" ] && return

  options=""

  for ((i=1; i<=$options_count; i++)); do
    option=$(zenity --entry --title="Add Option $i" --text="Enter option $i:")
    [ -z "$option" ] && return
    options="${options}$option%" #delimiter used to separate the options
  done

  # Remove the trailing '%' from the options so that last option does not have %
  options=${options%"%"}

  hints=$(zenity --entry --title="Add Hints (Optional)" --text="Enter hints for the question (optional):")
  # Check if hints are provided
  if [ -z "$hints" ]; then
    hints="no hints added"
  fi

  IFS='%' read -ra options_array <<< "$options"

  # Display options for correct answer
  correct_option=$(zenity --list --title="Select Correct Answer" --text="Select the correct answer:" --column="Options" "${options_array[@]}" --width=500 --height=200)
  [ -z "$correct_option" ] && return

  question_number=$(( $(wc -l < "$quiz_file") + 1 ))

  # Check if '%' is present in the question
  if [[ $question == *%* ]]; then
    # Separate the question into different options
    IFS='%' read -ra question_array <<< "$question"
    # Add each part of the question along with options count, options, correct answer, and hints
    for part in "${question_array[@]}"; do
      echo "$question_number: $part:$options_count:${options}:${correct_option}:${hints}" >> "$quiz_file"
      question_number=$((question_number + 1))
    done
  else
    # If no '%' in the question, add the question with options count, options, correct answer, and hints
    echo "$question_number: $question:$options_count:${options}:${correct_option}:${hints}" >> "$quiz_file"
  fi

  zenity --info --text="Question added successfully to the current quiz."
}


# Function to display questions and options for the current quiz
display_questions() {
  if [ ! -s "$quiz_file" ]; then
    zenity --info --text="No questions available in the current quiz."
    return
  fi

  if ! $authenticated; then
    authenticate_administrator
    [ $? -eq 1 ] && return
  fi

  questions_list=()
  while IFS=: read -r question_number question options_count options correct_option hints; do
    questions_list+=("$question_number" "$question")
  done < "$quiz_file"

  selected_question=$(zenity --list --title="Display Questions" --column="Question Number" --column="Question" --width=600 --height=300 "${questions_list[@]}")
  [ -z "$selected_question" ] && return

  question_data=$(grep "^$selected_question:" "$quiz_file")
  IFS=':' read -r q_num q_text q_options_count q_options q_correct_option q_hints <<< "$question_data"

  # Display options and hints for the selected question
  formatted_options=$(echo -e "${q_options//%/\\n}")

  # Check if hints are provided
  if [ "$q_hints" != "" ]; then
    formatted_hints=$(echo -e "Hints:\n${q_hints//%/\\n}")
  else
    formatted_hints=""
  fi

  zenity --text-info --title="Question Details" --width=500 --height=400 \
    --filename=<(echo -e "Question $q_num:\n\n$q_text\n\nOptions Count: $q_options_count\nOptions:\n$formatted_options\nCorrect Answer: $q_correct_option\n$formatted_hints")
}


# Function to delete or edit a question from the current quiz
delete_or_edit_question() {
  if [ -z "$quiz_file" ]; then
    zenity --info --text="Please create a new quiz first."
    return
  fi

  if ! $authenticated; then
    authenticate_administrator
    [ $? -eq 1 ] && return
  fi

  questions_list=()
  while IFS=: read -r question_number question options_count options correct_option hints; do
    questions_list+=("$question_number" "$question")
  done < "$quiz_file"

  question_to_modify=$(zenity --list --title="Choose Question to Modify" --column="Question Number" --column="Question" --width=600 --height=300 "${questions_list[@]}")
  [ -z "$question_to_modify" ] && return

  modify_option=$(zenity --list --title="Choose Action" --column="Action" "Edit" "Delete")
  [ -z "$modify_option" ] && return

  if [ "$modify_option" == "Delete" ]; then
    delete_confirmation=$(zenity --entry --title="Confirm Deletion" --text="Do you want to delete Question $question_to_modify? (yes/no)")

    if [ "$delete_confirmation" == "yes" ]; then
      sed -i "/^$question_to_modify:/d" "$quiz_file"
      zenity --info --text="Question $question_to_modify deleted successfully from the current quiz."

      # Renumber the questions
      awk -F':' -v OFS=':' '{if ($1 > question_number) $1 -= 1; print $0}' question_number="$question_to_modify" "$quiz_file" > "temp_file"
      mv "temp_file" "$quiz_file"
    else
      zenity --info --text="Deletion canceled."
   fi
    
  elif [ "$modify_option" == "Edit" ]; then
    question_data=$(grep "^$question_to_modify:" "$quiz_file")
    IFS=':' read -r q_num q_text q_options_count q_options q_correct_option q_hints <<< "$question_data"

    # Edit the question
    new_question_text=$(zenity --entry --title="Edit Question" --text="Enter the new text for Question $question_to_modify:" --entry-text="$q_text" --width=500 --height=200)
    [ -z "$new_question_text" ] && return

    # Edit the options
    new_options_count=$(zenity --entry --title="Edit Options Count" --text="Enter the new number of options:" --entry-text="$q_options_count" --width=500 --height=200)
    [ -z "$new_options_count" ] && return

    new_options=""
    for ((i=1; i<=$new_options_count; i++)); do
      old_option="${options_array[$((i-1))]}"
      new_option=$(zenity --entry --title="Edit Option $i" --text="Enter the new text for option $i:" --entry-text="$old_option" --width=500 --height=200)
      [ -z "$new_option" ] && return
      new_options="${new_options}$new_option%"

      # Ensure the last option doesn't have a trailing %
      if [ $i -eq $new_options_count ]; then
        new_options=${new_options%"%"}
      fi
    done

    IFS='%' read -ra new_options_array <<< "$new_options"

    # Edit the correct option
    new_correct_option=$(zenity --list --title="Edit Correct Answer" --text="Select the new correct answer:" --column="Options" --width=500 --height=200 "${new_options_array[@]}")
    [ -z "$new_correct_option" ] && return

    # Edit the hints
    new_hints=$(zenity --entry --title="Edit Hints" --text="Enter the new hints (optional):" --entry-text="$q_hints")
    # Check if hints are provided
    if [ -z "$new_hints" ]; then
      new_hints=""
    fi

    # Update the question in the quiz file
    sed -i "s/^$question_to_modify:.*/$question_to_modify: $new_question_text:$new_options_count:${new_options%}:$new_correct_option:$new_hints/" "$quiz_file"

    zenity --info --text="Question $question_to_modify edited successfully in the current quiz."
  fi
}

# Function to go to previous quizzes
go_to_previous_quizzes() {
  quiz_list=($(ls "$quiz_directory"/*.txt 2>/dev/null | xargs -n 1 basename))
  selected_quiz=$(zenity --list --title="Select Previous Quiz" --column="Quiz" "${quiz_list[@]}")
  
  if [ -z "$selected_quiz" ]; then
    zenity --info --text="No quiz selected."
    return
  fi

  quiz_file="$quiz_directory/$selected_quiz"
  zenity --info --text="You are now working on the quiz: $selected_quiz"
}

# Main menu
while true; do
  create_new_quiz  # Ask the administrator to create a new quiz each time
  choice=$(zenity --list --title="Test Management System" --column="Options" "Go to Previous Quizzes" "Add Question" "Display Questions" "Delete/Edit Question" "Exit" --width=600 --height=250)


  case $choice in
    "Go to Previous Quizzes") go_to_previous_quizzes ;;
    "Add Question") add_question ;;
    "Display Questions") display_questions ;;
    "Delete/Edit Question") delete_or_edit_question ;;
    "Exit") exit ;;
    *) zenity --error --text="Invalid option." ;;
  esac
done

