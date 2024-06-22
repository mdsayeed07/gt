#!/bin/bash
###
##
#

############################################################################
########################## Function Definition #############################
############################################################################

install_func(){

# Check if software is installed
command -v $SOFTWARE_NAME > /dev/null
RETURN_CODE=${?}

if [[ ${RETURN_CODE} -ne 0 ]]; then
  echo "INFO : Installing $SOFTWARE_NAME ..."
  sudo apt install -y $SOFTWARE_NAME &> /dev/null
  
  # Post installation-check
  if command -v $SOFTWARE_NAME > /dev/null; then
    echo "INFO: $SOFTWARE_NAME successfully installed. !!!"
    echo "$SOFTWARE_NAME Version :" $($SOFTWARE_NAME --version | awk 'NR==1 {print $1,$2,$3,$4}')
  else
    echo "ERROR: $SOFTWARE_NAME installation failed."
    exit 1
  fi

else
  echo "INFO: $SOFTWARE_NAME is already installed, skipping installation. !!!"
  echo "$SOFTWARE_NAME Version :" $($SOFTWARE_NAME --version | awk 'NR==1 {print $1,$2,$3,$4}')
fi
}


############################################################################
############################## Main Program ################################
############################################################################

### Updating Package Manager
echo "INFO : Updating (apt) Package Manager ..."
sudo apt update -y &> /dev/null

## Invoking functions for installation
SOFTWARE_NAME="tree" install_func

