NOTE: THIS PROJECT IS PERFORMED ONLY ON THE SAME COMPUTER. IF ONE CAN GET IT TO WORK ON A SERVER THAT WOULD BE APPRECIATED.

ORDER -> create_accounts.sh -> test_make.sh -> test_run.sh -> review_quiz.sh

This project is a Test Management System implemented using a Bash script with zenity (using YAD and GNU_plot) for creating graphical user interfaces (GUIs). It allows an administrator to create, manage, and interact with quizzes, enabling various functionalities such as:

    Creating New Quizzes:
        Administrators can create and name new quizzes, which are saved in a designated directory (saved_quizzes).
        The quizzes are stored as text files, with each quiz having a unique name.

    Adding Questions:
        The script allows the addition of multiple-choice questions to a quiz.
        Each question is stored in the format: question_number: question: options_count: option1%option2%...: correct_answer.
        Administrators can specify the question, the number of options, the correct answer, and hints (if given) using input dialogs.

    Displaying Questions:
        Administrators can view the list of questions in a quiz.
        The system displays the question along with its associated options, the correct answer, and the hints if given.

    Editing and Deleting Questions:
        The script provides the ability to either delete or edit existing questions in a quiz.
        Questions can be modified in terms of their text, options, hints and correct answer.

    Managing Previous Quizzes:
        Administrators can select and manage previously created quizzes from a list of saved quizzes.

    Authentication:
        The system includes an authentication mechanism that requires administrators to enter a username and password before accessing quiz management functionalities. Credentials are verified against an admin_accounts.txt file.

    Timer:
        A working visible timer of 10 seconds is displayed. When the timer ends without answering, it will give zero and move on to the next.

    Graph:
        The scores of the users are marked in a user-friendly way in a plotted graph using GNU.

WORKING:
1. create_accounts.sh is used by the administrator to set their credentials as well as the users which will be taking the quiz. run it in the terminal as ./create_accounts.sh after compiling it with chmod +x create_accounts.sh 
2. user_accounts.txt and admin_accounts.txt will be created which will store the usernames and passwords respectively.
3. next, compile the test_make.sh and run it
4. enter the administrator credentials, it will ask if you want to create a new quiz, if not it will go back to the previous working quiz
5. add, display edit or delete questions (of the current quiz) or go to the previous quiz and do the same options to it, then exit.
6. next compile test_run.sh and run it
7. enter the username and password from the user_accounts.txt file and select one from the multiple quizzes
8. if you have already attempted that particular quiz, it will exit
9. run the quiz, it will display the options and the hints with the timer of 10 sec. when the timer's up it will move on to the next question and give zero on the previous.
10. review_quiz.sh file will generate a bar graph in png format with the correct and incorrect scores of one of more usernames on a particular quiz.
