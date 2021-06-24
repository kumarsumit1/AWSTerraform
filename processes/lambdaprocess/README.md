# Example Project 

Has ways to hit Lambda API using Rest API
https://www.youtube.com/watch?v=50rBFasH3OE




# Initialize the project 

terraform init -backend-config=../init/init_dev.tfvars -input=false


terraform plan -var-file=../var/plan_dev.tfvars -input=false

terraform apply -var-file=../var/plan_dev.tfvars -input=false

OR 
terraform plan -var-file=../var/plan_dev.tfvars -input=false -out run.plan
terraform apply run.plan

# Setup Sam application

1. From pallet choose create a sam application
2. choose the environment
3. select the folder and it will create a sub folder within that space 
4. It will ask for project name and create a sub folder with that name
5. In parent folder i.e lambdaprocess create a virtual environment , that would mean terrafrom and virtual environment in same folder
    ```
    python -m venv smvenv
    #Activate venv and install requirements
    pip install -r hello_world/requirements.txt
    pip install pytest pytest-mock #mocker moto

    #Now test the app
    python -m pytest tests/ -v
    ```

6. Invoke Lambda locally
sam local invoke sendmail –no-event

