import requests
from flask import current_app


class SupabaseAdminError(Exception):
    pass


def create_auth_user(email: str, password: str, full_name: str) -> str:
    """Creates a Supabase auth user via the Admin API and returns its UUID.
    Requires the service_role key — server-side only."""
    url = current_app.config["SUPABASE_URL"]
    service_key = current_app.config["SUPABASE_SERVICE_ROLE_KEY"]
    if not url or not service_key:
        raise SupabaseAdminError("Supabase admin credentials are not configured on the server yet")

    try:
        res = requests.post(
            f"{url}/auth/v1/admin/users",
            headers={
                "apikey": service_key,
                "Authorization": f"Bearer {service_key}",
                "Content-Type": "application/json",
            },
            json={
                "email": email,
                "password": password,
                "email_confirm": True,
                "user_metadata": {"full_name": full_name},
            },
            timeout=15,
        )
    except requests.exceptions.RequestException as exc:
        raise SupabaseAdminError(f"Could not reach Supabase: {exc}") from exc

    if res.status_code >= 400:
        raise SupabaseAdminError(f"Supabase user creation failed: {res.text}")

    return res.json()["id"]
