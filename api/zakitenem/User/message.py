# Have to place all the messages' classes to the same file to make generated Objective C classes 
# names shorter

from protorpc import messages

class Session(messages.Message):
    cookie = messages.StringField(1)
    expires = messages.StringField(2)


class LoginInfo(messages.Message):
    # required:
    login = messages.StringField(1)
    device_id = messages.StringField(2)
    # optional
    password = messages.StringField(3)
    device_token = messages.StringField(4)

class AppInstallation(messages.Message):
    device_id = messages.StringField(1)
    device_token = messages.StringField(2)
    date = messages.StringField(3)
    session_info = messages.MessageField(Session, 4)

class User(messages.Message):
    login = messages.StringField(1)
    
    email = messages.StringField(2)
    phone = messages.StringField(3)
    
    gender = messages.BooleanField(4)
    password = messages.StringField(5)
    
    userpic = messages.StringField(6)
    # TODO: how to store user region?
    region = messages.StringField(7)
    subscription_end_date = messages.StringField(8) 
    