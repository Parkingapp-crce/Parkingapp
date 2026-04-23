import requests

# register
reg_response = requests.post("http://localhost:8000/api/v1/auth/register/", json={
    "full_name": "Test Owner",
    "email": "testowner6@example.com",
    "password": "Password123!",
    "phone": "9999999998",
    "role": "user",
    "flat_number": "A101",
    "floor_number": "1",
    "society_join_code": "A2541825"
})
print("Register:", reg_response.status_code, reg_response.text)

# login
login_response = requests.post("http://localhost:8000/api/v1/auth/login/", json={
    "email": "testowner6@example.com",
    "password": "Password123!"
})
if login_response.status_code == 200:
    token = login_response.json().get("access")
    
    # get profile
    profile_response = requests.get("http://localhost:8000/api/v1/auth/profile/", headers={
        "Authorization": f"Bearer {token}"
    })
    print("Profile status:", profile_response.status_code)
    print("Profile body:", profile_response.text)
