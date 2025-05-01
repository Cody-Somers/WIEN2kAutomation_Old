#!/bin/bash
# Could also be tcsh

# Created Mar 3, 2025
# Last Edit: May 1, 2025
# Cody Somers, cas003@usask.ca

################ Start of User Parameters ####################

# The name of the .struct that you start everything off with
session_name="YaBoi"

# Specify the atom number (inequivalent sites) that you want to perform a calculation on
# Put range of values in here. So {2..10} gives atoms 2,3,4,5,6,7,8,9,10
# Can also specify specific atoms, (2 4 64) separated by a single space
atoms_to_replace=({1..5})
#atoms_to_replace=(1 41 56)

# Specify the edited orbital for the core hole that you desire
replace_core_hole="1,-1,1               ( N,KAPPA,OCCUP)" # Try to keep all the spaces intact

# Specify how many lines down from NUMBER OF ORBITALS (ie, the 1s shell = 1)
lines_from_orbital=1

# Number of inequivalent atom sites given in structgen
number_of_atoms=56

# Specify the desired number of k points
k_mesh=200

# Check if the calculation is complex. Given by x symmetry saying "No Inversion"
complex_calc="y" # either y or n

# Specify whether more than one atom occupy an equivalent position (currently 'n' does not work
split="y" # either y or n

# Note: There are a couple parameters in coreHoleInitialization() that you can change if you don't want
# the default WIEN2k initialization settings.
# Note: This is setup for Graham. Will not function on Plato. See note about sed -i '' .bak

############## End of User Parameters #################

# Process:
# Start in main with a .struct for a supercell, and run.job
# User specifies a couple conditions.
# For each of the desired atoms in the array:
# Create a folder, cp struct/job into folder and rename
# Important: Structure is the one from "Save File and Clean Up" in StructGen
# Run initialization up to x lstart
# Create core hole and change energy range. (.inc, .inm, .in1)
# Finish initialization
# Submit to slurm
# Exit from folder and repeat for next corehole

# Function that copies the input files into their proper spots
prepare_input_files (){
  # Copy the .in0 file
  cp "$session_name"_"$i".in0_st "$session_name"_"$i".in0 || exit

  # Copy .in1 and .in2. Needs to specify whether it is complex calculation
  if [[ "$complex_calc" == "y" ]]; then
    cp "$session_name"_"$i".in1_st "$session_name"_"$i".in1c || exit
    cat "$session_name"_"$i".in2_ls > "$session_name"_"$i".in2c || exit
    cat "$session_name"_"$i".in2_sy >> "$session_name"_"$i".in2c || exit
  else
    cp "$session_name"_"$i".in1_st "$session_name"_"$i".in1 || exit
    cat "$session_name"_"$i".in2_ls > "$session_name"_"$i".in2 || exit
    cat "$session_name"_"$i".in2_sy >> "$session_name"_"$i".in2 || exit
  fi

  # Copy .inc, .inm, .inq
  cp "$session_name"_"$i".inc_st "$session_name"_"$i".inc || exit
  cp "$session_name"_"$i".inm_st "$session_name"_"$i".inm || exit
  cp "$session_name"_"$i".inq_st "$session_name"_"$i".inq || exit
}

# Function that edits the structure file to split an atom and places it at the end of the file
edit_structureFile () {
  #TODO: Make the else statement, where they don't want to split the atom at the start. Do OG process
  if [[ "$split" == "y" ]]; then
      # Go into the structure file
      structureFile="$session_name"_"$i".struct
      # Look for the nth atom that is specified by the user and get line number
      originalStruct="$i [[:space:]]*NPT="
      lineNum="$(grep -n "$originalStruct" "$structureFile" | head -n 1 | cut -d: -f1)"
      #lineNum=$(awk "/$originalStruct /{i++}i==1 {print NR; exit}" "$structureFile")

      # Go through all occurrences of Mult and find the line for the nth atom
      originalMult="          MULT="
      multLineNum=$(awk "/$originalMult /{i++}i==$i"'{print NR; exit}' "$structureFile")
      # Gets the multiplicity for that atom and decrement it
      multiplicity=$(awk "/$originalMult /{i++}i==$i"'{print $2; exit}' "$structureFile")
      multiplicity=$((multiplicity-1))

      # Replace the multiplicity line
      # Is valid for multiplicities less than 100.
      if [[ "$multiplicity" -gt 9 ]]; then
        replace_multiplicity="          MULT= $multiplicity         ISPLIT= 8"
      else
        replace_multiplicity="          MULT= $multiplicity          ISPLIT= 8"
      fi
      sed -i "$multLineNum s/.*/$replace_multiplicity/" "$structureFile" || exit

      # Get the info from the last line in the file
      lastLineNum="$(grep -n "NUMBER OF SYMMETRY OPERATIONS" "$structureFile" | head -n 1 | cut -d: -f1)"
      last_line_info=$(awk  "NR==$lastLineNum {print; exit}" "$structureFile") # Info of last line

      # Beginning of process to move the atom to end of file
      temp_info=$(awk  "NR==$((lineNum-1)) {print; exit}" "$structureFile") # Atom info
      sed -i "$lastLineNum s/.*/$temp_info/" "$structureFile" || exit # Place in last line
      # Edit the name of the atom to make it unique to be the last atom
      if [[ "$number_of_atoms" -gt 99 ]]; then
        sed -i "$lastLineNum s/ATOM[[:space:]]*-$i/ATOM-$((number_of_atoms+1))/" "$structureFile" || exit # place in last line
      elif [[ "$number_of_atoms" -gt 9 ]]; then
        sed -i "$lastLineNum s/ATOM[[:space:]]*-$i/ATOM -$((number_of_atoms+1))/" "$structureFile" || exit # place in last line
      else
        sed -i "$lastLineNum s/ATOM[[:space:]]*-$i/ATOM  -$((number_of_atoms+1))/" "$structureFile" || exit # place in last line
      fi

      # Put the required info from the original position into the end of the file
      multiplicity=1 # This is the new multiplicity for the core hole
      replace_multiplicity="          MULT= $multiplicity          ISPLIT= 8"
      echo "$replace_multiplicity" >> "$structureFile"
      temp_info=$(awk  "NR==$((lineNum)) {print; exit}" "$structureFile") # Atom info
      echo "$temp_info" >> "$structureFile"

      # Edit the name of the atom to make it unique to be the last atom
      if [[ "$number_of_atoms" -gt 99 ]]; then
        sed -i "$((lastLineNum+2)) s/$originalStruct/$((number_of_atoms+1))      NPT=/" "$structureFile" || exit
      elif [[ "$number_of_atoms" -gt 9 ]]; then
        sed -i "$((lastLineNum+2)) s/$originalStruct/$((number_of_atoms+1))       NPT=/" "$structureFile" || exit
      else
        sed -i "$((lastLineNum+2)) s/$originalStruct/$((number_of_atoms+1))        NPT=/" "$structureFile" || exit
      fi

      # Copying the rotational matrix
      temp_info=$(awk  "NR==$((lineNum+1)) {print; exit}" "$structureFile") # Atom info
      echo "$temp_info" >> "$structureFile"
      temp_info=$(awk  "NR==$((lineNum+2)) {print; exit}" "$structureFile") # Atom info
      echo "$temp_info" >> "$structureFile"
      temp_info=$(awk  "NR==$((lineNum+3)) {print; exit}" "$structureFile") # Atom info
      echo "$temp_info" >> "$structureFile"

      # Put the info from the last lines back in
      echo "$last_line_info" >> "$structureFile"

      # Change number of inequivalent atoms at top of file
      # Will break at 9 and 99 atoms maybe
      sed -i "2 s/$number_of_atoms/$((number_of_atoms+1))/" "$structureFile" || exit
      #number_of_atoms=$((number_of_atoms+1)) # pointless since it changes with nn later

      # Remove the atom from its original position
      sed -i "$((lineNum-1)) d" "$structureFile" || exit

      # Structure file has now been edited successfully
    fi
}

# Function that does the entire initialization process
coreHoleInitialization () {
  # Go through the x nn a couple times to adjust for the new structure. 3 times to be safe
  echo 3 | x nn || exit
  # Accept the nn that was found. 500 was arbitrary, but names can't be longer than that,
  # and 500 isn't useful data
  characterCount=$(wc -m < "$session_name"_"$i".struct_nn)
  if [[ "$characterCount" -gt 500 ]]; then
    cp "$session_name"_"$i".struct_nn "$session_name"_"$i".struct || exit
  fi

  echo 3 | x nn || exit
  # Accept the nn that was found
  characterCount=$(wc -m < "$session_name"_"$i".struct_nn)
  if [[ "$characterCount" -gt 500 ]]; then
    cp "$session_name"_"$i".struct_nn "$session_name"_"$i".struct || exit
  fi

  echo 3 | x nn || exit
  # Accept the nn that was found
  characterCount=$(wc -m < "$session_name"_"$i".struct_nn)
  if [[ "$characterCount" -gt 500 ]]; then
    cp "$session_name"_"$i".struct_nn "$session_name"_"$i".struct || exit
  fi

  # Update number of atoms after x nn
  number_of_atoms_after_nn=$(awk  'NR==2 {print $2; exit}' "$structureFile")

  # Find space group.
  # Does not use the found space group. Can be done by copying the .struct file
  x sgroup || exit

  # Find symmetry group
  # Uses the found symmetry group
  x symmetry || exit
  cp "$session_name"_"$i".struct_st "$session_name"_"$i".struct || exit

  # Creates the spin orbital, defaulting to spin up
  # The yes is to overwrite so that we can change the spin and overwrite files
  echo "y" | instgen_lapw -up || exit

  # Do lstart
  # If core leakage then you can change the -6 to a different value
  { echo "PBE" ; echo "-6"; } | x lstart || exit

  # Change the occupancy of the core hole of the atom at the end of the file
  # For graham we have sed -i, but plato/Mac we need -i '' or -i .bak if you want to create backup files
  coreholeFile="$session_name"_"$i".inc_st
  coreLastLineNum=$(awk "/NUMBER OF ORBITALS/{i++}i==$number_of_atoms_after_nn"'{print NR; exit}' "$coreholeFile")
  sed -i "$((coreLastLineNum + lines_from_orbital)) s/.*/$replace_core_hole/" "$coreholeFile" || exit
  
  # Change mixer file to add the background charge
  originalMix="MSR1   0.0   YES"
  replace_mixer="MSR1  -1.0   YES"
  mixerFile="$session_name"_"$i".inm_st
  sed -i "1s/$originalMix/$replace_mixer/" "$mixerFile" || exit

  # Change the energy range from -9 and 1.5 to -10 and 3. Gives more range for the xspec etc.
  # If you want a greater energy range for the xspec this is where you edit.
  originalEng="4   -9.0       1.5"
  replace_energy="4   -10.0       3.0"
  energyFile="$session_name"_"$i".in1_st
  energyLastLineNum="$(grep -n "VECTORS FROM UNIT" "$energyFile" | head -n 1 | cut -d: -f1)"
  sed -i "$energyLastLineNum s/$originalEng/$replace_energy/" "$energyFile" || exit

  # Copy files and rename them
  prepare_input_files

  # Generate the k-mesh
  # Does not perform the shifting operation
  { echo "$k_mesh" ; echo 0; } | x kgen || exit

  # Do dstart
  x dstart || exit

  # Copy file into proper spot
  cp "$session_name"_"$i".in0_std "$session_name"_"$i".in0 || exit

  # The final thing is asking about spin-polarized calculations. Not sure how to deal with that rn
}

# Function that takes the run.job file, renames it, then submits to slurm
run_jobFile () {
  replace_job="#SBATCH -J $session_name$i"
  sed -i "2s/.*/$replace_job/" "run.job" || exit
  sbatch "run.job"
}

# Main Function
# Makes unique directories for each core hole, then goes through entire process up until submission
coreHoleComputations () {
  for i in "${atoms_to_replace[@]}"; do
    # Make a new directory for each session, and copy the .struct file into it (exit if not found)
    mkdir "$session_name"_"$i"
    cp "$session_name".struct "$session_name"_"$i"/"$session_name"_"$i".struct || exit
    cp "run.job" "$session_name"_"$i"/"run.job" || exit

    # Move into the subdirectory
    cd "$session_name"_"$i" || exit

    # Do the rest of the initialization
    edit_structureFile
    coreHoleInitialization
    run_jobFile

    # Return back to main directory
    cd ..
  done
}

# Call function so that it runs in terminal
coreHoleComputations
