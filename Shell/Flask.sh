#!/bin/zsh

WriteInFile(){
    cat >"main.py" <<EOF
from mongoengine import connect
from app.config import app
import os
from dotenv import load_dotenv

variables_to_remove = ['FLASK_ENV', 'DB_NAME', 'DB_URL','DB_PORT','SECRET_KEY']
for var in variables_to_remove:
    os.environ.pop(var, None)

load_dotenv()

def greeting():
    return f"<h1>This is a Flask {os.getenv('FLASK_ENV')} Server</h1>"

app.add_url_rule("/", "greeting", greeting, methods=['GET'])

app.config['ENV'] = os.getenv('FLASK_ENV')
app.config["SECRET_KEY"] = os.getenv('SECRET_KEY')

if __name__ == "__main__":
    connect(db=os.getenv('DB_NAME'),
            host=os.getenv('DB_URL'),
            port=int(os.getenv('DB_PORT')))
    app.run(debug=True)
EOF


cat > "app/config.py" <<EOF
from flask import Flask, jsonify, request
from flask_cors import CORS

app = Flask(__name__)

CORS(app)

@app.before_request
def Before_Request():
    """REVIEW - Before Request Handler

    Raises:
        Exception: Check if it is a json format data or not
    """
    if request.method in ['PUT', 'DELETE', 'POST']:
        if request.headers['Content-Type'] != 'application/json':
            raise Exception("Content Type must be application/json")

@app.after_request
def convert_to_json(response):
    """REVIEW - Response Handler

    Args:
        response (dict): Get Response as dict
    Returns:
        response : Convert the dict response to json by parsing using jsonify 
    """
    if isinstance(response.get_json(), dict):
        response.set_data(jsonify(response.get_json()).data)
    return response

@app.errorhandler(Exception)
def Error_Handling(error):
    """REVIEW - Error Handler

    Args:
        error (string): When Raise and exception with a string
    Returns:
        json : Convert the string into dict and parse it using jsonify
    """
    data = {
        "status": "alert",
        "message": str(error)
    }
    return jsonify(data)

EOF

cat > ".env" <<EOF
FLASK_ENV=flask_name
SECRET_KEY=key
DB_NAME=db_name
DB_URL=mongodb://localhost
DB_PORT=27017
EOF

cat > ".gitignore"<<EOF
# Byte-compiled / optimized / DLL files
__pycache__/
*.py[cod]
*$py.class


# Unit test / coverage reports
.cache
*.cover
*.py,cover
.pytest_cache/

# VSCode
.vscode/

# Local settings
*.local

# Jupyter Notebook
.ipynb_checkpoints

# Enviroment
.venv
EOF
}
#REVIEW - Function to initialize the Flask app
Init() {
    if ! python -m venv .venv; then
        echo "Failed to create virtual environment"
        exit 1
    fi
    
    source ".venv/bin/activate"
    if [ -d ".venv" ]; then
        package_array=("flask" "flask-restful" "mongoengine" "python-dotenv" "gunicorn" "Flask-CORS")
        for pack in "${package_array[@]}";do
            pip install -q $pack 
        done  
    fi
    ExportEnv
    deactivate

    # Create the folders
    mkdir -p app/controller app/model app/repository app/service
    if [ $? -ne 0 ]; then
        echo "Failed to create project folders"
        exit 1
    fi

    # Create files
    file_array=(".env" ".gitignore" "main.py" "app/__init__.py" "app/config.py" "app/controller/__init__.py" "app/model/__init__.py" "app/repository/__init__.py" "app/service/__init__.py")
    for file in "${file_array[@]}"; do
        touch "$file";
    done

    WriteInFile
    echo "Flask Web Server is successfull installed ( change .env file attribute ) "

}


#REVIEW - Function to remove PYCACHE
RemovePycache() {
    find . -type d -name "__pycache__" -exec rm -rf {} +
    ExportEnv
    clear
}


#REVIEW - Function to export environment variables
ExportEnv() {
    pip freeze > requirements.txt
}

#REVIEW - Function to run the server
RunPythonServer() {
    trap RemovePycache SIGINT
    python main.py
}

RunProductionServer(){
    trap RemovePycache SIGINT
    gunicorn -w 3 -b 127.0.0.1:5000 main:app
}

#REVIEW - Function to create model and write in model files
CreateModel() {
    echo -n "Enter model name :"
    read model
    echo "Creating model files..."
    modelName=$(echo "$model" | awk '{ for(i=1;i<=NF;i++) { $i=toupper(substr($i,1,1)) tolower(substr($i,2)) } print }')
    lw_model=$(echo "$model" | tr '[:upper:]' '[:lower:]')

    touch "app/controller/${modelName}Controller.py"
    cat > "app/controller/${modelName}Controller.py" <<EOF
from flask import Blueprint
from flask_restful import Resource, Api
from ..service.${modelName}Service import ${modelName}Service

${modelName}Controller_bp = Blueprint("${lw_model}",__name__)
api = Api(${modelName}Controller_bp)

class ${modelName}Controller(Resource):
    
    def get(self):
        return

    def post(self):
        return
    
    def put(self):
        return
    
    def delete(self):
        return

api.add_resource(${modelName}Controller, '/${lw_model}')
EOF

    temp_file=$(mktemp)
    echo "from app.controller.${modelName}Controller import ${modelName}Controller_bp" > "$temp_file"
    cat "app/config.py" >> "$temp_file"
    mv "$temp_file" "app/config.py"
    echo "app.register_blueprint(${modelName}Controller_bp)" >> "app/config.py"

    touch "app/model/${modelName}Model.py"
    cat > "app/model/${modelName}Model.py" <<EOF
from mongoengine import Document,StringField

class ${modelName}Model(Document):
    
    meta = {'collection': '${lw_model}' }
    _field = StringField(db_field="field_name",max_length=10)

    
    def to_dict(self):
            return {
            "field": self._field,
            }
EOF

    touch "app/repository/${modelName}Repo.py"
    cat > "app/repository/${modelName}Repo.py" <<EOF
from ..model.${modelName}Model import ${modelName}Model

class ${modelName}Repo():
    
    @staticmethod
    def find_all():
        return ${modelName}Model.objects()

    @staticmethod
    def find():
        return ${modelName}Model.objects()
    
    @staticmethod
    def create():
        ${modelName}Model = ${modelName}Model()
        ${modelName}Model.save()
        return ${modelName}Model

    @staticmethod
    def update():
        ${modelName}Model.save()
        return ${modelName}Model

    @staticmethod
    def delete():
        return ${modelName}Model.objects().delete()
EOF


    touch "app/service/${modelName}Service.py"
    cat >  "app/service/${modelName}Service.py" <<EOF
from ..repository.${modelName}Repo import ${modelName}Repo

class ${modelName}Service():
    
    @staticmethod
    def find_all_${lw_model}():
        return ${modelName}Repo.find_all()
    
    @staticmethod
    def find_${lw_model}():
        return ${modelName}Repo.find()
    
    @staticmethod
    def create_${lw_model}():
        return ${modelName}Repo.create()
    
    @staticmethod
    def update_${lw_model}():
        return ${modelName}Repo.update()
    
    @staticmethod
    def delete_${lw_model}():
        return ${modelName}Repo.delete()
EOF

    echo "$modelName Model successfully created" 

}


#REVIEW - Function for help menu
HelpMenu() {
    echo "Usage: $0 [-h] [-i] [-r] [-p] [-c] [-e] [-x]"
    echo
    echo "Options:"
    echo "  -h     Display this help menu."
    echo "  -i     Setup the flask app."
    echo "  -r     Run python server."
    echo "  -p     Run python Production server."
    echo "  -m     Create the model."
    echo "  -e     Export the python envrioment."
    echo "  -x     Remove Pycache folders."
}

#REVIEW - Main function
Main() {
    while getopts "ihrmxep" opt; do
        case ${opt} in
        i)
            Init
            exit 0
            ;;
        h)
            HelpMenu
            exit 0
            ;;
        r)
            RunPythonServer
            ;;
        m)
            CreateModel
            ;;
        x)
            RemovePycache
            ;;
        e)
            ExportEnv
            ;;
        p)
            RunProductionServer
            ;;
        ?)
            HelpMenu
            exit 1
            ;;
        esac
    done
    
    if [ -z "$@" ]; then
        HelpMenu
    else
        exit 1
    fi
}

# Call the Main function
Main "$@"
