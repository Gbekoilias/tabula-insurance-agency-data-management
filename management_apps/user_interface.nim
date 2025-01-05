import nimx, strutils, os

# Define variables for user input and display data
var user_input: string
var display_data: string

# Function to handle user input from the CLI
proc handleCLIInput() =
  echo "Welcome to the User Interface!"
  echo "Please enter some data (type 'exit' to quit):"
  
  while true:
    user_input = readLine(stdin)
    if user_input == "exit":
      echo "Exiting the CLI."
      break
    else:
      display_data = "You entered: " & user_input
      echo display_data

# Function to create a simple GUI using nimx
proc createGUI() =
  let mainWindow = newWindow("User Interface", 400, 300)
  
  # Create a label to display data
  let label = newLabel(mainWindow, "Enter your data:")
  
  # Create an input field for user input
  let inputField = newTextField(mainWindow)
  
  # Create a button to submit the input
  let submitButton = newButton(mainWindow, "Submit")
  
  # Create a label to show output data
  let outputLabel = newLabel(mainWindow, "")
  
  # Define the action when the button is clicked
  submitButton.onClick:
    user_input = inputField.text
    if user_input.len > 0:
      display_data = "You entered: " & user_input
      outputLabel.text = display_data
    else:
      outputLabel.text = "Please enter some data."

  # Arrange components in the window
  mainWindow.add(label)
  mainWindow.add(inputField)
  mainWindow.add(submitButton)
  mainWindow.add(outputLabel)

# Main procedure to run either CLI or GUI based on user choice
proc main() =
  echo "Select interface:"
  echo "1. Command Line Interface (CLI)"
  echo "2. Graphical User Interface (GUI)"
  
  var choice: int
  while true:
    try:
      choice = parseInt(readLine(stdin))
      if choice in {1, 2}:
        break
      else:
        echo "Invalid choice. Please enter 1 or 2."
    except ValueError:
      echo "Invalid input. Please enter a number."

  if choice == 1:
    handleCLIInput()
  else:
    createGUI()
    runApp()

# Run the main procedure
main()
