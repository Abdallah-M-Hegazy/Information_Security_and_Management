from flask import Flask, request, jsonify, abort
from flask_sqlalchemy import SQLAlchemy
import jwt  
import datetime
from werkzeug.security import generate_password_hash, check_password_hash
from functools import wraps

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql+pymysql://root:@localhost/task2'
db = SQLAlchemy(app)
SECRET_KEY = "abdallah"

# Database Models
class Users(db.Model):
    __tablename__ = 'users'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(80), nullable=False)
    username = db.Column(db.String(80), unique=True, nullable=False)
    password = db.Column(db.String(200), nullable=False)

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'username': self.username
        }

class Products(db.Model):
    __tablename__ = 'product'
    pid = db.Column(db.Integer, primary_key=True)
    pname = db.Column(db.String(80), nullable=False)
    description = db.Column(db.Text)
    price = db.Column(db.Numeric(10, 2), nullable=False)
    stock = db.Column(db.Integer, nullable=False)
    created_at = db.Column(db.TIMESTAMP, default=datetime.datetime.utcnow)

    def to_dict(self):
        return {
            'pid': self.pid,
            'pname': self.pname,
            'description': self.description,
            'price': float(self.price),
            'stock': self.stock,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }

# Create the database tables
with app.app_context():
    db.create_all()

# Authentication Middleware
def token_required(f):
    @wraps(f)
    def decorator(*args, **kwargs):
        token = request.headers.get('Authorization')
        if not token:
            return jsonify({'error': 'No token provided'}), 401
        try:
            jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        except:
            return jsonify({'error': 'Invalid or expired token'}), 401
        return f(*args, **kwargs)
    return decorator

# User Operations
@app.route('/signup', methods=['POST'])
def signup():
    data = request.json
    if not data or 'name' not in data or 'username' not in data or 'password' not in data:
        return jsonify({'error': 'Missing required fields'}), 400

    # Hash the password
    hashed_password = generate_password_hash(data['password'])
    
    # Create a new user with the hashed password
    new_user = Users(name=data['name'], username=data['username'], password=hashed_password)
    db.session.add(new_user)
    db.session.commit()
    
    return jsonify(new_user.to_dict()), 201

@app.route('/login', methods=['POST'])
def login():
    auth = request.json
    if not auth or 'username' not in auth or 'password' not in auth:
        return jsonify({'error': 'Missing username or password'}), 400

    # Find the user by username
    user = Users.query.filter_by(username=auth['username']).first()
    
    # Verify the password
    if not user or not check_password_hash(user.password, auth['password']):
        return jsonify({'error': 'Invalid username or password'}), 401

    # Generate a JWT token
    token = jwt.encode({
        'user': user.username,
        'exp': datetime.datetime.utcnow() + datetime.timedelta(minutes=10)
    }, SECRET_KEY, algorithm="HS256")
    
    return jsonify({'token': token})

@app.route('/users/<int:id>', methods=['PUT'])
@token_required
def update_user(id):
    user = Users.query.get(id)
    if not user:
        return jsonify({'error': 'User not found'}), 404

    data = request.json
    if 'name' in data:
        user.name = data['name']
    if 'password' in data:
        # Hash the new password
        user.password = generate_password_hash(data['password'])
    
    db.session.commit()
    return jsonify(user.to_dict())

# Product Operations (Require JWT Token)
@app.route('/products', methods=['POST'])
@token_required
def create_product():
    data = request.json
    if not data or 'pname' not in data or 'price' not in data or 'stock' not in data:
        return jsonify({'error': 'Missing required fields'}), 400

    new_product = Products(
        pname=data['pname'],
        description=data.get('description', ''),
        price=data['price'],
        stock=data['stock']
    )
    db.session.add(new_product)
    db.session.commit()
    return jsonify(new_product.to_dict()), 201

@app.route('/products', methods=['GET'])
@token_required
def get_all_products():
    products = Products.query.all()
    return jsonify([product.to_dict() for product in products])

@app.route('/products/<int:pid>', methods=['GET'])
@token_required
def get_single_product(pid):
    product = Products.query.get(pid)
    if not product:
        return jsonify({'error': 'Product not found'}), 404
    return jsonify(product.to_dict())

@app.route('/products/<int:pid>', methods=['PUT'])
@token_required
def update_product(pid):
    product = Products.query.get(pid)
    if not product:
        return jsonify({'error': 'Product not found'}), 404

    data = request.json
    if 'pname' in data:
        product.pname = data['pname']
    if 'description' in data:
        product.description = data['description']
    if 'price' in data:
        product.price = data['price']
    if 'stock' in data:
        product.stock = data['stock']
    db.session.commit()
    return jsonify(product.to_dict())

@app.route('/products/<int:pid>', methods=['DELETE'])
@token_required
def delete_product(pid):
    product = Products.query.get(pid)
    if not product:
        return jsonify({'error': 'Product not found'}), 404
    db.session.delete(product)
    db.session.commit()
    return jsonify({'result': True})

# Run the Application
if __name__ == '__main__':
    app.run(debug=True)