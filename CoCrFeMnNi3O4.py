# Created Feb 24, 2025
# Cody Somers
# Updated Apr 11

from occupationFunctions import *

# User parameters
input_file = "CoCrFeMnNi3O4_sym.cif"
output_file = "CoCrFeMnNi3O4_middle.cif"
total_number_of_atoms = 152  # Total number of atoms after symmetry has been removed
number_of_unique_atoms = 5  # Number of different atoms sharing a single occupancy site
number_of_mixed_occupancy_sites = 16  # Number of sites that the "Unique Atoms" are trying to fit into

desired_occupancy = np.empty(shape=[2, number_of_unique_atoms], dtype=StringDtype)
# desired_occupancy[:,0] = ["atom name", "# of atoms you want in this position"]

desired_occupancy[:, 0] = ["Co1", "2"]
desired_occupancy[:, 1] = ["Cr1", "4"]
desired_occupancy[:, 2] = ["Fe1", "1"]
desired_occupancy[:, 3] = ["Mn1", "4"]
desired_occupancy[:, 4] = ["Ni1", "5"]
# End of user parameters

positions = siteChooser(number_of_unique_atoms, desired_occupancy, number_of_mixed_occupancy_sites)
atomic_data = inputData(input_file,output_file, total_number_of_atoms)
output_data, total_number_of_atoms = arraySolver(positions, atomic_data, total_number_of_atoms, desired_occupancy, number_of_mixed_occupancy_sites, number_of_unique_atoms)
outputData(output_data,output_file)


# Repeat for the second set of sites. Putting output of the other to be in the input to this one
# Note that the new total_number_of_atoms is calculated in the previous portion.

# User parameters
input_file = "CoCrFeMnNi3O4_middle.cif"
output_file = "CoCrFeMnNi3O4_output.cif"
number_of_unique_atoms = 5  # Number of different atoms sharing a single occupancy site
number_of_mixed_occupancy_sites = 8  # Number of sites that the "Unique Atoms" are trying to fit into

desired_occupancy = np.empty(shape=[2, number_of_unique_atoms], dtype=StringDtype)
# desired_occupancy[:,0] = ["atom name", "# of atoms you want in this position"]

desired_occupancy[:, 0] = ["Co2", "3"]
desired_occupancy[:, 1] = ["Cr2", "0"]
desired_occupancy[:, 2] = ["Fe2", "4"]
desired_occupancy[:, 3] = ["Mn2", "1"]
desired_occupancy[:, 4] = ["Ni2", "0"]
# End of user parameters

positions = siteChooser(number_of_unique_atoms, desired_occupancy, number_of_mixed_occupancy_sites)
atomic_data = inputData(input_file,output_file, total_number_of_atoms)
output_data, total_number_of_atoms = arraySolver(positions, atomic_data, total_number_of_atoms, desired_occupancy, number_of_mixed_occupancy_sites, number_of_unique_atoms)
outputData(output_data,output_file)
