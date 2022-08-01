# Important things to keep in mind
- Delete GPU from config before starting the instance if GPU isn't necessary for that particular session. This will save a lot of credits.
- Stop your instance when not in use. Maybe keep a reminder twice a day to stop it (to save credits when instance is not in use).
# Redeem Educational Credits
- Use [this link](https://cloud.google.com/billing/docs/how-to/edu-grants#redeem) to avail the credits using the coupon
# Create Project 
- Use suitable name
- Use billing account from above redeemed credits
# Create VM
- Enable Compute Engine API for the project (takes a while..)
- If you encounter no billing account linked dialog.. just refresh the page. [Twitter thread](https://twitter.com/lukwam/status/1553039280389476353) talking about the bug.
- Create instance using marketplace, select Deep Learning VM.
- ## Increase Quota
  - You will encounter a Quota error. Click on link to go to the GPU quotas page.
  - Submit request to increase quota and wait for approval email.
  - Refresh quota page until increased quota is reflected after approval of quota.
- Use default config for machine specs and GPU..
- Enable these unticked options
  - Install GPU Drivers automatically..
  - Enable access to Jupyter lab..
- Deploy
  - Takes a while.. wait
# Create Static External Ip
- VPC Network -> IP Address -> Reserve External Static IP address
# Create firewall rule
- Use network tag of VM for scope
- Sources: 0.0.0.0/0
- tcp: 8888
# Connect to VM using SSH
- SSH in browser (easier)
- SSH from local (involves SSH key setup)
# Setup Jupyter
- `jupyter notebook --generate-config`
- `vi ~/.jupyter/jupyter_notebook_config.py`
- Add the following at the end of the file
  ```
  c = get_config()
  c.NotebookApp.ip = '*' 
  c.NotebookApp.open_browser = False 
  c.NotebookApp.port = 8888
  ```
# Run Jupyter in background
- `jupyter notebook >> jup_notebook.log 2>&1 & tail -f jup_notebook.log`
- Access from browser `http://<external ip>:8888.. token from above method

# Clone repository and open notebook
- `git clone https://github.com/ma08/nlp_summer22_hw4.git`
- Open jupyter from the link in previouse section and navigate to `nlp_summer22_hw4/Assignment4.ipynb` to get started with installing the dependencies which don't come with the Deep Learning VM image and ran a few sample methods related to the hw4.
  
