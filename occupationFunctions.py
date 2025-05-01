# Created Feb 24, 2025
# Cody Somers
# Functions used

import random
import numpy as np
from pandas import StringDtype

# These functions assume several things:
#   All atoms of the same type/name are sequential
#   The final line before atomic positions is _atom_site_type_symbol
# Cif files should be made using vesta to avoid any issues. Remove all symmetry first as well.

# Returns positions as a list of lists.
def siteChooser(number_of_unique_atoms, desired_occupancy, number_of_mixed_occupancy_sites):
    #TODO: Make this into not a list, but a np.array

    # Get the number of atoms for each position based on user input
    desired_atoms = np.zeros(number_of_unique_atoms, dtype=int)
    for i in range(number_of_unique_atoms):
        desired_atoms[i] = int(desired_occupancy[1][i])

    indices = list(range(0, number_of_mixed_occupancy_sites, 1)) # Number of possible indices
    positions = [] # Empty list of positions
    for i in range(number_of_unique_atoms): # For each of the different unique atoms
        temp_array = []
        for j in range(desired_atoms[i]): # For the number of atoms desired of a specific unique atom
            choice = random.choice(indices)  # Pick a random position
            indices.remove(choice) # Remove it so noone else can have it
            temp_array.append(choice) # Store it in an array
        positions.append(temp_array) # After all positions for an individual atom have been picked, store it
    return positions # Returns a list of lists

# Gets data out of input cif file
def inputData(input_file, output_file, total_number_of_atoms):
    data = np.empty(shape=[8, total_number_of_atoms], dtype=StringDtype)
    # data[:,0] = ["label","occupancy","x","y","z","adp","iso","symbol"]

    with open(input_file, 'r') as f:
        with open(output_file, 'w') as g:
            flag = False
            atom_number = 0
            for line in f:
                if flag: # Organize each column into its own matrix element
                    line = line.strip('\n')
                    data[:, atom_number] = [x for x in line.split(' ') if x]
                    atom_number += 1
                else:
                    g.write(line)
                if line.__contains__("_atom_site_type_symbol"): # Skips until it reaches this line, then starts
                    flag = True
    return data # Returns a numpy array containing the atomic positions

# Puts only the data that we want to keep into a new array
def arraySolver(positions, atomic_data, total_number_of_atoms, desired_occupancy, number_of_mixed_occupancy_sites, number_of_unique_atoms):
    # Need to create a new array
    outputdata = np.empty(shape=[8, total_number_of_atoms-(number_of_mixed_occupancy_sites*(number_of_unique_atoms-1))], dtype=StringDtype)
    counter = 0
    counter2 = 0
    for j in range(total_number_of_atoms):  # For each atom we look at the all the original data
        flag = False
        for i in range(number_of_unique_atoms): # Go through the atoms sites
            # If name matches, create a new counter
            if atomic_data[0,j] == desired_occupancy[0,i]: # If the name matches we found one
                flag = True # Exists in our search
                if counter2 in positions[i]: # If this atom is in one of the chosen positions continue
                    atomic_data[1,j] = "1.0"
                    outputdata[:,counter] = atomic_data[:,j] # Put into output array
                    counter += 1
                counter2 += 1
                if counter2 == number_of_mixed_occupancy_sites: # We are assuming that all the atoms types are sequential
                    counter2 = 0
                break # Leave
        # If name does not match, put into the output array. Do nothing to it
        if not flag:
            outputdata[:,counter] = atomic_data[:,j]
            counter += 1

    return outputdata, total_number_of_atoms-(number_of_mixed_occupancy_sites*(number_of_unique_atoms-1))

# Outputs the data from the array into the .cif file again.
def outputData(outputdata, output_file):
    with open(output_file, 'a') as g:
        for i in range(len(outputdata[0,:])):
            for j in range(8): # Range 8 because there were 8 columns of data taken in from .cif
                g.write(outputdata[j,i])
                g.write(' ')
            g.write('\n')
    return