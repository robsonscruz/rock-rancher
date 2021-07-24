from flask import Flask, request, Response, jsonify
from json import dumps, loads
from middleware import set_unhealth, set_unready_for_seconds, middleware
import os 
from pymongo import MongoClient
from marshmallow import Schema, fields, ValidationError

app = Flask('comentarios')
app.wsgi_app = middleware(app.wsgi_app)
app.debug = True

# DB
app.config['MONGODB_URL'] = os.getenv("MONGODB_URL", "mongodb+srv://rcruz:VdLQ2ZIYTXkqGrCn@cluster0.nqf2q.mongodb.net/db_commets?retryWrites=true&w=majority")
client = MongoClient(app.config['MONGODB_URL'])
db = client.db_commets

# Schema
class CommentsSchema(Schema):
    email       = fields.String(required=True)
    comment     = fields.String(required=True)
    content_id  = fields.Integer(required=True)

@app.route('/')
def index():
    return jsonify({'api': 'v.1.0.0', 'host': os.uname().nodename})

@app.route('/unhealth', methods=['PUT'])
def unhealth():
    set_unhealth()
    return Response('OK')

@app.route('/unreadyfor/<int:seconds>', methods=['PUT'])
def unready_for(seconds):
    set_unready_for_seconds(seconds)
    return Response('OK')

@app.route('/health', methods=['GET'])
def heath():
    return Response('OK')

@app.route('/stress/<int:seconds>')
def stress(seconds):
    pystress(seconds, 1)
    return Response('OK')

@app.route('/api/comment/new', methods=['POST'])
def api_comment_new():
    request_data = request.get_json()
    schema = CommentsSchema()
    try:
        # Validate request body against schema data types
        result = schema.load(request_data)
        # Save new comment
        db.commets.insert_one(request_data)
    except ValidationError as err:
        # Return a nice message if validation fails
        return jsonify(err.messages), 400

    message = 'comment created and associated with content_id {}'.format(request_data['content_id'])

    # Send data back as JSON
    return jsonify({'status': 'SUCCESS', 'message': message }), 200

@app.route('/api/comment/list/<content_id>')
def api_comment_list(content_id):
    if content_id is not None and content_id.isnumeric():
        content_id = int(content_id)

    if not isinstance(content_id, int):
        return jsonify({'status': 'INVALID-PARAMETER', 'message': 'content_id {} is invalid.'.format(content_id)}), 400

    # Find DB
    comments = list(db.commets.find({"content_id" : content_id}, {"email":1, "comment": 1, "content_id": 1, "_id": 0}))

    if not comments:
        return jsonify({'status': 'NOT-FOUND', 'message': 'content_id {} not found'.format(content_id)}), 404

    return jsonify(comments), 200

if __name__ == '__main__':
    app.run()
