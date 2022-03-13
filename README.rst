##################
Titans Of Eden API
##################

This project provides a basic webserver API to process form submissions. In the
future, it will be upgraded to act as a full games server.

To deploy this service to a VM, simply execute:

.. code-block:: bash

   curl https://raw.githubusercontent.com/lakes-legendaries/titans-api/main/vm/provision.sh | bash

This script:

#. Installs the necessary packages
#. Creates a startup script that:
   #. Clones this repo
   #. Builds this repo's Docker image
   #. Runs this project as a containerized service