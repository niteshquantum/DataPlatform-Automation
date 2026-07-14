#################################################
# MongoDB Configuration
#################################################

# MongoDB Port
# Default MongoDB port is 27017
# Examples:
# 27018, 27019, 27020

mongodb_port = 27018


#################################################
# Existing MongoDB Handling
#################################################

# true  = Use existing MongoDB installation
# false = Create a new MongoDB installation/instance

use_existing_mongodb = false

#################################################
# Example Configurations
#################################################

# Example 1:
# Use existing MongoDB installation
#
# mongodb_port = 27017
# use_existing_mongodb = true


# Example 2:
# Create a new MongoDB instance on port 27018
#
# mongodb_port = 27018
# use_existing_mongodb = false


# Example 3:
# Create another MongoDB instance on port 27019
#
# mongodb_port = 27019
# use_existing_mongodb = false