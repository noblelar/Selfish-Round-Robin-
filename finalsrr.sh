#!/bin/bash

# Author: Nobleman
# Title: Selfish Round Robin

echo -e "\n"
echo -e "Setting parameters for SRR Algorithm \n"

# Array to store positional parameters
params=("$@")

# ! Check if the number of positional parameters is less than 3 or if the first parameter is not a file
while [ "${#params[@]}" -lt 3 ] || [ ! -f "${params[0]}" ]; do
   echo "Please provide at least three positional parameters, with the first parameter as a file: Format{DATA_FILE_NAME NEW_Q_INC ACCEPTED_Q_INC QUANTA(optional)}"
   read -a new_params
   params=("${new_params[@]}") # Update the array with provided values from positional parameters stating from $1
done

# ! Check if the remaining parameters  apart from the file name are integers
for ((i = 1; i < ${#params[@]}; i++)); do
   if ! [[ "${params[i]}" =~ ^[0-9]+$ ]]; then
      echo "Invalid parameter: ${params[i]}. It should be an integer."
      exit 1
   fi
done

# ! Store positional parameters in various variable names
data_file="${params[0]}"
new_queue_inc="${params[1]}"
accepted_queue_inc="${params[2]}"
quanta="${params[3]}"

# ! Check if the quanta is passed as part of the positional parameters and if not assign a default value of 1;
if [ -z "$quanta" ]; then
   quanta=1
fi

# print out all the positional parameters passed so far
echo "Data file Name: $data_file"
echo "New queue increment value: $new_queue_inc"
echo "Accepted queue increment value: $accepted_queue_inc"
echo -e "Quanta: $quanta \n"

echo "Number of positional parameters provided: ${#params[@]}"

# ! Declare and Assign values to the states elements
state_initial="_"
state_waiting="W"
state_running="R"
state_complete="F"

# ! Declaration of a Quanta Check Variable
quantaCheck=0

# ! Creation of processes arrays. That is, processes newQueue and acceptedQueue

declare -a processes
declare -a newQueue
declare -a acceptedQueue

declare -a completedProcesses

declare -a processStates

# ! Populating the processes array Reading the text file line by line
while read -r line; do
   if [[ -n "$line" ]]; then
      modifications=0
      modified_line=$(echo "$line" | sed 's/$/ /')
      processes+=("$state_initial $modifications $modified_line")
   fi
done <"$data_file"

# ! Assign the processes to the to a new array list for comparison and populate the process names to an array of processStates for display
processList=("${processes[@]}")
stages="ST"
for ((i = 0; i < ${#processList[@]}; i++)); do
   read -a plistItem <<<"${processList[$i]}"
   plitem="  ${plistItem[2]}"
   stages+="$plitem"
done
processStates+=("$stages")

# ! Initializing the time counter
timeCounter=0

# ! Starting the Selfish round robin Algorithm Loop
# ? Checks if all processes have been completely executed
while ((${#processList[@]} != ${#completedProcesses[@]})); do

   # ! Checks the and update the process queue accordingly that is accepted and new queues
   acceptlenght="${#acceptedQueue[@]}"
   if [ "$acceptlenght" == 0 ]; then
      for ((i = 0; i < ${#processes[@]}; i++)); do
         read -a eachprocess <<<"${processes[$i]}"
         parrivaltime="${eachprocess[4]}"

         numpat=$((parrivaltime))

         if [ "$numpat" == "$timeCounter" ]; then

            acceptlenght="${#acceptedQueue[@]}"
            if [ "$acceptlenght" == 0 ]; then
               eachprocess[0]="$state_running"
            else
               eachprocess[0]="$state_waiting"
            fi
            processPriority="${eachprocess[1]}"
            incVal=$((processPriority + accepted_queue_inc))
            eachprocess[1]="$incVal"
            stringedprocess="${eachprocess[*]}"
            acceptedQueue+=("$stringedprocess")

            unset processes[i]

         fi
      done

   else
      for ((i = 0; i < ${#processes[@]}; i++)); do
         read -a eachprocess <<<"${processes[$i]}"

         parrivaltime="${eachprocess[4]}"
         numpat=$((parrivaltime))

         if [ "$numpat" == "$timeCounter" ]; then
            eachprocess[0]="$state_waiting"
            stringedprocess="${eachprocess[*]}"
            newQueue+=("$stringedprocess")

            unset processes[i]

         fi
      done
   fi
   # * Re-order the process array after an element is selected and removed
   processes=("${processes[@]}")

   # ! Priority increament loop for AccceptedQueue NB: Accepted Queue Increment value is recieved from the positional parameter
   if ((timeCounter > 0)); then
      for ((i = 0; i < ${#acceptedQueue[@]}; i++)); do
         read -a arr <<<"${acceptedQueue[$i]}"
         processPriority="${arr[1]}"
         incVal=$((processPriority + accepted_queue_inc))
         arr[1]="$incVal"
         accstringed="${arr[*]}"

         acceptedQueue[i]="$accstringed"

      done
   fi

   # ! Priority increament loop for NewQueue NB: New Queue Increment value is recieved from the positional parameter
   if ((timeCounter > 0)); then
      for ((i = 0; i < ${#newQueue[@]}; i++)); do
         read -a arr <<<"${newQueue[$i]}"
         processPriority="${arr[1]}"
         incVal=$((processPriority + new_queue_inc))
         arr[1]="$incVal"
         accstringed="${arr[*]}"

         newQueue[i]="$accstringed"

      done
   fi

   # ! Compares NewQueue priority to AcceptedQueue priority and move new queue items to accepted queue
   if ((timeCounter > 1)); then
      for ((i = 0; i < ${#newQueue[@]}; i++)); do
         read -a newarr <<<"${newQueue[$i]}"
         read -a firstaccarr <<<"${acceptedQueue[0]}"

         newarrpriority="${newarr[1]}"
         firstaccarrpriority="${firstaccarr[1]}"

         if ((newarrpriority >= firstaccarrpriority)); then
            newaccepteditemstringed="${newQueue[$i]}"
            acceptedQueue+=("$newaccepteditemstringed")
            unset newQueue[i]
            newQueue=("${newQueue[@]}")
         fi
      done
   fi

   #   ! Check and decreasing the accepted queue service time if is in the running state and move processes to the back of the queue if the quanta is up
   if ((timeCounter > 0)); then

      if ((${#acceptedQueue[@]} > 1)); then
         read -a firstaccitem <<<"${acceptedQueue[0]}"
         firstaccitemST="${firstaccitem[3]}"
         decSerTimea=$((firstaccitemSTa - 1))

         if ((firstaccitemST > 0)); then
            read -a firstaccitema <<<"${acceptedQueue[0]}"
            firstaccitemSTa="${firstaccitema[3]}"
            decSerTime=$((firstaccitemSTa - 1))

            firstaccitem[3]="$decSerTime"
            firstaccitemstring="${firstaccitem[*]}"
            acceptedQueue[0]="$firstaccitemstring"

            # ! Check, decrease the service time and move element to the back of the accepted queue when the quanta is due
            ((quantaCheck++))
            if ((quanta == quantaCheck || decSerTime <= 0)); then
               read -a first <<<"${acceptedQueue[0]}"
               first[0]=$state_waiting
               firstacc="${first[*]}"
               acceptedQueue[0]="$firstacc"

               read -a second <<<"${acceptedQueue[1]}"
               second[0]=$state_running
               secondacc="${second[*]}"
               acceptedQueue[1]="$secondacc"

               acceptedQueue=("${acceptedQueue[@]}")
               acceptedQueue+=("${acceptedQueue[0]}")
               unset acceptedQueue[0]
               acceptedQueue=("${acceptedQueue[@]}")

               quantaCheck=0
            fi

         else

            acceptedQueue+=("${acceptedQueue[0]}")
            acceptedQueue=("${acceptedQueue[@]}")
            unset acceptedQueue[0]
            acceptedQueue=("${acceptedQueue[@]}")
         fi

      elif ((${#acceptedQueue[@]} == 1 && timeCounter >= 1)); then
         read -a elone <<<"${acceptedQueue[0]}"
         aloneST="${elone[3]}"
         decaloneSerTime=$((aloneST - 1))

         elone[3]="$decaloneSerTime"
         elone[0]="$state_running"

         elonestringed="${elone[*]}"
         acceptedQueue[0]="$elonestringed"
         acceptedQueue=("${acceptedQueue[@]}")
         # ? Incrementing the quantacheck since the processes remains runing
         if ((quanta >= 2)); then
            ((quantaCheck++))
         fi

      fi
   fi

   # ! Check and set Accepted processes state into complete based on service time
   for ((i = 0; i < ${#acceptedQueue[@]}; i++)); do
      read -a accitem <<<"${acceptedQueue[$i]}"
      itemST="${accitem[3]}"
      if ((itemST == 0)); then
         accitem[0]="$state_complete"
         accitemstring="${accitem[*]}"
         acceptedQueue[i]="$accitemstring"

      fi
      acceptedQueue=("${acceptedQueue[@]}")
   done

   # ! Checks the service time and pushes it into the completed array
   for ((i = 0; i < ${#acceptedQueue[@]}; i++)); do
      read -a accitem <<<"${acceptedQueue[$i]}"
      itemST="${accitem[3]}"
      if ((itemST == 0)); then

         completedProcesses+=("${acceptedQueue[i]}")
         unset acceptedQueue[i]

      fi
      acceptedQueue=("${acceptedQueue[@]}")
   done

   # ! Move in an element from the new queue as soon as it is empty
   if ((${#acceptedQueue[@]} == 0)); then
      newaccepteditemstringed="${newQueue[0]}"
      acceptedQueue+=("$newaccepteditemstringed")
      unset newQueue[0]
      newQueue=("${newQueue[@]}")
      acceptedQueue=("${acceptedQueue[@]}")
   fi

   # ! Checking and making sure the accepted queue element keeps runing if it is alone in the queue
   if ((${#acceptedQueue[@]} == 1)); then
      read -a first <<<"${acceptedQueue[0]}"
      first[0]=$state_running
      firstacc="${first[*]}"
      acceptedQueue[0]="$firstacc"
      acceptedQueue=("${acceptedQueue[@]}")
   fi

   # ! Check for the state of each process in all available arrays and append the state to the state array (Recording the state of the processes)
   stage=("$timeCounter ")
   read -a processName <<<"${processStates[0]}"
   for ((i = 1; i < ${#processName[@]}; i++)); do
      for ((a = 0; a < ${#processes[@]}; a++)); do
         read -a pros <<<"${processes[$a]}"
         if [[ "${pros[2]}" == "${processName[i]}" ]]; then
            stage[i]="${pros[0]} "
         fi

      done
   done
   for ((i = 1; i < ${#processName[@]}; i++)); do
      for ((a = 0; a < ${#acceptedQueue[@]}; a++)); do
         read -a pros <<<"${acceptedQueue[$a]}"
         if [[ "${pros[2]}" == "${processName[i]}" ]]; then
            stage[i]="${pros[0]} "
         fi

      done
   done
   for ((i = 1; i < ${#processName[@]}; i++)); do
      for ((a = 0; a < ${#newQueue[@]}; a++)); do
         read -a pros <<<"${newQueue[$a]}"
         if [[ "${pros[2]}" == "${processName[i]}" ]]; then
            stage[i]="${pros[0]} "
         fi

      done
   done
   for ((i = 1; i < ${#processName[@]}; i++)); do
      for ((a = 0; a < ${#completedProcesses[@]}; a++)); do
         read -a pros <<<"${completedProcesses[$a]}"
         if [[ "${pros[2]}" == "${processName[i]}" ]]; then
            stage[i]="${pros[0]} "
         fi

      done
   done
   stage=("${stage[@]}")
   stagestringed="${stage[*]}"
   processStates+=("$stagestringed")

   # ! Count incrementer and loop closure
   ((timeCounter++))
done

# ! Function for printing out result
function printing_output {

   # ! Prompt the user about how to choose the options and declare some important variables
   echo -e "\n"
   echo -e "CHOOSE YOUR OUTPUT MODE (Type y/n for YES/NO to each of the options) \n"

   text_file=""
   output_f_name=""

   # ! Ask if the user wants to print into a text file and if yes takes file name
   while true; do
      read -p "Do you want to print output into a text file? " text_filea

      if [[ $text_filea =~ [Yy] || $text_filea =~ [Nn] ]]; then
         text_file=$text_filea
         if [[ $text_filea =~ [Yy] ]]; then
            while true; do
               read -p "Output file name : " o_filename

               if [[ $o_filename =~ ^[[:alpha:]] ]]; then
                  output_f_name="${o_filename//[[:space:]]/}"
                  break
               else
                  echo "Your file name must start with a letter !!! "
               fi
            done
            break
         else
            break
         fi
      else
         echo "INVALID INPUT !!!"

      fi
   done

   # ! If the user want no file output, the program defaults standard output
   if [[ $text_file =~ [Nn] ]]; then
      echo -e "\n"
      echo -e "STANDARD OUTPUT DEFAULTED \n"
      for element in "${processStates[@]}"; do
         formatted_element="${element// /$'   '}"
         echo "$formatted_element"
      done
      # ! If the user want a file a question is asked to see if the user want standard output also
   else
      base_name=$(basename "${output_f_name%.*}")
      ext="txt"
      result_file="$base_name.$ext"
      printf "%s\n" "${processStates[@]}" >"$result_file"

      while true; do
         read -p "Do you want Standard Output also? " standard_output
         if [[ $standard_output =~ [Yy] || $standard_output =~ [Nn] ]]; then
            if [[ $standard_output =~ [Yy] ]]; then
               echo -e "\n"
               for element in "${processStates[@]}"; do
                  formatted_element="${element// /$'   '}"
                  echo "$formatted_element"
               done
               echo -e "\n"
               echo -e "Output successfully printed in $result_file "
               break
            else
               echo -e "Output successfully printed in $result_file "
               break
            fi
         else
            echo "INVALID INPUT !!!"

         fi
      done
   fi

}

#  ? Calling printout function
printing_output
