from flask import Flask, request, jsonify
from flask_cors import CORS
import os

app = Flask(__name__)
CORS(app)

# In-memory store for demo
auth_codes = {'DEMO-CODE-1234': True}

@app.route('/auth', methods=['POST'])
def auth():
    data = request.get_json()
    code = data.get('code')
    otp = data.get('otp')
    #password = data.get('password')
    # Demo validation
    if code in auth_codes and otp == '000000':
        return jsonify({'status': 'ok'}), 200
    return jsonify({'error': 'Invalid credentials'}), 400

@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    name = data.get('name')
    email = data.get('email')
    # Simple check
    if name and '@' in email:
        return jsonify({'status': 'registered'}), 201
    return jsonify({'error': 'Invalid registration data'}), 400

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=True)
