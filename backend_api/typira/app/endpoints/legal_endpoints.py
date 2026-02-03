from flask import Blueprint, render_template

ns = Blueprint('legal', __name__)

@ns.route('/privacy')
def privacy():
    return render_template('privacy.html')

@ns.route('/terms')
def terms():
    return render_template('terms.html')
