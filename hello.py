from flask import Flask, url_for
from flask import request, render_template
app = Flask(__name__)

@app.route('/')
def index():
    return "index Page"


@app.route('/login/<name>')
def login(name):
    #return "you are logined %s" %name
    return render_template('hello.html', name=name)

def some(cctv):
    pass
@app.route('/login/<int:Uid>', methods=['GET', 'POST'])
def loginById(Uid):
    if request.method == 'POST':
        return "request method is POST"
    else:
        return "Login by user id %d " % Uid

#url_for('static', filename='style.css')

if __name__ == '__main__':
    app.debug = True
    app.run(host='0.0.0.0')
