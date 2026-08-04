from flask import Flask

from database import init_database

from routes.users import users
from routes.catalog import catalog
from routes.orders import orders

from config import HOST, PORT, DEBUG


app = Flask(__name__)


app.register_blueprint(users)
app.register_blueprint(catalog)
app.register_blueprint(orders)


if __name__ == "__main__":
    init_database()
    app.run(
        host=HOST,
        port=PORT,
        debug=DEBUG
    )