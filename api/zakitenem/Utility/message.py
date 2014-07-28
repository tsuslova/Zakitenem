
from protorpc import messages

k_auth = "http://%s/api/auth"
k_logout = "http://%s/api/logout" 
k_password_tools = "http://%s/api/password/tools" 
k_password_request = "http://%s/api/password/request"

class Main(messages.Message):
    auth = messages.StringField(1)
    logout = messages.StringField(2)
    password_tools = messages.StringField(3)
    password_request = messages.StringField(4)
    
def main_with_host(hostname):
    return Main(auth = k_auth % hostname,
                logout = k_logout % hostname,
                password_tools = k_password_tools % hostname,
                password_request = k_password_request % hostname
                )
