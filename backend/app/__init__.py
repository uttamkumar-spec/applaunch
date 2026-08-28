from flask import Flask, jsonify
from flask_cors import CORS

from .config import Config
from .extensions import init_mongo, limiter


def create_app() -> Flask:
    app = Flask(__name__)
    app.config.from_object(Config)

    CORS(app, origins=app.config["CORS_ORIGINS"], supports_credentials=True)
    init_mongo(app)
    limiter.init_app(app)

    from .routes import admin, ai_chat, coach, form_analysis, nutrition, progress, strava, users, workouts

    app.register_blueprint(users.bp)
    app.register_blueprint(workouts.bp)
    app.register_blueprint(ai_chat.bp)
    app.register_blueprint(nutrition.bp)
    app.register_blueprint(progress.bp)
    app.register_blueprint(strava.bp)
    app.register_blueprint(admin.bp)
    app.register_blueprint(coach.bp)
    app.register_blueprint(form_analysis.bp)

    @app.get("/api/health")
    def health():
        return jsonify({"status": "ok"})

    @app.errorhandler(404)
    def not_found(_):
        return jsonify({"error": "not found"}), 404

    @app.errorhandler(429)
    def rate_limited(exc):
        return jsonify({"error": f"Too many requests — please slow down. ({exc.description})"}), 429

    @app.errorhandler(500)
    def server_error(exc):
        app.logger.exception(exc)
        return jsonify({"error": "internal server error"}), 500

    return app
