# Have to place all the messages' classes to the same file to make generated Objective C classes 
# names shorter

from protorpc import messages

class Session(messages.Message):
    cookie = messages.StringField(1)
    expires = messages.StringField(2)

class Tools(messages.Message):
    email = messages.StringField(1)
    push = messages.StringField(2, repeated=True)
    sms = messages.StringField(3)
    
class PasswordRequsest(messages.Message):
    tool = messages.StringField(1)
    session = messages.MessageField(Session, 2)
    
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
    session = messages.MessageField(Session, 4)

class Region(messages.Message):
    id = messages.StringField(1)
    name = messages.StringField(2)
    
    latitude = messages.FloatField(3)
    longitude = messages.FloatField(4)
   
class RegionList (messages.Message):
    possible_region = messages.MessageField(Region, 1) 
    regions = messages.MessageField(Region, 2, repeated = True)
    
class User(messages.Message):
    login = messages.StringField(1)
    
    email = messages.StringField(2)
    phone = messages.StringField(3)
    
    gender = messages.BooleanField(4)
    password = messages.StringField(5)
    
    userpic = messages.BytesField(6)
    
    region = messages.MessageField(Region, 7)
    
    subscription_end_date = messages.StringField(8) 
    
    # Store here newly created installation to pass client a cookie.
    # May be I should find a better way...
    # In request it is used for passing session info 
    session = messages.MessageField(Session, 9)
    
