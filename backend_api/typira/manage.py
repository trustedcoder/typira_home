from flask_migrate import Migrate
from app import create_app, db
import os, logging
import sys
from dotenv import load_dotenv

load_dotenv()

config_name = os.getenv("ENV","dev")
app = create_app(config_name)
migrate = Migrate(app, db)


logging.basicConfig(filename='error.log', level=logging.ERROR,
                    format='%(asctime)s - %(levelname)s - %(message)s')




if __name__ == "__main__":
    try:
        argument = sys.argv[1]
    except IndexError:
        argument = ""
    if argument == "run":
        from app import socketio
        socketio.run(app, host="0.0.0.0", port=7009, debug=True)
