from flask import request
from flask_restx import Resource
from app.util.scheduler_dto import SchedulerDto
from app.models.scheduler import Schedule
from app import db
from app.helpers.auth_helpers import token_required

ns = SchedulerDto.api
_schedule = SchedulerDto.schedule

@ns.route('/')
class SchedulerList(Resource):
    @ns.doc('list_of_schedules')
    @ns.doc(security="apikey")
    @token_required
    @ns.marshal_list_with(_schedule, envelope='data')
    def get(self, current_user, **kwargs):
        """List all schedules for the current user"""
        return Schedule.query.filter_by(user_id=current_user.id).all()

    @ns.doc('create_a_new_schedule')
    @ns.doc(security="apikey")
    @token_required
    @ns.expect(_schedule, validate=True)
    def post(self, current_user, **kwargs):
        """Create a new schedule"""
        data = request.json
        new_schedule = Schedule(
            user_id=current_user.id,
            title=data.get('title'),
            action_description=data.get('action_description'),
            timezone=data.get('timezone', 'UTC'),
            date_or_repeat=data.get('date_or_repeat'),
            time=data.get('time'),
            is_repeat=data.get('is_repeat', False)
        )
        db.session.add(new_schedule)
        db.session.commit()
        return {
            "status": "success",
            "message": "Schedule created successfully",
            "id": new_schedule.id
        }, 201

@ns.route('/<int:id>')
@ns.param('id', 'The schedule identifier')
class Scheduler(Resource):
    @ns.doc('get_a_schedule')
    @ns.doc(security="apikey")
    @token_required
    @ns.marshal_with(_schedule)
    def get(self, id, current_user, **kwargs):
        """Get a specific schedule"""
        schedule = Schedule.query.filter_by(id=id, user_id=current_user.id).first()
        if not schedule:
            ns.abort(404, "Schedule not found")
        return schedule

    @ns.doc('update_a_schedule')
    @ns.doc(security="apikey")
    @token_required
    @ns.expect(_schedule, validate=True)
    def put(self, id, current_user, **kwargs):
        """Update a schedule"""
        schedule = Schedule.query.filter_by(id=id, user_id=current_user.id).first()
        if not schedule:
            ns.abort(404, "Schedule not found")
        
        data = request.json
        schedule.title = data.get('title', schedule.title)
        schedule.action_description = data.get('action_description', schedule.action_description)
        schedule.timezone = data.get('timezone', schedule.timezone)
        schedule.date_or_repeat = data.get('date_or_repeat', schedule.date_or_repeat)
        schedule.time = data.get('time', schedule.time)
        schedule.is_repeat = data.get('is_repeat', schedule.is_repeat)
        
        db.session.commit()
        return {"status": "success", "message": "Schedule updated successfully"}

    @ns.doc('delete_a_schedule')
    @ns.doc(security="apikey")
    @token_required
    def delete(self, id, current_user, **kwargs):
        """Delete a schedule"""
        schedule = Schedule.query.filter_by(id=id, user_id=current_user.id).first()
        if not schedule:
            ns.abort(404, "Schedule not found")
        
        db.session.delete(schedule)
        db.session.commit()
        return {"status": "success", "message": "Schedule deleted successfully"}
